#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python="$workbench/scratch/cartesia-python/bin/python"
manifest="$workbench/cartesia-sample-manifest.json"
generator="$workbench/generate-cartesia-samples.py"
validator="$workbench/validate-cartesia-samples.py"
scratch="$workbench/scratch/cartesia-bakeoff"
open_page=true
full_pack=false
arguments=()

usage() {
  cat <<EOF
Usage: bash $0 [options]

Options:
  --full                Generate the full approved Archie/Gemma catalog.
  --discover-only       Fetch and sanitize the Cartesia voice catalog only.
  --shortlist-only      Fetch/filter voices without generating speech.
  --speaker VALUE       masculine, feminine, voice-a, or voice-b.
  --phrase ID           Generate one phrase.
  --phrases-file PATH   Generate listed full-pack phrase IDs; implies --full.
  --force               Refresh catalog/selection and regenerate selected audio.
  --remaster            Rebuild OGG files from cached provider WAVs.
  --verify-only         Check manifest and credential without network access.
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
    --phrases-file)
      full_pack=true
      arguments+=("$1" "${2:?$1 requires a value}")
      shift 2
      ;;
    --speaker|--phrase)
      arguments+=("$1" "${2:?$1 requires a value}")
      shift 2
      ;;
    --discover-only|--shortlist-only|--force|--remaster|--verify-only)
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
  manifest="$workbench/cartesia-pack-manifest.json"
  scratch="$workbench/scratch/cartesia-full-pack"
fi

for required in "$python" "$manifest" "$generator" "$validator"; do
  if [[ ! -e "$required" ]]; then
    echo "Missing Cartesia workbench dependency: $required" >&2
    echo "Run setup-cartesia-environment.sh first." >&2
    exit 1
  fi
done
if [[ -z "${CARTESIA_API_KEY:-}" ]]; then
  echo "CARTESIA_API_KEY is not set in this process." >&2
  exit 1
fi
echo "Cartesia API key loaded: ${#CARTESIA_API_KEY} characters."

"$python" "$validator" --manifest "$manifest"
base_arguments=(--manifest "$manifest" --scratch "$scratch")
if [[ ${#arguments[@]} -gt 0 ]]; then
  "$python" "$generator" "${base_arguments[@]}" "${arguments[@]}"
else
  "$python" "$generator" "${base_arguments[@]}"
fi

if [[ " ${arguments[*]-} " == *" --discover-only "* || " ${arguments[*]-} " == *" --shortlist-only "* || " ${arguments[*]-} " == *" --verify-only "* ]]; then
  exit 0
fi
report="$scratch/reports/cartesia-run.json"
"$python" "$validator" --manifest "$manifest" --run-report "$report"
page="$scratch/listening/index.html"
if [[ ! -f "$page" ]]; then
  echo "Listening page was not generated: $page" >&2
  exit 1
fi
echo "Listening page: $page"
if $open_page && command -v open >/dev/null 2>&1; then
  open "$page"
fi
