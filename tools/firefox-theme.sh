#!/bin/bash
# Build a browser theme for the Firefox family from the active Omarchy theme.
#
#   ./tools/firefox-theme.sh            build dist/<theme>-firefox.xpi
#   ./tools/firefox-theme.sh --out DIR
#
# Works for Firefox, Zen, LibreWolf, Floorp, Waterfox — one file for all of
# them, because they share Gecko's static-theme API.
#
# CHROMIUM NEEDS NOTHING. Omarchy already themes Chromium, Chrome and Brave
# itself: `omarchy-theme-set-browser` reads the theme's chromium.theme and
# writes BrowserThemeColor into each browser's managed-policy directory, then
# refreshes anything running. That happens on every theme change with no help
# from here.
#
# Gecko has no such hook, which is the whole reason this exists.
#
# Why a static theme and not userChrome.css: `theme.colors` is a documented,
# versioned WebExtension API that sets surfaces by name — frame, toolbar,
# popup, sidebar. It does not reach into the browser's internal CSS, so a
# chrome refactor in the next release cannot silently break it. userChrome.css
# does exactly that, and needs a legacy pref switched on to work at all.
#
# The one cost: Gecko will only install an unsigned theme permanently on
# builds that allow it. Sign it once, free, through addons.mozilla.org's
# self-distribution flow (upload, download the signed copy, no public listing,
# no review queue for static themes) and it installs like any other add-on.

set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$SOURCE_DIR/dist"

while (($#)); do
  case "$1" in
  --out)
    OUT="${2:-$OUT}"
    shift 2 || break
    ;;
  --out=*)
    OUT="${1#*=}"
    shift
    ;;
  -h | --help)
    sed -n '2,8p' "$0" | sed 's/^# \?//'
    exit 0
    ;;
  *)
    echo "firefox-theme.sh: unknown option: $1" >&2
    exit 1
    ;;
  esac
done

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

COLORS="$HOME/.local/state/omarchy/current/theme/colors.toml"
[[ -f $COLORS ]] || COLORS="$HOME/.config/omarchy/themes/neon-foundry/colors.toml"
if [[ ! -f $COLORS ]]; then
  warn "No colors.toml found."
  exit 1
fi

theme_name=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || echo "neon-foundry")

color() {
  local v
  v=$(omarchy-theme-color --file "$COLORS" "$1" 2>/dev/null)
  [[ -n $v && $v == \#* ]] && printf '%s' "$v" || printf '%s' "$2"
}

bg=$(color background "#1e1e2e")
bg_dark=$(color dark_background "$bg")
bg_light=$(color lighter_background "$bg")
fg=$(color foreground "#cdd6f4")
fg_dim=$(color dark_foreground "$fg")
line=$(color selection "#45475a")
accent=$(color accent "#89b4fa")

# Text that sits *on* the accent: an acid accent wants dark on it, a dark one
# wants light. Decided by luminance rather than assumed either way.
on_accent=$(python3 -I -c "
h='${accent}'.lstrip('#')
r,g,b=(int(h[i:i+2],16) for i in (0,2,4))
print('${bg}' if (0.2126*r+0.7152*g+0.0722*b) > 140 else '${fg}')
" 2>/dev/null || printf '%s' "$fg")

mode=$(omarchy-theme-color --file "$COLORS" mode 2>/dev/null)
[[ $mode == "light" ]] || mode="dark"

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

cat >"$stage/manifest.json" <<JSON
{
  "manifest_version": 2,
  "version": "1.0",
  "name": "$theme_name",
  "description": "Generated from the Omarchy theme '$theme_name'.",
  "browser_specific_settings": {
    "gecko": { "id": "$theme_name@omarchy.theme" }
  },
  "theme": {
    "colors": {
      "frame": "$bg",
      "frame_inactive": "$bg_dark",
      "tab_background_text": "$fg_dim",
      "tab_selected": "$bg_light",
      "tab_text": "$fg",
      "tab_line": "$accent",
      "tab_loading": "$accent",
      "toolbar": "$bg_light",
      "toolbar_text": "$fg",
      "toolbar_field": "$bg_dark",
      "toolbar_field_text": "$fg",
      "toolbar_field_border": "$line",
      "toolbar_field_focus": "$bg",
      "toolbar_field_text_focus": "$fg",
      "toolbar_field_border_focus": "$accent",
      "toolbar_top_separator": "$line",
      "toolbar_bottom_separator": "$line",
      "toolbar_vertical_separator": "$line",
      "popup": "$bg_light",
      "popup_text": "$fg",
      "popup_border": "$line",
      "popup_highlight": "$accent",
      "popup_highlight_text": "$on_accent",
      "sidebar": "$bg_dark",
      "sidebar_text": "$fg",
      "sidebar_border": "$line",
      "sidebar_highlight": "$accent",
      "sidebar_highlight_text": "$on_accent",
      "ntp_background": "$bg",
      "ntp_text": "$fg",
      "button_background_hover": "$line",
      "button_background_active": "$line",
      "icons": "$fg",
      "icons_attention": "$accent"
    },
    "properties": {
      "color_scheme": "$mode",
      "content_color_scheme": "$mode"
    }
  }
}
JSON

if ! python3 -I -c "import json,sys; json.load(open('$stage/manifest.json'))" 2>/dev/null; then
  warn "Generated manifest is not valid JSON; refusing to package."
  exit 1
fi

mkdir -p "$OUT"
xpi="$OUT/$theme_name-firefox.xpi"
rm -f "$xpi"

if command -v zip >/dev/null; then
  (cd "$stage" && zip -q -r -X "$xpi" manifest.json)
else
  # zip is not a hard dependency: an xpi is an ordinary zip archive.
  python3 -I -c "
import zipfile
z = zipfile.ZipFile('$xpi', 'w', zipfile.ZIP_DEFLATED)
z.write('$stage/manifest.json', 'manifest.json')
z.close()
"
fi

say "Built $xpi"
echo "    frame $bg   toolbar $bg_light   accent $accent   scheme $mode"
cat <<NEXT

  Chromium, Chrome and Brave need nothing: Omarchy themes them from
  chromium.theme on every theme change, through browser policy.

  To install this in Firefox / Zen / LibreWolf / Floorp:

    1. Sign it once, free, at https://addons.mozilla.org/developers/
       — "On your own" distribution. No listing, no review for static themes.
    2. Open the signed .xpi in the browser and keep it.

  To try it before signing, without installing it permanently:

    about:debugging#/runtime/this-firefox -> Load Temporary Add-on

  Rebuild after a theme change to follow the new palette.
NEXT
