#!/bin/sh
set -x

DIR=$(dirname "$0")
version=$(git describe  --always --tags --long --abbrev=8)
buildtime=$(date -u +%Y%m%d.%H%M%S)

#cd $DIR/..

if [[ $(git status -s) ]]
then
    echo "The working directory is dirty. Commiting any pending changes."
    git add --all
    git commit -m "hugo source updated ${buildtime} ${version}"
    git push
fi

echo "Generating site"
hugo

cd public && git add --all && git commit -m "publishing ${buildtime} ${version}" && git push && cd ..
