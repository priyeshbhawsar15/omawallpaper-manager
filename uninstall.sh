#!/usr/bin/env bash

set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
helper_source="$plugin_dir/bin/wallpaper-controller"
helper_target="$HOME/.local/bin/wallpaper-controller"

if [[ -f "$helper_target" ]] && cmp -s "$helper_source" "$helper_target"; then
  "$helper_target" stop >/dev/null 2>&1 || true
  rm -f -- "$helper_target"
  printf '%s\n' "Removed Wallpaper Controller helper. Wallpaper settings were preserved."
else
  printf '%s\n' "Wallpaper Controller helper was changed or absent; preserving it. Wallpaper settings were preserved."
fi
