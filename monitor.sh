#!/bin/sh

POLL_DELAY=60
# 15 minutes from first seen change till commit
COMMIT_DELAY=900
COMMIT_MESSAGE="fava snapshot"

upstream="$(git rev-parse --abbrev-ref "@{upstream}")"

log() {
    echo "[$(date "+%y-%m-%d %H:%M:%S")]" "$@"
}

while true; do
    sleep $POLL_DELAY

    if [ "$(git ls-files -m)" ]; then
        log "Local changes detected"
        sleep $COMMIT_DELAY
        git add .
        git commit -am "$COMMIT_MESSAGE"
        git rebase "$upstream"
        git push
    fi

    git fetch -p

    if [ "$(git rev-parse HEAD)" != "$(git rev-parse "$upstream")" ]; then
        log "Remote changes detected"
        git clean -dfx
        git reset --hard "$upstream"
    fi
done
