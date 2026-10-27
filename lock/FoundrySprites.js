.pragma library

// Pixel-art sprite data for the Neon Foundry lock screen.
//
// The same matrices the wallpaper generator draws from, so the unlock screens
// and the wallpapers show the same characters. Each scene maps letters to
// colours through the *Colors objects below.

var PALETTE = ["#c8ff00", "#ff5a1f", "#31e5ff", "#ff2e8b", "#f5f2ea"]

var BG = "#060709"
var FG = "#edebe5"
var FG_MUTED = "#8f9298"   // worker bodies
var LINE = "#27292d"       // grid lines
var ACCENT = "#baf700"
var LINK = "#44e7ef"

var CAT_GOLD = "#f2c14e"
var CAT_HALO_HI = "#fff3c4"
var CAT_BODY = "#07070a"
var CAT_EYE = "#c8ff00"
var LAMB_WOOL = "#f5f2ea"
var LAMB_DARK = "#2b2b31"
var LAMB_AURA = "#a8ecff"
var DEVIL_RED = "#ff3b3b"
var DEVIL_DARK = "#8a1c1c"
var BUG_HEAD = "#2b2b31"
var BUG_STRIPE = "#121215"
var UFO_HULL = "#a9a9b0"

// --- workers ---------------------------------------------------------------
// A frame is a 6-row torso plus a leg pair from a four-step walk cycle.
var LEGS = [
  [".#.#.", "#...#"],
  ["..#..", ".#.#."],
  [".#.#.", "..#.#"],
  ["..#..", ".#.#."]
]
var STAND = [".#.#.", ".#.#."]

var KINDS = [
  { // mason: hammer
    out:  ["LLL..", ".HHH.", ".###.", "..#..", "#.#.#", "..#.."],
    down: ["LLL..", ".HHH.", ".###.", "..#..", ".###.", "..#.."],
    work: [[".....", ".HHH.", ".###.", "..#.T", ".###T", "#.#.."],
           [".....", ".HHH.", ".###.", "..#..", ".###.", "#.#TT"]],
    wipe: [".....", ".HHH.", "####.", "..#..", ".###.", "..#.."]
  },
  { // carrier: wide slab on the head
    out:  ["LLLLL", ".HHH.", ".###.", "..#..", "#.#.#", "..#.."],
    down: ["LLLLL", ".HHH.", ".###.", "..#..", ".###.", "..#.."],
    work: [[".....", ".HHH.", ".###.", "..#..", "#.#.#", "TT.#."],
           [".....", ".HHH.", ".###.", "..#..", ".###.", "TT.#."]],
    wipe: [".....", ".HHH.", "####.", "..#..", ".###.", "..#.."]
  },
  { // foreman: flag
    out:  ["LLT..", ".HHH.", ".###.", "..#T.", "#.#.#", "..#.."],
    down: ["LLT..", ".HHH.", ".###.", "..#T.", ".###.", "..#.."],
    work: [["..T..", ".HHH.", ".###.", "..#T.", ".###.", "#.#.#"],
           ["..T..", ".HHH.", ".###.", "..#T.", "#.#.#", "..#.."]],
    wipe: ["..T..", ".HHH.", "####.", "..#T.", ".###.", "..#.."]
  }
]

// --- beetles ---------------------------------------------------------------
var BUG_RUN = [
  [".#.#.#A", ".BBBBH.", ".BSSBH.", ".BBBBH.", ".#.#.#A"],
  ["..#.#.A", ".BBBBH.", ".BSSBH.", ".BBBBH.", "#.#...A"],
  ["#.#...A", ".BBBBH.", ".BSSBH.", ".BBBBH.", "..#.#.A"]
]
var BUG_TWITCH = [".#.#.#.", ".BBBBHA", ".BSSBH.", ".BBBBHA", ".#.#.#."]
var BUG_DEAD = ["#.#.#.#", ".BBBBB.", ".BSSSB.", ".BBBBB.", "......."]

// --- flying saucer ---------------------------------------------------------
var UFO = ["....DDD....", "...DWWWD...", ".#########.", "L#L#L#L#L#L", "...#...#..."]

// --- black cat -------------------------------------------------------------
var CAT_WALK = [
  [".........#.#", ".T......####", "..T....#E###", "...T.#######", "....########", "....##...##.", "....##...##."],
  [".........#.#", "..T.....####", "..T....#E###", "...T.#######", "....########", "...##...##..", "..#...#..#.."]
]
var CAT_SIT = [
  [".......#.#..", ".......####.", "......#E###.", ".....######.", ".T..#######.", "..TT#######.", "....##..##.."],
  [".......#.#..", ".......####.", "......#E###.", ".....######.", "....#######.", ".TTT#######.", "....##..##.."]
]

