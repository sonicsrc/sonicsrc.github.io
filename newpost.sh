#!/usr/bin/env bash
set -euo pipefail

# Usage: ./newpost.sh "Post Title"
TITLE="${1:-}"
if [ -z "$TITLE" ]; then
  echo "Usage: $0 \"Post Title\""
  exit 1
fi

DATE="$(date +%F)"

# Build a safe slug: transliterate, lowercase, replace non-alnum with -, collapse dashes, trim
SLUG="$(echo "$TITLE" \
  | iconv -f utf8 -t ascii//TRANSLIT 2>/dev/null || echo "$TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | sed -E 's/-+/-/g')"

[ -z "$SLUG" ] && SLUG="post-$(date +%s)"

DIR="content/posts"
mkdir -p "$DIR"

FILENAME="$DIR/${DATE}-${SLUG}.md"

# If file already exists, open it for editing instead of overwriting
if [ -f "$FILENAME" ]; then
  echo "Editing existing file: $FILENAME"
else
  cat > "$FILENAME" <<EOF
---
title: "$TITLE"
date: "$DATE"
slug: "$SLUG"
---

Write your content here in Markdown.

EOF
  echo "Created $FILENAME"
fi

# Choose editor: VISUAL > EDITOR > nano
EDITOR_CMD="${VISUAL:-${EDITOR:-nano}}"

# Open the file for editing
"$EDITOR_CMD" "$FILENAME"

# After editing, stage, commit and push
git add "$FILENAME"
git commit -m "Add/Update post: $TITLE" || {
  echo "No changes to commit (file unchanged)."
}
git push

echo "✅ Done. Post saved and pushed."
echo "🔗 URL: https://sonicsrc.github.io/posts/${SLUG}.html"
