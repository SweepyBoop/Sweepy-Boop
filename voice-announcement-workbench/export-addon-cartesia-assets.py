#!/usr/bin/env python3
"""Export the promoted Cartesia review pack into shipped addon assets and Lua data."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

from audio_workbench import inspect_audio


WORKBENCH = Path(__file__).resolve().parent
REPOSITORY = WORKBENCH.parent
DEFAULT_SOURCE = REPOSITORY / "Docs" / "VoiceAnnouncementReview-KeyAbilities"
DEFAULT_SOUNDS = REPOSITORY / "Sounds" / "ArenaImportantAuras"
DEFAULT_DATA = REPOSITORY / "Common" / "ArenaImportantAuraVoiceData.lua"
BASE_SOURCE_CALLOUTS = 75
BASE_SOURCE_SPELL_IDS = 85
RUNTIME_CALLOUTS = 66
RUNTIME_SPELL_IDS = 71
TRINKET_CALLOUT_ID = "trinket"
# Audited opponent-unit buff auras. Pet/summon auras, totem/ground effects, and
# unverified variants remain packaged but are not exposed at runtime yet.
ARENA_OPPONENT_BUFF_SPELL_IDS = {
    642, 1022, 1719, 5277, 12472, 13750, 19574, 22812, 23920, 31224,
    31884, 33206, 45438, 47585, 47788, 48707, 48792, 51271, 61336, 97463,
    102342, 102543, 102560, 104773, 106951, 107574, 108271, 108416,
    114051, 114052, 116849, 117679, 118038, 120954, 121471, 125174,
    184364, 185422, 186265, 187827, 190319, 191634, 194223, 194249,
    196718, 200183, 204018, 209426, 210256, 212295, 212800, 264735, 288613,
    8178, 114050, 342246, 343818, 357170, 363534, 363916, 365362, 375087,
    378464, 410358, 454351, 466772, 1219480,
}
FRIENDLY_TARGET_DEBUFF_SPELL_IDS = {
    208086, 321507, 360194, 403631,
}
RUNTIME_AURA_SPELL_IDS = (
    ARENA_OPPONENT_BUFF_SPELL_IDS | FRIENDLY_TARGET_DEBUFF_SPELL_IDS
)
FRIENDLY_TARGET_UNIT_TOKENS = ("player", "party1", "party2")
ASCENDANCE_SPLITS = (
    {
        "id": "ascendance-elemental",
        "displayText": "Ascendance (Elemental)",
        "spellIds": [114050, 1219480],
        "specIds": [262],
        "soundFileName": "ascendance.ogg",
    },
    {
        "id": "ascendance-enhancement",
        "displayText": "Ascendance (Enhancement)",
        "spellIds": [114051],
        "specIds": [263],
        "soundFileName": "ascendance.ogg",
    },
)
VOICE_SOURCES = {
    "alliance": {
        "displayName": "Female - Gemma",
        "providerName": "Gemma",
        "sourcePrefix": "alliance-commander-",
        "voiceId": "62ae83ad-4f6a-430b-af41-a9bede9286ca",
    },
    "horde": {
        "displayName": "Male - Archie",
        "providerName": "Archie",
        "sourcePrefix": "horde-commander-",
        "voiceId": "ef191366-f52f-447a-a398-ed8c0f2943a1",
    },
}
SPEC_CLASS = {
    250: "DEATHKNIGHT", 251: "DEATHKNIGHT", 252: "DEATHKNIGHT",
    577: "DEMONHUNTER", 581: "DEMONHUNTER",
    102: "DRUID", 103: "DRUID", 104: "DRUID", 105: "DRUID",
    1467: "EVOKER", 1468: "EVOKER", 1473: "EVOKER",
    253: "HUNTER", 254: "HUNTER", 255: "HUNTER",
    62: "MAGE", 63: "MAGE", 64: "MAGE",
    268: "MONK", 269: "MONK", 270: "MONK",
    65: "PALADIN", 66: "PALADIN", 70: "PALADIN",
    256: "PRIEST", 257: "PRIEST", 258: "PRIEST",
    259: "ROGUE", 260: "ROGUE", 261: "ROGUE",
    262: "SHAMAN", 263: "SHAMAN", 264: "SHAMAN",
    265: "WARLOCK", 266: "WARLOCK", 267: "WARLOCK",
    71: "WARRIOR", 72: "WARRIOR", 73: "WARRIOR",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--sounds", type=Path, default=DEFAULT_SOUNDS)
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--check", action="store_true")
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def require_file(path: Path) -> Path:
    resolved = path.resolve()
    if not resolved.is_file():
        raise FileNotFoundError(f"Required promoted voice input is missing: {resolved}")
    return resolved


def load_inputs(source: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    manifest_path = require_file(source / "cartesia-pack-manifest.json")
    report_path = require_file(source / "reports" / "review-run.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    report = json.loads(report_path.read_text(encoding="utf-8"))
    if manifest.get("scope") != "full":
        raise ValueError("Promoted Cartesia manifest must use full scope")
    if manifest.get("model", {}).get("id") != "sonic-3.6":
        raise ValueError("Promoted Cartesia manifest must pin sonic-3.6")
    phrases = manifest.get("phrases", [])
    expected_samples = len(phrases) * len(VOICE_SOURCES)
    if len(phrases) not in (BASE_SOURCE_CALLOUTS, BASE_SOURCE_CALLOUTS + 1):
        raise ValueError(
            f"Expected {BASE_SOURCE_CALLOUTS} source callouts plus optional trinket"
        )
    if len(report.get("samples", [])) != expected_samples:
        raise ValueError(f"Expected {expected_samples} promoted samples")
    return manifest, report


def validate_catalog(manifest: dict[str, Any]) -> None:
    ids: set[str] = set()
    spell_owners: dict[int, str] = {}
    for callout in manifest["phrases"]:
        callout_id = str(callout["id"])
        if callout_id in ids:
            raise ValueError(f"Duplicate callout ID: {callout_id}")
        ids.add(callout_id)
        if not callout_id or any(
            character not in "abcdefghijklmnopqrstuvwxyz0123456789-"
            for character in callout_id
        ):
            raise ValueError(f"Invalid callout ID: {callout_id}")
        spell_ids = [int(value) for value in callout.get("spellIds", [])]
        if not spell_ids or any(value <= 0 for value in spell_ids):
            raise ValueError(f"Invalid spell IDs for {callout_id}")
        for spell_id in spell_ids:
            owner = spell_owners.get(spell_id)
            if owner is not None:
                raise ValueError(
                    f"Aura spell ID {spell_id} belongs to both {owner} and {callout_id}"
                )
            spell_owners[spell_id] = callout_id
        spec_ids = [int(value) for value in callout.get("specIds", [])]
        if callout_id == TRINKET_CALLOUT_ID:
            if spec_ids:
                raise ValueError("The universal trinket callout must not declare specs")
        else:
            classes = {SPEC_CLASS.get(spec_id) for spec_id in spec_ids}
            if None in classes or len(classes) != 1:
                raise ValueError(
                    f"Callout {callout_id} must map to exactly one known class: {spec_ids}"
                )
    expected_ids = BASE_SOURCE_CALLOUTS + (TRINKET_CALLOUT_ID in ids)
    if len(ids) != expected_ids:
        raise ValueError(f"Expected {expected_ids} unique source callout IDs")
    expected_spell_ids = BASE_SOURCE_SPELL_IDS + (TRINKET_CALLOUT_ID in ids)
    if len(spell_owners) != expected_spell_ids:
        raise ValueError(f"Expected {expected_spell_ids} unique source spell IDs")


def runtime_callouts(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    used_spell_ids: set[int] = set()
    for source_callout in manifest["phrases"]:
        if source_callout["id"] == "ascendance":
            source_spell_ids = {int(value) for value in source_callout["spellIds"]}
            for split in ASCENDANCE_SPLITS:
                split_spell_ids = [int(value) for value in split["spellIds"]]
                if not set(split_spell_ids).issubset(source_spell_ids):
                    raise ValueError("Ascendance split contains an unknown source spell ID")
                callout = dict(source_callout)
                callout.update(split)
                result.append(callout)
                used_spell_ids.update(split_spell_ids)
            continue

        verified_spell_ids = [
            int(spell_id)
            for spell_id in source_callout["spellIds"]
            if int(spell_id) in RUNTIME_AURA_SPELL_IDS
        ]
        if not verified_spell_ids:
            continue
        callout = dict(source_callout)
        callout["spellIds"] = verified_spell_ids
        if set(verified_spell_ids).issubset(FRIENDLY_TARGET_DEBUFF_SPELL_IDS):
            callout["unitTokens"] = list(FRIENDLY_TARGET_UNIT_TOKENS)
        result.append(callout)
        used_spell_ids.update(verified_spell_ids)
    if len(result) != RUNTIME_CALLOUTS:
        raise ValueError(f"Expected {RUNTIME_CALLOUTS} runtime aura callouts")
    if used_spell_ids != RUNTIME_AURA_SPELL_IDS:
        raise ValueError(
            "Runtime aura allowlist does not match the promoted manifest"
        )
    return result


def expected_source_files(
    source: Path,
    manifest: dict[str, Any],
) -> dict[tuple[str, str], Path]:
    result: dict[tuple[str, str], Path] = {}
    expected_names: set[str] = set()
    for voice_id, voice in VOICE_SOURCES.items():
        for callout in manifest["phrases"]:
            callout_id = str(callout["id"])
            name = f"{voice['sourcePrefix']}{callout_id}.ogg"
            expected_names.add(name)
            result[(voice_id, callout_id)] = require_file(source / "ogg" / name)
    actual_names = {path.name for path in (source / "ogg").glob("*.ogg")}
    if actual_names != expected_names:
        missing = sorted(expected_names - actual_names)
        orphaned = sorted(actual_names - expected_names)
        raise ValueError(
            f"Promoted OGG set mismatch; missing={missing}, orphaned={orphaned}"
        )
    return result


def report_hashes(report: dict[str, Any]) -> dict[str, str]:
    hashes: dict[str, str] = {}
    for sample in report["samples"]:
        name = Path(str(sample["ogg"]["path"])).name
        if name in hashes:
            raise ValueError(f"Duplicate OGG in promoted report: {name}")
        hashes[name] = str(sample["ogg"]["sha256"])
    return hashes


def validate_audio(
    sources: dict[tuple[str, str], Path],
    hashes: dict[str, str],
) -> None:
    for path in sources.values():
        expected_hash = hashes.get(path.name)
        actual_hash = sha256(path)
        if expected_hash is None or actual_hash != expected_hash:
            raise ValueError(f"Promoted OGG hash mismatch: {path}")
        info = inspect_audio(path)
        if int(info["channels"]) != 1:
            raise ValueError(f"Promoted OGG must be mono: {path}")
        duration = float(info["durationSeconds"])
        if duration <= 0 or duration > 1.0:
            raise ValueError(f"Promoted OGG duration is invalid: {path}")


def class_file(callout: dict[str, Any]) -> str:
    classes = {SPEC_CLASS[int(spec_id)] for spec_id in callout["specIds"]}
    return next(iter(classes))


def generate_lua(
    callouts: list[dict[str, Any]],
    manifest: dict[str, Any],
    manifest_hash: str,
) -> str:
    lines = [
        "local _, addon = ...;",
        "",
        "-- Generated by voice-announcement-workbench/export-addon-cartesia-assets.py.",
        f"-- Source manifest SHA-256: {manifest_hash}",
        f"-- Runtime aura callouts: {RUNTIME_CALLOUTS}; aura spell IDs: {RUNTIME_SPELL_IDS}.",
        f"-- Packaged OGG files: {len(manifest['phrases']) * len(VOICE_SOURCES)}.",
        "",
        "addon.ARENA_IMPORTANT_AURA_VOICE_PACKS = {",
    ]
    for voice_id in ("alliance", "horde"):
        voice = VOICE_SOURCES[voice_id]
        lines.extend(
            [
                f"    [{lua_string(voice_id)}] = {{",
                f"        displayName = {lua_string(str(voice['displayName']))},",
                f"        providerName = {lua_string(str(voice['providerName']))},",
                f"        providerVoiceID = {lua_string(str(voice['voiceId']))},",
                f"        directory = {lua_string(voice_id)},",
                "    },",
            ]
        )
    lines.extend(["};", "", "addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUTS = {"])
    for callout in callouts:
        spell_ids = ", ".join(str(int(value)) for value in callout["spellIds"])
        sound_file_name = str(
            callout.get("soundFileName") or (str(callout["id"]) + ".ogg")
        )
        lines.extend(
            [
                "    {",
                f"        id = {lua_string(str(callout['id']))},",
                f"        displayText = {lua_string(str(callout['displayText']))},",
                f"        spokenText = {lua_string(str(callout['spokenText']))},",
                f"        category = {lua_string(str(callout['category']))},",
                f"        classFile = {lua_string(class_file(callout))},",
                f"        iconSpellID = {int(callout['spellIds'][0])},",
                f"        soundFileName = {lua_string(sound_file_name)},",
                f"        spellIDs = {{ {spell_ids} }},",
            ]
        )
        unit_tokens = callout.get("unitTokens")
        if unit_tokens:
            tokens = ", ".join(lua_string(str(value)) for value in unit_tokens)
            lines.append(f"        unitTokens = {{ {tokens} }},")
        lines.append("    },")
    lines.extend(["};", ""])
    trinket_callout = next(
        (item for item in manifest["phrases"] if item["id"] == TRINKET_CALLOUT_ID),
        None,
    )
    if trinket_callout:
        spell_ids = ", ".join(str(int(value)) for value in trinket_callout["spellIds"])
        lines.extend(
            [
                "addon.ARENA_IMPORTANT_AURA_TRINKET_VOICE_CALLOUT = {",
                f"    soundFileName = {lua_string(TRINKET_CALLOUT_ID + '.ogg')},",
                f"    spellIDs = {{ {spell_ids} }},",
                "};",
                "",
            ]
        )
    lines.extend(
        [
            "addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUT_BY_ID = {};",
            "for _, callout in ipairs(addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUTS) do",
            "    addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUT_BY_ID[callout.id] = callout;",
            "end",
            "",
        ]
    )
    return "\n".join(lines)


def validate_export(
    sounds: Path,
    data_path: Path,
    manifest: dict[str, Any],
    sources: dict[tuple[str, str], Path],
    expected_lua: str,
) -> None:
    actual_files = sorted(sounds.rglob("*.ogg"))
    expected_oggs = len(manifest["phrases"]) * len(VOICE_SOURCES)
    if len(actual_files) != expected_oggs:
        raise ValueError(f"Expected {expected_oggs} packaged OGGs, found {len(actual_files)}")
    for (voice_id, callout_id), source in sources.items():
        destination = sounds / "enUS" / voice_id / f"{callout_id}.ogg"
        if not destination.is_file():
            raise FileNotFoundError(f"Packaged OGG is missing: {destination}")
        if sha256(destination) != sha256(source):
            raise ValueError(f"Packaged OGG differs from promoted source: {destination}")
    if data_path.read_text(encoding="utf-8") != expected_lua:
        raise ValueError(f"Generated Lua data is stale: {data_path}")
    text = data_path.read_text(encoding="utf-8")
    if "/Users/" in text or "CARTESIA_API_KEY" in text or "sk_car_" in text:
        raise ValueError("Generated runtime data contains local/provider secret material")
    if len(manifest["phrases"]) not in (BASE_SOURCE_CALLOUTS, BASE_SOURCE_CALLOUTS + 1):
        raise ValueError("Generated runtime data source count changed unexpectedly")


def replace_export(
    staging: Path,
    sounds: Path,
    data_temp: Path,
    data_path: Path,
) -> None:
    sounds_backup = sounds.parent / f".{sounds.name}.backup"
    data_backup = data_path.parent / f".{data_path.name}.backup"
    for backup in (sounds_backup, data_backup):
        if backup.exists():
            if backup.is_dir():
                shutil.rmtree(backup)
            else:
                backup.unlink()
    if sounds.exists():
        sounds.rename(sounds_backup)
    if data_path.exists():
        data_path.rename(data_backup)
    try:
        staging.rename(sounds)
        data_temp.replace(data_path)
    except Exception:
        if sounds.exists():
            shutil.rmtree(sounds)
        if data_path.exists():
            data_path.unlink()
        if sounds_backup.exists():
            sounds_backup.rename(sounds)
        if data_backup.exists():
            data_backup.rename(data_path)
        raise
    if sounds_backup.exists():
        shutil.rmtree(sounds_backup)
    if data_backup.exists():
        data_backup.unlink()


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    sounds = args.sounds.resolve()
    data_path = args.data.resolve()
    manifest_path = require_file(source / "cartesia-pack-manifest.json")
    manifest, report = load_inputs(source)
    validate_catalog(manifest)
    callouts = runtime_callouts(manifest)
    sources = expected_source_files(source, manifest)
    validate_audio(sources, report_hashes(report))
    lua_text = generate_lua(callouts, manifest, sha256(manifest_path))

    if args.check:
        validate_export(sounds, data_path, manifest, sources, lua_text)
        print(f"Validated runtime aura callouts: {RUNTIME_CALLOUTS}")
        print(f"Validated runtime aura IDs: {RUNTIME_SPELL_IDS}")
        print(f"Validated packaged OGG files: {len(manifest['phrases']) * len(VOICE_SOURCES)}")
        return 0

    sounds.parent.mkdir(parents=True, exist_ok=True)
    data_path.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(
        tempfile.mkdtemp(prefix=f".{sounds.name}.staging-", dir=sounds.parent)
    )
    data_temp = data_path.parent / f".{data_path.name}.staging"
    try:
        for (voice_id, callout_id), source_path in sources.items():
            destination = staging / "enUS" / voice_id / f"{callout_id}.ogg"
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, destination)
        data_temp.write_text(lua_text, encoding="utf-8", newline="\n")
        validate_export(staging, data_temp, manifest, sources, lua_text)
        replace_export(staging, sounds, data_temp, data_path)
    except Exception:
        if staging.exists():
            shutil.rmtree(staging)
        data_temp.unlink(missing_ok=True)
        raise

    validate_export(sounds, data_path, manifest, sources, lua_text)
    print(f"Exported runtime aura callouts: {RUNTIME_CALLOUTS}")
    print(f"Exported runtime aura IDs: {RUNTIME_SPELL_IDS}")
    print(f"Packaged OGG files: {len(manifest['phrases']) * len(VOICE_SOURCES)}")
    print(f"Sounds directory: {sounds}")
    print(f"Runtime data: {data_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
