"""Pixel-art sprite data for the Neon Foundry theme.

Every matrix and colour the wallpapers and the lock screen draw, so the two
show the same characters. The renderers map letters to colours through COLORS.

Sprite legends
  workers  '#' body, 'H' hard hat, 'T' tool, 'L' carried load
  bugs     '#' legs, 'A' antennae, 'H' head, 'B' body, 'S' wing-case stripe
  ufo      'D' dome, 'W' dome window, '#' hull, 'L' running lights
  cat      '#' body, 'E' eye, 'T' tail
  lamb     'W' wool, 'F' face and legs, 'E' eye
  devil    'R' red, 'D' dark red, 'W' eyes, '#' legs/horn tips
"""

# --- palette ---------------------------------------------------------------
# The five sprite colours, in order.
PALETTE = ["#c8ff00", "#ff5a1f", "#31e5ff", "#ff2e8b", "#f5f2ea"]

# app.css custom properties, converted from oklch to sRGB hex.
BG = "#060709"  # --bg          oklch(0.13 0.005 260)
BG_RAISED = "#0e0f12"  # --bg-raised    oklch(0.17 0.006 260)
FG = "#edebe5"  # --fg          oklch(0.94 0.008 90)
FG_MUTED = "#8f9298"  # --fg-muted    oklch(0.66 0.01 260)  == worker bodies
LINE = "#27292d"  # --line        oklch(0.28 0.008 260) == grid lines
ACCENT = "#baf700"  # --accent      oklch(0.90 0.24 125)
LINK = "#44e7ef"  # --link        oklch(0.85 0.13 200)

CAT_GOLD = "#f2c14e"
CAT_HALO_HI = "#fff3c4"
CAT_BODY = "#07070a"
CAT_EYE = "#c8ff00"
LAMB_WOOL = "#f5f2ea"
LAMB_DARK = "#2b2b31"
LAMB_AURA = "#a8ecff"
DEVIL_RED = "#ff3b3b"
DEVIL_DARK = "#8a1c1c"
BUG_HEAD = "#2b2b31"
BUG_STRIPE = "#121215"
UFO_HULL = "#a9a9b0"

# Geometry.
CELL = 64  # grid spacing
PX = 3  # one worker/bug/ufo sprite pixel
CAT_PX = 2
LAMB_PX = 2
DEVIL_PX = 3
PU = 8  # quarry pile block
GRID_ALPHA = 0.55
PILE_ALPHA = 0.75
GHOST_ALPHA = 0.14
SNAKE_STEP = 8
SNAKE_LEN = 14

# --- workers ---------------------------------------------------------------
# A frame is a 6-row torso (arms out or arms down) plus a leg pair from a
# four-step walk cycle.
LEGS = [
    [".#.#.", "#...#"],
    ["..#..", ".#.#."],
    [".#.#.", "..#.#"],
    ["..#..", ".#.#."],
]
STAND = [".#.#.", ".#.#."]

KINDS = [
    {  # mason: hammer
        "out": ["LLL..", ".HHH.", ".###.", "..#..", "#.#.#", "..#.."],
        "down": ["LLL..", ".HHH.", ".###.", "..#..", ".###.", "..#.."],
        "work": [
            [".....", ".HHH.", ".###.", "..#.T", ".###T", "#.#.."],
            [".....", ".HHH.", ".###.", "..#..", ".###.", "#.#TT"],
        ],
        "wipe": [".....", ".HHH.", "####.", "..#..", ".###.", "..#.."],
    },
    {  # carrier: wide slab on the head, sets it down to work
        "out": ["LLLLL", ".HHH.", ".###.", "..#..", "#.#.#", "..#.."],
        "down": ["LLLLL", ".HHH.", ".###.", "..#..", ".###.", "..#.."],
        "work": [
            [".....", ".HHH.", ".###.", "..#..", "#.#.#", "TT.#."],
            [".....", ".HHH.", ".###.", "..#..", ".###.", "TT.#."],
        ],
        "wipe": [".....", ".HHH.", "####.", "..#..", ".###.", "..#.."],
    },
    {  # foreman: flag
        "out": ["LLT..", ".HHH.", ".###.", "..#T.", "#.#.#", "..#.."],
        "down": ["LLT..", ".HHH.", ".###.", "..#T.", ".###.", "..#.."],
        "work": [
            ["..T..", ".HHH.", ".###.", "..#T.", ".###.", "#.#.#"],
            ["..T..", ".HHH.", ".###.", "..#T.", "#.#.#", "..#.."],
        ],
        "wipe": ["..T..", ".HHH.", "####.", "..#T.", ".###.", "..#.."],
    },
]
WORKERS = 9

