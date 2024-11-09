FROM alpine:3.20

RUN apk add --no-cache borgbackup openssh yq
RUN mkdir -p /etc/ssh/keys

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
