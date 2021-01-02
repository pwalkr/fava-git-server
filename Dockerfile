FROM python:3.9.1-alpine3.12

RUN apk add --no-cache \
    build-base \
    git \
    inotify-tools \
    libxml2-dev \
    libxslt-dev \
    openssh-client \
  && pip install \
    beancount==2.3.3 \
    fava==1.17 \
    flask==1.1.2 \
  && apk del \
    build-base \
    libxml2-dev \
    libxslt-dev

COPY askpass.sh /usr/local/bin/
COPY repo.sh /usr/local/bin/
COPY start.sh /
COPY webhook.py /usr/local/bin/

ENV GIT_ASKPASS=/usr/local/bin/askpass.sh
ENV REPOSITORY_ROOT=/data
ENV FAVA_PORT=5000
ENV WEBHOOK_PORT=5001

EXPOSE $FAVA_PORT
EXPOSE $WEBHOOK_PORT

VOLUME $REPOSITORY_ROOT

ENTRYPOINT ["/start.sh"]
