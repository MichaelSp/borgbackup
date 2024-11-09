FROM alpine:3.20

RUN apk add --no-cache borgbackup openssh yq
RUN adduser -D -s /bin/sh borg

COPY ./entrypoint.sh /entrypoint.sh

USER borg

ENTRYPOINT ["/entrypoint.sh"]
