FROM alpine:3.21

RUN apk add --no-cache borgbackup openssh yq kubectl
RUN mkdir -p /etc/ssh/keys /app

WORKDIR /app

COPY ./app /app
COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
