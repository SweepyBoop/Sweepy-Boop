#!/usr/bin/env python3
"""Generate and master the Qwen3-TTS voice comparison samples."""

from __future__ import annotations

import argparse
import hashlib
import html
import importlib.metadata
import json
import math
import os
import platform
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "sample-manifest.json"
DEFAULT_SCRATCH = WORKBENCH / "scratch"


@dataclass(frozen=True)
class SampleJob:
    speaker_id: str
    speaker_name: str
    speaker_description: str
    phrase_id: str
    display_text: str
    spoken_text: str
    category: str | None
    spell_ids: tuple[int, ...]
    spec_ids: tuple[int, ...]
    output_key: str
    seed: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--scratch", type=Path, default=DEFAULT_SCRATCH)
    parser.add_argument(
        "--model-cache",
        type=Path,
        help="Shared model-cache directory; defaults to <scratch>/models.",
    )
    parser.add_argument("--speaker", help="Generate one speaker by manifest id or Qwen name.")
    parser.add_argument("--phrase", help="Generate one phrase by manifest id.")
    parser.add_argument("--force", action="store_true", help="Regenerate existing WAV and OGG files.")
    parser.add_argument("--remaster", action="store_true", help="Rebuild OGG files from existing WAV files.")
    parser.add_argument("--verify-only", action="store_true", help="Verify the installed environment and exit.")
    return parser.parse_args()


def package_version(name: str) -> str | None:
    try:
        return importlib.metadata.version(name)
    except importlib.metadata.PackageNotFoundError:
        return None


def run(command: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=True,
        text=True,
        capture_output=capture,
    )


def environment_details(scratch: Path) -> dict[str, Any]:
    import imageio_ffmpeg
    import torch

    if package_version("qwen-tts") is None:
        raise RuntimeError("qwen-tts is not installed in the isolated environment.")

    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe()).resolve()
    if not ffmpeg.is_file():
        raise RuntimeError(f"Bundled ffmpeg executable is missing: {ffmpeg}")

    ffmpeg_version = run([str(ffmpeg), "-version"], capture=True).stdout.splitlines()[0]
    encoders = run([str(ffmpeg), "-hide_banner", "-encoders"], capture=True)
    encoder_output = encoders.stdout + encoders.stderr
    if "libvorbis" not in encoder_output:
        raise RuntimeError(f"Bundled ffmpeg does not provide the libvorbis encoder: {ffmpeg}")

    cuda_available = torch.cuda.is_available()
    details: dict[str, Any] = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "python": sys.version,
        "platform": platform.platform(),
        "packages": {
            "torch": package_version("torch"),
            "torchaudio": package_version("torchaudio"),
            "qwen-tts": package_version("qwen-tts"),
            "transformers": package_version("transformers"),
            "imageio-ffmpeg": package_version("imageio-ffmpeg"),
            "hf-xet": package_version("hf-xet"),
            "soundfile": package_version("soundfile"),
        },
        "ffmpeg": {
            "path": str(ffmpeg),
            "version": ffmpeg_version,
            "libvorbis": True,
        },
        "cuda": {
            "available": cuda_available,
            "torchCudaVersion": torch.version.cuda,
        },
    }

    if cuda_available:
        properties = torch.cuda.get_device_properties(0)
        details["cuda"].update(
            {
                "device": torch.cuda.get_device_name(0),
                "capability": list(torch.cuda.get_device_capability(0)),
                "totalMemoryBytes": properties.total_memory,
            }
        )

    reports = scratch / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    report_path = reports / "environment.json"
    report_path.write_text(json.dumps(details, indent=2) + "\n", encoding="utf-8")

    if not cuda_available:
        raise RuntimeError("CUDA is not available in the isolated PyTorch environment.")

    return details


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1:
        raise ValueError("sample-manifest.json must use schemaVersion 1.")

    model = manifest.get("model") or {}
    for key in ("repository", "revision", "dtype", "attentionImplementation"):
        if not isinstance(model.get(key), str) or not model[key]:
            raise ValueError(f"Manifest model.{key} must be a non-empty string.")

    mastering = manifest.get("mastering") or {}
    tempo = float(mastering.get("tempo", 1.0))
    if tempo < 0.5 or tempo > 2.0:
        raise ValueError("Manifest mastering.tempo must be between 0.5 and 2.0.")

    speakers = manifest.get("speakers")
    phrases = manifest.get("phrases")
    if not isinstance(speakers, list) or not speakers:
        raise ValueError("Manifest must contain at least one speaker.")
    if not isinstance(phrases, list) or not phrases:
        raise ValueError("Manifest must contain at least one phrase.")

    return manifest


