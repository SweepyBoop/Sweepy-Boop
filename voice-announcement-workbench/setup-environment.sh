#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scratch="$workbench/scratch"
python_dir="$scratch/python"
python="$python_dir/bin/python"
reports="$scratch/reports"
recreate=false

if [[ "${1:-}" == "--recreate" ]]; then
  recreate=true
elif [[ $# -gt 0 ]]; then
  echo "Usage: bash $0 [--recreate]" >&2
  exit 2
fi

python_bootstrap="${PYTHON_BIN:-python3.10}"
if ! command -v "$python_bootstrap" >/dev/null 2>&1; then
  echo "Python 3.10 is required. On macOS, install it with: brew install python@3.10" >&2
  exit 1
fi

if $recreate && [[ -d "$python_dir" ]]; then
  rm -rf -- "$python_dir"
fi

mkdir -p "$scratch" "$reports" "$scratch/pip-cache"
export PIP_CACHE_DIR="$scratch/pip-cache"
export PYTORCH_ENABLE_MPS_FALLBACK=1

if [[ ! -x "$python" ]]; then
  "$python_bootstrap" -m venv "$python_dir"
fi

"$python" -m pip install --upgrade pip
"$python" -m pip install --upgrade \
  'torch==2.9.1' \
  'torchaudio==2.9.1'
"$python" -m pip install --upgrade \
  'qwen-tts==0.1.1' \
  'imageio-ffmpeg==0.6.0' \
  'hf-xet==1.6.0'

"$python" -m pip freeze > "$reports/pip-freeze.txt"
"$python" "$workbench/generate-samples.py" --device auto --verify-only

echo "Voice generation environment is ready: $python"
