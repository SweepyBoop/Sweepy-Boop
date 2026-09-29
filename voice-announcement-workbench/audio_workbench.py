"""Shared audio processing and review-page helpers for voice experiments."""

from __future__ import annotations

import hashlib
import html
import json
import math
import os
import subprocess
from pathlib import Path
from typing import Any, Callable


def run(command: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=True,
        text=True,
        capture_output=capture,
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def inspect_audio(path: Path) -> dict[str, Any]:
    import numpy as np
    import soundfile as sf

    info = sf.info(path)
    samples, sample_rate = sf.read(path, dtype="float32", always_2d=True)
    peak = float(np.max(np.abs(samples))) if samples.size else 0.0
    peak_dbfs = 20.0 * float(np.log10(peak)) if peak > 0 else float("-inf")
    return {
        "path": str(path),
        "sha256": sha256(path),
        "sampleRate": sample_rate,
        "channels": info.channels,
        "frames": info.frames,
        "durationSeconds": round(info.duration, 6),
        "samplePeakDbfs": round(peak_dbfs, 4) if peak > 0 else None,
        "format": info.format,
        "subtype": info.subtype,
    }


def extract_loudnorm_json(stderr: str) -> dict[str, Any]:
    import re

    candidates = re.findall(r'\{\s*"input_i"[\s\S]*?\}', stderr)
    if not candidates:
        raise RuntimeError(f"Could not find loudnorm measurements in ffmpeg output:\n{stderr}")
    return json.loads(candidates[-1])


def loudnorm_filter(manifest: dict[str, Any], measured: dict[str, Any] | None = None) -> str:
    settings = manifest["mastering"]
    trim = (
        "silenceremove="
        f"start_periods=1:start_duration={settings['leadingSilenceSeconds']}:"
        f"start_threshold={settings['silenceThresholdDb']}dB,"
        "areverse,"
        "silenceremove="
        f"start_periods=1:start_duration={settings['trailingSilenceSeconds']}:"
        f"start_threshold={settings['silenceThresholdDb']}dB,"
        "areverse"
    )
    tempo = f"atempo={float(settings.get('tempo', 1.0))}"
    normalize = (
        "loudnorm="
        f"I={settings['integratedLufs']}:"
        f"LRA={settings['loudnessRange']}:"
        f"TP={settings['truePeakDb']}"
    )
    if measured:
        normalize += (
            f":measured_I={measured['input_i']}"
            f":measured_LRA={measured['input_lra']}"
            f":measured_TP={measured['input_tp']}"
            f":measured_thresh={measured['input_thresh']}"
            f":offset={measured['target_offset']}"
            ":linear=true"
        )
    return f"{trim},{tempo},{normalize}:print_format=json"


def master_audio(
    ffmpeg: Path,
    raw_path: Path,
    ogg_path: Path,
    manifest: dict[str, Any],
) -> dict[str, Any]:
    import soundfile as sf

    raw_info = sf.info(raw_path)
    first_pass = run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-i",
            str(raw_path),
            "-af",
            loudnorm_filter(manifest),
            "-f",
            "null",
            os.devnull,
        ],
        capture=True,
    )
    measured = extract_loudnorm_json(first_pass.stderr)
    measurement_fields = ("input_i", "input_lra", "input_tp", "input_thresh", "target_offset")
    has_finite_measurements = all(
        math.isfinite(float(measured[field])) for field in measurement_fields
    )
    # Very short clips may not have an integrated loudness measurement.
    normalization_mode = "two-pass" if has_finite_measurements else "short-clip-dynamic"
    final_filter = loudnorm_filter(manifest, measured if has_finite_measurements else None)

    ogg_path.parent.mkdir(parents=True, exist_ok=True)
    second_pass = run(
        [
            str(ffmpeg),
            "-hide_banner",
            "-nostats",
            "-y",
            "-i",
            str(raw_path),
            "-af",
            final_filter,
            "-ac",
            "1",
            "-ar",
            str(raw_info.samplerate),
            "-c:a",
            "libvorbis",
            "-q:a",
            str(manifest["mastering"]["vorbisQuality"]),
            str(ogg_path),
        ],
        capture=True,
    )
    final_measurement = extract_loudnorm_json(second_pass.stderr)
    return {
        "mode": normalization_mode,
        "firstPass": measured,
        "finalPass": final_measurement,
    }


