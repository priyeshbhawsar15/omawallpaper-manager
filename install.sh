#!/usr/bin/env bash

set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
helper_source="$plugin_dir/bin/wallpaper-controller"
helper_target="$HOME/.local/bin/wallpaper-controller"
menu_file="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

missing=()
command -v linux-wallpaperengine >/dev/null 2>&1 || missing+=(linux-wallpaperengine-git)
command -v aether >/dev/null 2>&1 || missing+=(aether)
command -v magick >/dev/null 2>&1 || missing+=(imagemagick)
command -v zenity >/dev/null 2>&1 || missing+=(zenity)
if ((${#missing[@]})); then
  message="Wallpaper Controller needs: ${missing[*]}. Install them with Omarchy, then reopen the controller."
  printf '%s\n' "$message" >&2
  command -v notify-send >/dev/null 2>&1 && notify-send -a "Wallpaper Controller" "$message" || true
fi

mkdir -p "$(dirname -- "$helper_target")" "$(dirname -- "$menu_file")"
if [[ ! -f "$helper_target" ]] || ! cmp -s "$helper_source" "$helper_target"; then
  install -Dm755 "$helper_source" "$helper_target"
  changed=true
else
  changed=false
fi

[[ -f "$menu_file" ]] || printf '{\n}\n' > "$menu_file"
if ! grep -q '"style.wallpaper-controller"' "$menu_file"; then
  MENU_FILE="$menu_file" python3 - <<'PY'
import os, re, tempfile
from pathlib import Path

path = Path(os.environ["MENU_FILE"])
text = path.read_text()
head, closing, tail = text.rpartition("}")
if not closing:
    raise SystemExit("Wallpaper Controller: invalid Omarchy menu extension")
active_lines = "\n".join(line for line in head.splitlines() if not line.lstrip().startswith("//"))
prefix = "," if re.search(r'"[^"\\n]+"\s*:', active_lines) else ""
entry = prefix + '\n  "style.wallpaper-controller": {"icon": "󰸉", "label": "Wallpaper Controller", "action": "omarchy-shell shell summon priyesh.wallpaper-controller"}\n'
fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".omarchy-menu.")
with os.fdopen(fd, "w") as out:
    out.write(head.rstrip() + entry + closing + tail)
os.replace(temporary, path)
PY
  changed=true
fi

if [[ "$changed" == true ]]; then
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  printf '%s\n' "Wallpaper Controller bootstrap completed."
else
  printf '%s\n' "Wallpaper Controller already installed."
fi
