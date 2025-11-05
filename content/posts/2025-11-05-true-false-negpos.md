---
title: "True false negpos"
date: "2025-11-05"
slug: "true-false-negpos"
---


# Images & Copyable Blocks

This post demonstrates an image, a captioned figure, a copy-friendly command block, and a syntax-highlighted code block.

## Image via Markdown

You can reference images stored in `assets/images/`:

![Mock screenshot](/assets/images/mock-screenshot.png "Mock screenshot")

## Image with caption and sizing (HTML figure)

If you want a caption or to control width, use HTML:

<figure>
  <img src="/assets/images/linux-hardening-flow.svg" alt="Linux hardening flow" width="720"/>
  <figcaption>Figure: Linux hardening flow (SVG)</figcaption>
</figure>

> Tip: use root-relative paths (`/assets/images/...`) so the image works the same locally and on GitHub Pages.

## Copyable shell commands

Run these in a terminal. The copy button will remove the leading `$ ` characters so you get runnable lines:

```bash
$ ./newpost.sh "My New Post"
$ git add .
$ git commit -m "Add post with image"
$ git push
```

---

# 3) Add image to repository (commands)

From the repo root:

```bash
# copy your image into assets
cp /path/to/mock-screenshot.png assets/images/

# strip metadata (recommended by your README security notes)
# requires exiftool; install if missing (e.g., apt-get install libimage-exiftool-perl)
exiftool -all= assets/images/mock-screenshot.png
# (exiftool writes a _original copy by default unless you pass -overwrite_original)

# stage & commit
git add assets/images/mock-screenshot.png content/posts/2025-11-05-images-and-copyable-commands.md
git commit -m "Add example post with image and copyable commands"
git push
```
