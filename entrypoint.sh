#!/usr/bin/env sh

SSH_HOST_KEY_DIR=${SSH_HOST_KEY_DIR:-/etc/ssh/keys}

# Check if the host directory exists. Create it if needed
if [ ! -d "$SSH_HOST_KEY_DIR" ]; then
  mkdir -p "$SSH_HOST_KEY_DIR"
fi

find /etc/ssh/ -type f -name "ssh_host_*" -exec mv -t "$SSH_HOST_KEY_DIR" "{}" \;

echo "🤖 Setting SSHD configuration..."
{
  echo "Port ${SSH_PORT:-2222}"
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
if [ ! -f "$SSH_HOST_KEY_DIR"/ssh_host_rsa_key ] || [ ! -f "$SSH_HOST_KEY_DIR"/ssh_host_ecdsa_key ] || [ ! -f "$SSH_HOST_KEY_DIR"/ssh_host_ed25519_key ]; then
  echo "🏃‍️ No ssh keys found. Generating SSH keys for you..."

  ssh-keygen -t rsa -b 4096 -f "$SSH_HOST_KEY_DIR"/ssh_host_rsa_key -N "" -q

  echo
  echo "ℹ️ This is the key: "
  echo
  cat "$SSH_HOST_KEY_DIR"/ssh_host_rsa_key.pub
  echo "ℹ️ Add this key to your authorized_keys file in your client machine."
  echo
  echo
fi

[ -f "${SSH_HOST_KEY_DIR}/ssh_host_rsa_key" ] && echo "HostKey ${SSH_HOST_KEY_DIR}/ssh_host_rsa_key" >> /etc/ssh/sshd_config.d/custom.conf
[ -f "${SSH_HOST_KEY_DIR}/ssh_host_ecdsa_key" ] && echo "HostKey ${SSH_HOST_KEY_DIR}/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config.d/custom.conf
[ -f "${SSH_HOST_KEY_DIR}/ssh_host_ed25519_key" ] && echo "HostKey ${SSH_HOST_KEY_DIR}/ssh_host_ed25519_key" >> /etc/ssh/sshd_config.d/custom.conf

# start sshd in the background. -e is to log everything to stderr.
/usr/sbin/sshd -e -D