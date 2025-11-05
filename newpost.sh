#!/usr/bin/env bash
# newpost.sh - safe, stable post creation with reliable slug generation
# Usage:
#   ./newpost.sh [--no-push] "Post Title"
set -euo pipefail

# --- config ---
MAX_SLUG_LEN=80
DIR="content/posts"
BASE_URL="https://sonicsrc.github.io/posts"
COUNTER_LIMIT=1000

# --- helpers ---
die()  { printf '%s\n' "Error: $*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }
cleanup() { [[ -n "${_TMP_COMMIT:-}" ]] && [[ -f "$_TMP_COMMIT" ]] && rm -f "$_TMP_COMMIT"; }
trap cleanup EXIT

# --- parse args ---
NO_PUSH=0
if [[ "${1:-}" = "--no-push" ]]; then
  NO_PUSH=1
  shift
fi

TITLE="${1:-}"
if [[ -z "${TITLE// /}" ]]; then
  cat <<USAGE
Usage: $0 [--no-push] "Post Title"

Creates a post file under ${DIR}/YYYY-MM-DD-slug.md and opens it in your editor.
Options:
  --no-push   Do not run 'git push' after committing (keeps it local)
USAGE
  exit 1
fi

# Normalize title:
# - collapse whitespace, trim leading/trailing
TITLE="$(printf '%s' "$TITLE" | tr '\t\r\n' '   ' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | sed -E 's/[[:space:]]+/ /g')"
if [[ ${#TITLE} -gt 2000 ]]; then
  die "Title too long (over 2000 chars)."
fi

# Escape for YAML double quotes
TITLE_ESCAPED="${TITLE//\\/\\\\}"
TITLE_ESCAPED="${TITLE_ESCAPED//\"/\\\"}"

# --- slug generation ---
# 1) transliterate with iconv if available, otherwise use raw title
SLUG_RAW="$TITLE"
if command -v iconv >/dev/null 2>&1; then
  SLUG_RAW="$(printf '%s' "$TITLE" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null || printf '%s' "$TITLE")"
fi

# 2) build slug: lowercase, replace non-alnum with '-', collapse dashes, trim edges
SLUG="$(printf '%s' "$SLUG_RAW" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | sed -E 's/-+/-/g')"

# fallback if slug empty (e.g., title was "!!!")
if [[ -z "$SLUG" ]]; then
  SLUG="post-$(date +%s)"
fi

# enforce max length (avoid mid-dash cut)
if (( ${#SLUG} > MAX_SLUG_LEN )); then
  SLUG="${SLUG:0:MAX_SLUG_LEN}"
  SLUG="${SLUG%-}"
fi

# --- determine filename and final slug consistently ---
DATE="$(date +%F)"
mkdir -p "$DIR"

BASE_FILENAME="${DATE}-${SLUG}.md"
PRIMARY_PATH="$DIR/$BASE_FILENAME"

if [[ -f "$PRIMARY_PATH" ]]; then
  # If primary exists, we will open it to edit (no suffixing)
  FILENAME="$PRIMARY_PATH"
  FINAL_SLUG="$SLUG"
  info "Editing existing file: $FILENAME"
else
  # Need to create a new file; ensure uniqueness by appending -n suffix if necessary
  FILENAME="$PRIMARY_PATH"
  FINAL_SLUG="$SLUG"
  COUNTER=0
  while [[ -f "$FILENAME" && $COUNTER -lt $COUNTER_LIMIT ]]; do
    COUNTER=$((COUNTER + 1))
    FINAL_SLUG="${SLUG}-${COUNTER}"
    FILENAME="$DIR/${DATE}-${FINAL_SLUG}.md"
  done
  if [[ -f "$FILENAME" ]]; then
    die "Failed to create unique filename after ${COUNTER_LIMIT} attempts."
  fi

  # create template file with consistent slug in front matter
  cat > "$FILENAME" <<EOF
---
title: "$TITLE_ESCAPED"
date: "$DATE"
slug: "$FINAL_SLUG"
---

Write your content here in Markdown.

EOF
  info "Created $FILENAME (slug: $FINAL_SLUG)"
fi

# --- open editor ---
EDITOR_CMD="${VISUAL:-${EDITOR:-nano}}"
# ensure editor exists; fallback to nano/vi
if ! command -v "${EDITOR_CMD%% *}" >/dev/null 2>&1; then
  info "Warning: editor '$EDITOR_CMD' not found in PATH, falling back..."
  if command -v nano >/dev/null 2>&1; then
    EDITOR_CMD="nano"
  elif command -v vi >/dev/null 2>&1; then
    EDITOR_CMD="vi"
  else
    die "No suitable editor found. Set \$VISUAL or \$EDITOR."
  fi
fi

"$EDITOR_CMD" "$FILENAME"

# --- git operations ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  info "Not inside a git repository. Skipping git operations."
  info "File saved: $FILENAME"
  exit 0
fi

git add -- "$FILENAME"

_TMP_COMMIT="$(mktemp)"
printf '%s\n' "Add/Update post: $TITLE" > "$_TMP_COMMIT"

if git commit -F "$_TMP_COMMIT"; then
  info "Committed changes."
else
  info "No changes to commit (file unchanged)."
fi

if [[ "$NO_PUSH" -eq 0 ]]; then
  if git remote >/dev/null 2>&1; then
    info "Pushing to remote..."
    git push || info "git push failed; check remote/credentials."
  else
    info "No git remote configured; skipping push."
  fi
else
  info "Skipping git push (--no-push)."
fi

info "✅ Done."
info "🔗 URL: ${BASE_URL}/${FINAL_SLUG}.html"