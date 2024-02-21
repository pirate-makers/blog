# Pirate Makers blog

## Usage

If you don't have the blog locally, use :

```bash
git clone --recursive git@github.com:pirate-makers/blog.git
```

Do some changes in the blog posts (content) in `content/posts`

### Test locally

```bash
hugo serve
```

### Generate pages

Use the script `generate-gh-pages.sh`:

```bash
./generate-gh-pages.sh

The working directory is dirty. Commiting any pending changes.
Generating site

                   | EN
-------------------+-----
  Pages            | 13
  Paginator pages  |  0
  Non-page files   |  0
  Static files     |  7
  Processed images |  0
  Aliases          |  4
  Sitemaps         |  1
  Cleaned          |  0
```

In case of issue with the `public` submodule being dirty:

```bash
cd public
git checkout master
cd ..
```

Then run the `./generate-gh-pages.sh` script.