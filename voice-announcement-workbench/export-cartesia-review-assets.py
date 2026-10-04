#!/usr/bin/env python3
"""Export the approved Cartesia voices as a portable review pack."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Any

import imageio_ffmpeg

from audio_workbench import inspect_audio


WORKBENCH = Path(__file__).resolve().parent
REPOSITORY = WORKBENCH.parent
DEFAULT_SCRATCH = WORKBENCH / "scratch" / "cartesia-full-pack"
DEFAULT_DESTINATION = REPOSITORY / "Docs" / "VoiceAnnouncementReview-KeyAbilities"
EXPECTED_DESTINATION_NAME = "VoiceAnnouncementReview-KeyAbilities"
MANIFEST_NAME = "cartesia-pack-manifest.json"
ARCHIVE_NAME = "alliance-horde-cartesia-voices-1.0s.zip"
EXPECTED_SAMPLE_COUNT = 154
EXPECTED_ACCELERATED_COUNT = 30
TERMS_VERIFIED_DATE = "2026-10-01"
ACCOUNT_TIER_DESCRIPTION = "user-confirmed eligible tier; exact tier not recorded"
TEXT_SUFFIXES = {".md", ".json", ".html", ".sha256"}
FORBIDDEN_TEXT = (
    "/users/",
    "scratch/cartesia-full-pack",
    "scratch/cartesia-bakeoff",
    "scratch/faction-voices",
    "scratch/models",
    "authorization",
    "bearer ",
    "cartesia_api_key",
    "sk_car_",
    '"api_key"',
    '"apikey"',
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scratch", type=Path, default=DEFAULT_SCRATCH)
    parser.add_argument("--destination", type=Path, default=DEFAULT_DESTINATION)
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def portable_audio_info(
    info: dict[str, Any],
    relative_path: str | None = None,
) -> dict[str, Any]:
    result = {key: value for key, value in info.items() if key != "path"}
    if relative_path is not None:
        result["path"] = relative_path
    return result


def require_under(path: Path, parent: Path) -> Path:
    resolved = path.resolve()
    try:
        resolved.relative_to(parent.resolve())
    except ValueError as error:
        raise ValueError(f"Review input must stay under {parent}: {resolved}") from error
    if not resolved.is_file():
        raise FileNotFoundError(f"Required review input is missing: {resolved}")
    return resolved


def package_version(name: str) -> str | None:
    try:
        return importlib.metadata.version(name)
    except importlib.metadata.PackageNotFoundError:
        return None


def portable_environment() -> dict[str, Any]:
    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe())
    ffmpeg_version = subprocess.run(
        [str(ffmpeg), "-version"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()[0]
    return {
        "platform": platform.platform(),
        "python": sys.version.splitlines()[0],
        "packages": {
            name: package_version(name)
            for name in (
                "cartesia",
                "certifi",
                "imageio-ffmpeg",
                "numpy",
                "soundfile",
            )
        },
        "ffmpeg": ffmpeg_version,
    }


def archive_inputs(staging: Path) -> list[Path]:
    excluded = {ARCHIVE_NAME, f"{ARCHIVE_NAME}.sha256"}
    return [
        path
        for path in sorted(staging.rglob("*"))
        if path.is_file() and path.name not in excluded
    ]


def build_archive(staging: Path, archive_path: Path) -> str:
    with zipfile.ZipFile(archive_path, "w") as archive:
        for path in archive_inputs(staging):
            info = zipfile.ZipInfo(
                path.relative_to(staging).as_posix(),
                date_time=(1980, 1, 1, 0, 0, 0),
            )
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(
                info,
                path.read_bytes(),
                compress_type=zipfile.ZIP_DEFLATED,
                compresslevel=9,
            )
    return sha256(archive_path)


def write_archive(staging: Path) -> tuple[Path, str]:
    archive_path = staging / ARCHIVE_NAME
    checksum = build_archive(staging, archive_path)
    verification_path = staging.parent / f".{ARCHIVE_NAME}.verification"
    try:
        verification_checksum = build_archive(staging, verification_path)
    finally:
        verification_path.unlink(missing_ok=True)
    if verification_checksum != checksum:
        raise ValueError(
            "Deterministic archive verification failed: "
            f"{checksum} != {verification_checksum}"
        )
    (staging / f"{ARCHIVE_NAME}.sha256").write_text(
        f"{checksum}  {ARCHIVE_NAME}\n",
        encoding="ascii",
    )
    return archive_path, checksum


def portable_voice(voice: dict[str, Any]) -> dict[str, Any]:
    metadata = dict(voice.get("catalogMetadata") or voice.get("metadata") or {})
    return {
        "id": voice.get("id") or voice.get("blind_id"),
        "displayName": voice.get("displayName") or voice.get("blind_name"),
        "voiceId": voice.get("voiceId") or voice.get("voice_id"),
        "providerName": voice.get("providerName") or voice.get("name"),
        "gender": voice.get("gender"),
        "stockVoice": True,
        "catalogMetadata": {
            key: metadata.get(key)
            for key in (
                "id",
                "name",
                "description",
                "gender",
                "language",
                "is_owner",
                "created_at",
            )
            if key in metadata
        },
    }


def portable_ogg_name(source_name: str) -> str:
    suffix = "-take-1.ogg"
    if not source_name.endswith(suffix):
        raise ValueError(f"Unexpected Cartesia full-pack OGG name: {source_name}")
    return source_name[: -len(suffix)] + ".ogg"


def portable_sample(sample: dict[str, Any], relative_ogg: str) -> dict[str, Any]:
    return {
        "outputKey": sample["outputKey"],
        "speakerId": sample["speakerId"],
        "speakerName": sample["speakerName"],
        "voiceId": sample["voiceId"],
        "voiceDisplayName": sample["voiceDisplayName"],
        "gender": sample["gender"],
        "stockVoice": sample["stockVoice"],
        "phraseId": sample["phraseId"],
        "displayText": sample["displayText"],
        "spokenText": sample["spokenText"],
        "generationSeconds": sample.get("generationSeconds"),
        "generationUtc": sample.get("generationUtc"),
        "requestFingerprint": sample["requestFingerprint"],
        "requestBodyVoiceIndependent": sample["requestBodyWithoutVoice"],
        "responseRequestId": sample.get("responseRequestId"),
        "providerOriginal": portable_audio_info(sample["providerOriginal"]),
        "tempo": sample["tempo"],
        "ogg": portable_audio_info(sample["ogg"], relative_ogg),
        "mastering": sample["mastering"],
    }


def make_portable_report(
    manifest: dict[str, Any],
    run_report: dict[str, Any],
    samples: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "createdUtc": run_report.get("createdUtc"),
        "sourceManifest": MANIFEST_NAME,
        "pack": manifest.get("pack"),
        "provider": "Cartesia",
        "scope": "full",
        "model": run_report.get("model"),
        "api": {
            key: value
            for key, value in run_report.get("api", {}).items()
            if key != "authenticationOrder"
        },
        "language": run_report.get("language"),
        "locale": run_report.get("locale"),
        "accountTier": ACCOUNT_TIER_DESCRIPTION,
        "termsVerifiedUtc": TERMS_VERIFIED_DATE,
        "voices": [portable_voice(voice) for voice in manifest["voices"]],
        "generation": run_report.get("generationConfig"),
        "providerOutputFormat": run_report.get("outputFormat"),
        "mastering": run_report.get("mastering"),
        "environment": portable_environment(),
        "samples": sorted(samples, key=lambda item: item["outputKey"]),
    }


def write_validation_summary(
    destination: Path,
    portable_report: dict[str, Any],
) -> None:
    samples = portable_report["samples"]
    accelerated = [sample for sample in samples if float(sample["tempo"]) > 1.0]
    maximum_duration = max(float(sample["ogg"]["durationSeconds"]) for sample in samples)
    maximum_tempo = max(float(sample["tempo"]) for sample in samples)
    lines = [
        "# Cartesia Voice Review Validation",
        "",
        "- Validation: PASS",
        "- Provider: Cartesia",
        "- Model: `sonic-3.6`",
        "- API version: `2026-08-14`",
        "- Voices: 2",
        "- Callouts per voice: 77",
        f"- Mastered OGG files: {len(samples)}",
        f"- Maximum mastered duration: {maximum_duration:.6f} seconds",
        f"- Accelerated clips: {len(accelerated)}",
        f"- Maximum mastering tempo: {maximum_tempo:.6f}x",
        "- Duration policy: clips already within one second remain at natural tempo",
        f"- Redistribution terms verified by user: {TERMS_VERIFIED_DATE}",
        "",
        "## Stock Voices",
        "",
        "| Faction | Provider voice | Gender | Voice ID |",
        "| --- | --- | --- | --- |",
    ]
    for voice in portable_report["voices"]:
        lines.append(
            f"| {voice['displayName']} | {voice['providerName']} | {voice['gender']} | "
            f"`{voice['voiceId']}` |"
        )
    lines.extend(
        [
            "",
            "## Mastered Clips",
            "",
            "| Voice | Callout | Duration | Tempo | SHA-256 |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for sample in samples:
        lines.append(
            f"| {sample['speakerName']} | {sample['displayText']} | "
            f"{sample['ogg']['durationSeconds']:.3f}s | {sample['tempo']:.6g}x | "
            f"`{sample['ogg']['sha256']}` |"
        )
    destination.write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def write_readme(destination: Path) -> None:
    destination.write_text(
        "\n".join(
            [
                "# Alliance and Horde Cartesia Voice Review",
                "",
                "This portable review pack contains 77 arena callouts for each of two",
                "faction-flavored stock voices, for 154 mastered OGG files total.",
                "",
                "- Alliance: Gemma, Cartesia stock feminine voice",
                "- Horde: Archie, Cartesia stock masculine voice",
                "- Model: Cartesia `sonic-3.6`, API version `2026-08-14`",
                "",
                "Open `listening/index.html` in a browser to compare both voices by ability.",
                "No API key, Python environment, or provider access is required for listening.",
                "",
                "Every mastered clip is at most 1.0 seconds. Clips already within one second",
                "remain at natural speed; only longer clips receive the minimum tempo increase",
                "required to satisfy the cap.",
                "",
                "The generated OGG files were committed on 2026-10-01 under a user-confirmed",
                "eligible Cartesia tier; the exact tier name was not recorded.",
                "",
                "The files under `ogg/` are review assets only. They are not wired into the addon",
                "runtime or included in the published addon package.",
                "",
                "See `reports/validation-summary.md` for human-readable hashes and durations, and",
                "`reports/review-run.json` for portable provider, voice, request, tempo, and",
                "mastering provenance.",
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )


def scan_portability(staging: Path) -> None:
    for path in staging.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        content = path.read_text(encoding="utf-8").casefold()
        for value in FORBIDDEN_TEXT:
            if value in content:
                raise ValueError(
                    f"Portable file contains forbidden value {value!r}: {path}"
                )


def validate_staging(staging: Path, portable_report: dict[str, Any]) -> None:
    samples = portable_report["samples"]
    ogg_files = sorted((staging / "ogg").glob("*.ogg"))
    if len(samples) != EXPECTED_SAMPLE_COUNT or len(ogg_files) != EXPECTED_SAMPLE_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_SAMPLE_COUNT} samples/OGGs; "
            f"found {len(samples)}/{len(ogg_files)}"
        )
    output_keys = [str(sample["outputKey"]) for sample in samples]
    ogg_names = [Path(sample["ogg"]["path"]).name for sample in samples]
    if len(set(output_keys)) != EXPECTED_SAMPLE_COUNT:
        raise ValueError("Portable report contains duplicate output keys")
    if len(set(ogg_names)) != EXPECTED_SAMPLE_COUNT:
        raise ValueError("Portable report contains duplicate OGG names")

    fingerprints: dict[str, set[str]] = {}
    accelerated = 0
    for sample in samples:
        path = staging / sample["ogg"]["path"]
        if not path.is_file():
            raise FileNotFoundError(f"Staged OGG is missing: {path}")
        if sha256(path) != sample["ogg"]["sha256"]:
            raise ValueError(f"Staged OGG hash mismatch: {path}")
        probed = inspect_audio(path)
        if int(probed["channels"]) != 1:
            raise ValueError(f"Staged OGG must be mono: {path}")
        if float(probed["durationSeconds"]) <= 0 or float(probed["durationSeconds"]) > 1.0:
            raise ValueError(f"Staged OGG duration is invalid: {path}")
        if abs(
            float(probed["durationSeconds"])
            - float(sample["ogg"]["durationSeconds"])
        ) > 0.001:
            raise ValueError(f"Staged OGG duration drifted: {path}")
        mastering = sample.get("mastering")
        if not isinstance(mastering, dict):
            raise ValueError(f"Missing mastering data: {path}")
        if float(mastering["finalPass"]["output_tp"]) > -1.4:
            raise ValueError(f"Staged OGG exceeds true-peak tolerance: {path}")
        tempo = float(sample["tempo"])
        if tempo < 1.0:
            raise ValueError(f"Staged OGG has invalid tempo: {path}")
        if tempo > 1.0:
            accelerated += 1
            if float(sample["providerOriginal"]["durationSeconds"]) <= 1.0:
                raise ValueError(f"Short provider clip was unnecessarily accelerated: {path}")
        fingerprints.setdefault(str(sample["phraseId"]), set()).add(
            str(sample["requestFingerprint"])
        )
    if accelerated != EXPECTED_ACCELERATED_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_ACCELERATED_COUNT} accelerated clips, found {accelerated}"
        )
    for phrase_id, values in fingerprints.items():
        if len(values) != 1 or "" in values:
            raise ValueError(
                f"Voice-independent Cartesia requests differ for phrase {phrase_id}"
            )

    listening_page = staging / "listening" / "index.html"
    text = listening_page.read_text(encoding="utf-8")
    audio_sources = re.findall(r'<audio[^>]+src="([^"]+)"', text)
    if len(audio_sources) != EXPECTED_SAMPLE_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_SAMPLE_COUNT} listening-page players, "
            f"found {len(audio_sources)}"
        )
    if "raw-wav" in text or "provider-original" in text or ".wav" in text or "/Users/" in text:
        raise ValueError("Portable listening page contains a provider/local WAV link")
    for source in audio_sources:
        if not source.startswith("../ogg/"):
            raise ValueError(f"Listening-page link is not a relative OGG path: {source}")
        if not (listening_page.parent / source).resolve().is_file():
            raise ValueError(f"Listening-page audio link is broken: {source}")

    for forbidden_directory in ("references", "provider-original", "raw-wav"):
        if (staging / forbidden_directory).exists():
            raise ValueError(f"Forbidden portable directory exists: {forbidden_directory}")
    scan_portability(staging)


def build_staging(scratch: Path, staging: Path) -> tuple[int, Path, str]:
    manifest_path = WORKBENCH / MANIFEST_NAME
    run_report_path = scratch / "reports" / "cartesia-run.json"
    listening_page_path = scratch / "listening" / "index.html"
    validator_path = WORKBENCH / "validate-cartesia-samples.py"
    for required in (manifest_path, run_report_path, listening_page_path, validator_path):
        if not required.is_file():
            raise FileNotFoundError(f"Required review input is missing: {required}")

    subprocess.run(
        [
            sys.executable,
            str(validator_path),
            "--manifest",
            str(manifest_path),
            "--run-report",
            str(run_report_path),
        ],
        check=True,
    )
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    run_report = json.loads(run_report_path.read_text(encoding="utf-8"))
    samples = run_report.get("samples", [])
    expected_count = len(manifest["voices"]) * len(manifest["phrases"])
    if expected_count != EXPECTED_SAMPLE_COUNT or len(samples) != EXPECTED_SAMPLE_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_SAMPLE_COUNT} source samples, found {len(samples)}"
        )

    ogg_destination = staging / "ogg"
    listening_destination = staging / "listening"
    reports_destination = staging / "reports"
    for path in (ogg_destination, listening_destination, reports_destination):
        path.mkdir(parents=True, exist_ok=True)

    portable_samples: list[dict[str, Any]] = []
    seen_names: set[str] = set()
    for sample in samples:
        source = require_under(Path(sample["ogg"]["path"]), scratch)
        destination_name = portable_ogg_name(source.name)
        if destination_name in seen_names:
            raise ValueError(f"Duplicate portable OGG filename: {destination_name}")
        seen_names.add(destination_name)
        actual_hash = sha256(source)
        if actual_hash != sample["ogg"]["sha256"]:
            raise ValueError(f"Source OGG hash mismatch: {source}")
        destination = ogg_destination / destination_name
        shutil.copy2(source, destination)
        portable_samples.append(
            portable_sample(sample, f"ogg/{destination_name}")
        )

    shutil.copy2(manifest_path, staging / MANIFEST_NAME)
    listening_page = listening_page_path.read_text(encoding="utf-8")
    listening_page = listening_page.replace("-take-1.ogg", ".ogg")
    (listening_destination / "index.html").write_text(
        listening_page,
        encoding="utf-8",
        newline="\n",
    )

    portable_report = make_portable_report(manifest, run_report, portable_samples)
    (reports_destination / "review-run.json").write_text(
        json.dumps(portable_report, indent=2) + "\n",
        encoding="utf-8",
    )
    write_validation_summary(
        reports_destination / "validation-summary.md",
        portable_report,
    )
    write_readme(staging / "README.md")

    validate_staging(staging, portable_report)
    archive_path, checksum = write_archive(staging)
    validate_staging(staging, portable_report)
    staged_file_count = len([path for path in staging.rglob("*") if path.is_file()])
    expected_staged_count = EXPECTED_SAMPLE_COUNT + 7
    if staged_file_count != expected_staged_count:
        raise ValueError(
            f"Staged pack must contain exactly {expected_staged_count} files; "
            f"found {staged_file_count}"
        )
    with zipfile.ZipFile(archive_path) as archive:
        if len(archive.namelist()) != EXPECTED_SAMPLE_COUNT + 5:
            raise ValueError("Deterministic archive has an unexpected file count")
    return len(portable_samples), archive_path, checksum


def replace_destination(staging: Path, destination: Path) -> None:
    backup = destination.parent / f".{destination.name}.backup"
    if backup.exists():
        shutil.rmtree(backup)
    if destination.exists():
        destination.rename(backup)
    try:
        staging.rename(destination)
    except Exception:
        if backup.exists() and not destination.exists():
            backup.rename(destination)
        raise
    if backup.exists():
        shutil.rmtree(backup)


def main() -> int:
    args = parse_args()
    scratch = args.scratch.resolve()
    destination = args.destination.resolve()
    if destination.name != EXPECTED_DESTINATION_NAME:
        raise ValueError(
            "Refusing to replace unexpected destination; expected directory name "
            f"{EXPECTED_DESTINATION_NAME!r}: {destination}"
        )
    destination.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(
        tempfile.mkdtemp(
            prefix=f".{destination.name}.staging-",
            dir=destination.parent,
        )
    )
    try:
        sample_count, archive_path, checksum = build_staging(scratch, staging)
        archive_name = archive_path.name
        replace_destination(staging, destination)
    except Exception:
        if staging.exists():
            shutil.rmtree(staging)
        raise

    print(f"Review directory: {destination}")
    print(f"Mastered OGG files: {sample_count}")
    print("Stock voices: Gemma (Alliance), Archie (Horde)")
    print(f"Archive: {destination / archive_name}")
    print(f"SHA256: {checksum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
