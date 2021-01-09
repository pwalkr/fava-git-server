#!/bin/sh

lockdir="/tmp/lock.d"

retry=30
while ! mkdir $lockdir; do
    ((retry--))
    if [ $retry -lt 1 ]; then
        echo "Failed to acquire lock" 1>&2
        exit 1
    fi
    sleep 1
done

push() {
    set -x
    git add * || return 1
    git commit --all --message Snapshot || ecode=1
    git push || ecode=1
    { set +x; } 2>/dev/null
}

pull() {
    upstream="$(git rev-parse --abbrev-ref "@{upstream}")"
    if [ "$(git rev-parse HEAD)" = "$(git rev-parse "$upstream")" ]; then
        return
    fi
    set -x
    git fetch --prune || ecode=1
    git clean -xfd || ecode=1
    git submodule foreach --recursive git clean -xfd || ecode=1
    git reset --hard "$upstream" || ecode=1
    git submodule foreach --recursive git reset --hard || ecode=1
    git submodule update --init --recursive || ecode=1
    { set +x; } 2>/dev/null
}

case "$1" in
    push|pull)
        cd "$REPOSITORY_ROOT"
        $1 || ecode=1
        ;;
    *)
        echo "Invalid command $1" 1>&2
        ecode=1
        ;;
esac

rmdir $lockdir

exit $ecode
