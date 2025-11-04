#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1-}" ]; then
  echo "Usage: $0 \"Post Title\""
  exit 1
fi

TITLE="$1"
DATE="$(date +%F)"

# create a safe slug: lowercase, replace non-alnum with -, collapse multiple -, trim leading/trailing -
SLUG="$(echo "$TITLE" \
  | iconv -f utf8 -t ascii//TRANSLIT 2>/dev/null || true \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | sed -E 's/-+/-/g')"

# fall back if slug ends up empty
if [ -z "$SLUG" ]; then
  SLUG="post-$(date +%s)"
fi

DIR="content/posts"
mkdir -p "$DIR"

FILENAME="$DIR/${DATE}-${SLUG}.md"

cat > "$FILENAME" <<EOF
---
title: "$TITLE"
date: "$DATE"
slug: "$SLUG"
---

Write your content here in Markdown.
EOF

git add "$FILENAME"
git commit -m "Add post: $TITLE"
git push
echo "Created and pushed: $FILENAME"
echo "Front-matter slug: $SLUG"
