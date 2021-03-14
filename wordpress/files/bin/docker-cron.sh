#!/usr/bin/env bash
set -eu

exec busybox crond -f -l 0 -L /dev/stdout
