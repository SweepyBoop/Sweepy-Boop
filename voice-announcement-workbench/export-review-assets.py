#!/usr/bin/env python3
"""Export a portable, source-controlled review copy of the key-ability audio."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
REPOSITORY = WORKBENCH.parent
DEFAULT_SCRATCH = WORKBENCH / "scratch" / "key-abilities"
DEFAULT_DESTINATION = REPOSITORY / "Docs" / "VoiceAnnouncementReview-KeyAbilities"
EXPECTED_DESTINATION_NAME = "VoiceAnnouncementReview-KeyAbilities"


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


def portable_audio_info(info: dict[str, Any], relative_path: str | None = None) -> dict[str, Any]:
    result = {key: value for key, value in info.items() if key != "path"}
    if relative_path is not None:
        result["path"] = relative_path
    return result


def main() -> int:
    args = parse_args()
    scratch = args.scratch.resolve()
    destination = args.destination.resolve()
    if destination.name != EXPECTED_DESTINATION_NAME:
        raise ValueError(
            f"Refusing to replace unexpected destination; expected directory name "
            f"{EXPECTED_DESTINATION_NAME!r}: {destination}"
        )

    manifest_path = WORKBENCH / "key-abilities-manifest.json"
    coverage_path = scratch / "reports" / "key-abilities-coverage.md"
    run_report_path = scratch / "reports" / "sample-run.json"
    listening_page_path = scratch / "listening" / "index.html"
    for required in (manifest_path, coverage_path, run_report_path, listening_page_path):
        if not required.is_file():
            raise FileNotFoundError(f"Required review input is missing: {required}")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    run_report = json.loads(run_report_path.read_text(encoding="utf-8"))
    samples = run_report.get("samples", [])
    expected_count = len(manifest["speakers"]) * len(manifest["phrases"])
    if len(samples) != expected_count:
        raise ValueError(f"Expected {expected_count} samples, found {len(samples)}")

    if destination.exists():
        shutil.rmtree(destination)
    ogg_destination = destination / "ogg"
    listening_destination = destination / "listening"
    reports_destination = destination / "reports"
    ogg_destination.mkdir(parents=True)
    listening_destination.mkdir()
    reports_destination.mkdir()

    portable_samples: list[dict[str, Any]] = []
    for sample in samples:
        source_ogg = Path(sample["ogg"]["path"])
        if not source_ogg.is_file():
            raise FileNotFoundError(f"Missing mastered audio for {sample['outputKey']}: {source_ogg}")
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
                "category": sample.get("category"),
                "spellIds": sample.get("spellIds", []),
                "specIds": sample.get("specIds", []),
                "seed": sample["seed"],
                "sourceRawWav": portable_audio_info(sample["rawWav"]),
                "ogg": portable_audio_info(sample["ogg"], f"ogg/{source_ogg.name}"),
                "mastering": sample.get("mastering"),
            }
        )

    shutil.copy2(manifest_path, destination / manifest_path.name)
    shutil.copy2(coverage_path, reports_destination / coverage_path.name)
    listening_page = listening_page_path.read_text(encoding="utf-8")
    listening_page = re.sub(
        r'<a href="\.\./raw-wav/[^"]+">Raw WAV</a>',
        "",
        listening_page,
    )
    (listening_destination / "index.html").write_text(
        listening_page, encoding="utf-8", newline="\n"
    )

    environment = run_report.get("environment", {})
    ffmpeg = environment.get("ffmpeg", {})
    portable_report = {
        "createdUtc": run_report.get("createdUtc"),
        "sourceManifest": "key-abilities-manifest.json",
        "model": run_report.get("model"),
        "locale": run_report.get("locale"),
        "language": run_report.get("language"),
        "instruction": run_report.get("instruction"),
        "mastering": run_report.get("mastering"),
        "environment": {
            "platform": environment.get("platform"),
            "python": environment.get("python"),
            "packages": environment.get("packages"),
            "execution": environment.get("execution"),
            "cuda": environment.get("cuda"),
            "mps": environment.get("mps"),
            "ffmpeg": {
                "version": ffmpeg.get("version"),
                "libvorbis": ffmpeg.get("libvorbis"),
            },
        },
        "samples": portable_samples,
    }
    portable_report_path = reports_destination / "review-run.json"
    portable_report_path.write_text(
        json.dumps(portable_report, indent=2) + "\n", encoding="utf-8"
    )

    readme_path = destination / "README.md"
    readme_path.write_text(
        "\n".join(
            [
                "# Aiden and Sohee Key Ability Review",
                "",
                "This is a portable review copy of the natural-speed arena key-ability pack.",
                "It contains 74 callouts for each voice, for 148 mastered OGG files total.",
                "",
                "Open `listening/index.html` in a browser to compare both voices by ability.",
                "No Python environment or model download is required for listening.",
                "",
                "The files under `ogg/` are review assets only. They are not wired into the addon",
                "runtime or included in the published addon package.",
                "",
                "See `reports/key-abilities-coverage.md` for per-spec selection and",
                "`reports/review-run.json` for portable hashes, durations, seeds, and mastering data.",
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )

    archive_path = destination / "aiden-sohee-key-abilities-1.0x.zip"
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(destination.rglob("*")):
            if path.is_file() and path != archive_path:
                archive.write(path, path.relative_to(destination).as_posix())

    checksum = sha256(archive_path)
    (destination / "aiden-sohee-key-abilities-1.0x.zip.sha256").write_text(
        f"{checksum}  {archive_path.name}\n", encoding="ascii"
    )

    print(f"Review directory: {destination}")
    print(f"Mastered OGG files: {len(portable_samples)}")
    print(f"Archive: {archive_path}")
    print(f"SHA256: {checksum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
