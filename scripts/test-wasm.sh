#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
zig="${root_dir}/.tools/zig-0.15.2/zig"
emsdk_env="${root_dir}/scripts/emsdk-env.sh"

if [[ ! -x "${zig}" ]]; then
  echo "Zig not found at ${zig}" >&2
  exit 1
fi

if [[ ! -f "${emsdk_env}" ]]; then
  echo "emsdk env script not found at ${emsdk_env}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${emsdk_env}"
"${zig}" build -Dwasm=true

if [[ ! -f "${root_dir}/zig-out/web/ziggystarclaw-client.html" ]]; then
  echo "WASM output missing: zig-out/web/ziggystarclaw-client.html" >&2
  exit 1
fi
