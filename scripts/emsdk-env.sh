#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/.tools/emsdk/emsdk_env.sh" >/dev/null 2>&1

# Print a short status when run directly.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "emsdk env loaded from ${ROOT_DIR}/.tools/emsdk"
  emcc -v | head -n 1
fi
