#!/usr/bin/env python3
"""Generate and master the Qwen3-TTS voice comparison samples."""

from __future__ import annotations

import argparse
import importlib.metadata
import json
import os
import platform
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from audio_workbench import inspect_audio, master_audio, run, write_listening_page


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
    parser.add_argument(
        "--device",
        choices=("auto", "cuda", "mps", "cpu"),
        default="auto",
        help="Inference device. Auto prefers CUDA, then Apple Metal, then CPU.",
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


def resolve_execution_device(torch: Any, requested: str) -> tuple[str, Any]:
    mps_available = bool(
        hasattr(torch.backends, "mps") and torch.backends.mps.is_available()
    )
    if requested == "cuda" and not torch.cuda.is_available():
        raise RuntimeError("CUDA was requested but is not available.")
    if requested == "mps" and not mps_available:
        raise RuntimeError("Apple Metal (MPS) was requested but is not available.")

    if requested == "auto":
        device = "cuda:0" if torch.cuda.is_available() else "mps" if mps_available else "cpu"
    else:
        device = "cuda:0" if requested == "cuda" else requested
    dtype = torch.bfloat16 if device.startswith("cuda") else torch.float32
    return device, dtype


def environment_details(scratch: Path, requested_device: str) -> dict[str, Any]:
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
    mps_available = bool(
        hasattr(torch.backends, "mps") and torch.backends.mps.is_available()
    )
    execution_device, execution_dtype = resolve_execution_device(torch, requested_device)
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
        "execution": {
            "requestedDevice": requested_device,
            "device": execution_device,
            "dtype": str(execution_dtype).removeprefix("torch."),
        },
        "cuda": {
            "available": cuda_available,
            "torchCudaVersion": torch.version.cuda,
        },
        "mps": {
            "available": mps_available,
            "built": bool(hasattr(torch.backends, "mps") and torch.backends.mps.is_built()),
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
    device: str,
    dtype_name: str,
) -> dict[str, float]:
    pending = [job for job in jobs if force or not (raw_directory / f"{job.output_key}.wav").is_file()]
    if not pending:
        print("All selected raw WAV files already exist; synthesis is not needed.")
        return {}

    import numpy as np
    import soundfile as sf
    import torch
    from qwen_tts import Qwen3TTSModel

    os.environ["HF_HOME"] = str(model_cache)
    os.environ["HF_HUB_CACHE"] = str(model_cache / "hub")

    model_spec = manifest["model"]
    dtype = getattr(torch, dtype_name)
    snapshot_directory = download_model_snapshot(manifest, model_cache)
    print(f"Loading pinned model from {snapshot_directory}...")
    model = Qwen3TTSModel.from_pretrained(
        str(snapshot_directory),
        local_files_only=True,
        device_map=device,
        dtype=dtype,
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
        if device.startswith("cuda"):
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
        if device.startswith("cuda"):
            torch.cuda.synchronize()
        elif device == "mps":
            torch.mps.synchronize()
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


def main() -> int:
    args = parse_args()
    scratch = args.scratch.resolve()
    model_cache = (args.model_cache or scratch / "models").resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    model_cache.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("HF_HOME", str(model_cache))
    os.environ.setdefault("HF_HUB_CACHE", str(model_cache / "hub"))

    os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
    details = environment_details(scratch, args.device)
    print(
        f"Execution device: {details['execution']['device']} "
        f"({details['execution']['dtype']})"
    )
    print(f"Bundled ffmpeg: {details['ffmpeg']['path']}")
    if args.verify_only:
        print(f"Environment report: {scratch / 'reports' / 'environment.json'}")
        return 0

    manifest = load_manifest(args.manifest.resolve())
    jobs = build_jobs(manifest, args.speaker, args.phrase)
    raw_directory = scratch / "raw-wav"
    ogg_directory = scratch / "ogg"
    reports_directory = scratch / "reports"
    timings = generate_raw_samples(
        jobs,
        raw_directory,
        manifest,
        model_cache,
        args.force,
        str(details["execution"]["device"]),
        str(details["execution"]["dtype"]),
    )

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
