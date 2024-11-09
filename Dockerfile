FROM alpine:3.20

RUN apk add --no-cache borgbackup openssh yq
RUN adduser -D -s /bin/sh borg &&  \
    mkdir -p /etc/ssh/keys && \
    touch /etc/ssh/sshd_config.d/custom.conf /run/sshd.pid && \
    chown borg:borg /etc/ssh/keys /etc/ssh/sshd_config.d/custom.conf /run/sshd.pid

COPY ./entrypoint.sh /entrypoint.sh

USER borg

ENTRYPOINT ["/entrypoint.sh"]
