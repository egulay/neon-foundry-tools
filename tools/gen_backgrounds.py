#!/usr/bin/env python3
"""Generate the Neon Foundry wallpapers.

Six scenes drawn at native panel resolution. Captions are laid on afterwards
with ImageMagick (JetBrains Mono, uppercase, wide tracking).

    python3 -I tools/gen_backgrounds.py [--out DIR] [--size WxH] [--seed N]
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

CAPTION_FONT = "JetBrainsMono-NF-Bold"
CAPTION_FONT_FALLBACK = "JetBrainsMono-NF-Regular"


def snap(v, cell=S.CELL):
    """Put a thing on a grid line — the characters move along them, not between."""
    return int(round(v / cell) * cell)


def base(w, h, seed_offset=0):
    """Dark ground and a 1px grid at 55%."""
    c = Canvas(w, h, S.BG)
    c.grid(120, S.LINE, 0.75)
    return c


def caption_args(path, w, h, title, subtitle):
    """ImageMagick arguments for the lower-left caption block."""
    font = CAPTION_FONT
    probe = subprocess.run(["magick", "-list", "font"], capture_output=True, text=True)
    if font not in probe.stdout:
        font = CAPTION_FONT_FALLBACK if CAPTION_FONT_FALLBACK in probe.stdout else "DejaVu-Sans-Mono"

    pad = int(h * 0.075)
    label_pt = max(15, int(h * 0.0125))
    eyebrow_pt = max(12, int(h * 0.0095))
    rule_w = int(w * 0.022)

    return [
        "magick", path,
        # thin accent rule above the label
        "-fill", S.ACCENT, "-draw",
        f"rectangle {pad},{h - pad - int(label_pt * 3.2)} {pad + rule_w},{h - pad - int(label_pt * 3.2) + 2}",
        "-font", font,
        "-fill", S.FG_MUTED, "-pointsize", str(eyebrow_pt), "-kerning", str(eyebrow_pt * 0.22),
        "-annotate", f"+{pad}+{h - pad - int(label_pt * 1.7)}", subtitle.upper(),
        "-fill", S.FG, "-pointsize", str(label_pt), "-kerning", str(label_pt * 0.2),
        "-annotate", f"+{pad}+{h - pad}", title.upper(),
        path,
    ]


# --- scenes ----------------------------------------------------------------
# Sprite scales. A 2880x1800 panel needs roughly six times the 1x pixel size
# before a beetle reads as a beetle.
W_PX = 16          # workers   -> 80 x 128
B_PX = 14          # beetles   -> 98 x 70
U_PX = 20          # saucer    -> 220 x 100
CAT_PX = 18        # cat       -> 216 x 126
LAMB_PX = 18       # lamb      -> 234 x 162
DEVIL_PX = 22      # devil     -> 198 x 264
PILE = 28          # quarry block
SNAKE = 20         # snake segment


def scene_quarry(c, rng):
    """A wide industrial panorama: stock on the left, lattice rising right,
    the crew strung out along the haul route between them."""
    w, h = c.w, c.h
    ground = snap(h * 0.70)

    # Three quarries at descending stock levels.
    for i, (qx, shape, level) in enumerate((
        (snap(w * 0.08), 0, 3), (snap(w * 0.155), 1, 2), (snap(w * 0.225), 2, 1),
    )):
        color = S.PALETTE[i % len(S.PALETTE)]
        rows = S.PILE_SHAPES[shape][: max(1, level + 1)]
        for r, row in enumerate(rows):
            for off in row:
                c.rect(qx + off * PILE + 2, ground - (r + 1) * PILE + 2,
                       PILE - 3, PILE - 3, color, S.PILE_ALPHA)
        c.disc(qx, ground - PILE * 2, 210, color, 0.06)

    # Lattice under construction: placed blocks below, plan ghosted above.
    cells = S.snowflake(rng, radius=8)
    colors = S.flake_colors(cells, rng)
    u = 32
    fx, fy = snap(w * 0.76), snap(h * 0.40)
    c.disc(fx, fy, u * 10, S.PALETTE[0], 0.08)
    for (dx, dy) in cells:
        x, y = fx + dx * u, fy + dy * u
        if dy > -3:  # built bottom-up, so only the crown is still a plan
            c.rect(x + 2, y + 2, u - 3, u - 3, colors[(dx, dy)])
        else:
            c.rect(x + 3, y + 3, u - 5, u - 5, colors[(dx, dy)], 0.22)

    # The crew, hauling. Carriers go right with a block, empties come back left.
    for i in range(S.WORKERS):
        kind = i % 3
        hat = S.PALETTE[i % len(S.PALETTE)]
        tool = S.PALETTE[(i + 2) % len(S.PALETTE)]
        outbound = i % 2 == 0
        x = snap(w * 0.10 + (w * 0.52) * (i / (S.WORKERS - 1)))
        lane = ground if outbound else ground - 150
        frame = S.worker_frame(kind, i, moving=True)
        load = S.PALETTE[(i + 1) % len(S.PALETTE)] if outbound else None
        c.sprite(frame, x, lane - 8 * W_PX, S.worker_colors(hat, tool, load),
                 W_PX, flip=not outbound)
        c.disc(x + 2 * W_PX, lane - 4 * W_PX, 120, hat, 0.05)


def scene_abduction(c, rng):
    """The saucer has a beetle off the ground. The rest scatter down the lines."""
    w, h = c.w, c.h
    ground = snap(h * 0.76)
    ufo_x, ufo_y = snap(w * 0.50), snap(h * 0.14)
    ufo_w = len(S.UFO[0]) * U_PX

    # Beam: a dithered cone from the hull to the ground.
    beam_top, beam_bottom = ufo_y + 4 * U_PX, ground
    for y in range(beam_top, beam_bottom, 6):
        t = (y - beam_top) / max(1, beam_bottom - beam_top)
        half = int(ufo_w * 0.18 + ufo_w * 0.95 * t)
        for x in range(ufo_x - half, ufo_x + half, 12):
            if rng.random() < 0.6 - 0.3 * t:
                col = S.LINK if (x // 12 + y // 6) % 2 else S.PALETTE[4]
                c.rect(x, y, 5, 5, col, (1 - t * 0.8) * 0.55)
    c.disc(ufo_x, (beam_top + beam_bottom) // 2, ufo_w * 1.3, S.LINK, 0.09)

    # The saucer, running lights cycling through the palette.
    light_shift = rng.randrange(5)
    c.sprite(S.UFO, ufo_x - ufo_w // 2, ufo_y,
             {"D": S.LINK, "W": S.PALETTE[4], "#": S.UFO_HULL}, U_PX)
    for rx, ch in enumerate(S.UFO[3]):
        if ch == "L":
            c.rect(ufo_x - ufo_w // 2 + rx * U_PX, ufo_y + 3 * U_PX, U_PX, U_PX,
                   S.PALETTE[(rx // 2 + light_shift) % len(S.PALETTE)])
    c.disc(ufo_x, ufo_y + 2 * U_PX, ufo_w * 0.7, S.LINK, 0.20)

    # One beetle lifted and tumbling in the beam.
    lifted = S.rot90(S.BUG_TWITCH)
    lw = len(lifted[0]) * B_PX
    c.outlined_sprite(lifted, ufo_x - lw // 2, beam_top + (beam_bottom - beam_top) // 3,
                      S.bug_colors(S.PALETTE[3]), S.LINK, B_PX, 0.5, outline_px=4)

    # The others bolting along the lanes.
    for i, (fx, fy, rotated) in enumerate((
        (0.13, 0.80, False), (0.27, 0.90, False), (0.73, 0.86, True), (0.87, 0.78, False),
    )):
        frame = S.rot90(S.BUG_RUN[i % 3]) if rotated else S.BUG_RUN[i % 3]
        c.sprite(frame, snap(w * fx), snap(h * fy) - len(frame) * B_PX,
                 S.bug_colors(S.PALETTE[i % len(S.PALETTE)]), B_PX, flip=(i >= 2))

    # One that did not make it.
    c.sprite(S.BUG_DEAD, snap(w * 0.40), ground - len(S.BUG_DEAD) * B_PX,
             S.bug_colors(S.PALETTE[1]), B_PX)


def scene_crew(c, rng):
    """All nine, mid-shift, across three lanes: hauling, working, catching breath."""
    w, h = c.w, c.h
    lanes = [snap(h * 0.32), snap(h * 0.54), snap(h * 0.76)]
    for i in range(S.WORKERS):
        kind = i % 3
        lane = lanes[i // 3]
        x = snap(w * (0.16 + 0.27 * (i % 3)))
        hat = S.PALETTE[i % len(S.PALETTE)]
        tool = S.PALETTE[(i + 3) % len(S.PALETTE)]
        mode = i % 4
        if mode == 0:
            frame = S.worker_frame(kind, i, working=True)
        elif mode == 3:
            frame = S.worker_frame(kind, 0, moving=False, idle_wipe=True)
        else:
            frame = S.worker_frame(kind, i, moving=True)
        load = S.PALETTE[(i + 1) % len(S.PALETTE)] if mode == 1 else None
        c.disc(x + 2 * W_PX, lane - 4 * W_PX, 165, hat, 0.06)
        c.sprite(frame, x, lane - 8 * W_PX, S.worker_colors(hat, tool, load),
                 W_PX, flip=(i % 3 == 1))

    # Blocks set down on the middle lane, mid-haul.
    for k in range(5):
        c.rect(snap(w * 0.70) + k * PILE, lanes[1] - PILE, PILE - 3, PILE - 3,
               S.PALETTE[k % len(S.PALETTE)], 0.85)


def scene_lattice(c, rng):
    """The finished thing, centred and lit. What the whole shift was for."""
    w, h = c.w, c.h
    cells = S.snowflake(rng, radius=10)
    colors = S.flake_colors(cells, rng)
    u = 42
    cx, cy = w // 2, int(h * 0.44)
    c.disc(cx, cy, u * 13, S.PALETTE[0], 0.09)
    c.disc(cx, cy, u * 7, S.LINK, 0.07)
    for (dx, dy) in cells:
        c.rect(cx + dx * u + 2, cy + dy * u + 2, u - 3, u - 3, colors[(dx, dy)])
    # A worker at the foot of it, looking up: the scale cue.
    frame = S.worker_frame(2, 0, moving=False, idle_wipe=True)
    c.sprite(frame, cx - 5 * W_PX // 2, snap(h * 0.84) - 8 * W_PX,
             S.worker_colors(S.PALETTE[0], S.PALETTE[3]), W_PX)


def _chaikin(points, iterations=3):
    """Round the corners of a polyline (Chaikin). A grid-walking snake turns at
    right angles because it is pinned to the grid and only 14 segments long; at
    wallpaper scale those corners read as a circuit trace, so they get eased."""
    for _ in range(iterations):
        out = [points[0]]
        for (x0, y0), (x1, y1) in zip(points, points[1:]):
            out.append((x0 * 0.75 + x1 * 0.25, y0 * 0.75 + y1 * 0.25))
            out.append((x0 * 0.25 + x1 * 0.75, y0 * 0.25 + y1 * 0.75))
        out.append(points[-1])
        points = out
    return points


def _resample(points, spacing):
    """Even points along a polyline, so the body is continuous rather than a
    dotted line: segments overlap instead of leaving a gap at every step."""
    out = [points[0]]
    carry = 0.0
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        seg = ((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5
        if seg <= 0:
            continue
        t = carry
        while t < seg:
            f = t / seg
            out.append((x0 + (x1 - x0) * f, y0 + (y1 - y0) * f))
            t += spacing
        carry = t - seg
    out.append(points[-1])
    return out


def scene_patrol(c, rng):
    """The snake, full length, winding across the frame out of a wormhole.

    Pinned to the grid and fourteen segments long, a snake reads at 8px and
    turns into a dotted circuit trace at 2880px. This one keeps what makes it a
    snake — the two alternating greens, the width falling away to the tail, the
    wider head with eyes on the leading side and a forked tongue — but follows a
    smoothed curve and is sampled densely enough to be solid.
    """
    w, h = c.w, c.h

    # A winding path rising left to right, as fractions of the frame.
    control = [(0.07, 0.56), (0.19, 0.72), (0.33, 0.67), (0.44, 0.47),
               (0.56, 0.34), (0.69, 0.35), (0.80, 0.27)]
    coarse = [(fx * w, fy * h) for fx, fy in control]

    # Neck width in pixels, stated outright rather than derived from the
    # grid step: this is a drawn creature, not a grid walker, and tying it
    # to the step is what left it 25px wide on a 2880px canvas.
    girth = 78
    body = _resample(_chaikin(coarse, 4), girth * 0.18)
    body.reverse()                      # index 0 is the head
    n = len(body)

    # Tail first, so each blob is overlapped by the thicker one ahead of it.
    for i in range(n - 1, 0, -1):
        bx, by = body[i]
        taper = 1 - (i / max(1, n - 1)) * 0.68   # full at the neck, thin at the tip
        size = max(3, round(girth * taper))
        # Scales band along the body; alternating per sample at this density
        # would just read as noise.
        col = "#8fbf00" if (i // 4) % 2 else S.PALETTE[0]
        c.rect(bx - size / 2, by - size / 2, size, size, col)

    # Head: a little wider than the neck.
    hx, hy = body[0]
    hs = round(girth * 1.15)
    c.rect(hx - hs / 2, hy - hs / 2, hs, hs, S.PALETTE[0])

    # Facing, averaged over a few samples so the curve does not throw it.
    ahead = body[min(8, n - 1)]
    vx, vy = hx - ahead[0], hy - ahead[1]
    mag = max(1e-6, (vx * vx + vy * vy) ** 0.5)
    dx, dy = vx / mag, vy / mag
    px_, py_ = -dy, dx
    k = girth / 8.0
    eye = max(3, round(2.0 * k))

    for side in (1, -1):
        c.rect(hx + dx * 1.5 * k + px_ * side * 2.2 * k - eye / 2,
               hy + dy * 1.5 * k + py_ * side * 2.2 * k - eye / 2,
               eye, eye, "#121215")

    tx, ty = hx + dx * (hs / 2 + k * 0.4), hy + dy * (hs / 2 + k * 0.4)
    c.rect(tx - eye / 2, ty - eye / 2, eye, eye, "#ff2e8b")
    for fork in (1, -1):
        c.rect(tx + dx * 2.4 * k + px_ * fork * 1.7 * k - eye / 2,
               ty + dy * 2.4 * k + py_ * fork * 1.7 * k - eye / 2,
               eye, eye, "#ff2e8b")

    c.disc(hx, hy, 300, S.PALETTE[0], 0.09)

    # The hole the tail is still coming out of.
    c.wormhole(coarse[0][0], coarse[0][1], 10.0, rng)

    # Beetles getting out of the way, well clear of the caption.
    for i in range(3):
        c.sprite(S.BUG_RUN[i % 3], snap(w * (0.46 + 0.17 * i)), snap(h * 0.86),
                 S.bug_colors(S.PALETTE[(i + 1) % len(S.PALETTE)]), B_PX, flip=(i == 1))


def scene_off_shift(c, rng):
    """Nobody working: the cat, the lamb and the devil, each in their own light."""
    import math
    w, h = c.w, c.h
    ground = snap(h * 0.68)

    # Cat: golden halo pass, then the black body over it, then sparkles.
    cat_x = snap(w * 0.20)
    cat_cx, cat_cy = cat_x + 6 * CAT_PX, ground - 4 * CAT_PX
    for ring in range(6):
        c.disc(cat_cx, cat_cy, 150 + ring * 26,
               S.CAT_GOLD if ring % 2 else S.CAT_HALO_HI, 0.035)
    c.outlined_sprite(S.CAT_SIT[0], cat_x, ground - 7 * CAT_PX,
                      S.CAT_COLORS, S.CAT_GOLD, CAT_PX, 1.0, outline_px=5)
    for k in range(10):
        a = k * 1.047 + rng.random()
        c.rect(cat_cx + math.cos(a) * (120 + rng.randrange(60)),
               cat_cy + math.sin(a) * (80 + rng.randrange(40)), 5, 5,
               S.CAT_GOLD if k % 2 else S.CAT_HALO_HI, 0.5 + rng.random() * 0.5)

    # Lamb: breathing light-blue aura, eight-way, plus motes over its back.
    lamb_x = snap(w * 0.50)
    lamb_cx, lamb_cy = lamb_x + 6 * LAMB_PX, ground - 5 * LAMB_PX
    for ring in range(6):
        c.disc(lamb_cx, lamb_cy, 160 + ring * 26,
               S.LAMB_AURA if ring % 2 else S.LAMB_WOOL, 0.03)
    c.outlined_sprite(S.LAMB_GRAZE[0], lamb_x, ground - 9 * LAMB_PX,
                      S.LAMB_COLORS, S.LAMB_AURA, LAMB_PX, 0.7, outline_px=4)
    for k in range(5):
        a = (k * math.pi * 2) / 5 + 0.4
        c.rect(lamb_cx + math.cos(a) * 150, lamb_cy - 110 + math.sin(a) * 50, 5, 5,
               S.LAMB_AURA if k % 2 else S.LAMB_WOOL, 0.75)

    # Devil: never hurries. Embers at its feet, a dull red wash behind.
    devil_x = snap(w * 0.80)
    c.disc(devil_x + 4 * DEVIL_PX, ground - 5 * DEVIL_PX, 300, S.DEVIL_RED, 0.055)
    c.outlined_sprite(S.DEVIL[0], devil_x, ground - 12 * DEVIL_PX, S.DEVIL_COLORS,
                      S.DEVIL_DARK, DEVIL_PX, 0.8, flip=True, outline_px=5)
    for e in range(26):
        ex = devil_x + rng.randrange(-70, 9 * DEVIL_PX + 70)
        ey = ground - rng.randrange(0, 90)
        c.rect(ex, ey, 5, 5, ("#f5c542", S.PALETTE[1], S.DEVIL_RED)[e % 3],
               0.45 + rng.random() * 0.45)


SCENES = [
    ("01-quarry", scene_quarry, "Quarry Detail", "Sector 09"),
    ("02-abduction", scene_abduction, "Specimen Recovered", "Unidentified"),
    ("03-crew", scene_crew, "Nine Hands", "One Structure"),
    ("04-lattice", scene_lattice, "Lattice Complete", "Sector 09"),
    ("05-patrol", scene_patrol, "Perimeter Patrol", "Wormhole Open"),
    ("06-off-shift", scene_off_shift, "Off Shift", "Sector 09"),
]


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
    ap.add_argument("--out", default=default_out(here, "backgrounds"),
                    help="defaults to the installed theme's backgrounds/")
    ap.add_argument("--size", default="2880x1800")
    ap.add_argument("--seed", type=int, default=20261012)
    ap.add_argument("--only", default=None, help="comma-separated scene names")
    args = ap.parse_args()

    w, h = (int(v) for v in args.size.lower().split("x"))
    os.makedirs(args.out, exist_ok=True)
    have_magick = shutil.which("magick") is not None
    wanted = args.only.split(",") if args.only else None

    for i, (name, fn, title, subtitle) in enumerate(SCENES):
        if wanted and name not in wanted:
            continue
        rng = random.Random(args.seed + i * 7919)
        c = base(w, h)
        fn(c, rng)
        c.vignette(0.5)
        path = os.path.join(args.out, f"{name}.png")
        c.write_png(path)
        if have_magick:
            subprocess.run(caption_args(path, w, h, title, subtitle),
                           check=True, capture_output=True)
        print(f"  {name}.png  {os.path.getsize(path) // 1024} KiB")


if __name__ == "__main__":
    main()
