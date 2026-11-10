"""Generates every PNG for the project in a flat, beginner-friendly style:
plain colored shapes, one outline color, no shading."""
import os
import sys
from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets"
os.makedirs(OUT, exist_ok=True)

LINE = (30, 30, 40, 255)
WHITE = (255, 255, 255, 255)
BLUE = (70, 130, 220, 255)
RED = (230, 60, 60, 255)
ORANGE = (220, 110, 40, 255)
GREEN = (60, 170, 80, 255)
LIGHT_GREEN = (110, 200, 110, 255)
YELLOW = (250, 200, 50, 255)
BROWN = (150, 90, 50, 255)
GRAY = (150, 150, 160, 255)
PINK = (240, 100, 160, 255)


def save(img, name):
    img.save(os.path.join(OUT, name))


def new(w, h):
    img = Image.new("RGBA", (w, h))
    return img, ImageDraw.Draw(img)


# ------------------------------------------------------------------ Bolt ---
# Frames: 0 idle, 1 walk A, 2 walk B, 3 jump, 4 dead
LEGS = [(4, 9), (3, 10), (5, 8), (2, 11), (4, 9)]


def bolt_sheet(h):
    sheet = Image.new("RGBA", (16 * 5, h))
    for f, (l1, l2) in enumerate(LEGS):
        img, d = new(16, h)
        d.line([8, 0, 8, 3], fill=LINE)                      # antenna
        d.rectangle([7, 0, 8, 1], fill=RED)
        d.rectangle([3, 3, 12, h - 3], fill=BLUE, outline=LINE)  # body
        d.rectangle([8, 5, 11, 8], fill=WHITE)                  # eye
        if f == 4:
            d.line([8, 5, 11, 8], fill=LINE)
            d.line([8, 8, 11, 5], fill=LINE)
        else:
            d.rectangle([10, 6, 10, 7], fill=LINE)
        d.rectangle([l1, h - 2, l1 + 2, h - 1], fill=LINE)     # feet
        d.rectangle([l2, h - 2, l2 + 2, h - 1], fill=LINE)
        sheet.paste(img, (f * 16, 0))
    return sheet


save(bolt_sheet(16), "player_small.png")
save(bolt_sheet(32), "player_big.png")

# --------------------------------------------------------------- Rustbug ---
# Frames: 0 walk A, 1 walk B, 2 squashed
sheet = Image.new("RGBA", (48, 16))
for f in range(3):
    img, d = new(16, 16)
    if f < 2:
        d.pieslice([1, 3, 14, 26], 180, 360, fill=ORANGE, outline=LINE)
        d.rectangle([4, 8, 5, 10], fill=WHITE)
        d.rectangle([10, 8, 11, 10], fill=WHITE)
        feet = (3, 10) if f == 0 else (5, 8)
        for x in feet:
            d.rectangle([x, 14, x + 2, 15], fill=LINE)
    else:
        d.ellipse([1, 11, 14, 15], fill=ORANGE, outline=LINE)
    sheet.paste(img, (f * 16, 0))
save(sheet, "rustbug.png")

# -------------------------------------------------------------- Shellbot ---
# Frames: 0 walk A, 1 walk B, 2 hiding in shell
sheet = Image.new("RGBA", (48, 24))
for f in range(3):
    img, d = new(16, 24)
    if f < 2:
        d.ellipse([0, 9, 6, 15], fill=GRAY, outline=LINE)      # head
        d.rectangle([2, 11, 2, 12], fill=LINE)                 # eye
        d.pieslice([3, 12, 15, 32], 180, 360, fill=GREEN, outline=LINE)
        feet = (4, 11) if f == 0 else (6, 9)
        for x in feet:
            d.rectangle([x, 22, x + 2, 23], fill=LINE)
    else:
        d.pieslice([2, 14, 14, 33], 180, 360, fill=GREEN, outline=LINE)
    sheet.paste(img, (f * 16, 0))
save(sheet, "shellbot.png")

# ----------------------------------------------------------------- items ---
# Frames: 0 gear, 1 battery, 2 spare chip (heart), 3 power bolt, 4 gear (spin)
items, d = new(80, 16)
d.ellipse([3, 2, 12, 13], fill=YELLOW, outline=LINE)
d.rectangle([7, 7, 8, 8], fill=LINE)
d.rectangle([16 + 6, 1, 16 + 9, 2], fill=LINE)
d.rectangle([16 + 4, 3, 16 + 11, 15], fill=GREEN, outline=LINE)
d.ellipse([32 + 2, 3, 32 + 8, 9], fill=PINK)
d.ellipse([32 + 7, 3, 32 + 13, 9], fill=PINK)
d.polygon([(32 + 2, 7), (32 + 13, 7), (32 + 7, 14)], fill=PINK)
d.polygon([(48 + 9, 0), (48 + 3, 9), (48 + 7, 9), (48 + 5, 15), (48 + 12, 5), (48 + 8, 5), (48 + 11, 0)],
          fill=YELLOW, outline=LINE)
d.ellipse([64 + 6, 2, 64 + 9, 13], fill=YELLOW, outline=LINE)
save(items, "items.png")

# ----------------------------------------------------------------- tiles ---
# 0 ground top, 1 ground, 2 brick, 3 ? block, 4 used block, 5 stair block,
# 6-9 pipe (top-left, top-right, body-left, body-right), 10 invisible
tiles, d = new(16 * 11, 16)


