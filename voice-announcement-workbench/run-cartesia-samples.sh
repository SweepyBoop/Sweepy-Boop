#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python="$workbench/scratch/cartesia-python/bin/python"
manifest="$workbench/cartesia-sample-manifest.json"
generator="$workbench/generate-cartesia-samples.py"
validator="$workbench/validate-cartesia-samples.py"
scratch="$workbench/scratch/cartesia-bakeoff"
open_page=true
arguments=()

usage() {
  cat <<EOF
Usage: bash $0 [options]

Options:
  --discover-only       Fetch and sanitize the Cartesia voice catalog only.
  --shortlist-only      Fetch/filter voices without generating speech.
  --speaker VALUE       masculine, feminine, voice-a, or voice-b.
  --phrase ID           Generate one phrase.
  --force               Refresh catalog/selection and regenerate selected audio.
  --remaster            Rebuild OGG files from cached provider WAVs.
  --verify-only         Check manifest and credential without network access.
  --no-open             Do not open the listening page.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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
