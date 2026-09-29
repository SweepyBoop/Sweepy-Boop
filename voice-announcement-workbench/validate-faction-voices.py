#!/usr/bin/env python3
"""Validate the reproducible faction-voice manifest and optional generated run."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "faction-voice-manifest.json"
DEFAULT_OUTPUT = WORKBENCH / "scratch" / "faction-voices" / "reports" / "validation.json"
VOICE_DESIGN_REVISION = "5ecdb67327fd37bb2e042aab12ff7391903235d3"
CLONE_REVISION = "fd4b254389122332181a7c3db7f27e918eec64e3"
EXPECTED_VOICES = {"alliance-commander", "horde-commander"}
EXPECTED_PHRASES = {
    "avenging-wrath": "Wings",
    "combustion": "Combustion",
    "invoke-chi-ji": "Cheejee",
    "metamorphosis": "Meta",
    "nullifying-shroud": "Null Shroud",
    "bestial-wrath": "Bestial Wrath",
    "coordinated-assault": "Coordinated Assault",
    "touch-of-the-magi": "Touch of the Magi",
    "apotheosis": "Apotheosis",
    "spell-reflection": "Reflection",
}
PROHIBITED_INSTRUCTION_TERMS = {
    "anduin",
    "jaina",
    "saurfang",
    "sylvanas",
    "thrall",
    "varian",
    "warcraft",
}
EXPECTED_GENERATION = {
    "doSample": True,
    "temperature": 0.6,
    "topP": 0.8,
    "topK": 20,
    "repetitionPenalty": 1.05,
    "subtalkerDoSample": True,
    "subtalkerTemperature": 0.6,
    "subtalkerTopP": 0.8,
    "subtalkerTopK": 20,
    "nonStreamingMode": True,
    "cloneMode": "x-vector-only",
    "appendTerminalPunctuation": True,
    "designMaxNewTokens": 512,
    "cloneMaxNewTokens": 96,
    "prefixText": "Ready.",
    "separatorMinimumSeconds": 0.12,
    "separatorSearchStartSeconds": 0.25,
    "separatorSearchEndRatio": 0.85,
    "separatorThresholdDb": -48.0,
    "separatorRelativeThreshold": 0.06,
    "preservedLeadingSilenceSeconds": 0.02,
    "maximumCalloutSeconds": 3.0,
    "maximumAttempts": 6,
    "retrySeedStep": 1,
}
EXPECTED_MASTERING = {
    "integratedLufs": -16.0,
    "loudnessRange": 7.0,
    "truePeakDb": -1.5,
    "vorbisQuality": 5,
    "tempo": 1.0,
    "silenceThresholdDb": -50.0,
    "leadingSilenceSeconds": 0.02,
    "trailingSilenceSeconds": 0.08,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--run-report", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def require_string(value: Any, field: str, errors: list[str]) -> None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{field} must be a non-empty string")


def validate_manifest(manifest: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if manifest.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    expected_models = {
        "voiceDesignModel": (
            "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign",
            VOICE_DESIGN_REVISION,
        ),
        "cloneModel": ("Qwen/Qwen3-TTS-12Hz-1.7B-Base", CLONE_REVISION),
    }
    for field, (repository, revision) in expected_models.items():
        model = manifest.get(field) or {}
        if model.get("repository") != repository:
            errors.append(f"{field}.repository must be {repository}")
        if model.get("revision") != revision:
            errors.append(f"{field}.revision must be pinned to {revision}")
        if model.get("attentionImplementation") != "sdpa":
            errors.append(f"{field}.attentionImplementation must be sdpa")

    if manifest.get("generation") != EXPECTED_GENERATION:
        errors.append("generation settings must match the pinned plain-delivery baseline")
    if manifest.get("mastering") != EXPECTED_MASTERING:
        errors.append("mastering settings must match the established workbench baseline")

    speakers = manifest.get("speakers")
    if not isinstance(speakers, list):
        errors.append("speakers must be an array")
        speakers = []
    actual_voices = {
        speaker.get("id") for speaker in speakers if isinstance(speaker, dict)
    }
    if actual_voices != EXPECTED_VOICES or len(speakers) != len(EXPECTED_VOICES):
        errors.append(f"speakers must contain exactly {sorted(EXPECTED_VOICES)}")
    design_seeds: set[int] = set()
    for index, speaker in enumerate(speakers):
        prefix = f"speakers[{index}]"
        if not isinstance(speaker, dict):
            errors.append(f"{prefix} must be an object")
            continue
        for field in ("id", "displayName", "description", "designInstruction", "referenceText"):
            require_string(speaker.get(field), f"{prefix}.{field}", errors)
        instruction = str(speaker.get("designInstruction") or "").casefold()
        prohibited = sorted(term for term in PROHIBITED_INSTRUCTION_TERMS if term in instruction)
        if prohibited:
            errors.append(f"{prefix}.designInstruction contains named-IP terms: {prohibited}")
        try:
            design_seed = int(speaker["designSeed"])
            int(speaker["cloneSeedOffset"])
            if design_seed in design_seeds:
                errors.append(f"duplicate design seed: {design_seed}")
            design_seeds.add(design_seed)
        except (KeyError, TypeError, ValueError):
            errors.append(f"{prefix} must have integer designSeed and cloneSeedOffset")
        seed_overrides = speaker.get("seedOverrides") or {}
        if not isinstance(seed_overrides, dict):
            errors.append(f"{prefix}.seedOverrides must be an object")
        else:
            for phrase_id, seed in seed_overrides.items():
                if phrase_id not in EXPECTED_PHRASES or not isinstance(seed, int):
                    errors.append(f"{prefix}.seedOverrides contains invalid entry {phrase_id!r}")

    phrases = manifest.get("phrases")
    if not isinstance(phrases, list):
        errors.append("phrases must be an array")
        phrases = []
    actual_phrases: dict[str, str] = {}
    for index, phrase in enumerate(phrases):
        prefix = f"phrases[{index}]"
        if not isinstance(phrase, dict):
            errors.append(f"{prefix} must be an object")
            continue
        for field in ("id", "displayText", "spokenText"):
            require_string(phrase.get(field), f"{prefix}.{field}", errors)
        phrase_id = str(phrase.get("id") or "")
        if phrase_id in actual_phrases:
            errors.append(f"duplicate phrase id: {phrase_id}")
        actual_phrases[phrase_id] = str(phrase.get("spokenText") or "")
    if actual_phrases != EXPECTED_PHRASES:
        errors.append("phrases must match the established ten-callout evaluation set")
    return errors


def validate_run(manifest: dict[str, Any], report: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for model_key in ("voiceDesignModel", "cloneModel"):
        if report.get(model_key) != manifest.get(model_key):
            errors.append(f"run {model_key} does not match the manifest")
    if report.get("generation") != manifest.get("generation"):
        errors.append("run generation settings do not match the manifest")
    references = report.get("references") or []
    samples = report.get("samples") or []
    if len(references) != len(manifest["speakers"]):
        errors.append(f"run must contain {len(manifest['speakers'])} references")
    expected_samples = len(manifest["speakers"]) * len(manifest["phrases"])
    if len(samples) != expected_samples:
        errors.append(f"run must contain {expected_samples} samples")

    reference_hashes: dict[str, str] = {}
    for reference in references:
        audio = reference.get("audio") or {}
        path = Path(str(audio.get("path") or ""))
        if not path.is_file():
            errors.append(f"reference file is missing: {path}")
        if not audio.get("sha256"):
            errors.append(f"reference hash is missing for {reference.get('speakerId')}")
        reference_hashes[str(reference.get("speakerId"))] = str(audio.get("sha256") or "")

    seen_keys: set[str] = set()
    for sample in samples:
        key = str(sample.get("outputKey") or "")
        if key in seen_keys:
            errors.append(f"duplicate sample outputKey: {key}")
        seen_keys.add(key)
        speaker_id = str(sample.get("speakerId") or "")
        if sample.get("referenceSha256") != reference_hashes.get(speaker_id):
            errors.append(f"sample {key} does not reference the frozen voice hash")
        for field in ("paddedWav", "rawWav", "ogg"):
            audio = sample.get(field) or {}
            path = Path(str(audio.get("path") or ""))
            if not path.is_file():
                errors.append(f"sample file is missing: {path}")
            if field == "ogg" and audio.get("channels") != 1:
                errors.append(f"sample {key} must be mono")
            if not audio.get("sha256"):
                errors.append(f"sample {key} is missing {field} sha256")
        preprocessing = sample.get("preprocessing")
        if not isinstance(preprocessing, dict):
            errors.append(f"sample {key} is missing prefix-crop provenance")
        else:
            duration = float(preprocessing.get("croppedDurationSeconds", 0))
            if duration <= 0 or duration > float(manifest["generation"]["maximumCalloutSeconds"]):
                errors.append(f"sample {key} has invalid cropped duration {duration}")
            if int(preprocessing.get("attempt", 0)) < 1:
                errors.append(f"sample {key} has invalid generation attempt")
        mastering = sample.get("mastering")
        if not isinstance(mastering, dict):
            errors.append(f"sample {key} is missing mastering provenance")
            continue
        try:
            output_tp = float(mastering["finalPass"]["output_tp"])
            if output_tp > float(manifest["mastering"]["truePeakDb"]) + 0.1:
                errors.append(f"sample {key} exceeds the true-peak ceiling: {output_tp} dBTP")
        except (KeyError, TypeError, ValueError):
            errors.append(f"sample {key} has invalid mastering measurements")
    return errors


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.resolve().read_text(encoding="utf-8"))
    errors = validate_manifest(manifest)
    run_report = None
    if args.run_report:
        run_report = json.loads(args.run_report.resolve().read_text(encoding="utf-8"))
        errors.extend(validate_run(manifest, run_report))

    result = {
        "valid": not errors,
        "manifest": str(args.manifest.resolve()),
        "voiceCount": len(manifest.get("speakers", [])),
        "phraseCount": len(manifest.get("phrases", [])),
        "expectedAudioCount": len(manifest.get("speakers", [])) * len(manifest.get("phrases", [])),
        "runReport": str(args.run_report.resolve()) if args.run_report else None,
        "errors": errors,
    }
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    scope = "manifest and generated run" if run_report is not None else "manifest"
    print(f"Validated faction voice {scope}: 2 voices, 10 phrases, 20 expected clips.")
    print(f"Validation report: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
