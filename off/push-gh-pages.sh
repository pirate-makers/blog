hugo
echo 'gitdir: ../.git/modules/public' > public/.git
cd public && git push origin gh-pages && cd ..
