#!/usr/bin/env python3
"""Generate the boot/login screen assets.

Omarchy's Plymouth boot screen and its SDDM login screen are set from a theme
by `omarchy plymouth set-by-theme`, which reads two files from the theme
directory and nothing else:

    unlock.png          the mark, centred above the password entry. Copied to
                        both themes as logo.png and NOT recoloured, so it keeps
                        its own colours. It must be a real file, not a symlink.
    preview-unlock.png  a 1920x1080 mock of that screen. Its presence is what
                        makes the theme appear in `omarchy plymouth switcher`.

The mark is the lattice the crew builds — the theme's own art, and the one
shape here that carries no text.

    python3 -I tools/gen_logo.py [--seed N]
"""

import argparse
import os
import random
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import sprites as S
from canvas import Canvas

# The stock assets Omarchy composites under the logo, which the preview apes.
SDDM_ASSETS = "/usr/share/omarchy/default/sddm/omarchy"


def build_logo(path, rng, block=26):
    """The lattice, on a flat background that is made transparent afterwards."""
    cells = S.snowflake(rng, radius=9)
    colors = S.flake_colors(cells, rng)
    span = max(max(abs(dx), abs(dy)) for dx, dy in cells)
    size = (span * 2 + 1) * block
    c = Canvas(size, size, S.BG)
    cx = cy = size // 2
    for (dx, dy) in cells:
        c.rect(cx + dx * block - block // 2 + 1, cy + dy * block - block // 2 + 1,
               block - 2, block - 2, colors[(dx, dy)])
    c.write_png(path)
    return size


def theme_dir(here):
    """Where the theme lives on this machine.

    The tools sit apart from the theme because Omarchy's gallery lists only
    repositories that carry no code. So look for the theme where Omarchy
    installed it, then for a checkout beside this one.
    """
    for c in (os.path.expanduser("~/.config/omarchy/themes/neon-foundry"),
              os.path.join(here, "..", "neon-foundry"),
              os.path.join(here, "..", "gulay-omarchy-theme")):
        if os.path.isfile(os.path.join(c, "colors.toml")):
            return os.path.realpath(c)
    return None


def default_out(here, sub=""):
    """Write into the theme if it is here, else into dist/ beside the tools."""
    base = theme_dir(here) or os.path.join(here, "dist")
    return os.path.join(base, sub) if sub else base


def main():
    ap = argparse.ArgumentParser()
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--out", default=default_out(here),
                    help="defaults to the installed theme directory")
    ap.add_argument("--seed", type=int, default=20261012)
    args = ap.parse_args()

    if not shutil.which("magick"):
        sys.exit("ImageMagick is required to build the login assets.")

    rng = random.Random(args.seed)
    logo = os.path.join(args.out, "unlock.png")
    size = build_logo(logo, rng)

    # The flat ground becomes transparency: none of the palette collides with
    # it, so nothing inside the lattice is punched out by mistake.
    subprocess.run(["magick", logo, "-transparent", S.BG, logo], check=True)
    print(f"  unlock.png          {size}x{size}  {os.path.getsize(logo) // 1024} KiB")

    # The preview: the same screen Plymouth will draw. Background and entry
    # colours come from colors.toml exactly as omarchy-plymouth-set reads them.
    preview = os.path.join(args.out, "preview-unlock.png")
    logo_w = 460
    cmd = ["magick", "-size", "1920x1080", f"xc:{S.BG}"]

    # The mark, centred a little above the middle.
    cmd += ["(", logo, "-resize", f"{logo_w}x", ")",
            "-gravity", "center", "-geometry", "+0-90", "-composite"]

    # The lock glyph and the entry box, tinted to the foreground the way
    # omarchy-plymouth-set tints them.
    lock = os.path.join(SDDM_ASSETS, "lock.png")
    entry = os.path.join(SDDM_ASSETS, "entry.png")
    bullet = os.path.join(SDDM_ASSETS, "bullet.png")
    if os.path.isfile(lock) and os.path.isfile(entry):
        # Lock glyph and entry box sit side by side and are centred as one
        # group, the way the SDDM Main.qml lays them out (a Row with spacing).
        lock_w, lock_h = 84, 96
        entry_w, entry_h = 286, 48
        gap = 38
        group = lock_w + gap + entry_w
        lock_x = -group // 2 + lock_w // 2
        entry_x = group // 2 - entry_w // 2
        row_y = 170

        cmd += ["(", lock, "-channel", "RGB", "+level-colors", f"{S.FG},{S.FG}", ")",
                "-gravity", "center", "-geometry", f"{lock_x:+d}{row_y:+d}", "-composite"]
        cmd += ["(", entry, "-channel", "RGB", "+level-colors", f"{S.FG},{S.FG}", ")",
                "-gravity", "center", "-geometry", f"{entry_x:+d}{row_y:+d}", "-composite"]
        if os.path.isfile(bullet):
            # Four dots typed into the left of the entry box.
            first = entry_x - entry_w // 2 + 28
            for i in range(4):
                cmd += ["(", bullet, "-channel", "RGB",
                        "+level-colors", f"{S.FG},{S.FG}", ")",
                        "-gravity", "center",
                        "-geometry", f"{first + i * 22:+d}{row_y:+d}", "-composite"]

    cmd += [preview]
    subprocess.run(cmd, check=True)
    print(f"  preview-unlock.png  1920x1080  {os.path.getsize(preview) // 1024} KiB")


if __name__ == "__main__":
    main()
