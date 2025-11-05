#!/usr/bin/env python3
"""
Simple static site builder:
- Reads Markdown files from content/posts/*.md
- Uses very small YAML-like front matter (title, date, slug)
- Renders posts with Jinja2 templates and writes HTML into site/
- Generates site/index.html and site/posts/index.html (All Posts)
- Copies assets/
"""
import os
import shutil
from pathlib import Path
import datetime
import markdown
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).parent.resolve()
CONTENT = ROOT / "content"
TEMPLATES = ROOT / "templates"
ASSETS = ROOT / "assets"
SITE = ROOT / "site"
POSTS_DIR = CONTENT / "posts"

env = Environment(loader=FileSystemLoader(str(TEMPLATES)))


def parse_front_matter(text):
    text = text.lstrip()
    if text.startswith('---'):
        parts = text.split('---', 2)
        if len(parts) >= 3:
            fm_raw = parts[1].strip()
            body = parts[2].lstrip()
            fm = {}
            for line in fm_raw.splitlines():
                if ':' in line:
                    k, v = line.split(':', 1)
                    fm[k.strip()] = v.strip().strip('"').strip("'")
            return fm, body
    return {}, text


def ensure_site():
    if SITE.exists():
        shutil.rmtree(SITE)
    SITE.mkdir(parents=True, exist_ok=True)
    (SITE / "posts").mkdir(parents=True, exist_ok=True)
    (SITE / "assets").mkdir(parents=True, exist_ok=True)


def build_posts():
    posts_meta = []
    md = markdown.Markdown(extensions=['fenced_code', 'tables'])
    for mdfile in sorted(POSTS_DIR.glob("*.md")):
        try:
            text = mdfile.read_text(encoding="utf-8")
        except Exception as e:
            print(f"[WARN] Could not read {mdfile}: {e}")
            continue

        fm, body = parse_front_matter(text)
        if not fm.get("title"):
            print(f"[SKIP] {mdfile.name}: missing front matter title")
            continue

        # Normalize slug safely
        slug = (fm.get("slug") or mdfile.stem).strip().lower()
        slug = "".join(c if c.isalnum() or c == "-" else "-" for c in slug)
        slug = "-".join(filter(None, slug.split("-")))  # collapse multiple dashes

        # Markdown → HTML
        try:
            html_body = md.convert(body)
        except Exception as e:
            print(f"[WARN] Markdown conversion failed for {mdfile}: {e}")
            continue

        # Title and date
        title = fm["title"]
        date_str = fm.get("date", "")
        try:
            date = datetime.datetime.fromisoformat(date_str) if date_str else datetime.datetime.fromtimestamp(mdfile.stat().st_mtime)
        except Exception:
            date = datetime.datetime.fromtimestamp(mdfile.stat().st_mtime)

        # Write HTML file
        outpath = SITE / "posts" / f"{slug}.html"
        tpl = env.get_template("post.html")
        rendered = tpl.render(
            title=title,
            content=html_body,
            date=date.strftime("%Y-%m-%d"),
            site_title="sonicsrc",
        )
        outpath.write_text(rendered, encoding="utf-8")
        posts_meta.append({"title": title, "url": f"posts/{slug}.html", "date": date})

        print(f"[OK] Built {slug}.html from {mdfile.name}")
        md.reset()

    posts_meta.sort(key=lambda x: x["date"], reverse=True)
    print(f"Built {len(posts_meta)} posts.")
    return posts_meta


def build_indexes(posts_meta):
    # site index (home)
    tpl_index = env.get_template("index.html")
    SITE.joinpath("index.html").write_text(tpl_index.render(posts=posts_meta, site_title="sonicsrc"), encoding='utf-8')

    # posts listing
    tpl_posts = env.get_template("posts_index.html")
    SITE.joinpath("posts/index.html").write_text(tpl_posts.render(posts=posts_meta, site_title="sonicsrc"), encoding='utf-8')


def copy_assets():
    assets_dir = Path("assets")
    target_dir = Path("site/assets")
    target_dir.mkdir(parents=True, exist_ok=True)

    for item in assets_dir.rglob("*"):
        target = target_dir / item.relative_to(assets_dir)

        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            shutil.copy2(item, target)


def main():
    ensure_site()
    posts_meta = build_posts()
    build_indexes(posts_meta)
    copy_assets()
    print("Built site/ with", len(posts_meta), "posts.")


if __name__ == "__main__":
    main()
