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
        git push
    fi

    git fetch -p

    lrev="$(git rev-parse HEAD)"
    urev="$(git rev-parse "$upstream")"
    if [ "$lrev" != "$urev" ]; then
        if git rev-list HEAD | grep -q "$urev"; then
            log "Retrying push"
            git push
        else
            log "Remote changes detected"
            if git rev-list "$upstream" | grep -q "$lrev"; then
                git pull
            else
                if git rebase "$upstream"; then
                    git push
                else
                    log "Failed to sync. Resetting to origin"
                    git rebase --abort
                    git clean -dfx
                    git reset --hard "$upstream"
                fi
            fi
        fi
    fi
done
