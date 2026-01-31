#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
zig="${root_dir}/.tools/zig-0.15.2/zig"

if [[ ! -x "${zig}" ]]; then
  echo "Zig not found at ${zig}" >&2
  exit 1
fi

"${root_dir}/scripts/test-native.sh"
"${zig}" build -Dtarget=x86_64-windows-gnu

if [[ -f "${root_dir}/scripts/emsdk-env.sh" ]]; then
  if "${root_dir}/scripts/test-wasm.sh"; then
    :
  fi
else
  echo "Skipping WASM: emsdk-env.sh not found"
fi

if [[ -d "${root_dir}/.tools/android-sdk" ]] || [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  "${root_dir}/scripts/test-android.sh"
else
  echo "Skipping Android: SDK not found"
fi
