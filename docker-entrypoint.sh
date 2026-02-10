#!/bin/sh
set -e

# Ensure tmp directories are writable (Docker volumes mount as root)
mkdir -p tmp/pids tmp/cache tmp/sockets

exec "$@"
