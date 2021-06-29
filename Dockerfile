FROM python:3.9.1-alpine3.12

# Install any additional packages needed for importers
ARG APK_PKGS
ARG PIP_PKGS

RUN apk add --no-cache \
    build-base \
    git \
    git-lfs \
    libxml2-dev \
    libxslt-dev \
    openssh-client \
    $APK_PKGS \
  && pip install \
    beancount==2.3.4 \
    fava==1.19 \
    flask==1.1.4 \
    $PIP_PKGS \
  && apk del \
    build-base \
    libxml2-dev \
    libxslt-dev

COPY askpass.sh /usr/local/bin/
COPY monitor.sh /usr/local/bin/
COPY start.sh /

ENV GIT_ASKPASS=/usr/local/bin/askpass.sh
ENV REPOSITORY_ROOT=/data
ENV FAVA_PORT=5000

EXPOSE $FAVA_PORT

VOLUME $REPOSITORY_ROOT

ENTRYPOINT ["/start.sh"]
