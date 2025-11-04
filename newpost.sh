#!/usr/bin/env bash
# usage: ./newpost.sh "Post Title"
if [ -z "$1" ]; then
  echo "Usage: $0 \"Post Title\""
  exit 1
fi
TITLE="$1"
DATE=\$(date +%F)
SLUG=\$(echo "\$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-|-$//g')
DIR=content/posts
mkdir -p "\$DIR"
FILE="\$DIR/\$DATE-\$SLUG.md"
cat > "\$FILE" <<EOM
---
title: "\$TITLE"
date: "\$DATE"
slug: "\$SLUG"
---

Write your post here in Markdown.

EOM
${EDITOR:-nano} "\$FILE"
echo "Created \$FILE"
