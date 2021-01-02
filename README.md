# Fava Server with Git Backend

This project runs a [beancount fava](https://beancount.github.io/fava/) server backed by a git repository with support for bidirectional source updates.
The server can fetch updates on trigger from webhook (loading changes from local development)

## Usage

Build the container

    docker build -t local/fava .

Run to manage a pre-fetched clone on default listening ports

    docker run -d -p 5000:5000 -p 5001:5001 \
        -v $HOME/.ssh:/root/.ssh:ro \
        -v $PWD:/data \
        -e GIT_NAME="Fava" \
        -e GIT_EMAIL="fava@example.com" \
        -e BEAN_FILE=main.beancount \
        local/fava

To trigger fava updates on push to the upstream repository, create a webook for push events pointing to the server at `WEBHOOK_PORT`.
For a local test, you can use curl:

    curl -XPOST localhost:5001

## Environment Variables

    # Path where your source should be mounted (or will be cloned)
    REPOSITORY_ROOT=/data
    # relative to repo root, optional file argument for fava
    BEAN_FILE=main.bean

    # Listening Ports
    FAVA_PORT=5000     # Default port on which fava listens

    # Git authentication
    GIT_REPO      # Repository to clone (if not already mounted at REPOSITORY_ROOT)
    GIT_USER      # Username for git if using HTTP auth
    GIT_PASSWORD  # Password for git if using HTTP auth
    SSH_KEY       # SSH private key for git if using SSH auth
