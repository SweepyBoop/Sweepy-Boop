#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workbench_scratch="$workbench/scratch"
python="$workbench_scratch/python/bin/python"
generator="$workbench/generate-samples.py"
manifest="$workbench/sample-manifest.json"
scratch="$workbench_scratch"
device="auto"
open_page=true
arguments=()

usage() {
  cat <<EOF
Usage: bash $0 [options]

Options:
  --key-abilities       Generate the Aiden/Sohee key-ability pack.
  --manifest PATH       Use a specific manifest.
  --scratch PATH        Use a specific output directory.
  --device DEVICE       auto, cuda, mps, or cpu (default: auto).
  --speaker ID          Generate one speaker.
  --phrase ID           Generate one phrase.
  --force               Regenerate selected WAV and OGG files.
  --remaster            Rebuild selected OGG files from existing WAVs.
  --no-open             Do not open the listening page.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key-abilities)
      manifest="$workbench/key-abilities-manifest.json"
      scratch="$workbench_scratch/key-abilities"
      shift
      ;;
    --manifest)
      manifest="${2:?--manifest requires a path}"
      shift 2
      ;;
    --scratch)
      scratch="${2:?--scratch requires a path}"
      shift 2
      ;;
    --device)
      device="${2:?--device requires auto, cuda, mps, or cpu}"
      shift 2
      ;;
    --speaker|--phrase)
      arguments+=("$1" "${2:?$1 requires a value}")
      shift 2
      ;;
    --force|--remaster)
      arguments+=("$1")
      shift
      ;;
    --no-open)
      open_page=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for required_path in "$python" "$generator" "$manifest"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Required workbench file is missing: $required_path" >&2
    exit 1
  fi
done

export PYTORCH_ENABLE_MPS_FALLBACK=1
base_arguments=(
  --manifest "$manifest"
  --scratch "$scratch"
  --model-cache "$workbench_scratch/models"
  --device "$device"
)
if [[ ${#arguments[@]} -gt 0 ]]; then
  "$python" "$generator" "${base_arguments[@]}" "${arguments[@]}"
else
  "$python" "$generator" "${base_arguments[@]}"
fi

listening_page="$scratch/listening/index.html"
if [[ ! -f "$listening_page" ]]; then
  echo "Listening page was not generated: $listening_page" >&2
  exit 1
fi

echo "Listening page: $listening_page"
if $open_page && command -v open >/dev/null 2>&1; then
  open "$listening_page"
fi
