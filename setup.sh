#!/usr/bin/env bash
set -euo pipefail

# Jump to repo root even if invoked from a subfolder
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
echo "Repo: $REPO_ROOT"

# Ensure submodule present
if [ ! -f "yolov5/requirements.txt" ]; then
  echo "Initializing yolov5 submodule…"
  git submodule update --init --recursive
fi

# (Re)create parent venv
if [ -d ".venv" ]; then
  echo "Found existing .venv (using it)."
else
  echo "Creating .venv…"
  python3 -m venv .venv
fi

# Activate venv
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip wheel

# Install YOLOv5 deps
echo "Installing YOLOv5 requirements…"
pip install -r yolov5/requirements.txt

# Install extras (working on Python 3.13)
echo "Installing extras (labelme, imagededup)…"
pip install labelme==5.5.0 imagededup

# Create project folders
echo "Creating data/scripts/configs/results folders…"
mkdir -p data/{raw,interim,yolo/images/{train,val},yolo/labels/{train,val}} scripts configs results

# Add .gitignore entries if not present
if ! grep -q "^\.venv/$" .gitignore 2>/dev/null; then
  {
    echo ".venv/"
    echo "data/**"
    echo "results/**"
    echo "runs/**"
    echo "*.pt"
    echo "*.mp4"
    echo "*.avi"
    echo "*.mov"
    echo "*.jpg"
    echo "*.png"
    echo "yolov5/.venv/"
  } >> .gitignore
  echo "Updated .gitignore"
fi

echo
echo "✅ Setup complete."
echo "Next steps:"
echo "  source .venv/bin/activate"
echo
echo "Quick YOLOv5 test:"
echo "  cd yolov5 && python detect.py --weights yolov5s.pt --source data/images/bus.jpg"
echo
echo "Annotation with labelme:"
echo "  labelme data/interim --labels license-plate"