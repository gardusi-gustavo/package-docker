#!/usr/bin/env bash
# Inspect or remove embedded metadata from raster images.
set -euo pipefail

MODE="check"
ARGS=()
while (($#)); do
  case "$1" in
    --check) MODE="check"; shift ;;
    --strip) MODE="strip"; shift ;;
    -h|--help)
      cat <<'EOF'
usage: image-metadata.sh --check|--strip [paths...]

  --check   report embedded metadata and exit non-zero when found
  --strip   re-encode files that contain metadata, removing it

Defaults to the current directory. Only raster images are considered.
EOF
      exit 0
      ;;
    --) shift; ARGS+=("$@"); break ;;
    -*) echo "error: unknown argument: $1" >&2; exit 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
(( ${#ARGS[@]} )) || ARGS=(".")

python3 - "$MODE" "${ARGS[@]}" <<'PY'
import os
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageOps
except ImportError:
    print("error: Pillow is required (python3-pil)", file=sys.stderr)
    sys.exit(2)

MODE = sys.argv[1]
PATHS = sys.argv[2:] or ["."]
EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff"}
SKIP_DIRS = {".git", "node_modules", "dist", "build", ".venv", "venv"}
# Container defaults and color hints are not identifying metadata.
IGNORED = {"jfif", "jfif_version", "jfif_unit", "jfif_density", "dpi", "srgb"}


def iter_files(paths):
    for raw in paths:
        path = Path(raw)
        if path.is_file():
            if path.suffix.lower() in EXTENSIONS:
                yield path
            continue
        if not path.is_dir():
            print(f"error: not found: {path}", file=sys.stderr)
            continue
        for root, dirs, names in os.walk(path):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            for name in names:
                file = Path(root) / name
                if file.suffix.lower() in EXTENSIONS:
                    yield file


def metadata_keys(image):
    keys = {k for k in image.info if k not in IGNORED}
    try:
        if len(image.getexif()):
            keys.add("exif")
    except Exception:
        pass
    return sorted(keys)


def strip(path):
    image = Image.open(path)
    keys = metadata_keys(image)
    if not keys:
        print(f"clean {path}")
        return 0

    fmt = image.format
    image = ImageOps.exif_transpose(image)
    image.info.clear()
    if fmt == "JPEG":
        image = image.convert("RGB")
        suffix = ".jpg"
        save = {"format": "JPEG", "quality": 95, "optimize": True}
    elif fmt == "PNG":
        image = image.convert("RGBA" if "A" in image.getbands() else "RGB")
        suffix = ".png"
        save = {"format": "PNG", "optimize": True}
    else:
        print(f"error: unsupported format for --strip: {path} ({fmt})", file=sys.stderr)
        return 1

    mode = path.stat().st_mode
    fd, tmp = tempfile.mkstemp(prefix=".image-metadata-", suffix=suffix, dir=path.parent)
    os.close(fd)
    try:
        image.save(tmp, **save)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
    print(f"stripped {path}: {', '.join(keys)}")
    return 0


checked = 0
failed = 0
for file in iter_files(PATHS):
    checked += 1
    try:
        image = Image.open(file)
        keys = metadata_keys(image)
    except Exception as exc:
        print(f"error: {file}: {exc}", file=sys.stderr)
        failed += 1
        continue

    if MODE == "check":
        if keys:
            print(f"metadata {file}: {', '.join(keys)}")
            failed += 1
        continue
    try:
        failed += strip(file)
    except Exception as exc:
        print(f"error: {file}: {exc}", file=sys.stderr)
        failed += 1

if MODE == "check":
    print(f"checked {checked} images; {failed} with metadata")
else:
    print(f"checked {checked} images; {failed} failed")
sys.exit(1 if failed else 0)
PY
