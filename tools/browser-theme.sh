#!/bin/bash
# Theme every browser on this machine from the active Omarchy theme.
#
#   ./tools/browser-theme.sh            do what each installed browser needs
#   ./tools/browser-theme.sh --revert   undo what this script wrote
#
# One entry point, because the three families need three different things and
# only one of them is automatic:
#
#   Chromium / Chrome / Brave   Omarchy already does it. omarchy-theme-set-browser
#                               reads the theme's chromium.theme and writes
#                               BrowserThemeColor into each browser's managed
#                               policy on every theme change. Nothing to do.
#
#   Firefox / LibreWolf /       A static theme (tools/firefox-theme.sh). The
#   Floorp / Waterfox           theme.colors API names surfaces rather than
#                               overriding internal CSS, so an update cannot
#                               quietly break it. Needs signing once.
#
#   Zen                         Neither. Zen ships zen.theme.disable-lightweight
#                               = true, and "lightweight theme" is Gecko's
#                               internal name for exactly those static themes —
#                               Zen turns them off on purpose, and its sidebar
#                               and borders are its own chrome besides. Its
#                               supported route is its own theme colours, so
#                               this unlocks the hex entry and prints what to
#                               paste.
#
# Nothing here touches Omarchy, so no update or refresh can reset it.

set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BEGIN="// neon-foundry begin"
END="// neon-foundry end"
revert=0
[[ ${1:-} == "--revert" ]] && revert=1

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
head2() { printf '\n\033[1m%s\033[0m\n' "$*"; }

COLORS="$HOME/.local/state/omarchy/current/theme/colors.toml"
[[ -f $COLORS ]] || COLORS="$HOME/.config/omarchy/themes/neon-foundry/colors.toml"

color() {
  local v
  v=$(omarchy-theme-color --file "$COLORS" "$1" 2>/dev/null)
  [[ -n $v && $v == \#* ]] && printf '%s' "$v" || printf '%s' "$2"
}
bg=$(color background "#1e1e2e")
bg_dark=$(color dark_background "$bg")
accent=$(color accent "#89b4fa")

# --- chromium family --------------------------------------------------------
head2 "Chromium, Chrome, Brave"
found_chromium=0
for b in chromium brave google-chrome-stable; do
  command -v "$b" >/dev/null 2>&1 && { found_chromium=1; echo "  found: $b"; }
done
if ((found_chromium)); then
  applied=$(grep -ho '"BrowserThemeColor"[^,}]*' /etc/chromium/policies/managed/*.json \
    /etc/brave/policies/managed/*.json /etc/opt/chrome/policies/managed/*.json 2>/dev/null | head -1)
  if [[ -n $applied ]]; then
    say "Already themed by Omarchy: $applied"
  else
    warn "No BrowserThemeColor policy yet — run: omarchy theme set \$(omarchy theme current)"
  fi
else
  echo "  none installed"
fi

# --- gecko family, minus zen ------------------------------------------------
head2 "Firefox, LibreWolf, Floorp, Waterfox"
found_ff=0
for b in firefox librewolf floorp waterfox; do
  command -v "$b" >/dev/null 2>&1 && { found_ff=1; echo "  found: $b"; }
done
if ((found_ff)); then
  if ((revert)); then
    rm -f "$SOURCE_DIR"/dist/*-firefox.xpi 2>/dev/null
    say "Removed the built .xpi (uninstall it in the browser's Add-ons page)"
  else
    "$SOURCE_DIR/tools/firefox-theme.sh" | sed 's/^/  /'
  fi
else
  echo "  none installed"
fi

# --- zen --------------------------------------------------------------------
head2 "Zen"
zen_profile=""
if [[ -f $HOME/.config/zen/profiles.ini ]]; then
  # The install section names the default profile; fall back to the first Path=.
  zen_profile=$(awk -F= '/^\[Install/{f=1} f&&/^Default=/{print $2; exit}' "$HOME/.config/zen/profiles.ini")
  [[ -n $zen_profile ]] || zen_profile=$(awk -F= '/^Path=/{print $2; exit}' "$HOME/.config/zen/profiles.ini")
fi

if [[ -z $zen_profile || ! -d $HOME/.config/zen/$zen_profile ]]; then
  echo "  not installed"
else
  userjs="$HOME/.config/zen/$zen_profile/user.js"
  echo "  profile: $zen_profile"

  # user.js is the supported way to pin prefs: Zen applies it at every start and
  # updates do not touch it. Only our own marked block is ever rewritten.
  if [[ -f $userjs ]] && grep -qF "$BEGIN" "$userjs"; then
    tmp=$(mktemp)
    awk -v b="$BEGIN" -v e="$END" '
      index($0,b){s=1} !s{print} index($0,e){s=0}
    ' "$userjs" >"$tmp" && mv "$tmp" "$userjs"
  fi

  if ((revert)); then
    say "Removed the Neon Foundry block from user.js"
  else
    [[ -f $userjs ]] || : >"$userjs"
    cat >>"$userjs" <<PREFS
$BEGIN
// Let Zen's theme-colour picker take a hex code instead of only its swatches.
user_pref("zen.theme.gradient.show-custom-colors", true);
// Follow the Omarchy theme's accent rather than the desktop's system accent.
user_pref("zen.theme.accent-color", "$accent");
$END
PREFS
    say "Wrote Zen prefs to user.js"
    cat <<ZEN

  Zen draws its own sidebar and borders, so its colours are set in Zen, not by
  an add-on. With the pref above in place:

    1. Restart Zen (user.js is read at startup).
    2. Press Ctrl+L, type "theme", choose Open Theme Picker.
    3. Enter the hex:   background $bg    accent $accent

  Those two are this theme's background and accent. Nothing else is needed.

  The picker only initialises on a synced window. With
  zen.window-sync.prefer-unsynced-windows = true it does nothing, and the
  Browser Console shows "panelNode is undefined". Set the colour on a synced
  window; it persists on the workspace.
ZEN
  fi
fi

echo
say "Done. ./tools/browser-theme.sh --revert undoes what this wrote."
