#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workbench_scratch="$workbench/scratch"
python="$workbench_scratch/python/bin/python"
generator="$workbench/generate-faction-voices.py"
validator="$workbench/validate-faction-voices.py"
manifest="$workbench/faction-voice-manifest.json"
scratch="$workbench_scratch/faction-voices"
device="auto"
open_page=true
design_only=false
arguments=()

usage() {
  cat <<EOF
Usage: bash $0 [options]

Options:
  --device DEVICE       auto, cuda, mps, or cpu (default: auto).
  --speaker ID          Generate one voice.
  --phrase ID           Generate one phrase.
  --design-only         Create or reuse references without cloning callouts.
  --redesign            Replace selected references and regenerate their callouts.
  --force               Regenerate selected cloned WAV and OGG files.
  --remaster            Rebuild selected OGG files from existing WAVs.
  --no-open             Do not open the listening page.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      device="${2:?--device requires auto, cuda, mps, or cpu}"
      shift 2
      ;;
    --speaker|--phrase)
      arguments+=("$1" "${2:?$1 requires a value}")
      shift 2
      ;;
    --design-only)
      design_only=true
      arguments+=("$1")
      shift
      ;;
    --redesign|--force|--remaster)
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

for required_path in "$python" "$generator" "$validator" "$manifest"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Required workbench file is missing: $required_path" >&2
    exit 1
  fi
done

"$python" "$validator" --manifest "$manifest"
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

if $design_only; then
  exit 0
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
