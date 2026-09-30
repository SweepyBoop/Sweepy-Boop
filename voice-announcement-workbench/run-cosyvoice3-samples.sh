#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workbench_scratch="$workbench/scratch"
scratch="$workbench_scratch/cosyvoice3-zero-shot"
python="$workbench/scratch/cosyvoice3-python/bin/python"
generator="$workbench/generate-cosyvoice3-samples.py"
validator="$workbench/validate-cosyvoice3-samples.py"
manifest="$workbench/cosyvoice3-sample-manifest.json"
source_dir="$workbench/scratch/cosyvoice3-src"
model_dir="$workbench/scratch/cosyvoice3-models/fun-cosyvoice3-0.5b-29e01c4e8d00"
open_page=true
full_pack=false
arguments=()

usage() {
  cat <<EOF
Usage: bash $0 [options]

Options:
  --full                Generate the full Instruct2 Take 1 catalog.
  --speaker ID          Generate one source voice.
  --phrase ID           Generate one phrase.
  --mode MODE           cross-lingual or instruct2.
  --take NUMBER         Generate one take (1 or 2).
  --force               Regenerate selected raw and mastered files.
  --remaster            Rebuild selected OGG files from existing WAVs.
  --verify-only         Verify the isolated environment without loading the model.
  --no-open             Do not open the listening page.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)
      full_pack=true
      shift
      ;;
    --speaker|--phrase|--mode|--take)
      arguments+=("$1" "${2:?$1 requires a value}")
      shift 2
      ;;
    --force|--remaster|--verify-only)
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

if $full_pack; then
  manifest="$workbench/cosyvoice3-pack-manifest.json"
  scratch="$workbench_scratch/cosyvoice3-instruct2"
fi

for required_path in "$python" "$generator" "$validator" "$manifest"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Required CosyVoice workbench file is missing: $required_path" >&2
    exit 1
  fi
done
if [[ ! -d "$source_dir" || ! -d "$model_dir" ]]; then
  echo "Run setup-cosyvoice3-environment.sh first." >&2
  exit 1
fi

"$python" "$validator" --manifest "$manifest"

base_arguments=(
  --manifest "$manifest"
  --scratch "$scratch"
  --source "$source_dir"
  --model "$model_dir"
)
if [[ ${#arguments[@]} -gt 0 ]]; then
  "$python" "$generator" "${base_arguments[@]}" "${arguments[@]}"
else
  "$python" "$generator" "${base_arguments[@]}"
fi

if [[ " ${arguments[*]-} " == *" --verify-only "* ]]; then
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