def build_jobs(manifest: dict[str, Any], speaker_filter: str | None, phrase_filter: str | None) -> list[SampleJob]:
    jobs: list[SampleJob] = []
    seen: set[str] = set()
    base_seed = int(manifest["seed"])
    normalized_speaker_filter = speaker_filter.casefold() if speaker_filter else None
    normalized_phrase_filter = phrase_filter.casefold() if phrase_filter else None

    for speaker_index, speaker in enumerate(manifest["speakers"]):
        speaker_id = str(speaker["id"])
        speaker_name = str(speaker["qwenName"])
        if normalized_speaker_filter not in (None, speaker_id.casefold(), speaker_name.casefold()):
            continue

        spoken_text_overrides = speaker.get("spokenTextOverrides") or {}
        if not isinstance(spoken_text_overrides, dict):
            raise ValueError(f"Speaker {speaker_id} spokenTextOverrides must be an object.")
        seed_overrides = speaker.get("seedOverrides") or {}
        if not isinstance(seed_overrides, dict):
            raise ValueError(f"Speaker {speaker_id} seedOverrides must be an object.")

        for phrase_index, phrase in enumerate(manifest["phrases"]):
            phrase_id = str(phrase["id"])
            if normalized_phrase_filter not in (None, phrase_id.casefold()):
                continue

            output_key = f"{speaker_id}-{phrase_id}"
            if output_key in seen:
                raise ValueError(f"Duplicate output key: {output_key}")
            seen.add(output_key)
            jobs.append(
                SampleJob(
                    speaker_id=speaker_id,
                    speaker_name=speaker_name,
                    speaker_description=str(speaker.get("description") or ""),
                    phrase_id=phrase_id,
                    display_text=str(phrase["displayText"]),
                    spoken_text=str(
                        spoken_text_overrides.get(phrase_id)
                        or phrase.get("spokenText")
                        or phrase["displayText"]
                    ),
                    category=str(phrase["category"]) if phrase.get("category") else None,
                    spell_ids=tuple(int(spell_id) for spell_id in phrase.get("spellIds", [])),
                    spec_ids=tuple(int(spec_id) for spec_id in phrase.get("specIds", [])),
                    output_key=output_key,
                    seed=int(
                        seed_overrides.get(
                            phrase_id,
                            base_seed + speaker_index * 1000 + phrase_index,
                        )
                    ),
                )
            )

    if not jobs:
        raise ValueError("The speaker and phrase filters selected no samples.")
    return jobs


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
    candidates = re.findall(r"\{\s*\"input_i\"[\s\S]*?\}", stderr)
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


def master_audio(ffmpeg: Path, raw_path: Path, ogg_path: Path, manifest: dict[str, Any]) -> dict[str, Any]:
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
    # EBU R128 has no integrated-loudness result for very short clips. In that case,
    # ffmpeg's dynamic pass still reaches the true-peak target without invalid -inf inputs.
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


def download_model_snapshot(manifest: dict[str, Any], model_cache: Path) -> Path:
    from huggingface_hub import snapshot_download

    model_spec = manifest["model"]
    snapshot_directory = model_cache / (
        "qwen3-tts-1.7b-customvoice-" + model_spec["revision"][:12]
    )
    os.environ.setdefault("HF_XET_HIGH_PERFORMANCE", "1")
    print(
        f"Ensuring complete model snapshot {model_spec['repository']} "
        f"at {model_spec['revision']}..."
    )
    snapshot_download(
        repo_id=model_spec["repository"],
        revision=model_spec["revision"],
        local_dir=snapshot_directory,
    )

    required_files = (
        "config.json",
        "generation_config.json",
        "model.safetensors",
        "preprocessor_config.json",
        "speech_tokenizer/config.json",
        "speech_tokenizer/model.safetensors",
        "speech_tokenizer/preprocessor_config.json",
        "tokenizer_config.json",
        "vocab.json",
    )
    missing = [name for name in required_files if not (snapshot_directory / name).is_file()]
    if missing:
        raise RuntimeError(f"Pinned model snapshot is incomplete: {', '.join(missing)}")
    return snapshot_directory