// --- lamb ------------------------------------------------------------------
var LAMB_WALK = [
  ["....WWWW.....", "..WWWWWWWW.F.", ".WWWWWWWWWWFF", "WWWWWWWWWWFEF", "WWWWWWWWWWWFF", ".WWWWWWWWW.F.", "..WWWWWWWW...", "...F...F.....", "...F...F....."],
  ["....WWWW.....", "..WWWWWWWW.F.", ".WWWWWWWWWWFF", "WWWWWWWWWWFEF", "WWWWWWWWWWWFF", ".WWWWWWWWW.F.", "..WWWWWWWW...", "..F...F......", ".F.....F....."]
]
var LAMB_GRAZE = [
  ["....WWWW.....", "..WWWWWWWW...", ".WWWWWWWWWW..", "WWWWWWWWWWW..", "WWWWWWWWWWWF.", ".WWWWWWWWW.FF", "..WWWWWWWW.EF", "...F...F...FF", "...F...F....."],
  ["....WWWW.....", "..WWWWWWWW...", ".WWWWWWWWWW..", "WWWWWWWWWWW..", "WWWWWWWWWWWF.", ".WWWWWWWWW.FF", "..WWWWWWWW.FE", "...F...F...FF", "...F...F....."]
]

// --- devil -----------------------------------------------------------------
var DEVIL = [
  ["#.......#", ".D.....D.", "..RRRRR..", ".RRRRRRR.", "RRRRRRRRR", "RRWWRWWRR", "RRRRRRRRR", ".RRRRRRR.", "..RRRRR..", "...DDD...", "...#.#...", "..#...#.."],
  ["#.......#", ".D.....D.", "..RRRRR..", ".RRRRRRR.", "RRRRRRRRR", "RRWWRWWRR", "RRRRRRRRR", ".RRRRRRR.", "..RRRRR..", "...DDD...", "...#.#...", "...#.#..."]
]

// --- colour maps -----------------------------------------------------------
var CAT_COLORS = { "#": CAT_BODY, "T": CAT_BODY, "E": CAT_EYE }
var LAMB_COLORS = { "W": LAMB_WOOL, "F": LAMB_DARK, "E": LAMB_WOOL }
var DEVIL_COLORS = { "#": FG_MUTED, "R": DEVIL_RED, "D": DEVIL_DARK, "W": LAMB_WOOL }

function workerColors(hat, tool, load) {
  return { "#": FG_MUTED, "H": hat, "T": tool, "L": load || "" }
}

function bugColors(color) {
  return { "#": FG_MUTED, "A": FG_MUTED, "H": BUG_HEAD, "B": color, "S": BUG_STRIPE }
}

function ufoColors() {
  return { "D": LINK, "W": PALETTE[4], "#": UFO_HULL, "L": PALETTE[0] }
}

// --- helpers ---------------------------------------------------------------
/** Rotate a sprite matrix 90 degrees clockwise (bugs running up or down). */
function rot90(m) {
  var h = m.length, w = m[0].length, out = []
  for (var x = 0; x < w; x++) {
    var row = ""
    for (var y = h - 1; y >= 0; y--) row += m[y][x]
    out.push(row)
  }
  return out
}

/** Assemble one 8-row worker frame: torso plus a leg pair. */
function workerFrame(kind, step, moving, working, idleWipe) {
  var k = KINDS[kind % KINDS.length]
  if (working) return k.work[step % 2].concat(STAND)
  if (moving) return (step % 2 ? k.down : k.out).concat(LEGS[step % 4])
  if (idleWipe) return k.wipe.concat(STAND)
  return k.down.concat(STAND)
}

/** All four walking frames for a worker, ready to hand to FoundryPixel. */
function workerWalkFrames(kind) {
  var out = []
  for (var s = 0; s < 4; s++) out.push(workerFrame(kind, s, true, false, false))
  return out
}

// --- curve helpers ---------------------------------------------------------
// The same two steps tools/gen_backgrounds.py uses to draw the snake on the
// wallpapers. A snake pinned to the grid and fourteen segments long works at
// 8px; at panel scale it reads as a dotted circuit trace, so the path is eased
// and then sampled densely enough that the body comes out solid.

/** Round the corners of a polyline (Chaikin). */
function chaikin(points, iterations) {
  iterations = iterations === undefined ? 3 : iterations
  for (var it = 0; it < iterations; it++) {
    var out = [points[0]]
    for (var i = 0; i < points.length - 1; i++) {
      var a = points[i], b = points[i + 1]
      out.push({ x: a.x * 0.75 + b.x * 0.25, y: a.y * 0.75 + b.y * 0.25 })
      out.push({ x: a.x * 0.25 + b.x * 0.75, y: a.y * 0.25 + b.y * 0.75 })
    }
    out.push(points[points.length - 1])
    points = out
  }
  return points
}

/** Evenly spaced points along a polyline, so body segments overlap. */
function resample(points, spacing) {
  if (!points.length) return []
  var out = [points[0]]
  var carry = 0
  for (var i = 0; i < points.length - 1; i++) {
    var a = points[i], b = points[i + 1]
    var dx = b.x - a.x, dy = b.y - a.y
    var seg = Math.sqrt(dx * dx + dy * dy)
    if (seg <= 0) continue
    var t = carry
    while (t < seg) {
      var f = t / seg
      out.push({ x: a.x + dx * f, y: a.y + dy * f })
      t += spacing
    }
    carry = t - seg
  }
  out.push(points[points.length - 1])
  return out
}
