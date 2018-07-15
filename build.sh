#!/bin/bash
set -o errexit

show_help() {
    echo \"--dry-run\" for only upload images
    echo \"publish\" for deployment
}

OPT_DRYRUN=0
OPT_PUBLISH=0

while [ $# -gt 0 ]
do
    case "$1" in
        --dry-run)
            OPT_DRYRUN=1
            ;;
        publish)
            OPT_PUBLISH=1
            ;;
        -h|help)
            show_help
            exit 0
            ;;
    esac
    shift
done

if [[ $OPT_DRYRUN -eq 1 ]]; then
    aws s3 sync static/img/ s3://imgs.networkchallenge.de --size-only --dryrun
else
    aws s3 sync static/img/ s3://imgs.networkchallenge.de --size-only --metadata-directive REPLACE --cache-control max-age=2419200
fi

if [[ $OPT_PUBLISH -eq 1 ]]; then
    echo publishing ...
    git clone https://github.com/adulescentulus/adulescentulus.github.io.git /tmp/target
    git submodule init
    git submodule update

    hugo -d /tmp/target
    cd /tmp/target
    git add .
    git commit -am "content update"
    git push origin master
else
    echo missing publish argument, doing nothing
fi
