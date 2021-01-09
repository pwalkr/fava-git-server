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

# Start monitor to listen for webhook and file events
set -x
python /usr/local/bin/monitor.py &
{ set +x; } 2>/dev/null
sleep 1

cd "$REPOSITORY_ROOT"
export PYTHONPATH=.
set -x
fava --host=0.0.0.0 --port="$FAVA_PORT" "$@"
