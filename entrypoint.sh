#!/usr/bin/env sh

export DEFAULT_SRC="${DEFAULT_SRC:-/data}"
export DEFAULT_TYPE="${DEFAULT_TYPE:-pvc}" # PVC or FS
export DEFAULT_KEEP="${DEFAULT_KEEP:-7d}"
export DEFAULT_SCHEDULE="${DEFAULT_SCHEDULE:-0 0 * * *}"
export DEFAULT_COMPRESSION="${DEFAULT_COMPRESSION:-lz4}"
BACKUP_CONFIG_YAML="${BACKUP_CONFIG_YAML:-/etc/backup/config.yaml}"
SSH_HOST_KEY_DIR="${SSH_HOST_KEY_DIR:-/etc/ssh/keys}"
SSH_PORT="${SSH_PORT:-2222}"

backup() {
  KEY=${2}

  set -e # exit on error

  DATE=$(date +%Y-%m-%d-%H-%M-%S)
  CONFIG=$(yq eval ".${KEY}" "${BACKUP_CONFIG_YAML}")

  if [ "${CONFIG}" = "" ] || [ "${CONFIG}" = "null" ]; then
    echo "🤖 No config found for '${KEY}'"
    exit 1
  fi

  COMPRESSION=$(echo "${CONFIG}" | yq eval '.compression // env(DEFAULT_COMPRESSION)')
  KEEP=$(echo "${CONFIG}" | yq eval '.keep // env(DEFAULT_KEEP)')
  SRC=$(echo "${CONFIG}" | yq eval '.source // env(DEFAULT_SRC)')
  TYPE=$(echo "${CONFIG}" | yq eval '.type // env(DEFAULT_TYPE)' | tr '[:upper:]' '[:lower:]')

  if [ "${TYPE}" = "pvc" ]; then
    echo "🤖 PVC backup detected. Find PVC path"

    NS=$(echo "${SRC}" | cut -d'/' -f1)
    PVC=$(echo "${SRC}" | cut -d'/' -f2)
    PV=$(kubectl get pvc -n "${NS}" "${PVC}"  -o jsonpath='{.spec.volumeName}')
    SRC=$(kubectl get pv "${PV}" -o jsonpath='{.spec.local.path}')
    echo "🤖 PVC path is ${SRC}"
  fi

  echo "🧐 Check if the repo is initialized..."
  if ! borg info > /dev/null 2>&1; then
    echo "🤖 Initializing borg repo..."
    borg init --encryption=repokey

    borg key export > "${BORG_SECURITY_DIR}/repokey"
    echo "🤖 store the repo-key passphrase in ${BORG_SECURITY_DIR}/repokey"
  fi

  echo "🤖 Running borg backup for '${KEY}' from '$SRC'"
  borg create --stats --progress --compression "${COMPRESSION}" "${BORG_REPO}::${KEY}-${DATE}" "${SRC}"

  echo "🤖 Pruning old backups..."
  borg prune --list --keep-within "${KEEP}"
}

client() {
  if [ -f "${BACKUP_CONFIG_YAML}" ]; then
    echo "🤖 Setting up crontab from '${BACKUP_CONFIG_YAML}'"
    yq 'to_entries | .[] | "\(.value.schedule // env(DEFAULT_SCHEDULE)) /entrypoint.sh backup \(.key)"' "${BACKUP_CONFIG_YAML}" >> /etc/crontabs/root
  else
    echo "🤖 assuming a crontab is mounted at '/etc/crontabs/root'"
  fi

  echo "🤖 Current crontab:"
  cat /etc/crontabs/root

  echo "🤖 Starting crond..."
  exec crond -f -d 8 -L /dev/stdout -l 8
}

server() {
  # Check if the host directory exists. Create it if needed
  if [ ! -d "$SSH_HOST_KEY_DIR" ]; then
    mkdir -p "$SSH_HOST_KEY_DIR"
  fi

  echo "🤖 Setting SSHD configuration..."
  {
    echo "Port ${SSH_PORT}"
    echo "PermitRootLogin prohibit-password"
    echo "PermitEmptyPasswords no"
    echo "PasswordAuthentication no"
    echo "MaxAuthTries 5"
    echo "LoginGraceTime 20"
    echo "ChallengeResponseAuthentication no"
    echo "X11Forwarding no"
    echo "AllowAgentForwarding no"
    echo "AllowTcpForwarding no"
    echo "PermitTunnel no"
  } > /etc/ssh/sshd_config.d/custom.conf


  # Check if any ssh keys are present. If not, generate them.
  if [ ! -f "${SSH_HOST_KEY_DIR}/ssh_host_rsa_key" ] && [ ! -f "${SSH_HOST_KEY_DIR}/ssh_host_ecdsa_key" ] && [ ! -f "${SSH_HOST_KEY_DIR}/ssh_host_ed25519_key" ]; then
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

  # start sshd in the background. -e is to log everything to stderr. PID file is needed for termination
  exec /usr/sbin/sshd -D -e
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