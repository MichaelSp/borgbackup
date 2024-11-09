#!/usr/bin/env sh

export DEFAULT_SRC="${DEFAULT_SRC:-/data}"
export DEFAULT_TYPE="${DEFAULT_TYPE:-pvc}" # pvc, postgresql, mysql, fs
export DEFAULT_KEEP="${DEFAULT_KEEP:-7d}"
export DEFAULT_SCHEDULE="${DEFAULT_SCHEDULE:-0 0 * * *}"
export DEFAULT_COMPRESSION="${DEFAULT_COMPRESSION:-lz4}"
export BACKUP_CONFIG_YAML="${BACKUP_CONFIG_YAML:-/etc/backup/config.yaml}"
export SSH_HOST_KEY_DIR="${SSH_HOST_KEY_DIR:-/etc/ssh/keys}"
export SSH_PORT="${SSH_PORT:-2222}"
