#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scratch="$workbench/scratch"
python_dir="$scratch/cosyvoice3-python"
python="$python_dir/bin/python"
source_dir="$scratch/cosyvoice3-src"
reports="$scratch/cosyvoice3-zero-shot/reports"
model_dir="$scratch/cosyvoice3-models/fun-cosyvoice3-0.5b-29e01c4e8d00"
source_revision="074ca6dc9e80a2f424f1f74b48bdd7d3fea531cc"
model_revision="29e01c4e8d000f4bcd70751be16fa94bf3d85a18"
uv_version="0.12.21"
python_version="3.10.19"
python_bootstrap="${PYTHON_BIN:-}"

if [[ "${1:-}" == "--recreate" ]]; then
  rm -rf -- "$python_dir"
elif [[ $# -gt 0 ]]; then
  echo "Usage: bash $0 [--recreate]" >&2
  exit 2
fi

mkdir -p "$scratch" "$reports" "$scratch/pip-cache" "$scratch/cosyvoice3-models"
if [[ -z "$python_bootstrap" ]]; then
  if command -v python3.10 >/dev/null 2>&1; then
    python_bootstrap="$(command -v python3.10)"
  else
    uv_bootstrap="$scratch/cosyvoice3-uv-bootstrap"
    uv="$uv_bootstrap/bin/uv"
    if [[ ! -x "$uv" ]]; then
      python3 -m venv "$uv_bootstrap"
      "$uv_bootstrap/bin/python" -m pip install "uv==$uv_version"
    fi
    export UV_PYTHON_INSTALL_DIR="$scratch/cosyvoice3-python-install"
    "$uv" python install "$python_version"
    python_bootstrap="$("$uv" python find "$python_version")"
  fi
fi
export PIP_CACHE_DIR="$scratch/pip-cache"
export HF_HOME="$scratch/cosyvoice3-models"
export HF_HUB_CACHE="$scratch/cosyvoice3-models/hub"
export MODELSCOPE_CACHE="$scratch/cosyvoice3-modelscope"

if [[ ! -d "$source_dir/.git" ]]; then
  git clone --filter=blob:none --recurse-submodules https://github.com/QwenAudio/CosyVoice.git "$source_dir"
fi
git -C "$source_dir" fetch origin "$source_revision"
git -C "$source_dir" checkout --detach "$source_revision"
git -C "$source_dir" submodule update --init --recursive
actual_revision="$(git -C "$source_dir" rev-parse HEAD)"
if [[ "$actual_revision" != "$source_revision" ]]; then
  echo "Unexpected CosyVoice source revision: $actual_revision" >&2
  exit 1
fi

if [[ ! -x "$python" ]]; then
  "$python_bootstrap" -m venv "$python_dir"
fi
"$python" -m pip install --upgrade pip 'setuptools<81' wheel
inference_requirements="$scratch/cosyvoice3-requirements-macos.txt"
grep -Ev \
  '^(--extra-index-url|deepspeed|grpcio|grpcio-tools|onnxruntime-gpu|openai-whisper|pyworld|tensorrt)' \
  "$source_dir/requirements.txt" > "$inference_requirements"
"$python" -m pip install -r "$inference_requirements"
"$python" -m pip install 'Cython==0.29.37'
"$python" -m pip install --no-build-isolation 'pyworld==0.3.4'
"$python" -m pip install \
  'lightning==2.2.4' \
  'rich==13.7.1' \
  'openai-whisper==20250625' \
  'imageio-ffmpeg==0.6.0' \
  'huggingface-hub==0.36.2'

MODEL_DIR="$model_dir" MODEL_REVISION="$model_revision" "$python" - <<'PY'
import os
from pathlib import Path
from huggingface_hub import snapshot_download

target = Path(os.environ["MODEL_DIR"])
snapshot_download(
    repo_id="FunAudioLLM/Fun-CosyVoice3-0.5B-2512",
    revision=os.environ["MODEL_REVISION"],
    local_dir=target,
)
required = (
    "config.json",
    "configuration.json",
    "cosyvoice3.yaml",
    "llm.pt",
    "flow.pt",
    "hift.pt",
    "speech_tokenizer_v3.onnx",
)
missing = [name for name in required if not (target / name).is_file()]
if missing:
    raise RuntimeError(f"Incomplete CosyVoice model snapshot: {', '.join(missing)}")
print(f"CosyVoice model snapshot: {target}")
PY

PYTHONPATH="$source_dir:$source_dir/third_party/Matcha-TTS" "$python" - <<'PY'
from cosyvoice.cli.cosyvoice import AutoModel
print(f"CosyVoice AutoModel import: {AutoModel.__module__}.{AutoModel.__name__}")
PY

"$python" -m pip freeze > "$reports/pip-freeze.txt"
cat > "$reports/setup.json" <<JSON
{
  "sourceRepository": "https://github.com/QwenAudio/CosyVoice.git",
  "sourceRevision": "$source_revision",
  "modelRepository": "FunAudioLLM/Fun-CosyVoice3-0.5B-2512",
  "modelRevision": "$model_revision",
  "executionDevice": "cpu",
  "loadJit": false,
  "loadTrt": false,
  "loadVllm": false,
  "fp16": false
}
JSON

if command -v sox >/dev/null 2>&1; then
  sox --version
else
  echo "Note: no system SoX binary was found; inference verification will determine whether it is required." >&2
fi

echo "CosyVoice environment: $python"
echo "CosyVoice source: $source_dir@$actual_revision"
echo "CosyVoice model: $model_dir"
