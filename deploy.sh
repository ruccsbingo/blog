#! /bin/sh

hexo generate
cp -R public/* ../deploy
cd ../deploy
git add .
git commit -m "update"
git push origin master

