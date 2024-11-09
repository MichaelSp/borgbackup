FROM alpine:3.20

RUN apk add --no-cache borgbackup openssh yq su-exec
RUN adduser -D -s /bin/sh borg &&  \
    mkdir -p /etc/ssh/keys && \
    chmod u+s /usr/bin/crontab

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