def generate_raw_samples(
    jobs: list[SampleJob],
    raw_directory: Path,
    manifest: dict[str, Any],
    model_cache: Path,
    force: bool,
) -> dict[str, float]:
    pending = [job for job in jobs if force or not (raw_directory / f"{job.output_key}.wav").is_file()]
    if not pending:
        print("All selected raw WAV files already exist; synthesis is not needed.")
        return {}

    import numpy as np
    import soundfile as sf
    import torch
    from qwen_tts import Qwen3TTSModel

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is required for the 1.7B sample generation run.")

    os.environ["HF_HOME"] = str(model_cache)
    os.environ["HF_HUB_CACHE"] = str(model_cache / "hub")

    model_spec = manifest["model"]
    snapshot_directory = download_model_snapshot(manifest, model_cache)
    print(f"Loading pinned model from {snapshot_directory}...")
    model = Qwen3TTSModel.from_pretrained(
        str(snapshot_directory),
        local_files_only=True,
        device_map="cuda:0",
        dtype=torch.bfloat16,
        attn_implementation=model_spec["attentionImplementation"],
    )

    supported_speakers = {name.casefold() for name in model.get_supported_speakers()}
    for job in pending:
        if job.speaker_name.casefold() not in supported_speakers:
            raise RuntimeError(f"Model does not report the requested speaker: {job.speaker_name}")

    raw_directory.mkdir(parents=True, exist_ok=True)
    timings: dict[str, float] = {}
    for job in pending:
        torch.manual_seed(job.seed)
        torch.cuda.manual_seed_all(job.seed)
        started = time.perf_counter()
        print(f"Generating {job.output_key}: {job.spoken_text!r}")
        generation_arguments = {
            "text": job.spoken_text,
            "language": manifest["language"],
            "speaker": job.speaker_name,
        }
        if manifest["instruction"]:
            generation_arguments["instruct"] = manifest["instruction"]
        wavs, sample_rate = model.generate_custom_voice(**generation_arguments)
        torch.cuda.synchronize()
        elapsed = time.perf_counter() - started
        waveform = wavs[0]
        if hasattr(waveform, "detach"):
            waveform = waveform.detach().cpu().numpy()
        waveform = np.asarray(waveform, dtype=np.float32).squeeze()
        output_path = raw_directory / f"{job.output_key}.wav"
        sf.write(output_path, waveform, sample_rate, subtype="PCM_24")
        timings[job.output_key] = round(elapsed, 3)
        print(f"Wrote {output_path} ({elapsed:.2f}s)")

    return timings


