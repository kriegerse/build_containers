#!/usr/bin/env bash

set -e

function infinite_loop() {
  # Handle shutdown behavior
  trap 'shutdown_wg "$1"' SIGTERM SIGINT SIGQUIT

  sleep infinity &
  wait $!
}

function shutdown_wg() {
  echo "Shutting down Wireguard (boringtun)"
  /usr/bin/wg-quick down "$1"
  exit 0
}

function start_wg() {
  echo "Starting up Wireguard (boringtun)"
  /usr/bin/wg-quick up "$1"
  infinite_loop "$1"
}


if [[ "$1" =~ ^wg.*$ ]]; then
  start_wg $1
else
  exec "$@"
fi
