# Pirate Makers blog

Hugo site, published automatically to **https://piratemakers.ca** by GitHub Actions on every push to `main`.

## Getting started

Requirements: [Hugo extended](https://gohugo.io/installation/) (v0.168.0 or newer), [Dart Sass](https://sass-lang.com/dart-sass/) on your `PATH` (`brew install dart-sass`), and git.

```bash
git clone --recursive git@github.com:pirate-makers/blog.git
cd blog
hugo server -D   # -D includes drafts
```

## Writing posts

Posts live in `content/posts/<date>_<slug>/index.md` (add `index.fr.md` alongside for a French version).

Create a new post:

```bash
hugo new posts/$(date +%F)_my-post-title/index.md
```

Set `draft: true` in the front matter while writing; remove it (or let the date pass) to publish. The repo is also set up for the [Front Matter CMS](https://frontmatter.codes) VS Code extension if you prefer editing posts visually.

## Deploy

Push to `main` — that's it. GitHub Actions (`.github/workflows/hugo.yml`) builds the site and deploys it to GitHub Pages. Pull requests get a build check without deploying. Need a manual redeploy? Actions → Hugo → Run workflow.

The custom domain `piratemakers.ca` is configured in the repo's **Settings → Pages**; `static/CNAME` keeps it stable across deploys.

## Theme

The [hello-friend-ng](https://github.com/rhazdon/hugo-theme-hello-friend-ng) theme is **vendored** into `themes/hello-friend-ng/` — no submodule, fully independent from upstream. Community fixes are applied that upstream hasn't merged:

- Dart Sass transpiler + `languages.*.locale` deprecation fix (upstream PRs #530/#531)
- `font-feature-settings` fix for ALL-CAPS code blocks on Linux (PR #528)
- Improved code block styling (PR #529)
- `hugo.Data` instead of deprecated `.Site.Data`

Site-specific styles go in `assets/scss/_custom.scss` (project level) — it is compiled after the theme styles.

Updating the theme is now a manual diff-and-merge against upstream; edit the vendored files freely.
