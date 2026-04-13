#!/usr/bin/env bash
set -eu

for zone in "$1"/*; do
  build/queso/zonefile-1.0.0-aarch64-macos "$zone" >/dev/null
done
