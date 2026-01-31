#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
zig="${root_dir}/.tools/zig-0.15.2/zig"

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${root_dir}/.tools/android-sdk}"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT}}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"

if [[ ! -x "${zig}" ]]; then
  echo "Zig not found at ${zig}" >&2
  exit 1
fi

if [[ ! -d "${ANDROID_SDK_ROOT}" ]]; then
  echo "Android SDK not found at ${ANDROID_SDK_ROOT}" >&2
  exit 1
fi

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}" \
ANDROID_HOME="${ANDROID_HOME}" \
JAVA_HOME="${JAVA_HOME}" \
"${zig}" build -Dandroid=true

apk_path="${root_dir}/zig-out/bin/ziggystarclaw_android.apk"
if [[ ! -f "${apk_path}" ]]; then
  echo "APK not found at ${apk_path}" >&2
  exit 1
fi

if [[ "${1:-}" == "--install" ]]; then
  if ! command -v adb >/dev/null 2>&1; then
    echo "adb not found in PATH" >&2
    exit 1
  fi
  adb install -r "${apk_path}"
fi
