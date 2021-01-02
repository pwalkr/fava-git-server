#!/bin/sh

# If SSH_KEY private key is defined, write id_rsa for ssh-git
if [ "$SSH_KEY" ]; then
    privkey="$HOME/.ssh/id_rsa"
    mkdir -p "$(dirname "$privkey")"
    echo "$SSH_KEY" > "$privkey"
    chmod -R 700 "$(dirname "$privkey")"
    set -x
    ssh-keygen -y -f "$privkey" > "$privkey".pub
    { set +x; } 2>/dev/null
fi

# If repository is not populated, clone
if [ -z "$(ls "$REPOSITORY_ROOT")" ]; then
    if [ -z "$GIT_REPO" ]; then
        echo "Please set GIT_REPO to something we can clone"
        exit 1
    fi
    set -x
    git clone --recurse-submodules "$GIT_REPO" "$REPOSITORY_ROOT"
    { set +x; } 2>/dev/null
fi

cd "$REPOSITORY_ROOT"

if [ "$GIT_NAME" ]; then
    export GIT_AUTHOR_NAME="$GIT_NAME"
    export GIT_COMMITTER_NAME="$GIT_NAME"
fi

if [ "$GIT_EMAIL" ]; then
    export GIT_AUTHOR_EMAIL="$GIT_EMAIL"
    export GIT_COMMITTER_EMAIL="$GIT_EMAIL"
fi

# Start monitor to watch for local/remote changes
set -x
/usr/local/bin/monitor.sh &
{ set +x; } 2>/dev/null
sleep 1

export PYTHONPATH=.
set -x
fava --host=0.0.0.0 --port="$FAVA_PORT" "$@" $BEAN_FILE
