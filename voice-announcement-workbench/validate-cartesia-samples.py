#!/usr/bin/env python3
"""Validate the Cartesia stock-voice bake-off manifest and optional run report."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "cartesia-sample-manifest.json"
EXPECTED_PHRASES = {
    "adrenaline-rush": "Adrenaline",
    "aspect-of-the-turtle": "Turtle",
    "fortifying-brew": "Fort Brew",
    "summon-demonic-tyrant": "Tyrant",
}
SECRET_FIELDS = {"api_key", "apikey", "x-api-key", "authorization", "secret", "token"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--run-report", type=Path)
    return parser.parse_args()


def validate_manifest(manifest: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if manifest.get("schemaVersion") != 1 or manifest.get("scope") != "comparison":
        errors.append("manifest must use schemaVersion 1 and comparison scope")
    if manifest.get("api", {}).get("baseUrl") != "https://api.cartesia.ai":
        errors.append("api.baseUrl must be https://api.cartesia.ai")
    if manifest.get("api", {}).get("version") != "2026-08-14":
        errors.append("api.version must be pinned to 2026-08-14")
    if manifest.get("model", {}).get("id") != "sonic-3.6":
        errors.append("model.id must be sonic-3.6")
    phrases = {
        phrase.get("id"): phrase.get("spokenText")
        for phrase in manifest.get("phrases", [])
        if isinstance(phrase, dict)
    }
    if phrases != EXPECTED_PHRASES:
        errors.append("phrases must match the four short-callout probes")
    if set(manifest.get("selection", {}).get("requiredGenders", [])) != {
        "masculine",
        "feminine",
    }:
        errors.append("selection must require masculine and feminine voices")
    if float(manifest.get("mastering", {}).get("tempo", 0)) != 1.0:
        errors.append("mastering tempo must be 1.0")
    return errors


def find_secret_field(value: Any, path: str = "root") -> list[str]:
    errors: list[str] = []
    if isinstance(value, dict):
        for key, item in value.items():
            normalized = str(key).casefold().replace("-", "_")
            if normalized in {field.replace("-", "_") for field in SECRET_FIELDS}:
                errors.append(f"secret-like field at {path}.{key}")
            errors.extend(find_secret_field(item, f"{path}.{key}"))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            errors.extend(find_secret_field(item, f"{path}[{index}]"))
    return errors


def validate_run(manifest: dict[str, Any], report: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if report.get("api") != manifest.get("api"):
        errors.append("run API settings do not match the manifest")
    if report.get("model") != manifest.get("model"):
        errors.append("run model does not match the manifest")
    if report.get("generationConfig") != manifest.get("generationConfig"):
        errors.append("run generation settings do not match the manifest")
    voices = report.get("selectedVoices") or []
    if len(voices) != 2 or {voice.get("gender") for voice in voices} != {
        "masculine",
        "feminine",
    }:
        errors.append("run must contain one masculine and one feminine voice")
    if any(not voice.get("voice_id") for voice in voices):
        errors.append("every selected voice must have a voice ID")
    samples = report.get("samples") or []
    if len(samples) != 8:
        errors.append("run must contain exactly eight samples")
    seen: set[str] = set()
    fingerprints: dict[str, set[str]] = {}
    for sample in samples:
        key = str(sample.get("outputKey") or "")
        if key in seen:
            errors.append(f"duplicate output key: {key}")
        seen.add(key)
        if sample.get("stockVoice") is not True:
            errors.append(f"sample {key} is not marked as a stock voice")
        fingerprints.setdefault(str(sample.get("phraseId")), set()).add(
            str(sample.get("requestFingerprint") or "")
        )
        for field in ("providerOriginal", "ogg"):
            audio = sample.get(field) or {}
            path = Path(str(audio.get("path") or ""))
            if not path.is_file() or not audio.get("sha256"):
                errors.append(f"sample {key} has invalid {field} provenance")
        if sample.get("ogg", {}).get("channels") != 1:
            errors.append(f"sample {key} must be mono")
        if float(sample.get("tempo", 0)) != 1.0:
            errors.append(f"sample {key} must use natural tempo")
        mastering = sample.get("mastering")
        if not isinstance(mastering, dict):
            errors.append(f"sample {key} is missing mastering data")
        elif float(mastering["finalPass"]["output_tp"]) > float(
            manifest["mastering"]["truePeakDb"]
        ) + 0.1:
            errors.append(f"sample {key} exceeds the true-peak ceiling")
    for phrase_id, values in fingerprints.items():
        if len(values) != 1 or "" in values:
            errors.append(f"male/female requests differ beyond voice for {phrase_id}")
    errors.extend(find_secret_field(report))
    api_key = os.environ.get("CARTESIA_API_KEY")
    if api_key and api_key in json.dumps(report):
        errors.append("run report contains the Cartesia API key value")
    return errors


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.resolve().read_text(encoding="utf-8"))
    errors = validate_manifest(manifest)
    if args.run_report:
        report = json.loads(args.run_report.resolve().read_text(encoding="utf-8"))
        errors.extend(validate_run(manifest, report))
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print("Validated Cartesia stock-voice comparison manifest and run." if args.run_report else "Validated Cartesia stock-voice comparison manifest.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
