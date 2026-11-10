"""Writes tiles/tileset.tres and scenes/level_1_1.tscn for the Godot project.

The layout follows the block/pipe/pit/staircase layout of World 1-1 from the NES
original (tile units, 16 px per tile, ground surface at row 13).
"""
import base64
import os
import struct
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
TILE = 16
LEVEL_W = 212          # tiles
GROUND_ROW = 13        # first row of ground

# atlas coords in assets/tiles.png
GROUND_TOP, GROUND, BRICK, QUESTION, USED, HARD = (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0)
PIPE_TL, PIPE_TR, PIPE_BL, PIPE_BR, INVISIBLE = (6, 0), (7, 0), (8, 0), (9, 0), (10, 0)
ATLAS_TILES = 11

cells = {}


def put(x, y, t):
    cells[(x, y)] = t


# --- ground with the three pits --------------------------------------------
PITS = [(69, 70), (86, 88), (153, 154)]
for x in range(LEVEL_W):
    if any(a <= x <= b for a, b in PITS):
        continue
    put(x, GROUND_ROW, GROUND_TOP)
    put(x, GROUND_ROW + 1, GROUND)

# --- blocks ------------------------------------------------------------------
BRICKS = [(20, 9), (22, 9), (24, 9), (77, 9), (79, 9)] + [(x, 5) for x in range(80, 88)] \
    + [(x, 5) for x in range(91, 94)] + [(94, 9), (100, 9), (101, 9), (118, 9)] \
    + [(x, 5) for x in range(121, 124)] + [(128, 5), (131, 5), (129, 9), (130, 9)] \
    + [(168, 9), (169, 9), (171, 9)]
QUESTIONS = [(16, 9), (21, 9), (23, 9), (22, 5), (78, 9), (94, 5), (106, 9), (109, 9),
             (112, 9), (109, 5), (129, 5), (130, 5), (170, 9)]
for c in BRICKS:
    put(*c, BRICK)
for c in QUESTIONS:
    put(*c, QUESTION)

# --- pipes (x, height in tiles) ---------------------------------------------
for px, h in [(28, 2), (38, 3), (46, 4), (57, 4), (163, 2), (179, 2)]:
    top = GROUND_ROW - h
    put(px, top, PIPE_TL)
    put(px + 1, top, PIPE_TR)
    for y in range(top + 1, GROUND_ROW):
        put(px, y, PIPE_BL)
        put(px + 1, y, PIPE_BR)


# --- staircases --------------------------------------------------------------
def column(x, h):
    for y in range(GROUND_ROW - h, GROUND_ROW):
        put(x, y, HARD)


for i in range(4):
    column(134 + i, i + 1)      # up
    column(140 + i, 4 - i)      # down
for i in range(4):
    column(148 + i, i + 1)
column(152, 4)
for i in range(4):
    column(155 + i, 4 - i)
for i in range(8):
    column(181 + i, i + 1)
column(189, 8)
put(198, GROUND_ROW - 1, HARD)  # antenna base

# --- encode TileMapLayer.tile_map_data (format 0: header u16 + 12 bytes/cell)
data = bytearray(struct.pack("<H", 0))
for (x, y), (ax, ay) in sorted(cells.items()):
    data += struct.pack("<hhHHHH", x, y, 0, ax, ay, 0)
tile_map_data = base64.b64encode(bytes(data)).decode()

# --- TileSet resource --------------------------------------------------------
os.makedirs(os.path.join(ROOT, "tiles"), exist_ok=True)
ts = ['[gd_resource type="TileSet" format=3]', "",
      '[ext_resource type="Texture2D" path="res://assets/tiles.png" id="1_tiles"]', "",
      '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_main"]',
      'texture = ExtResource("1_tiles")',
      "texture_region_size = Vector2i(16, 16)"]
for i in range(ATLAS_TILES):
    ts.append(f"{i}:0/0 = 0")
    ts.append(f"{i}:0/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, 8, -8, 8, 8, -8, 8)")
ts += ["", "[resource]", "tile_size = Vector2i(16, 16)",
       "physics_layer_0/collision_layer = 1", "physics_layer_0/collision_mask = 0",
       'sources/0 = SubResource("TileSetAtlasSource_main")', ""]
with open(os.path.join(ROOT, "tiles", "tileset.tres"), "w") as f:
    f.write("\n".join(ts))

# --- level scene -------------------------------------------------------------
ext = []


def res(kind, path):
    rid = f"{len(ext) + 1}_{os.path.splitext(os.path.basename(path))[0]}"
    ext.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
    return f'ExtResource("{rid}")'


