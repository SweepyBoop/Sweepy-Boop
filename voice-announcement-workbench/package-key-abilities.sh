#!/usr/bin/env bash
set -euo pipefail

workbench="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scratch="${1:-$workbench/scratch/key-abilities}"
output="${2:-$scratch/aiden-sohee-key-abilities-1.0x.zip}"
python="$workbench/scratch/python/bin/python"
manifest="$workbench/key-abilities-manifest.json"
coverage="$scratch/reports/key-abilities-coverage.md"
report="$scratch/reports/sample-run.json"

for required_path in "$python" "$manifest" "$coverage" "$report"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Required package input is missing: $required_path" >&2
    exit 1
  fi
done

"$python" - "$manifest" "$coverage" "$report" "$output" <<'PY'
from __future__ import annotations

import hashlib
import json
import sys
import zipfile
from pathlib import Path

manifest_path, coverage_path, report_path, output_path = map(Path, sys.argv[1:])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
report = json.loads(report_path.read_text(encoding="utf-8"))
expected = len(manifest["speakers"]) * len(manifest["phrases"])
samples = report.get("samples", [])
if len(samples) != expected:
    raise SystemExit(f"Expected {expected} generated samples, found {len(samples)}.")
if float(manifest["mastering"]["tempo"]) != 1.0:
    raise SystemExit("The key-ability package must use natural 1.0x tempo.")

output_path.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for sample in samples:
        ogg = Path(sample["ogg"]["path"])
        if not ogg.is_file():
            raise SystemExit(f"A mastered OGG is missing for {sample['outputKey']}: {ogg}")
        archive.write(ogg, f"ogg/{ogg.name}")
    archive.write(manifest_path, manifest_path.name)
    archive.write(coverage_path, f"reports/{coverage_path.name}")
    archive.write(report_path, f"reports/{report_path.name}")

digest = hashlib.sha256(output_path.read_bytes()).hexdigest().upper()
print(f"Archive: {output_path.resolve()}")
print(f"Bytes: {output_path.stat().st_size}")
print(f"SHA256: {digest}")
PY
