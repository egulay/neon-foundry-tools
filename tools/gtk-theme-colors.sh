#!/bin/bash
# Make GTK apps follow the current Omarchy theme's palette.
#
#   ./tools/gtk-theme-colors.sh            write the colours of the current theme
#   ./tools/gtk-theme-colors.sh --revert   take the block back out
#   ./tools/gtk-theme-colors.sh --install  also install it as a theme-set hook
#
# Omarchy themes everything it owns from colors.toml, but GTK apps are not among
# them: `omarchy-theme-set-gnome` only sets `color-scheme: prefer-dark` and the
# icon theme, so Nautilus renders in stock Adwaita grey while the bar and the
# terminals are on the theme's background.
#
# This writes libadwaita's named colours into ~/.config/gtk-4.0/gtk.css, inside
# markers of its own. Omarchy's Glassy windows option writes to the same file,
# but only between `/* omarchy-glass begin */` and its end marker, and its
# remove_block deletes just that range — so the two blocks coexist and glass can
# be turned on and off underneath this one.
#
# Installed as a theme-set hook it follows every theme, not only Neon Foundry:
# switch to Tokyo Night and Nautilus turns Tokyo Night.
#
# NOT theme content. `omarchy theme install` does not carry it.

set -uo pipefail

GTK_CSS="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/gtk.css"
BEGIN="/* neon-foundry-colors begin */"
END="/* neon-foundry-colors end */"

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

remove_block() {
  [[ -f $GTK_CSS ]] || return 0
  grep -qF "$BEGIN" "$GTK_CSS" 2>/dev/null || return 0
  # Delete only our own range; anything else in the file, including Omarchy's
  # glass block, is left exactly as it was.
  sed -i "\|^$(sed 's/[][\\.*^$/|]/\\&/g' <<<"$BEGIN")\$|,\|^$(sed 's/[][\\.*^$/|]/\\&/g' <<<"$END")\$|d" "$GTK_CSS"
}

if [[ ${1:-} == "--revert" ]]; then
  remove_block
  say "Removed the colour block from $GTK_CSS"
  say "Reopen GTK apps to see it."
  exit 0
fi

if [[ ${1:-} == "--install" ]]; then
  omarchy hook install theme-set "$(readlink -f "$0")" &&
    say "Installed as a theme-set hook; it will follow every theme change"
fi

# --- read the active theme's palette ---------------------------------------
COLORS="$HOME/.local/state/omarchy/current/theme/colors.toml"
if [[ ! -f $COLORS ]]; then
  warn "No current theme colors.toml; nothing to do."
  exit 0
fi

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
accent=$(color accent "#89b4fa")
red=$(color red "#f38ba8")

# Acid-bright accents need dark text on them; dark accents need light. Decide
# from luminance rather than assuming either way.
accent_fg=$(python3 -I -c "
h='${accent}'.lstrip('#')
r,g,b=(int(h[i:i+2],16) for i in (0,2,4))
print('${bg}' if (0.2126*r+0.7152*g+0.0722*b) > 140 else '${fg}')
" 2>/dev/null || printf '%s' "$fg")

# --- write the block --------------------------------------------------------
mkdir -p "${GTK_CSS%/*}"
remove_block
[[ -f $GTK_CSS ]] || : >"$GTK_CSS"
# Keep a trailing newline so a following block (glass) starts on its own line.
if [[ -s $GTK_CSS && -n $(tail -c 1 "$GTK_CSS") ]]; then printf '\n' >>"$GTK_CSS"; fi

cat >>"$GTK_CSS" <<CSS
$BEGIN
/* Generated from the active Omarchy theme's colors.toml. Edit the theme, not
   this block: it is rewritten on every theme change. */
@define-color window_bg_color $bg;
@define-color window_fg_color $fg;
@define-color view_bg_color $bg;
@define-color view_fg_color $fg;
@define-color headerbar_bg_color $bg_dark;
@define-color headerbar_fg_color $fg;
@define-color headerbar_border_color $bg_dark;
@define-color headerbar_backdrop_color $bg_dark;
@define-color sidebar_bg_color $bg_dark;
@define-color sidebar_fg_color $fg;
@define-color sidebar_backdrop_color $bg_dark;
@define-color secondary_sidebar_bg_color $bg_dark;
@define-color card_bg_color $bg_light;
@define-color card_fg_color $fg;
@define-color dialog_bg_color $bg_light;
@define-color dialog_fg_color $fg;
@define-color popover_bg_color $bg_light;
@define-color popover_fg_color $fg;
@define-color accent_bg_color $accent;
@define-color accent_fg_color $accent_fg;
@define-color accent_color $accent;
@define-color destructive_bg_color $red;
@define-color error_color $red;
$END
CSS

say "Wrote the active theme's palette into $GTK_CSS"
echo "    background $bg   foreground $fg   accent $accent"
say "Reopen GTK apps (SUPER + SHIFT + F) to see it."
