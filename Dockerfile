FROM alpine:3.20

RUN apk add --no-cache borgbackup openssh

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
