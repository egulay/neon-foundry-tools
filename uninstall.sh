#!/bin/bash
# Take Neon Foundry's extras out again.
#
#   ./uninstall.sh                      stock unlock screen back; theme link removed
#   ./uninstall.sh --keep-theme         leave the theme installed
#   ./uninstall.sh --remove-lock-clone  also drop the lock clone, back to omarchy.lock
#
# The lock clone itself is left in place by default (it is yours, and may hold
# other edits); only the view is restored. The GTK and browser scripts in
# tools/ each have their own --revert.

set -euo pipefail

THEME_NAME="neon-foundry"
THEMES_DIR="$HOME/.config/omarchy/themes"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
LOCK_ID="${USER:-$(id -un)}.lock"

remove_clone=0
keep_theme=0
for arg in "$@"; do
  case "$arg" in
  --remove-lock-clone) remove_clone=1 ;;
  --keep-theme) keep_theme=1 ;;
  -h | --help)
    sed -n '2,10p' "$0" | sed 's/^# \?//'
    exit 0
    ;;
  *)
    echo "uninstall.sh: unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

# --- the theme ----------------------------------------------------------------
target="$THEMES_DIR/$THEME_NAME"
if ((!keep_theme)); then
  if [[ -L $target ]]; then
    real="$(readlink -f "$target")"
    # The glow copy install.sh made; the .example it came from stays.
    if [[ -f $real/hyprland.lua && -f $real/hyprland.lua.example ]]; then
      rm -f "$real/hyprland.lua"
      say "Removed the generated hyprland.lua"
    fi
    rm "$target"
    say "Unlinked $target"
  elif [[ -d $target ]]; then
    say "The theme at $target is a clone, not a link. Remove it with:"
    say "  omarchy theme remove $THEME_NAME"
  fi
fi

# --- the unlock screens -------------------------------------------------------
lock_dir="$PLUGINS_DIR/$LOCK_ID"
if [[ -d $lock_dir ]]; then
  if ((remove_clone)); then
    # Go through omarchy rather than rm -rf: cloning recorded a
    # cloneSourceRestores entry and disabled omarchy.lock, and only the
    # supported removal re-enables it. Deleting the directory by hand leaves
    # the built-in disabled and the session with no lock screen at all.
    omarchy plugin remove "$LOCK_ID" --yes
    say "Removed $LOCK_ID; the built-in omarchy.lock takes over again"
  elif [[ -f $lock_dir/LockView.qml.orig ]]; then
    mv "$lock_dir/LockView.qml.orig" "$lock_dir/LockView.qml"
    rm -f "$lock_dir"/{FoundryPixel.qml,FoundryGrid.qml,FoundryScene.qml,FoundrySprites.js} \
      "$lock_dir"/Scene{Crew,Abduction,Menagerie,Patrol}.qml
    say "Restored the stock unlock screen in $lock_dir"
  else
    warn "No LockView.qml.orig in $lock_dir; leaving the view as it is."
  fi
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  omarchy restart shell >/dev/null 2>&1 || true
fi

warn "If this theme is still applied, pick another with: omarchy theme set <name>"
