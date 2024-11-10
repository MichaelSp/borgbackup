#!/usr/bin/env sh

case "${1:-server}" in
  borgmatic-init)
    /app/borgmatic-init "$@"
    ;;
  server)
    /app/server
    ;;
  *)
    echo "🤖 Usage: $0 <server|borgmatic-init>"
    echo "   Defaulting to 'server'"
    exit 42
    ;;
esac