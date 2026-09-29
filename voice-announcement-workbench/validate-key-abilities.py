#!/usr/bin/env python3
"""Validate the curated arena key-ability voice manifest and report spec coverage."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "key-abilities-manifest.json"
DEFAULT_OUTPUT = WORKBENCH / "scratch" / "key-abilities" / "reports"
PINNED_REVISION = "0c0e3051f131929182e2c023b9537f8b1c68adfe"
EXPECTED_SPEAKERS = {"aiden": "Aiden", "sohee": "Sohee"}
EXPECTED_SPECS = {
    251: ("Frost Death Knight", "DEATHKNIGHT", "dps"),
    252: ("Unholy Death Knight", "DEATHKNIGHT", "dps"),
    577: ("Havoc Demon Hunter", "DEMONHUNTER", "dps"),
    102: ("Balance Druid", "DRUID", "dps"),
    103: ("Feral Druid", "DRUID", "dps"),
    105: ("Restoration Druid", "DRUID", "healer"),
    1467: ("Devastation Evoker", "EVOKER", "dps"),
    1468: ("Preservation Evoker", "EVOKER", "healer"),
    1473: ("Augmentation Evoker", "EVOKER", "dps"),
    253: ("Beast Mastery Hunter", "HUNTER", "dps"),
    254: ("Marksmanship Hunter", "HUNTER", "dps"),
    255: ("Survival Hunter", "HUNTER", "dps"),
    62: ("Arcane Mage", "MAGE", "dps"),
    63: ("Fire Mage", "MAGE", "dps"),
    64: ("Frost Mage", "MAGE", "dps"),
    270: ("Mistweaver Monk", "MONK", "healer"),
    269: ("Windwalker Monk", "MONK", "dps"),
    65: ("Holy Paladin", "PALADIN", "healer"),
    70: ("Retribution Paladin", "PALADIN", "dps"),
    256: ("Discipline Priest", "PRIEST", "healer"),
    257: ("Holy Priest", "PRIEST", "healer"),
    258: ("Shadow Priest", "PRIEST", "dps"),
    259: ("Assassination Rogue", "ROGUE", "dps"),
    260: ("Outlaw Rogue", "ROGUE", "dps"),
    261: ("Subtlety Rogue", "ROGUE", "dps"),
    262: ("Elemental Shaman", "SHAMAN", "dps"),
    263: ("Enhancement Shaman", "SHAMAN", "dps"),
    264: ("Restoration Shaman", "SHAMAN", "healer"),
    265: ("Affliction Warlock", "WARLOCK", "dps"),
    266: ("Demonology Warlock", "WARLOCK", "dps"),
    267: ("Destruction Warlock", "WARLOCK", "dps"),
    71: ("Arms Warrior", "WARRIOR", "dps"),
    72: ("Fury Warrior", "WARRIOR", "dps"),
}
TANK_SPEC_IDS = {250, 581, 104, 268, 66, 73}
MANDATORY_UTILITY = {
    23920: {71, 72},
    8178: {262, 263, 264},
    212295: {265, 266, 267},
}
VALID_CATEGORIES = {"offensive", "defensive", "utility"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def require_non_empty_string(value: Any, field: str, errors: list[str]) -> None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{field} must be a non-empty string")


def validate(manifest: dict[str, Any]) -> tuple[list[str], list[str], dict[int, dict[str, list[str]]]]:
    errors: list[str] = []
    warnings: list[str] = []

    if manifest.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if manifest.get("model", {}).get("revision") != PINNED_REVISION:
        errors.append(f"model.revision must be pinned to {PINNED_REVISION}")
    if float(manifest.get("mastering", {}).get("tempo", -1)) != 1.0:
        errors.append("mastering.tempo must be 1.0")

    speakers = manifest.get("speakers")
    if not isinstance(speakers, list):
        errors.append("speakers must be an array")
        speakers = []
    actual_speakers = {
        speaker.get("id"): speaker.get("qwenName")
        for speaker in speakers
        if isinstance(speaker, dict)
    }
    if actual_speakers != EXPECTED_SPEAKERS:
        errors.append(f"speakers must be exactly {EXPECTED_SPEAKERS}")

    specs = manifest.get("specs")
    if not isinstance(specs, list):
        errors.append("specs must be an array")
        specs = []
    actual_specs: dict[int, tuple[str, str, str]] = {}
    for index, spec in enumerate(specs):
        if not isinstance(spec, dict):
            errors.append(f"specs[{index}] must be an object")
            continue
        try:
            spec_id = int(spec["id"])
            actual_specs[spec_id] = (str(spec["name"]), str(spec["class"]), str(spec["role"]))
        except (KeyError, TypeError, ValueError):
            errors.append(f"specs[{index}] is missing valid id/name/class/role fields")
    if actual_specs != EXPECTED_SPECS:
        missing = sorted(set(EXPECTED_SPECS) - set(actual_specs))
        extra = sorted(set(actual_specs) - set(EXPECTED_SPECS))
        changed = sorted(
            spec_id
            for spec_id in set(actual_specs) & set(EXPECTED_SPECS)
            if actual_specs[spec_id] != EXPECTED_SPECS[spec_id]
        )
        errors.append(f"spec roster mismatch; missing={missing}, extra={extra}, changed={changed}")
    if set(actual_specs) & TANK_SPEC_IDS:
        errors.append(f"tank-only specs are not allowed: {sorted(set(actual_specs) & TANK_SPEC_IDS)}")

    phrases = manifest.get("phrases")
    if not isinstance(phrases, list) or not phrases:
        errors.append("phrases must be a non-empty array")
        phrases = []

    seen_ids: set[str] = set()
    seen_spell_ids: dict[int, str] = {}
    spoken_aliases: dict[str, list[str]] = defaultdict(list)
    coverage = {
        spec_id: {"offensive": [], "defensive": [], "utility": []}
        for spec_id in EXPECTED_SPECS
    }

    for index, phrase in enumerate(phrases):
        prefix = f"phrases[{index}]"
        if not isinstance(phrase, dict):
            errors.append(f"{prefix} must be an object")
            continue
        for field in ("id", "displayText", "spokenText", "category"):
            require_non_empty_string(phrase.get(field), f"{prefix}.{field}", errors)

        phrase_id = str(phrase.get("id") or "")
        if phrase_id in seen_ids:
            errors.append(f"duplicate phrase id: {phrase_id}")
        seen_ids.add(phrase_id)

        category = phrase.get("category")
        if category not in VALID_CATEGORIES:
            errors.append(f"{prefix}.category must be one of {sorted(VALID_CATEGORIES)}")
            continue

        spell_ids = phrase.get("spellIds")
        spec_ids = phrase.get("specIds")
        if not isinstance(spell_ids, list) or not spell_ids:
            errors.append(f"{prefix}.spellIds must be a non-empty array")
            spell_ids = []
        if not isinstance(spec_ids, list) or not spec_ids:
            errors.append(f"{prefix}.specIds must be a non-empty array")
            spec_ids = []

        for spell_id in spell_ids:
            if not isinstance(spell_id, int) or spell_id <= 0:
                errors.append(f"{prefix}.spellIds contains invalid value {spell_id!r}")
                continue
            prior = seen_spell_ids.get(spell_id)
            if prior:
                errors.append(f"spell ID {spell_id} appears in both {prior} and {phrase_id}")
            seen_spell_ids[spell_id] = phrase_id

        for spec_id in spec_ids:
            if spec_id not in EXPECTED_SPECS:
                errors.append(f"{prefix}.specIds contains unsupported spec {spec_id}")
                continue
            coverage[spec_id][category].append(phrase_id)

        spoken_aliases[str(phrase.get("spokenText") or "").casefold()].append(phrase_id)

    for spec_id, categories in coverage.items():
        spec_name, _, role = EXPECTED_SPECS[spec_id]
        offensive_count = len(categories["offensive"])
        defensive_count = len(categories["defensive"])
        if role == "dps" and offensive_count == 0:
            errors.append(f"{spec_name} has no offensive callout")
        if offensive_count > 2:
            errors.append(f"{spec_name} exceeds two offensive callouts: {categories['offensive']}")
        if defensive_count == 0:
            errors.append(f"{spec_name} has no defensive callout")
        if defensive_count > 2:
            errors.append(f"{spec_name} exceeds two defensive callouts: {categories['defensive']}")

    for spell_id, required_specs in MANDATORY_UTILITY.items():
        phrase = next(
            (item for item in phrases if isinstance(item, dict) and spell_id in item.get("spellIds", [])),
            None,
        )
        if phrase is None:
            errors.append(f"mandatory utility spell {spell_id} is missing")
            continue
        if phrase.get("category") != "utility":
            errors.append(f"mandatory utility spell {spell_id} must use category utility")
        if set(phrase.get("specIds", [])) != required_specs:
            errors.append(
                f"mandatory utility spell {spell_id} must map to specs {sorted(required_specs)}"
            )

    for spoken_text, phrase_ids in sorted(spoken_aliases.items()):
        if spoken_text and len(phrase_ids) > 1:
            warnings.append(f"spoken alias {spoken_text!r} is shared by {phrase_ids}")

    return errors, warnings, coverage


def write_reports(
    manifest: dict[str, Any],
    errors: list[str],
    warnings: list[str],
    coverage: dict[int, dict[str, list[str]]],
    output_dir: Path,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    summary = {
        "valid": not errors,
        "speakerCount": len(manifest.get("speakers", [])),
        "calloutCount": len(manifest.get("phrases", [])),
        "expectedAudioCount": len(manifest.get("speakers", [])) * len(manifest.get("phrases", [])),
        "specCount": len(manifest.get("specs", [])),
        "errors": errors,
        "warnings": warnings,
        "coverage": {str(spec_id): categories for spec_id, categories in coverage.items()},
    }
    (output_dir / "key-abilities-coverage.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )

    lines = [
        "# Arena Key Ability Coverage",
        "",
        f"- Validation: {'PASS' if not errors else 'FAIL'}",
        f"- Included specs: {len(manifest.get('specs', []))}",
        f"- Unique callouts: {len(manifest.get('phrases', []))}",
        f"- Expected mastered clips: {summary['expectedAudioCount']}",
        "",
        "| Spec | Role | Offensives | Defensives | Utility |",
        "| --- | --- | --- | --- | --- |",
    ]
    for spec in manifest.get("specs", []):
        spec_id = int(spec["id"])
        categories = coverage.get(spec_id, {})
        format_items = lambda values: ", ".join(f"`{value}`" for value in values) or "-"
        lines.append(
            f"| {spec['name']} (`{spec_id}`) | {spec['role']} | "
            f"{format_items(categories.get('offensive', []))} | "
            f"{format_items(categories.get('defensive', []))} | "
            f"{format_items(categories.get('utility', []))} |"
        )

    if warnings:
        lines.extend(["", "## Warnings", ""] + [f"- {warning}" for warning in warnings])
    if errors:
        lines.extend(["", "## Errors", ""] + [f"- {error}" for error in errors])

    (output_dir / "key-abilities-coverage.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
    )


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.resolve().read_text(encoding="utf-8"))
    errors, warnings, coverage = validate(manifest)
    write_reports(manifest, errors, warnings, coverage, args.output_dir.resolve())

    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(
        f"Validated {len(manifest['phrases'])} callouts across "
        f"{len(manifest['specs'])} specs for {len(manifest['speakers'])} voices."
    )
    print(f"Coverage report: {args.output_dir.resolve() / 'key-abilities-coverage.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
