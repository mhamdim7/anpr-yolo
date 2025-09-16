#!/usr/bin/env bash
set -euo pipefail

# cleanup.sh — safely reset generated artifacts so you can retry.
# Preserves raw videos under data/raw/*
#
# Usage:
#   bash cleanup.sh            # interactive confirm
#   bash cleanup.sh --yes      # no prompt
#   bash cleanup.sh --dry-run  # show what would be removed
#
# What it removes:
#   - data/interim/*                     (extracted frames + labelme jsons)
#   - data/yolo/images/{train,val}/*     (YOLO images)
#   - data/yolo/labels/{train,val}/*     (YOLO labels)
#   - results/*                          (training outputs from wrapper repo)
#   - yolov5/runs/*                      (YOLOv5 runs/ outputs)

set +e
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
set -e
if [ -n "${REPO_ROOT:-}" ] && [ -d "$REPO_ROOT" ]; then
  cd "$REPO_ROOT"
else
  echo "⚠️  Not in a git repo, using current directory: $(pwd)"
fi

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    *) echo "Unknown option: $arg" ; exit 1 ;;
  esac
done

# Targets (relative to repo root)
TARGETS=(
  "data/interim/*"
  "data/yolo/images/train/*"
  "data/yolo/images/val/*"
  "data/yolo/labels/train/*"
  "data/yolo/labels/val/*"
  "results/*"
  "yolov5/runs/*"
)

echo "Cleanup will remove the following (raw videos are preserved):"
for t in "${TARGETS[@]}"; do
  echo "  - $t"
done

if [ "$DRY_RUN" -eq 1 ]; then
  echo "---- DRY RUN: listing existing matches ----"
  shopt -s nullglob
  for t in "${TARGETS[@]}"; do
    echo "# $t"
    for f in $t; do
      [ -e "$f" ] && echo "$f"
    done
  done
  exit 0
fi

if [ "$ASSUME_YES" -ne 1 ]; then
  read -r -p "Proceed with deletion? (y/N) " ans
  case "${ans:-N}" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

echo "Removing files..."
shopt -s nullglob
for t in "${TARGETS[@]}"; do
  for f in $t; do
    rm -rf "$f"
  done
done

echo "✅ Cleanup complete."
echo "Raw videos under data/raw/ are intact."