def box(i):
    return [i * 16, 0, i * 16 + 15, 15]


d.rectangle(box(0), fill=BROWN, outline=LINE)
d.rectangle([0, 0, 15, 3], fill=GREEN, outline=LINE)
d.rectangle(box(1), fill=BROWN, outline=LINE)
d.rectangle(box(2), fill=ORANGE, outline=LINE)
d.line([32, 7, 47, 7], fill=LINE)
d.line([40, 0, 40, 7], fill=LINE)
d.line([36, 8, 36, 15], fill=LINE)
d.line([44, 8, 44, 15], fill=LINE)
d.rectangle(box(3), fill=YELLOW, outline=LINE)
for x, y in [(6, 4), (7, 3), (8, 3), (9, 4), (9, 5), (8, 6), (7, 7), (7, 8), (7, 11)]:
    d.point((48 + x, y), fill=LINE)
d.rectangle(box(4), fill=BROWN, outline=LINE)
d.rectangle(box(5), fill=GRAY, outline=LINE)
d.rectangle([96, 0, 111, 15], fill=GREEN, outline=LINE)   # pipe top left
d.line([111, 1, 111, 14], fill=GREEN)
d.rectangle([112, 0, 127, 15], fill=GREEN, outline=LINE)  # pipe top right
d.line([112, 1, 112, 14], fill=GREEN)
d.rectangle([130, 0, 143, 15], fill=GREEN)                # pipe body left
d.line([130, 0, 130, 15], fill=LINE)
d.rectangle([144, 0, 157, 15], fill=GREEN)                # pipe body right
d.line([157, 0, 157, 15], fill=LINE)
save(tiles, "tiles.png")

# ------------------------------------------------------------ background ---
img, d = new(80, 36)
d.pieslice([0, 0, 79, 71], 180, 360, fill=GREEN)
save(img, "hill_big.png")
img, d = new(48, 20)
d.pieslice([0, 0, 47, 39], 180, 360, fill=GREEN)
save(img, "hill_small.png")
for n in (1, 2, 3):
    w = 16 * (n + 1)
    img, d = new(w, 16)
    for i in range(n + 1):
        d.pieslice([i * 16 - 1, 2, i * 16 + 16, 30], 180, 360, fill=LIGHT_GREEN)
    save(img, f"bush_{n}.png")
    img, d = new(w, 24)
    for i in range(n + 1):
        d.ellipse([i * 16, 4, i * 16 + 15, 19], fill=WHITE)
    save(img, f"cloud_{n}.png")

# outpost (end fortress) 80x80
img, d = new(80, 80)
d.rectangle([0, 40, 79, 79], fill=BROWN, outline=LINE)
d.rectangle([20, 10, 59, 40], fill=BROWN, outline=LINE)
d.rectangle([32, 56, 47, 79], fill=LINE)
d.rectangle([36, 20, 43, 28], fill=LINE)
save(img, "outpost.png")

# goal antenna 16x160 and its flag
img, d = new(16, 160)
d.rectangle([7, 8, 8, 159], fill=GRAY)
d.ellipse([4, 1, 11, 8], fill=RED, outline=LINE)
save(img, "antenna.png")
img, d = new(16, 16)
d.polygon([(15, 2), (15, 13), (1, 8)], fill=YELLOW, outline=LINE)
save(img, "flag.png")

# ------------------------------------------------------- story screen art ---
# lighthouse 32x96: frame 0 dark, frame 1 lit
sheet = Image.new("RGBA", (64, 96))
for f in range(2):
    img, d = new(32, 96)
    d.rectangle([10, 24, 21, 95], fill=WHITE, outline=LINE)
    d.rectangle([10, 50, 21, 60], fill=RED, outline=LINE)
    d.rectangle([10, 80, 21, 90], fill=RED, outline=LINE)
    d.rectangle([9, 10, 22, 23], fill=YELLOW if f else GRAY, outline=LINE)
    d.polygon([(7, 10), (24, 10), (15, 1)], fill=RED, outline=LINE)
    sheet.paste(img, (f * 32, 0))
save(sheet, "lighthouse.png")

img, d = new(32, 32)
d.rectangle([4, 14, 27, 31], fill=GRAY, outline=LINE)
d.polygon([(1, 15), (30, 15), (16, 3)], fill=BLUE, outline=LINE)
d.rectangle([18, 22, 23, 31], fill=BROWN, outline=LINE)
save(img, "house.png")

# the Rust Baron 32x32
img, d = new(32, 32)
d.rectangle([4, 4, 27, 29], fill=ORANGE, outline=LINE)
d.rectangle([8, 10, 12, 13], fill=RED)
d.rectangle([19, 10, 23, 13], fill=RED)
d.line([10, 20, 21, 20], fill=LINE)
d.rectangle([7, 30, 11, 31], fill=LINE)
d.rectangle([20, 30, 24, 31], fill=LINE)
save(img, "baron.png")

img, d = new(16, 16)
d.ellipse([2, 2, 13, 13], fill=YELLOW, outline=LINE)
save(img, "sun_core.png")

# window icon
icon = Image.open(os.path.join(OUT, "player_small.png")).crop((0, 0, 16, 16)).resize((64, 64), Image.NEAREST)
bg = Image.new("RGBA", (64, 64), (107, 168, 220, 255))
bg.alpha_composite(icon)
bg.save(os.path.join(OUT, "..", "icon.png"))
print("art written to", OUT)
