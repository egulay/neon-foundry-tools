#!/bin/bash
# Set up Neon Foundry's unlock screens, and the theme itself if it is not
# installed yet.
#
#   ./install.sh                  theme (if missing) + unlock screens, then apply
#   ./install.sh --theme-dir DIR  link a local checkout of the theme at DIR
#   ./install.sh --no-apply       install without switching to the theme
#
# The theme lives in its own repository, https://github.com/egulay/neon-foundry.
# Omarchy's gallery lists only repositories that carry no code, so everything
# that runs lives here instead, and this script puts the two together.
#
# What it does, in order:
#   1. The theme. Already installed: left alone. --theme-dir, or a checkout
#      beside this one: linked into ~/.config/omarchy/themes, which Omarchy
#      treats as the user's own. Otherwise: `omarchy theme install`.
#   2. The focused-window glow. The theme ships hyprland.lua.example, because
#      Omarchy drops every *.lua from a theme it cloned from git. A linked
#      theme is the user's own and does load it, so the file is put in place
#      there. A cloned theme cannot have it. The gradient border is unaffected
#      either way: that comes from colors.toml.
#   3. The unlock screens. Omarchy's lock screen is the Quickshell plugin
#      omarchy.lock. It is cloned to <user>.lock and only LockView.qml is
#      replaced; Service.qml, the PAM flows, stays byte-identical to Omarchy's.

set -euo pipefail

THEME_NAME="neon-foundry"
THEME_DISPLAY="Neon Foundry"
THEME_REPO="https://github.com/egulay/neon-foundry"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$HOME/.config/omarchy/themes"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
LOCK_ID="${USER:-$(id -un)}.lock"
LOCK_FILES=(LockView.qml FoundryPixel.qml FoundryGrid.qml FoundryScene.qml
  FoundrySprites.js SceneCrew.qml SceneAbduction.qml SceneMenagerie.qml ScenePatrol.qml)

theme_dir_opt=""
apply=1
while (($#)); do
  case "$1" in
  --theme-dir)
    theme_dir_opt="${2:-}"
    [[ -n $theme_dir_opt ]] || { echo "install.sh: --theme-dir needs a path" >&2; exit 1; }
    shift 2
    ;;
  --theme-dir=*) theme_dir_opt="${1#*=}"; shift ;;
  --no-apply) apply=0; shift ;;
  -h | --help)
    sed -n '2,8p' "$0" | sed 's/^# \?//'
    exit 0
    ;;
  *)
    echo "install.sh: unknown option: $1" >&2
    exit 1
    ;;
  esac
done

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

target="$THEMES_DIR/$THEME_NAME"

link_theme() {
  local src
  src="$(cd "$1" && pwd)"
  if [[ ! -f $src/colors.toml ]]; then
    warn "No colors.toml in $src; that is not a checkout of the theme."
    exit 1
  fi
  if [[ -e $target && ! -L $target ]]; then
    warn "$target exists and is a real directory, not a link."
    warn "Move it aside first if you want that checkout to drive the theme."
    exit 1
  fi
  ln -nsf "$src" "$target"
  say "Linked $target -> $src"
}

# --- 1. the theme -------------------------------------------------------------
mkdir -p "$THEMES_DIR"
if [[ -n $theme_dir_opt ]]; then
  link_theme "$theme_dir_opt"
elif [[ -d $target ]]; then
  say "Theme already installed at $target"
else
  linked=0
  for cand in "$SOURCE_DIR/../$THEME_NAME" "$SOURCE_DIR/../gulay-omarchy-theme"; do
    if [[ -f $cand/colors.toml ]]; then
      link_theme "$cand"
      linked=1
      break
    fi
  done
  if ((!linked)); then
    say "Installing the theme from $THEME_REPO"
    # Installing applies the theme as part of it; --no-apply cannot stop that.
    omarchy theme install "$THEME_REPO"
  fi
fi

# --- 2. the focused-window glow ----------------------------------------------
if [[ -L $target ]]; then
  real="$(readlink -f "$target")"
  if [[ -f $real/hyprland.lua ]]; then
    say "Focused-window glow already in place"
  elif [[ -f $real/hyprland.lua.example ]]; then
    cp "$real/hyprland.lua.example" "$real/hyprland.lua"
    say "Enabled the focused-window glow (hyprland.lua; the theme's git ignores it)"
  fi
else
  say "Theme is a git clone, not a link, so the focused-window glow is not available:"
  say "Omarchy strips *.lua from cloned themes. The gradient border is unaffected."
fi

# --- 3. the unlock screens ----------------------------------------------------
lock_dir="$PLUGINS_DIR/$LOCK_ID"
if [[ ! -d $lock_dir ]]; then
  say "Cloning omarchy.lock -> $LOCK_ID"
  omarchy plugin clone omarchy.lock
else
  say "Using existing clone at $lock_dir"
fi

if [[ ! -f $lock_dir/Service.qml ]]; then
  warn "$lock_dir has no Service.qml, so it is not a lock clone. Skipping the unlock screens."
else
  # Keep a pristine copy of the stock view once, so uninstall can restore it.
  if [[ ! -f $lock_dir/LockView.qml.orig ]]; then
    cp "$lock_dir/LockView.qml" "$lock_dir/LockView.qml.orig"
  fi
  for f in "${LOCK_FILES[@]}"; do
    cp "$SOURCE_DIR/lock/$f" "$lock_dir/$f"
  done
  say "Installed the unlock screens into $lock_dir"

  # A rescan reloads the plugin's service code, but the LockView component the
  # shell already instantiated stays cached: the lock screen keeps rendering
  # the stock view, with no error to show for it. Only a restart picks it up.
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  say "Restarting the shell so the new lock view is picked up"
  omarchy restart shell >/dev/null 2>&1 || true
fi

# --- apply --------------------------------------------------------------------
if ((apply)); then
  say "Applying $THEME_DISPLAY"
  omarchy theme set "$THEME_NAME"
fi

cat <<DONE

$THEME_DISPLAY is set up.

  omarchy theme bg next        cycle the six wallpapers
  omarchy system lock          one of four unlock scenes, at random
  omarchy plymouth switcher    boot and login screen (asks for sudo)

Also here, each optional:

  tools/gtk-match-bar.sh       GTK apps in the bar's font, with smaller icons
  tools/gtk-theme-colors.sh    GTK apps on the theme's colours (--install follows every theme)
  tools/browser-theme.sh       browsers

To pin one unlock scene instead of a random draw, set variant (0-3) on
FoundryScene in $lock_dir/LockView.qml.
DONE
