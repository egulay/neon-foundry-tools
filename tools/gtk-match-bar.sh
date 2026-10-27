#!/bin/bash
# Make GTK apps — Nautilus above all — read like Omarchy's top bar: the same
# monospace family, a size down from the GNOME default, and smaller icons.
#
#   ./tools/gtk-match-bar.sh [--size N]   apply (default size 10)
#   ./tools/gtk-match-bar.sh --revert     back to GNOME's defaults
#
# This is NOT theme content and `omarchy theme install` does not carry it.
# Omarchy has no GTK template, `~/.config/gtk-4.0/` is not theme-staged, and a
# font is a machine preference rather than something a palette should decide.
# It lives here so the choice is reproducible on another machine.
#
# Everything below is gsettings, deliberately. Omarchy's Glassy windows option
# works by appending a delimited block to ~/.config/gtk-4.0/gtk.css that imports
# its glass.css; writing that file here would mean two things editing it. Going
# through gsettings leaves it untouched, so glass and this stack cleanly.
#
# Why Omarchy does not already do this: `omarchy font set` is the *monospace*
# font — it rewrites the terminals and the fontconfig alias the bar follows, and
# never touches org.gnome.desktop.interface, which is why Nautilus stays on
# Adwaita Sans while the bar is JetBrains Mono.

set -euo pipefail

size=10
revert=0
for arg in "$@"; do
  case "$arg" in
  --revert) revert=1 ;;
  --size) shift || true ;;
  --size=*) size="${arg#*=}" ;;
  -h | --help)
    sed -n '2,8p' "$0" | sed 's/^# \?//'
    exit 0
    ;;
  [0-9]*) size="$arg" ;;
  *)
    echo "gtk-match-bar.sh: unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

say() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

if ! command -v gsettings >/dev/null; then
  warn "gsettings not found; nothing to do."
  exit 1
fi

if ((revert)); then
  for key in font-name document-font-name monospace-font-name; do
    gsettings reset org.gnome.desktop.interface "$key" || true
  done
  for schema in org.gnome.nautilus.icon-view org.gnome.nautilus.list-view; do
    gsettings reset "$schema" default-zoom-level 2>/dev/null || true
  done
  say "Reset to GNOME defaults"
  gsettings get org.gnome.desktop.interface font-name
  exit 0
fi

# Follow whatever `omarchy font set` chose, so this keeps matching the bar if
# the font is changed later.
family=$(omarchy font current 2>/dev/null || true)
[[ -n $family ]] || family="JetBrainsMono Nerd Font"

# No `grep -q` here: it exits on the first match, fc-list dies with SIGPIPE,
# and `set -o pipefail` turns that into a failed pipeline — an installed
# font then reads as missing.
if ! fc-list | grep -Fi -- "$family" >/dev/null; then
  warn "Font '$family' not installed; leaving fonts alone."
  exit 1
fi

say "Matching GTK to the bar: $family $size"
gsettings set org.gnome.desktop.interface font-name "$family $size"
gsettings set org.gnome.desktop.interface document-font-name "$family $size"
gsettings set org.gnome.desktop.interface monospace-font-name "$family $size"

# Nautilus icons, down one step from 'medium'. Only Nautilus reads these.
for schema in org.gnome.nautilus.icon-view org.gnome.nautilus.list-view; do
  if gsettings writable "$schema" default-zoom-level >/dev/null 2>&1; then
    gsettings set "$schema" default-zoom-level "'small'"
  fi
done

say "Done. Reopen Nautilus (SUPER + SHIFT + F) to see it."
echo
echo "  interface font : $(gsettings get org.gnome.desktop.interface font-name)"
echo "  nautilus icons : $(gsettings get org.gnome.nautilus.icon-view default-zoom-level)"
echo "  nautilus list  : $(gsettings get org.gnome.nautilus.list-view default-zoom-level)"
echo
echo "  revert with: $0 --revert"
