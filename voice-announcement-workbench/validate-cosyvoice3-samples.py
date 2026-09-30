#!/usr/bin/env python3
"""Validate the isolated CosyVoice 3 comparison manifest and generated samples."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "cosyvoice3-sample-manifest.json"
FACTION_MANIFEST = WORKBENCH / "faction-voice-manifest.json"
DEFAULT_REPORT = WORKBENCH
DEFAULT_REPORT = WORKBENCH / "scratch" / "cosyvoice3-zero-shot" / "reports" / "cosyvoice3-run.json"
MODEL_REVISION = "29e01c4e8d000f4bcd70751be16fa94bf3d85a18"
SOURCE_REVISION = "074ca6dc9e80a2f424f1f74b48bdd7d3fea531cc"
REFERENCE_HASHES = {
    "alliance-commander": "DCB7499F00A62577615FBB2DE32DC156BFCC56A13ECF1B5068BFC6F56C316519",
    "horde-commander": "50E52EB550990CAA497B2DF10C040297989F6990C2A5BE8143973DE733C886FB",
}
EXPECTED_PHRASES = {
    "adrenaline-rush": "Adrenaline",
    "aspect-of-the-turtle": "Turtle",
    "fortifying-brew": "Fort Brew",
    "summon-demonic-tyrant": "Tyrant",
}
EXPECTED_MODES = {"cross-lingual", "instruct2"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--run-report", type=Path)
    return parser.parse_args()


def validate_manifest(manifest: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if manifest.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if manifest.get("model", {}).get("revision") != MODEL_REVISION:
        errors.append(f"model.revision must be {MODEL_REVISION}")
    if manifest.get("source", {}).get("revision") != SOURCE_REVISION:
        errors.append(f"source.revision must be {SOURCE_REVISION}")
    speakers = manifest.get("speakers") or []
    actual_references = {
        speaker.get("id"): speaker.get("referenceSha256")
        for speaker in speakers
        if isinstance(speaker, dict)
    }
    if actual_references != REFERENCE_HASHES:
        errors.append("speakers must use the two approved frozen references")
    mode_items = [mode for mode in manifest.get("modes", []) if isinstance(mode, dict)]
    modes = {mode.get("id") for mode in mode_items}
    if any(not isinstance(mode.get("seedOffset"), int) for mode in mode_items):
        errors.append("every mode must define an integer seedOffset")
    scope = manifest.get("scope")
    phrases = manifest.get("phrases") or []
    if scope == "comparison":
        if modes != EXPECTED_MODES:
            errors.append(f"comparison modes must be exactly {sorted(EXPECTED_MODES)}")
        actual_phrases = {
            phrase.get("id"): phrase.get("spokenText")
            for phrase in phrases
            if isinstance(phrase, dict)
        }
        if actual_phrases != EXPECTED_PHRASES:
            errors.append("comparison phrases must match the four stability probes")
        if int(manifest.get("takesPerMode", 0)) != 2:
            errors.append("comparison takesPerMode must be 2")
        if manifest.get("enforceMaximumDuration") is not False:
            errors.append("comparison must report rather than enforce the duration target")
    elif scope == "full":
        faction = json.loads(FACTION_MANIFEST.read_text(encoding="utf-8"))
        if modes != {"instruct2"}:
            errors.append("full-pack mode must be instruct2")
        if int(manifest.get("takesPerMode", 0)) != 1:
            errors.append("full-pack takesPerMode must be 1")
        if manifest.get("enforceMaximumDuration") is not True:
            errors.append("full pack must enforce the duration target")
        if phrases != faction.get("phrases"):
            errors.append("full-pack phrases must match the faction catalog")
    else:
        errors.append("scope must be comparison or full")
    return errors


def validate_run(manifest: dict[str, Any], report: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for field in ("model", "source", "mastering", "enforceMaximumDuration"):
        if report.get(field) != manifest.get(field):
            errors.append(f"run {field} does not match the manifest")
    expected_count = (
        len(manifest["speakers"])
        * len(manifest["modes"])
        * int(manifest["takesPerMode"])
        * len(manifest["phrases"])
    )
    samples = report.get("samples") or []
    if len(samples) != expected_count:
        errors.append(f"run must contain {expected_count} samples")
    seen: set[str] = set()
    for sample in samples:
        key = str(sample.get("outputKey") or "")
        if key in seen:
            errors.append(f"duplicate output key: {key}")
        seen.add(key)
        if sample.get("referenceSha256") not in REFERENCE_HASHES.values():
            errors.append(f"sample {key} uses an unexpected reference")
        for field in ("rawWav", "ogg"):
            audio = sample.get(field) or {}
            path = Path(str(audio.get("path") or ""))
            if not path.is_file() or not audio.get("sha256"):
                errors.append(f"sample {key} has invalid {field} provenance")
        if sample.get("ogg", {}).get("channels") != 1:
            errors.append(f"sample {key} must be mono")
        if not isinstance(sample.get("tempo"), (int, float)) or sample["tempo"] < 1.0:
            errors.append(f"sample {key} has invalid mastering tempo")
        duration = float(sample.get("ogg", {}).get("durationSeconds", 0))
        if manifest.get("enforceMaximumDuration") and duration > float(
            manifest["mastering"]["maximumDurationSeconds"]
        ):
            errors.append(f"sample {key} exceeds the full-pack duration cap")
        mastering = sample.get("mastering")
        if not isinstance(mastering, dict):
            errors.append(f"sample {key} is missing mastering measurements")
        elif float(mastering["finalPass"]["output_tp"]) > float(
            manifest["mastering"]["truePeakDb"]
        ) + 0.1:
            errors.append(f"sample {key} exceeds the true-peak ceiling")
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
    expected = (
        len(manifest["speakers"])
        * len(manifest["modes"])
        * int(manifest["takesPerMode"])
        * len(manifest["phrases"])
    )
    print(f"Validated CosyVoice {manifest['scope']}: {expected} expected samples.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