def write_listening_page(samples: list[dict[str, Any]], output_path: Path, manifest: dict[str, Any]) -> None:
    by_phrase: dict[str, dict[str, dict[str, Any]]] = {}
    for sample in samples:
        by_phrase.setdefault(sample["phraseId"], {})[sample["speakerId"]] = sample

    speaker_ids = [speaker["id"] for speaker in manifest["speakers"]]
    speaker_names = {speaker["id"]: speaker["qwenName"] for speaker in manifest["speakers"]}
    spec_names = {int(spec["id"]): spec["name"] for spec in manifest.get("specs", [])}

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
            ogg_name = html.escape(Path(sample["ogg"]["path"]).name)
            wav_name = html.escape(Path(sample["rawWav"]["path"]).name)
            duration = sample["ogg"]["durationSeconds"]
            cells.append(
                '<div class="sample">'
                f'<audio controls preload="metadata" src="../ogg/{ogg_name}"></audio>'
                f'<div class="meta">{duration:.2f}s mastered OGG</div>'
                f'<a href="../raw-wav/{wav_name}">Raw WAV</a>'
                '</div>'
            )
        rows.append(
            '<section class="phrase">'
            f'<h2>{html.escape(str(phrase["displayText"]))}</h2>'
            f'{detail_html}'
            '<div class="comparison">'
            + ''.join(
                f'<article><h3>{html.escape(speaker_names[speaker_id])}</h3>{cells[index]}</article>'
                for index, speaker_id in enumerate(speaker_ids)
            )
            + '</div></section>'
        )

    model = html.escape(manifest["model"]["repository"])
    revision = html.escape(manifest["model"]["revision"][:12])
    speaker_summary = html.escape(
        ", ".join(str(speaker["qwenName"]) for speaker in manifest["speakers"])
    )
    pack_description = html.escape(
        str((manifest.get("pack") or {}).get("description") or "Arena callout voice comparison.")
    )
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
<p>Compare {speaker_summary} using mastered OGG files. Raw model WAV files remain linked below each sample.</p>
</header>
{''.join(rows)}
<footer>Model: {model}<br>Revision: {revision}<br>Mastering target: -16 LUFS, -1.5 dBTP, mono OGG Vorbis.</footer>
</main>
</body>
</html>
"""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(document, encoding="utf-8", newline="\n")


def main() -> int:
    args = parse_args()
    scratch = args.scratch.resolve()
    model_cache = (args.model_cache or scratch / "models").resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    model_cache.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("HF_HOME", str(model_cache))
    os.environ.setdefault("HF_HUB_CACHE", str(model_cache / "hub"))

    details = environment_details(scratch)
    print(f"CUDA device: {details['cuda']['device']}")
    print(f"Bundled ffmpeg: {details['ffmpeg']['path']}")
    if args.verify_only:
        print(f"Environment report: {scratch / 'reports' / 'environment.json'}")
        return 0

    manifest = load_manifest(args.manifest.resolve())
    jobs = build_jobs(manifest, args.speaker, args.phrase)
    raw_directory = scratch / "raw-wav"
    ogg_directory = scratch / "ogg"
    reports_directory = scratch / "reports"
    timings = generate_raw_samples(jobs, raw_directory, manifest, model_cache, args.force)

    ffmpeg = Path(details["ffmpeg"]["path"])
    samples: list[dict[str, Any]] = []
    for job in jobs:
        raw_path = raw_directory / f"{job.output_key}.wav"
        ogg_path = ogg_directory / f"{job.output_key}.ogg"
        if not raw_path.is_file():
            raise RuntimeError(f"Expected raw sample is missing: {raw_path}")

        mastering: dict[str, Any] | None = None
        if args.force or args.remaster or not ogg_path.is_file():
            print(f"Mastering {job.output_key}...")
            mastering = master_audio(ffmpeg, raw_path, ogg_path, manifest)
        if not ogg_path.is_file():
            raise RuntimeError(f"Expected mastered sample is missing: {ogg_path}")

        raw_info = inspect_audio(raw_path)
        ogg_info = inspect_audio(ogg_path)
        if ogg_info["channels"] != 1 or ogg_info["durationSeconds"] <= 0:
            raise RuntimeError(f"Invalid mastered audio properties: {ogg_path}")
        if mastering:
            output_tp = float(mastering["finalPass"]["output_tp"])
            if output_tp > float(manifest["mastering"]["truePeakDb"]) + 0.1:
                raise RuntimeError(f"True peak exceeded target for {ogg_path}: {output_tp} dBTP")

        samples.append(
            {
                "outputKey": job.output_key,
                "speakerId": job.speaker_id,
                "speakerName": job.speaker_name,
                "speakerDescription": job.speaker_description,
                "phraseId": job.phrase_id,
                "displayText": job.display_text,
                "spokenText": job.spoken_text,
                "category": job.category,
                "spellIds": list(job.spell_ids),
                "specIds": list(job.spec_ids),
                "seed": job.seed,
                "generationSeconds": timings.get(job.output_key),
                "rawWav": raw_info,
                "ogg": ogg_info,
                "mastering": mastering,
            }
        )

    report = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "manifest": str(args.manifest.resolve()),
        "modelCache": str(model_cache),
        "pack": manifest.get("pack"),
        "specs": manifest.get("specs", []),
        "model": manifest["model"],
        "locale": manifest["locale"],
        "language": manifest["language"],
        "instruction": manifest["instruction"],
        "mastering": manifest["mastering"],
        "environment": details,
        "samples": samples,
    }
    reports_directory.mkdir(parents=True, exist_ok=True)
    report_path = reports_directory / "sample-run.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    listening_page = scratch / "listening" / "index.html"
    write_listening_page(samples, listening_page, manifest)
    print(f"Run report: {report_path}")
    print(f"Listening page: {listening_page}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        if error.stdout:
            print(error.stdout, file=sys.stderr)
        if error.stderr:
            print(error.stderr, file=sys.stderr)
        raise
