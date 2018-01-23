#!/bin/sh
#set -o errexit

#s3cmd sync -n --access_key=${AWS_ACCESS_KEY} --
aws s3 sync static/img/ s3://img.networkchallenge.de 
#--dryrun

git clone https://github.com/adulescentulus/adulescentulus.github.io.git /tmp/target
git submodule init
git submodule update

hugo -d /tmp/target
cd /tmp/target
git add .
git commit -am "content update"
git push origin master