# --- beetles ---------------------------------------------------------------
BUG_RUN = [
    [".#.#.#A", ".BBBBH.", ".BSSBH.", ".BBBBH.", ".#.#.#A"],
    ["..#.#.A", ".BBBBH.", ".BSSBH.", ".BBBBH.", "#.#...A"],
    ["#.#...A", ".BBBBH.", ".BSSBH.", ".BBBBH.", "..#.#.A"],
]
BUG_TWITCH = [".#.#.#.", ".BBBBHA", ".BSSBH.", ".BBBBHA", ".#.#.#."]
BUG_DEAD = ["#.#.#.#", ".BBBBB.", ".BSSSB.", ".BBBBB.", "......."]
BUGS = 5

# --- flying saucer ---------------------------------------------------------
UFO = ["....DDD....", "...DWWWD...", ".#########.", "L#L#L#L#L#L", "...#...#..."]

# --- black cat -------------------------------------------------------------
CAT_WALK = [
    [".........#.#", ".T......####", "..T....#E###", "...T.#######", "....########", "....##...##.", "....##...##."],
    [".........#.#", "..T.....####", "..T....#E###", "...T.#######", "....########", "...##...##..", "..#...#..#.."],
]
CAT_SIT = [
    [".......#.#..", ".......####.", "......#E###.", ".....######.", ".T..#######.", "..TT#######.", "....##..##.."],
    [".......#.#..", ".......####.", "......#E###.", ".....######.", "....#######.", ".TTT#######.", "....##..##.."],
]

# --- lamb ------------------------------------------------------------------
LAMB_WALK = [
    ["....WWWW.....", "..WWWWWWWW.F.", ".WWWWWWWWWWFF", "WWWWWWWWWWFEF", "WWWWWWWWWWWFF", ".WWWWWWWWW.F.", "..WWWWWWWW...", "...F...F.....", "...F...F....."],
    ["....WWWW.....", "..WWWWWWWW.F.", ".WWWWWWWWWWFF", "WWWWWWWWWWFEF", "WWWWWWWWWWWFF", ".WWWWWWWWW.F.", "..WWWWWWWW...", "..F...F......", ".F.....F....."],
]
LAMB_GRAZE = [
    ["....WWWW.....", "..WWWWWWWW...", ".WWWWWWWWWW..", "WWWWWWWWWWW..", "WWWWWWWWWWWF.", ".WWWWWWWWW.FF", "..WWWWWWWW.EF", "...F...F...FF", "...F...F....."],
    ["....WWWW.....", "..WWWWWWWW...", ".WWWWWWWWWW..", "WWWWWWWWWWW..", "WWWWWWWWWWWF.", ".WWWWWWWWW.FF", "..WWWWWWWW.FE", "...F...F...FF", "...F...F....."],
]

# --- devil -----------------------------------------------------------------
DEVIL = [
    ["#.......#", ".D.....D.", "..RRRRR..", ".RRRRRRR.", "RRRRRRRRR", "RRWWRWWRR", "RRRRRRRRR", ".RRRRRRR.", "..RRRRR..", "...DDD...", "...#.#...", "..#...#.."],
    ["#.......#", ".D.....D.", "..RRRRR..", ".RRRRRRR.", "RRRRRRRRR", "RRWWRWWRR", "RRRRRRRRR", ".RRRRRRR.", "..RRRRR..", "...DDD...", "...#.#...", "...#.#..."],
]

# --- quarry pile shapes ----------------------------------------------------
PILE_SHAPES = [
    [[-2, -1, 0, 1, 2], [-1, 0, 1], [0]],  # pyramid
    [[-3, -2, -1, 0, 1, 2, 3], [-2, 0, 2]],  # slab with loose blocks on top
    [[-1, 0], [-1, 0], [-1, 0], [0]],  # column
]


