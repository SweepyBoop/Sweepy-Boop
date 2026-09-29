#!/usr/bin/env python3
"""Export the approved faction voices as a portable source-controlled review pack."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
REPOSITORY = WORKBENCH.parent
DEFAULT_SCRATCH = WORKBENCH / "scratch" / "faction-voices"
DEFAULT_DESTINATION = REPOSITORY / "Docs" / "VoiceAnnouncementReview-KeyAbilities"
EXPECTED_DESTINATION_NAME = "VoiceAnnouncementReview-KeyAbilities"
ARCHIVE_NAME = "alliance-horde-faction-voices-1.0s.zip"
EXPECTED_REFERENCES = {
    "alliance-commander": "DCB7499F00A62577615FBB2DE32DC156BFCC56A13ECF1B5068BFC6F56C316519",
    "horde-commander": "50E52EB550990CAA497B2DF10C040297989F6990C2A5BE8143973DE733C886FB",
}


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


def sanitized_environment(run_report: dict[str, Any]) -> dict[str, Any]:
    environment = run_report.get("environment", {})
    ffmpeg = environment.get("ffmpeg", {})
    python = str(environment.get("python") or "").splitlines()[0]
    return {
        "platform": environment.get("platform"),
        "python": python,
        "packages": environment.get("packages"),
        "execution": environment.get("execution"),
        "cuda": environment.get("cuda"),
        "mps": environment.get("mps"),
        "ffmpeg": {
            "version": ffmpeg.get("version"),
            "libvorbis": ffmpeg.get("libvorbis"),
        },
    }


def write_archive(staging: Path) -> tuple[Path, str]:
    archive_path = staging / ARCHIVE_NAME
    with zipfile.ZipFile(archive_path, "w") as archive:
        for path in sorted(staging.rglob("*")):
            if not path.is_file() or path == archive_path:
                continue
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
    checksum = sha256(archive_path)
    (staging / f"{ARCHIVE_NAME}.sha256").write_text(
        f"{checksum}  {ARCHIVE_NAME}\n",
        encoding="ascii",
    )
    return archive_path, checksum


def validate_staging(staging: Path, portable_report: dict[str, Any]) -> None:
    ogg_files = sorted((staging / "ogg").glob("*.ogg"))
    reference_files = sorted((staging / "references").glob("*.wav"))
    if len(ogg_files) != 20:
        raise ValueError(f"Expected 20 staged OGG files, found {len(ogg_files)}")
    if len(reference_files) != 2:
        raise ValueError(f"Expected 2 staged references, found {len(reference_files)}")
    if len(portable_report.get("samples", [])) != 20:
        raise ValueError("Portable report must contain exactly 20 samples")

    for sample in portable_report["samples"]:
        path = staging / sample["ogg"]["path"]
        if sha256(path) != sample["ogg"]["sha256"]:
            raise ValueError(f"Staged OGG hash mismatch: {path}")
        if float(sample["ogg"]["durationSeconds"]) > 1.0:
            raise ValueError(f"Staged OGG exceeds one second: {path}")
    for reference in portable_report["references"]:
        path = staging / reference["audio"]["path"]
        if sha256(path) != reference["audio"]["sha256"]:
            raise ValueError(f"Staged reference hash mismatch: {path}")

    listening_page = staging / "listening" / "index.html"
    text = listening_page.read_text(encoding="utf-8")
    if "raw-wav" in text or "/Users/" in text:
        raise ValueError("Portable listening page contains a working-directory link")
    for match in re.findall(r'<audio[^>]+src="([^"]+)"', text):
        if not (listening_page.parent / match).resolve().is_file():
            raise ValueError(f"Listening-page audio link is broken: {match}")

    forbidden = ("/Users/", "scratch/faction-voices", "scratch/models")
    for path in staging.rglob("*"):
        if path.suffix.lower() not in {".md", ".json", ".html", ".sha256"}:
            continue
        content = path.read_text(encoding="utf-8")
        for value in forbidden:
            if value in content:
                raise ValueError(f"Portable file contains non-portable path {value!r}: {path}")


def build_staging(
    scratch: Path,
    destination: Path,
    staging: Path,
) -> tuple[int, Path, str]:
    manifest_path = WORKBENCH / "faction-voice-manifest.json"
    run_report_path = scratch / "reports" / "faction-voice-run.json"
    listening_page_path = scratch / "listening" / "index.html"
    validator_path = WORKBENCH / "validate-faction-voices.py"
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
    expected_count = len(manifest["speakers"]) * len(manifest["phrases"])
    if expected_count != 20 or len(samples) != expected_count:
        raise ValueError(f"Expected 20 samples, found {len(samples)}")

    ogg_destination = staging / "ogg"
    reference_destination = staging / "references"
    listening_destination = staging / "listening"
    reports_destination = staging / "reports"
    for path in (
        ogg_destination,
        reference_destination,
        listening_destination,
        reports_destination,
    ):
        path.mkdir(parents=True, exist_ok=True)

    portable_references: list[dict[str, Any]] = []
    actual_reference_ids: set[str] = set()
    for reference in run_report.get("references", []):
        speaker_id = str(reference["speakerId"])
        if speaker_id not in EXPECTED_REFERENCES:
            raise ValueError(f"Unexpected reference speaker: {speaker_id}")
        source = require_under(Path(reference["audio"]["path"]), scratch)
        actual_hash = sha256(source)
        if actual_hash != EXPECTED_REFERENCES[speaker_id]:
            raise ValueError(
                f"Reference {speaker_id} does not match the approved hash: {actual_hash}"
            )
        filename = f"{speaker_id}.wav"
        shutil.copy2(source, reference_destination / filename)
        portable_references.append(
            {
                "speakerId": speaker_id,
                "speakerName": reference["speakerName"],
                "description": reference["description"],
                "designInstruction": reference["designInstruction"],
                "designInstructionSha256": reference["designInstructionSha256"],
                "referenceText": reference["referenceText"],
                "referenceTextSha256": reference["referenceTextSha256"],
                "designSeed": reference["designSeed"],
                "audio": portable_audio_info(reference["audio"], f"references/{filename}"),
            }
        )
        actual_reference_ids.add(speaker_id)
    if actual_reference_ids != set(EXPECTED_REFERENCES):
        raise ValueError(f"References must be exactly {sorted(EXPECTED_REFERENCES)}")

    portable_samples: list[dict[str, Any]] = []
    seen_ogg_names: set[str] = set()
    for sample in samples:
        source_ogg = require_under(Path(sample["ogg"]["path"]), scratch)
        if source_ogg.name in seen_ogg_names:
            raise ValueError(f"Duplicate OGG filename: {source_ogg.name}")
        seen_ogg_names.add(source_ogg.name)
        destination_ogg = ogg_destination / source_ogg.name
        shutil.copy2(source_ogg, destination_ogg)
        portable_samples.append(
            {
                "outputKey": sample["outputKey"],
                "speakerId": sample["speakerId"],
                "speakerName": sample["speakerName"],
                "phraseId": sample["phraseId"],
                "displayText": sample["displayText"],
                "spokenText": sample["spokenText"],
                "synthesisText": sample["synthesisText"],
                "generatedText": sample["generatedText"],
                "seed": sample["seed"],
                "referenceSha256": sample["referenceSha256"],
                "generationSeconds": sample.get("generationSeconds"),
                "sourcePaddedAudio": portable_audio_info(sample["paddedWav"]),
                "sourceCroppedAudio": portable_audio_info(sample["rawWav"]),
                "preprocessing": sample["preprocessing"],
                "tempo": sample["tempo"],
                "ogg": portable_audio_info(sample["ogg"], f"ogg/{source_ogg.name}"),
                "mastering": sample["mastering"],
            }
        )

    shutil.copy2(manifest_path, staging / manifest_path.name)
    listening_page = listening_page_path.read_text(encoding="utf-8")
    listening_page = re.sub(
        r'<a href="\.\./raw-wav/[^"]+">Raw WAV</a>',
        "",
        listening_page,
    )
    (listening_destination / "index.html").write_text(
        listening_page,
        encoding="utf-8",
        newline="\n",
    )

    portable_report = {
        "createdUtc": run_report.get("createdUtc"),
        "sourceManifest": "faction-voice-manifest.json",
        "pack": run_report.get("pack"),
        "voiceDesignModel": run_report.get("voiceDesignModel"),
        "cloneModel": run_report.get("cloneModel"),
        "locale": run_report.get("locale"),
        "language": run_report.get("language"),
        "generation": run_report.get("generation"),
        "mastering": run_report.get("mastering"),
        "tempoOverrides": run_report.get("tempoOverrides"),
        "environment": sanitized_environment(run_report),
        "references": sorted(portable_references, key=lambda item: item["speakerId"]),
        "samples": sorted(portable_samples, key=lambda item: item["outputKey"]),
    }
    portable_report_path = reports_destination / "review-run.json"
    portable_report_path.write_text(
        json.dumps(portable_report, indent=2) + "\n",
        encoding="utf-8",
    )

    summary_lines = [
        "# Faction Voice Review Validation",
        "",
        "- Validation: PASS",
        "- Voices: 2",
        "- Callouts per voice: 10",
        "- Mastered OGG files: 20",
        "- Maximum mastered duration: 1.0 seconds",
        "- Generation: frozen VoiceDesign references with Base speaker embeddings",
        "- Onset handling: disposable `Ready.` prefix removed at a validated silence boundary",
        "",
        "## Frozen References",
        "",
        "| Voice | SHA-256 | Duration |",
        "| --- | --- | --- |",
    ]
    for reference in portable_report["references"]:
        audio = reference["audio"]
        summary_lines.append(
            f"| {reference['speakerName']} | `{audio['sha256']}` | "
            f"{audio['durationSeconds']:.3f}s |"
        )
    summary_lines.extend(
        [
            "",
            "## Mastered Clips",
            "",
            "| Voice | Callout | Duration | Tempo | Attempts | SHA-256 |",
            "| --- | --- | --- | --- | --- | --- |",
        ]
    )
    for sample in portable_report["samples"]:
        summary_lines.append(
            f"| {sample['speakerName']} | {sample['displayText']} | "
            f"{sample['ogg']['durationSeconds']:.3f}s | {sample['tempo']:.6g}x | "
            f"{sample['preprocessing']['attempt']} | `{sample['ogg']['sha256']}` |"
        )
    (reports_destination / "validation-summary.md").write_text(
        "\n".join(summary_lines) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    (staging / "README.md").write_text(
        "\n".join(
            [
                "# Alliance and Horde Commander Voice Review",
                "",
                "This portable review pack contains 10 arena callouts for each of two original",
                "faction-flavored voices, for 20 mastered OGG files total.",
                "",
                "Open `listening/index.html` in a browser to compare both voices by ability.",
                "No Python environment or model download is required for listening.",
                "",
                "The exact frozen VoiceDesign inputs used by the Base clone model are under",
                "`references/`. Keep them with the provenance report; regenerating from a seed",
                "alone is not guaranteed to preserve voice identity across devices.",
                "",
                "Every mastered clip is at most 1.0 seconds. Generation uses a disposable spoken",
                "prefix that is removed at a validated silence boundary before mastering.",
                "",
                "The files under `ogg/` are review assets only. They are not wired into the addon",
                "runtime or included in the published addon package.",
                "",
                "See `reports/validation-summary.md` for human-readable hashes and durations, and",
                "`reports/review-run.json` for portable model, reference, generation, crop, seed,",
                "tempo, and mastering provenance.",
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )

    archive_path, checksum = write_archive(staging)
    validate_staging(staging, portable_report)
    if len([path for path in staging.rglob("*") if path.is_file()]) != 29:
        raise ValueError("Staged review pack must contain exactly 29 files")
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
            f"Refusing to replace unexpected destination; expected directory name "
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
        sample_count, archive_path, checksum = build_staging(
            scratch,
            destination,
            staging,
        )
        archive_name = archive_path.name
        replace_destination(staging, destination)
    except Exception:
        if staging.exists():
            shutil.rmtree(staging)
        raise

    print(f"Review directory: {destination}")
    print(f"Mastered OGG files: {sample_count}")
    print(f"Frozen references: {len(EXPECTED_REFERENCES)}")
    print(f"Archive: {destination / archive_name}")
    print(f"SHA256: {checksum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