def write_listening_page(
    samples: list[dict[str, Any]],
    output_path: Path,
    manifest: dict[str, Any],
    *,
    model_label: str | None = None,
    audio_path: Callable[[dict[str, Any]], str] | None = None,
) -> None:
    by_phrase: dict[str, dict[str, dict[str, Any]]] = {}
    for sample in samples:
        by_phrase.setdefault(sample["phraseId"], {})[sample["speakerId"]] = sample

    speakers = manifest["speakers"]
    speaker_ids = [speaker["id"] for speaker in speakers]
    speaker_names = {
        speaker["id"]: speaker.get("displayName") or speaker.get("qwenName") or speaker["id"]
        for speaker in speakers
    }
    spec_names = {int(spec["id"]): spec["name"] for spec in manifest.get("specs", [])}
    resolve_audio_path = audio_path or (
        lambda sample: f"../ogg/{Path(sample['ogg']['path']).name}"
    )

    rows: list[str] = []
    for phrase in manifest["phrases"]:
        phrase_id = phrase["id"]
        details: list[str] = []
        if phrase.get("category"):
            details.append(str(phrase["category"]).title())
        if phrase.get("spellIds"):
            details.append("Spell IDs " + ", ".join(str(value) for value in phrase["spellIds"]))
        if phrase.get("specIds"):
            details.append(
                "Specs "
                + ", ".join(
                    html.escape(spec_names.get(int(spec_id), str(spec_id)))
                    for spec_id in phrase["specIds"]
                )
            )
        detail_html = f'<p class="phrase-details">{" | ".join(details)}</p>' if details else ""
        cells: list[str] = []
        for speaker_id in speaker_ids:
            sample = by_phrase.get(phrase_id, {}).get(speaker_id)
            if not sample:
                cells.append('<div class="sample missing">Not generated</div>')
                continue
            source = html.escape(resolve_audio_path(sample))
            duration = sample["ogg"]["durationSeconds"]
            raw_link = ""
            if sample.get("rawWav"):
                wav_name = html.escape(Path(sample["rawWav"]["path"]).name)
                raw_link = f'<a href="../raw-wav/{wav_name}">Raw WAV</a>'
            cells.append(
                '<div class="sample">'
                f'<audio controls preload="metadata" src="{source}"></audio>'
                f'<div class="meta">{duration:.2f}s mastered OGG</div>'
                f"{raw_link}"
                "</div>"
            )
        rows.append(
            '<section class="phrase">'
            f'<h2>{html.escape(str(phrase["displayText"]))}</h2>'
            f"{detail_html}"
            '<div class="comparison">'
            + "".join(
                f'<article><h3>{html.escape(str(speaker_names[speaker_id]))}</h3>{cells[index]}</article>'
                for index, speaker_id in enumerate(speaker_ids)
            )
            + "</div></section>"
        )

    if model_label is None:
        model_label = manifest["model"]["repository"]
    model = html.escape(model_label)
    speaker_summary = html.escape(
        ", ".join(str(speaker_names[speaker_id]) for speaker_id in speaker_ids)
    )
    pack_description = html.escape(
        str((manifest.get("pack") or {}).get("description") or "Arena callout voice comparison.")
    )
    revision_values = [
        model_spec["revision"][:12]
        for key in ("model", "voiceDesignModel", "cloneModel")
        if (model_spec := manifest.get(key))
    ]
    revisions = html.escape(", ".join(revision_values))
    document = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SweepyBoop Voice Comparison</title>
<style>
:root {{ --ink: #172126; --muted: #5f6c70; --paper: #f4f7f5; --line: #b9c6c2; --accent: #b12f26; --panel: #ffffff; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; color: var(--ink); background: repeating-linear-gradient(135deg, #edf2ef 0, #edf2ef 18px, #e8eeeb 18px, #e8eeeb 36px); font-family: Bahnschrift, "Trebuchet MS", sans-serif; }}
main {{ width: min(980px, calc(100% - 32px)); margin: 36px auto 64px; background: var(--paper); border-top: 7px solid var(--accent); box-shadow: 0 18px 50px rgba(21, 40, 36, .16); }}
header {{ padding: 30px 34px 24px; border-bottom: 1px solid var(--line); }}
h1 {{ margin: 0 0 8px; font: 700 34px/1.1 "Palatino Linotype", Georgia, serif; }}
header p {{ margin: 0; color: var(--muted); line-height: 1.5; }}
.phrase {{ padding: 24px 34px 28px; border-bottom: 1px solid var(--line); }}
h2 {{ margin: 0 0 6px; font-size: 20px; }}
.phrase-details {{ margin: 0 0 16px; color: var(--muted); font-size: 12px; line-height: 1.45; }}
.comparison {{ display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 26px; }}
article {{ min-width: 0; }}
h3 {{ margin: 0 0 8px; color: var(--accent); font-size: 14px; text-transform: uppercase; }}
a {{ color: #225b54; }}
audio {{ display: block; width: 100%; }}
.meta {{ margin: 8px 0 4px; color: var(--muted); font-size: 12px; }}
.missing {{ color: var(--muted); }}
footer {{ padding: 20px 34px; color: var(--muted); font-size: 12px; line-height: 1.5; }}
@media (max-width: 650px) {{ .comparison {{ grid-template-columns: 1fr; }} main {{ width: min(100% - 18px, 980px); margin-top: 12px; }} header, .phrase, footer {{ padding-left: 20px; padding-right: 20px; }} }}
</style>
</head>
<body>
<main>
<header>
<h1>Arena Callout Voice Study</h1>
<p>{pack_description}</p>
<p>Compare {speaker_summary} using mastered OGG files.</p>
</header>
{"".join(rows)}
<footer>Model: {model}<br>Revision: {revisions}<br>Mastering target: -16 LUFS, -1.5 dBTP, mono OGG Vorbis.</footer>
</main>
</body>
</html>
"""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(document, encoding="utf-8", newline="\n")