R = {
    "script": res("Script", "res://scripts/level.gd"),
    "cam": res("Script", "res://scripts/level_camera.gd"),
    "tileset": res("TileSet", "res://tiles/tileset.tres"),
    "player": res("PackedScene", "res://scenes/player.tscn"),
    "rustbug": res("PackedScene", "res://scenes/rustbug.tscn"),
    "shellbot": res("PackedScene", "res://scenes/shellbot.tscn"),
    "flagpole": res("PackedScene", "res://scenes/flagpole.tscn"),
    "hud": res("PackedScene", "res://scenes/hud.tscn"),
    "outpost": res("Texture2D", "res://assets/outpost.png"),
    "hill_big": res("Texture2D", "res://assets/hill_big.png"),
    "hill_small": res("Texture2D", "res://assets/hill_small.png"),
}
for n in (1, 2, 3):
    R[f"cloud_{n}"] = res("Texture2D", f"res://assets/cloud_{n}.png")
    R[f"bush_{n}"] = res("Texture2D", f"res://assets/bush_{n}.png")

nodes = []


def node(name, typ, parent, props=None, instance=None):
    head = f'[node name="{name}"'
    if typ:
        head += f' type="{typ}"'
    if parent is not None:
        head += f' parent="{parent}"'
    if instance:
        head += f" instance={instance}"
    head += "]"
    nodes.append(head)
    for k, v in (props or {}).items():
        nodes.append(f"{k} = {v}")
    nodes.append("")


def vec(x, y):
    return f"Vector2({x:g}, {y:g})"


GY = GROUND_ROW * TILE  # 208, y of the ground surface

node("Level", "Node2D", None, {"script": R["script"]})

# background scenery repeats every 48 tiles, like the original
node("Background", "Node2D", ".", {"z_index": -10})
PATTERN = [  # (texture, tile x, bottom y in px)
    ("hill_big", 0, GY), ("cloud_1", 8, 56), ("bush_3", 11, GY), ("hill_small", 16, GY),
    ("cloud_1", 19, 40), ("bush_1", 23, GY), ("cloud_3", 27, 56), ("cloud_2", 36, 40),
    ("bush_2", 41, GY),
]
count = 0
for base in range(0, LEVEL_W, 48):
    for tex, tx, bottom in PATTERN:
        x = base + tx
        if x >= 196:          # keep the end area clear for the antenna and outpost
            continue
        h = {"hill_big": 36, "hill_small": 20, "bush_1": 16, "bush_2": 16, "bush_3": 16,
             "cloud_1": 24, "cloud_2": 24, "cloud_3": 24}[tex]
        count += 1
        node(f"{tex.title().replace('_', '')}{count}", "Sprite2D", "Background",
             {"position": vec(x * TILE, bottom - h), "texture": R[tex], "centered": "false"})

node("Outpost", "Sprite2D", ".", {"z_index": -5, "position": vec(202 * TILE, GY - 80),
                                  "texture": R["outpost"], "centered": "false"})

node("Tiles", "TileMapLayer", ".", {"tile_map_data": f'PackedByteArray("{tile_map_data}")',
                                     "tile_set": R["tileset"]})

node("Flagpole", None, ".", {"position": vec(198 * TILE + 8, GY - TILE)}, instance=R["flagpole"])

node("Items", "Node2D", ".")

# enemies: (kind, tile x, row of the surface they stand on)
ENEMIES = [("rustbug", 22, 13), ("rustbug", 40, 13), ("rustbug", 51, 13), ("rustbug", 52.5, 13),
           ("rustbug", 80, 5), ("rustbug", 82, 5), ("rustbug", 97, 13), ("rustbug", 98.5, 13),
           ("shellbot", 107, 13), ("rustbug", 114, 13), ("rustbug", 115.5, 13),
           ("rustbug", 124, 13), ("rustbug", 125.5, 13), ("rustbug", 128, 13),
           ("rustbug", 129.5, 13), ("rustbug", 174, 13), ("rustbug", 175.5, 13)]
node("Enemies", "Node2D", ".")
for i, (kind, tx, row) in enumerate(ENEMIES, 1):
    node(f"{kind.title()}{i}", None, "Enemies",
         {"position": vec(tx * TILE + 8, row * TILE)}, instance=R[kind])

node("Player", None, ".", {"position": vec(3 * TILE, GY)}, instance=R["player"])
node("Camera", "Camera2D", ".", {"position": vec(128, 120), "process_callback": 0,
                                 "script": R["cam"], "target_path": 'NodePath("../Player")',
                                 "level_width": float(LEVEL_W * TILE)})
node("HUD", None, ".", instance=R["hud"])

os.makedirs(os.path.join(ROOT, "scenes"), exist_ok=True)
with open(os.path.join(ROOT, "scenes", "level_1_1.tscn"), "w") as f:
    f.write("[gd_scene format=3]\n\n" + "\n".join(ext) + "\n\n" + "\n".join(nodes))

# --- preview image of the layout (for checking against the original) --------
try:
    from PIL import Image
    tiles_img = Image.open(os.path.join(ROOT, "assets", "tiles.png"))
    prev = Image.new("RGBA", (LEVEL_W * TILE, 15 * TILE), (107, 168, 220, 255))
    for (x, y), (ax, ay) in cells.items():
        prev.alpha_composite(tiles_img.crop((ax * 16, ay * 16, ax * 16 + 16, ay * 16 + 16)), (x * 16, y * 16))
    prev.save("/tmp/level_preview.png")
except Exception as e:  # preview is optional
    print("preview skipped:", e)
print(f"{len(cells)} tiles written")
