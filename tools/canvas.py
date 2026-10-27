"""A tiny RGB canvas and PNG writer, so wallpaper generation needs no deps.

Pillow is not installed on a stock Omarchy box and adding it just to draw
rectangles would be silly: every shape the wallpapers need is an axis-aligned
fill, and PNG's filter-0 encoding is a dozen lines of zlib.
"""

import struct
import zlib


def hex_rgb(value):
    v = value.lstrip("#")
    if len(v) == 3:
        v = "".join(c * 2 for c in v)
    return int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)


class Canvas:
    def __init__(self, width, height, background="#000000"):
        self.w = width
        self.h = height
        r, g, b = hex_rgb(background)
        self.buf = bytearray(bytes((r, g, b)) * (width * height))

    # --- primitives --------------------------------------------------------
    def px(self, x, y, color, alpha=1.0):
        x, y = int(x), int(y)
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        i = (y * self.w + x) * 3
        r, g, b = color
        if alpha >= 1.0:
            self.buf[i] = r
            self.buf[i + 1] = g
            self.buf[i + 2] = b
        else:
            a = alpha
            self.buf[i] = int(self.buf[i] * (1 - a) + r * a)
            self.buf[i + 1] = int(self.buf[i + 1] * (1 - a) + g * a)
            self.buf[i + 2] = int(self.buf[i + 2] * (1 - a) + b * a)

    def rect(self, x, y, w, h, color, alpha=1.0):
        if isinstance(color, str):
            color = hex_rgb(color)
        x0, y0 = int(x), int(y)
        x1, y1 = x0 + int(w), y0 + int(h)
        x0, y0 = max(0, x0), max(0, y0)
        x1, y1 = min(self.w, x1), min(self.h, y1)
        if x1 <= x0 or y1 <= y0:
            return
        r, g, b = color
        if alpha >= 1.0:
            row = bytes((r, g, b)) * (x1 - x0)
            for y in range(y0, y1):
                i = (y * self.w + x0) * 3
                self.buf[i:i + len(row)] = row
        else:
            for y in range(y0, y1):
                for x in range(x0, x1):
                    self.px(x, y, (r, g, b), alpha)

    def disc(self, cx, cy, radius, color, alpha=1.0):
        """Soft radial glow, cheap: alpha falls off squared."""
        if isinstance(color, str):
            color = hex_rgb(color)
        r2 = radius * radius
        for y in range(int(cy - radius), int(cy + radius) + 1):
            if y < 0 or y >= self.h:
                continue
            dy = y - cy
            for x in range(int(cx - radius), int(cx + radius) + 1):
                if x < 0 or x >= self.w:
                    continue
                dx = x - cx
                d2 = dx * dx + dy * dy
                if d2 > r2:
                    continue
                fall = 1.0 - (d2 / r2)
                self.px(x, y, color, alpha * fall * fall)

    def sprite(self, matrix, x, y, colormap, size=1, alpha=1.0, flip=False):
        """Draw a character matrix, one rectangle per set pixel."""
        if not matrix:
            return
        width = len(matrix[0])
        cache = {}
        for ry, row in enumerate(matrix):
            for rx, ch in enumerate(row):
                col = colormap.get(ch)
                if not col:
                    continue
                if col not in cache:
                    cache[col] = hex_rgb(col) if isinstance(col, str) else col
                cx = width - 1 - rx if flip else rx
                self.rect(x + cx * size, y + ry * size, size, size, cache[col], alpha)

    def outlined_sprite(self, matrix, x, y, colormap, outline, size=1,
                        alpha=1.0, flip=False, diagonal=False, outline_px=4):
        """Halo pass then body pass — what keeps the black cat readable.

        The sprite is stamped in a single flat colour at small offsets first
        (four-way for the cat, eight-way for the lamb's aura), then the real
        colours go on top. `outline_px` is in screen pixels, not sprite pixels:
        a rim is one or two screen pixels wide, and offsetting by a whole
        sprite pixel at wallpaper scale would swallow the sprite instead of
        outlining it.
        """
        offsets = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            offsets += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
        halo = {ch: outline for ch in {c for row in matrix for c in row if c != "."}}
        for dx, dy in offsets:
            self.sprite(matrix, x + dx * outline_px, y + dy * outline_px,
                        halo, size, alpha, flip)
        self.sprite(matrix, x, y, colormap, size, 1.0, flip)

    def wormhole(self, cx, cy, scale, rng):
        """Three concentric pixel rings, pink and cyan, around a dark core."""
        import math
        for ring in range(3):
            r = (5 + ring * 5) * scale
            n = int((6 + ring * 4) * max(1, scale / 2.0))
            spin = rng.random() * 6.28
            for k in range(n):
                a = spin + (k * math.pi * 2) / n
                col = "#ff2e8b" if (k + ring) % 2 else "#31e5ff"
                self.rect(cx + r * math.cos(a) - scale, cy + r * math.sin(a) - scale,
                          3 * scale, 3 * scale, col, 0.9 - ring * 0.2)
        self.rect(cx - 3 * scale, cy - 3 * scale, 6 * scale, 6 * scale, "#050508")

    def grid(self, cell, color, alpha, offset=(0, 0)):
        ox, oy = offset
        x = cell + ox
        while x <= self.w:
            self.rect(x, 0, 1, self.h, color, alpha)
            x += cell
        y = cell + oy
        while y <= self.h:
            self.rect(0, y, self.w, 1, color, alpha)
            y += cell

    def vignette(self, strength=0.45, color="#000000"):
        """Darken towards the edges so the sprites hold the centre of attention."""
        c = hex_rgb(color)
        cx, cy = self.w / 2, self.h / 2
        maxd = (cx * cx + cy * cy) ** 0.5
        step = 4  # coarse bands, then it is imperceptible at wallpaper scale
        for y in range(0, self.h, step):
            for x in range(0, self.w, step):
                d = (((x - cx) ** 2 + (y - cy) ** 2) ** 0.5) / maxd
                a = strength * max(0.0, d - 0.35) / 0.65
                if a <= 0.004:
                    continue
                self.rect(x, y, step, step, c, min(1.0, a))

    # --- output ------------------------------------------------------------
    def write_png(self, path):
        raw = bytearray()
        stride = self.w * 3
        for y in range(self.h):
            raw.append(0)  # filter type 0 (None)
            i = y * stride
            raw += self.buf[i:i + stride]

        def chunk(tag, data):
            out = struct.pack(">I", len(data)) + tag + data
            return out + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        ihdr = struct.pack(">IIBBBBB", self.w, self.h, 8, 2, 0, 0, 0)
        with open(path, "wb") as fh:
            fh.write(b"\x89PNG\r\n\x1a\n")
            fh.write(chunk(b"IHDR", ihdr))
            fh.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
            fh.write(chunk(b"IEND", b""))
