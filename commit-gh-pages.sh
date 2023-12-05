hugo
echo 'gitdir: ../.git/modules/public' > public/.git
cd public && git add --all && git commit -m "publishing to gh-pages" && cd ..
