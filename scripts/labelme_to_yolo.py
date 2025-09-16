"""
Convert LabelMe JSON annotations in data/interim/ to YOLO format and
perform a 90/10 train/val split automatically.

Usage:
  python scripts/labelme_to_yolo.py

Outputs:
  data/yolo/images/train, data/yolo/images/val
  data/yolo/labels/train, data/yolo/labels/val

Assumes a single class 'license-plate' (class id 0).
"""
import os, glob, json, random, math, shutil
from PIL import Image

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(REPO_ROOT, "data", "interim")
DST_IMG = os.path.join(REPO_ROOT, "data", "yolo", "images")
DST_LBL = os.path.join(REPO_ROOT, "data", "yolo", "labels")

os.makedirs(os.path.join(DST_IMG, "train"), exist_ok=True)
os.makedirs(os.path.join(DST_IMG, "val"), exist_ok=True)
os.makedirs(os.path.join(DST_LBL, "train"), exist_ok=True)
os.makedirs(os.path.join(DST_LBL, "val"), exist_ok=True)

# Collect labeled images (require matching .json)
imgs = sorted([p for p in glob.glob(os.path.join(SRC, "*")) if p.lower().endswith(('.jpg','.jpeg','.png'))])
pairs = []
for img in imgs:
    base = os.path.splitext(os.path.basename(img))[0]
    js = os.path.join(SRC, base + ".json")
    if os.path.exists(js):
        pairs.append((img, js))

if not pairs:
    print("No labeled images found in data/interim/.json. Nothing to do.")
    raise SystemExit(1)

random.seed(42)
random.shuffle(pairs)
val_n = max(1, math.floor(0.1 * len(pairs)))
val_set = set(pairs[:val_n])

def to_yolo_bbox(xmin, ymin, xmax, ymax, w, h):
    x_c = (xmin + xmax) / 2.0 / w
    y_c = (ymin + ymax) / 2.0 / h
    bw  = (xmax - xmin) / w
    bh  = (ymax - ymin) / h
    return x_c, y_c, bw, bh

def convert(img_path, json_path, split):
    base = os.path.splitext(os.path.basename(img_path))[0]
    with Image.open(img_path) as im:
        w, h = im.size
    with open(json_path, "r") as f:
        data = json.load(f)

    lines = []
    for shape in data.get("shapes", []):
        if shape.get("label", "license-plate") != "license-plate":
            continue
        st = shape.get("shape_type", "rectangle")
        pts = shape.get("points", [])
        if st == "rectangle" and len(pts) >= 2:
            (x1, y1), (x2, y2) = pts[:2]
            xmin, ymin = min(x1, x2), min(y1, y2)
            xmax, ymax = max(x1, x2), max(y1, y2)
        else:
            xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
            xmin, xmax, ymin, ymax = min(xs), max(xs), min(ys), max(ys)
        x_c, y_c, bw, bh = to_yolo_bbox(xmin, ymin, xmax, ymax, w, h)
        lines.append(f"0 {x_c:.6f} {y_c:.6f} {bw:.6f} {bh:.6f}")

    # Copy image
    dst_img = os.path.join(DST_IMG, split, os.path.basename(img_path))
    if not os.path.exists(dst_img):
        shutil.copy2(img_path, dst_img)
    # Write label
    with open(os.path.join(DST_LBL, split, base + ".txt"), "w") as f:
        f.write("\n".join(lines))

for img_path, js_path in pairs:
    split = "val" if (img_path, js_path) in val_set else "train"
    convert(img_path, js_path, split)

print(f"Done: converted {len(pairs)} labeled images → YOLO; split 90/10 into train/val.")
print("Check data/yolo/{images,labels}/{train,val}")