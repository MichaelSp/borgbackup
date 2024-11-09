#!/usr/bin/env sh

export DEFAULT_SRC="${DEFAULT_SRC:-/data}"
export DEFAULT_KEEP="${DEFAULT_KEEP:-7}"
BACKUP_CONFIG_YAML="${BACKUP_CONFIG_YAML:-/etc/backup/config.yaml}"
SSH_HOST_KEY_DIR="${SSH_HOST_KEY_DIR:-/etc/ssh/keys}"
SSH_PORT="${SSH_PORT:-2222}"

backup() {
  ID=${1}
  SRC=${2}
  KEEP=${3}
  DATE=$(date +%Y-%m-%d-%H-%M-%S)

  set -e # exit on error

  echo "🤖 Running borg backup for $ID from $SRC..."
  borg create --stats --progress --compression lz4 "${BORG_REPO}::${ID}-${DATE}" "${SRC}"

  echo "🤖 Pruning old backups..."
  borg prune --list --keep-within "${KEEP}" "${BORG_REPO}"
}

client() {
  yq 'to_entries | .[] | "\(.value.schedule) /entrypoint.sh backup \(.key) \"\(.value.source // env(DEFAULT_SRC))\" \(.value.keep // env(DEFAULT_KEEP))"' "${BACKUP_CONFIG_YAML}" > /etc/crontabs/root

  echo "🤖 Crontab file:"
  cat /etc/crontabs/root

  echo "🤖 Starting crond..."
  crond -f -d 8 -L /dev/stdout -l 8
}

server() {
  # Check if the host directory exists. Create it if needed
  if [ ! -d "$SSH_HOST_KEY_DIR" ]; then
    mkdir -p "$SSH_HOST_KEY_DIR"
  fi

  echo "🤖 Setting SSHD configuration..."
  {
    echo "Port ${SSH_PORT}"
    echo "PermitRootLogin no"
    echo "PermitEmptyPasswords no"
    echo "MaxAuthTries 5"
    echo "LoginGraceTime 20"
    echo "ChallengeResponseAuthentication no"
    echo "X11Forwarding no"
    echo "AllowAgentForwarding no"
    echo "AllowTcpForwarding no"
    echo "PermitTunnel no"
  } > /etc/ssh/sshd_config.d/custom.conf


  # Check if SSH host keys are missing
  if [ ! -e "$SSH_HOST_KEY_DIR"/ssh_host_rsa_key ] || [ ! -e "$SSH_HOST_KEY_DIR"/ssh_host_ecdsa_key ] || [ ! -e "$SSH_HOST_KEY_DIR"/ssh_host_ed25519_key ]; then
    echo "🏃‍️ No ssh keys found. Generating SSH keys for you..."

    ssh-keygen -t rsa -b 4096 -f "$SSH_HOST_KEY_DIR"/ssh_host_rsa_key -N "" -q

    echo
    echo "ℹ️ This is the key: "
    echo
    cat "$SSH_HOST_KEY_DIR"/ssh_host_rsa_key.pub
    echo
    echo "ℹ️ Add this key to your known_hosts file on the client side."
    echo
    echo
  fi

  [ -f "${SSH_HOST_KEY_DIR}/ssh_host_rsa_key" ] && echo "HostKey ${SSH_HOST_KEY_DIR}/ssh_host_rsa_key" >> /etc/ssh/sshd_config.d/custom.conf
  [ -f "${SSH_HOST_KEY_DIR}/ssh_host_ecdsa_key" ] && echo "HostKey ${SSH_HOST_KEY_DIR}/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config.d/custom.conf
  [ -f "${SSH_HOST_KEY_DIR}/ssh_host_ed25519_key" ] && echo "HostKey ${SSH_HOST_KEY_DIR}/ssh_host_ed25519_key" >> /etc/ssh/sshd_config.d/custom.conf

  # start sshd in the background. -e is to log everything to stderr.
  /usr/sbin/sshd -e -D
}

case "${1:-client}" in
  client)
    client "$@"
    ;;
  server)
    server
    ;;
  backup)
    backup "$@"
    ;;
  *)
    echo "🤖 Usage: $0 <server|client|backup>"
    echo "   Defaulting to 'client'"
    exit 2
    ;;
esac