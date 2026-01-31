#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
zig="${root_dir}/.tools/zig-0.15.2/zig"

if [[ ! -x "${zig}" ]]; then
  echo "Zig not found at ${zig}" >&2
  exit 1
fi

"${zig}" build test
"${zig}" build
