#!/bin/sh
set -e

# Ensure tmp directories are writable (Docker volumes mount as root)
mkdir -p tmp/pids tmp/cache tmp/sockets

# If running the rails server then create or migrate the primary database
# and the Solid Cache/Queue/Cable databases (mirrors the stock Rails 8
# generated entrypoint's conditional; db:prepare is multi-database aware).
if [ "$1" = "bin/rails" ] && [ "$2" = "server" ]; then
  ./bin/rails db:prepare
fi

exec "$@"