def rot90(matrix):
    """Rotate a sprite matrix 90 degrees clockwise (bugs running up/down)."""
    h, w = len(matrix), len(matrix[0])
    out = []
    for x in range(w):
        out.append("".join(matrix[y][x] for y in range(h - 1, -1, -1)))
    return out


def flip_h(matrix):
    """Mirror a sprite horizontally (a character facing left)."""
    return [row[::-1] for row in matrix]


def worker_frame(kind, step, moving=True, working=False, idle_wipe=False):
    """Assemble one 8-row worker frame: torso plus a leg pair."""
    k = KINDS[kind]
    if working:
        return list(k["work"][step % 2]) + list(STAND)
    if moving:
        top = k["down"] if step % 2 else k["out"]
        return list(top) + list(LEGS[step % 4])
    if idle_wipe:
        return list(k["wipe"]) + list(STAND)
    return list(k["down"]) + list(STAND)


def worker_colors(hat, tool, load=None):
    return {"#": FG_MUTED, "H": hat, "T": tool, "L": load or ""}


def bug_colors(color):
    return {"#": FG_MUTED, "A": FG_MUTED, "H": BUG_HEAD, "B": color, "S": BUG_STRIPE}


CAT_COLORS = {"#": CAT_BODY, "T": CAT_BODY, "E": CAT_EYE}
LAMB_COLORS = {"W": LAMB_WOOL, "F": LAMB_DARK, "E": LAMB_WOOL}
DEVIL_COLORS = {"#": FG_MUTED, "R": DEVIL_RED, "D": DEVIL_DARK, "W": LAMB_WOOL}


def _d4(cells):
    """Every image of a cell under the square's eight symmetries.

    Applied to one arm this is what turns it into a whole flake: an arm drawn
    along +y comes back as the four axial arms, and one drawn along the
    diagonal comes back as the four corner arms.
    """
    out = set()
    for dx, dy in cells:
        for a, b in ((dx, dy), (dy, dx)):
            for sx in (1, -1):
                for sy in (1, -1):
                    out.add((a * sx, b * sy))
    return out


def snowflake(rng, radius=None):
    """Randomised pixel snowflake blueprint.

    One arm is drawn along +y and one along the diagonal, each a single block
    wide with spurs hanging off it, and both are then mapped through the eight
    symmetries of the square. Keeping the arms one block wide is what makes it
    read as a crystal rather than a blob — mirroring a filled wedge packs the
    centre solid. Returns {(dx, dy)} in block units.
    """
    radius = radius or rng.randint(7, 9)
    axial = {(0, d) for d in range(1, radius + 1)}

    # Spurs off the axial arm, longer nearer the core, mirrored by _d4.
    spur_spots = rng.sample(range(2, radius), min(3, max(1, radius - 2)))
    for d in spur_spots:
        for b in range(1, max(1, int((radius - d) * 0.6) + 1)):
            axial.add((b, d))
            axial.add((b, d + 1) if rng.random() < 0.35 else (b, d))

    # A cross at the tip, so each arm finishes on a point.
    axial.add((1, radius - 1))
    axial.add((0, radius))

    # The corner arms are shorter, as they are on a real flake.
    diag_len = max(3, int(radius * rng.uniform(0.6, 0.85)))
    diagonal = {(d, d) for d in range(1, diag_len + 1)}
    if diag_len >= 3:
        diagonal.add((diag_len - 1, diag_len))

    cells = _d4(axial) | _d4(diagonal)
    cells |= {(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)}  # core
    return cells


def flake_colors(cells, rng):
    """Colour a flake by ring: each shell of
    the lattice takes one palette colour so the arms read as banded."""
    out = {}
    for dx, dy in cells:
        ring = max(abs(dx), abs(dy))
        out[(dx, dy)] = PALETTE[ring % len(PALETTE)]
    # Scatter a few off-colour blocks so it is not perfectly mechanical.
    for key in list(out):
        if rng.random() < 0.07:
            out[key] = rng.choice(PALETTE)
    return out
