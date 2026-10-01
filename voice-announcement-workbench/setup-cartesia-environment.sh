#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python_dir="$workbench/scratch/cartesia-python"
python="$python_dir/bin/python"
python_bootstrap="${PYTHON_BIN:-python3}"
reports="$workbench/scratch/cartesia-bakeoff/reports"

if [[ "${1:-}" == "--recreate" ]]; then
  rm -rf -- "$python_dir"
elif [[ $# -gt 0 ]]; then
  echo "Usage: bash $0 [--recreate]" >&2
  exit 2
fi

mkdir -p "$workbench/scratch/pip-cache" "$reports"
export PIP_CACHE_DIR="$workbench/scratch/pip-cache"
if [[ ! -x "$python" ]]; then
  "$python_bootstrap" -m venv "$python_dir"
fi
"$python" -m pip install --upgrade pip
"$python" -m pip install \
  'cartesia==4.2.0' \
  'certifi==2026.7.22' \
  'numpy==1.26.4' \
  'soundfile==0.13.1' \
  'imageio-ffmpeg==0.6.0'
"$python" -m pip freeze > "$reports/pip-freeze.txt"
"$python" - <<'PY'
import imageio_ffmpeg
import numpy
import soundfile
print(f"numpy={numpy.__version__}")
print(f"soundfile={soundfile.__version__}")
print(f"ffmpeg={imageio_ffmpeg.get_ffmpeg_exe()}")
PY

echo "Cartesia environment: $python"
