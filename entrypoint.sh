#!/usr/bin/env sh

case "${1:-client}" in
  client)
    /app/client "$@"
    ;;
  server)
    /app/server
    ;;
  backup)
    /app/backup "$@"
    ;;
  *)
    echo "🤖 Usage: $0 <server|client|backup>"
    echo "   Defaulting to 'client'"
    exit 42
    ;;
esac