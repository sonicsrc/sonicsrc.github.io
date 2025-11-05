# Publishing Workflow

This guide explains how to publish new posts, update content, and verify
the GitHub Pages pipeline.

------------------------------------------------------------------------

## Create a New Post

Use the automation script:

``` bash
./newpost.sh "Your Post Title"
```

The script will:

-   generate a markdown file in `content/posts/`
-   sanitize the URL slug
-   commit the post
-   push to `main`

You will see output similar to:

    Created and pushed: content/posts/YYYY-MM-DD-your-post-title.md
    URL will be: https://<username>.github.io/posts/your-post-title.html

------------------------------------------------------------------------

## Edit the New Post

Once created, open the file and add content:

    content/posts/YYYY-MM-DD-your-post-title.md

Include code blocks, screenshots, commands, diagrams, etc.

Images should go under:

    assets/images/

Example:

``` bash
cp local_screenshot.png assets/images/
```

------------------------------------------------------------------------

## Local Preview (Optional)

To preview before publishing:

``` bash
python build.py
python -m http.server --directory site 8000 &
xdg-open http://localhost:8000
```

------------------------------------------------------------------------

## Commit Additional Changes

If you add images or edit posts:

``` bash
git add content/posts/* assets/images/*
git commit -m "Update post content and assets"
git push
```

This triggers the build workflow.

------------------------------------------------------------------------

## Verify Deployment

GitHub Actions automatically deploys.

Watch logs:

``` bash
gh run watch
```

Verify page:

``` bash
curl -I https://<username>.github.io/posts/your-post-title.html
```

Response should include `200 OK`.

------------------------------------------------------------------------

## Remove a Post

Delete the file:

``` bash
rm content/posts/DATE-slug.md
git add .
git commit -m "Remove post"
git push
```

------------------------------------------------------------------------

## Update Homepage

Edit:

    content/index.md

Then:

``` bash
git add content/index.md
git commit -m "Update homepage"
git push
```

------------------------------------------------------------------------

## Security Notes

-   Images should be stripped of metadata
-   Avoid personal identifiers
-   Use ProtonMail or alias-based commit email
-   CI/CD handles deployment, do not push to `gh-pages`

------------------------------------------------------------------------

## Summary Commands

New post:

``` bash
./newpost.sh "Title"
```

Update post:

``` bash
vim content/posts/<file>.md
git add .
git commit -m "Edit post"
git push
```

Add images:

``` bash
cp img.png assets/images/
git add assets/images/*
git commit -m "Add image"
git push
```

Local preview:

``` bash
python build.py && python -m http.server --directory site 8000
```

------------------------------------------------------------------------

Happy publishing. Stay silent. Stay sharp. Build truth one post at a
time.
