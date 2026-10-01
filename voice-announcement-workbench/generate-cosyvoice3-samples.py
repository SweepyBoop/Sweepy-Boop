#!/usr/bin/env python3
"""Generate an isolated CosyVoice 3 short-callout comparison."""

from __future__ import annotations

import argparse
import importlib.metadata
import json
import os
import platform
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from audio_workbench import inspect_audio, master_audio, sha256, write_listening_page


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "cosyvoice3-sample-manifest.json"
DEFAULT_SCRATCH = WORKBENCH / "scratch" / "cosyvoice3-zero-shot"
DEFAULT_SOURCE = WORKBENCH / "scratch" / "cosyvoice3-src"
DEFAULT_MODEL = WORKBENCH / "scratch" / "cosyvoice3-models" / "fun-cosyvoice3-0.5b-29e01c4e8d00"


@dataclass(frozen=True)
class SampleJob:
    speaker_id: str
    speaker_name: str
    reference_path: Path
    reference_sha256: str
    mode_id: str
    mode_name: str
    text_prefix: str | None
    instruction: str | None
    take: int
    phrase_id: str
    display_text: str
    spoken_text: str
    seed: int
    output_key: str
    comparison_id: str
    comparison_name: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--scratch", type=Path, default=DEFAULT_SCRATCH)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--speaker")
    parser.add_argument("--phrase")
    parser.add_argument("--mode", choices=("cross-lingual", "instruct2"))
    parser.add_argument("--take", type=int)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--remaster", action="store_true")
    parser.add_argument("--verify-only", action="store_true")
    return parser.parse_args()


def package_version(name: str) -> str | None:
    try:
        return importlib.metadata.version(name)
    except importlib.metadata.PackageNotFoundError:
        return None


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1:
        raise ValueError("CosyVoice sample manifest must use schemaVersion 1")
    for section in ("model", "source"):
        for field in ("repository", "revision", "license"):
            value = (manifest.get(section) or {}).get(field)
            if not isinstance(value, str) or not value:
                raise ValueError(f"{section}.{field} must be a non-empty string")
    if manifest.get("scope") not in {"comparison", "full"}:
        raise ValueError("CosyVoice manifest scope must be comparison or full")
    if len(manifest.get("speakers", [])) != 2:
        raise ValueError("CosyVoice manifests require exactly two speakers")
    if not manifest.get("modes"):
        raise ValueError("CosyVoice manifests require at least one mode")
    if not manifest.get("phrases"):
        raise ValueError("CosyVoice manifests require at least one phrase")
    if int(manifest.get("takesPerMode", 0)) < 1:
        raise ValueError("CosyVoice manifests require at least one take per mode")
    return manifest


def verify_environment(
    manifest: dict[str, Any],
    scratch: Path,
    source: Path,
    model: Path,
) -> dict[str, Any]:
    import imageio_ffmpeg
    import torch

    source_revision = subprocess.run(
        ["git", "-C", str(source), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if source_revision != manifest["source"]["revision"]:
        raise RuntimeError(f"Unexpected CosyVoice source revision: {source_revision}")
    required_model_files = (
        "config.json",
        "configuration.json",
        "cosyvoice3.yaml",
        "llm.pt",
        "flow.pt",
        "hift.pt",
        "speech_tokenizer_v3.onnx",
    )
    missing = [name for name in required_model_files if not (model / name).is_file()]
    if missing:
        raise RuntimeError(f"CosyVoice model snapshot is incomplete: {', '.join(missing)}")

    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe()).resolve()
    details = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "python": sys.version,
        "platform": platform.platform(),
        "packages": {
            name: package_version(name)
            for name in (
                "torch",
                "torchaudio",
                "transformers",
                "onnxruntime",
                "HyperPyYAML",
                "soundfile",
                "imageio-ffmpeg",
            )
        },
        "execution": {
            "device": "cpu",
            "dtype": "float32",
            "loadJit": False,
            "loadTrt": False,
            "loadVllm": False,
            "fp16": False,
        },
        "source": {**manifest["source"], "path": str(source)},
        "model": {**manifest["model"], "path": str(model)},
        "ffmpeg": {
            "path": str(ffmpeg),
            "version": subprocess.run(
                [str(ffmpeg), "-version"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout.splitlines()[0],
        },
    }
    reports = scratch / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    (reports / "environment.json").write_text(
        json.dumps(details, indent=2) + "\n",
        encoding="utf-8",
    )
    return details


def build_jobs(manifest: dict[str, Any], args: argparse.Namespace) -> list[SampleJob]:
    jobs: list[SampleJob] = []
    base_seed = int(manifest["seed"])
    take_count = int(manifest["takesPerMode"])
    for speaker_index, speaker in enumerate(manifest["speakers"]):
        if args.speaker and args.speaker.casefold() not in {
            str(speaker["id"]).casefold(),
            str(speaker["displayName"]).casefold(),
        }:
            continue
        reference_path = (WORKBENCH / str(speaker["referencePath"])).resolve()
        if not reference_path.is_file():
            raise FileNotFoundError(f"Reference WAV is missing: {reference_path}")
        actual_reference_hash = sha256(reference_path)
        if actual_reference_hash != speaker["referenceSha256"]:
            raise ValueError(
                f"Reference hash mismatch for {speaker['id']}: {actual_reference_hash}"
            )
        for mode_index, mode in enumerate(manifest["modes"]):
            if args.mode and args.mode != mode["id"]:
                continue
            for take in range(1, take_count + 1):
                if args.take and args.take != take:
                    continue
                comparison_id = f"{speaker['id']}-{mode['id']}-take-{take}"
                comparison_name = f"{speaker['displayName']} / {mode['displayName']} / Take {take}"
                for phrase_index, phrase in enumerate(manifest["phrases"]):
                    if args.phrase and args.phrase.casefold() != str(phrase["id"]).casefold():
                        continue
                    output_key = f"{comparison_id}-{phrase['id']}"
                    jobs.append(
                        SampleJob(
                            speaker_id=str(speaker["id"]),
                            speaker_name=str(speaker["displayName"]),
                            reference_path=reference_path,
                            reference_sha256=actual_reference_hash,
                            mode_id=str(mode["id"]),
                            mode_name=str(mode["displayName"]),
                            text_prefix=mode.get("textPrefix"),
                            instruction=mode.get("instruction"),
                            take=take,
                            phrase_id=str(phrase["id"]),
                            display_text=str(phrase["displayText"]),
                            spoken_text=str(phrase["spokenText"]),
                            seed=(
                                base_seed
                                + speaker_index * 1000
                                + int(mode.get("seedOffset", mode_index * 100))
                                + take * 10
                                + phrase_index
                            ),
                            output_key=output_key,
                            comparison_id=comparison_id,
                            comparison_name=comparison_name,
                        )
                    )
    if not jobs:
        raise ValueError("The selected filters produced no CosyVoice jobs")
    return jobs


def load_cosyvoice(source: Path, model_path: Path) -> Any:
    matcha = source / "third_party" / "Matcha-TTS"
    sys.path.insert(0, str(matcha))
    sys.path.insert(0, str(source))
    from cosyvoice.cli.cosyvoice import AutoModel

    return AutoModel(
        model_dir=str(model_path),
        load_trt=False,
        load_vllm=False,
        fp16=False,
    )


def generate_raw(model: Any, job: SampleJob) -> tuple[Any, int]:
    import numpy as np
    import torch

    text = job.spoken_text if job.spoken_text[-1:] in ".!?" else job.spoken_text + "."
    torch.manual_seed(job.seed)
    if job.mode_id == "cross-lingual":
        iterator = model.inference_cross_lingual(
            f"{job.text_prefix}{text}",
            str(job.reference_path),
            stream=False,
            speed=1.0,
        )
    elif job.mode_id == "instruct2":
        iterator = model.inference_instruct2(
            text,
            str(job.instruction),
            str(job.reference_path),
            stream=False,
            speed=1.0,
        )
    else:
        raise ValueError(f"Unsupported CosyVoice mode: {job.mode_id}")

    chunks: list[Any] = []
    for output in iterator:
        waveform = output["tts_speech"]
        if hasattr(waveform, "detach"):
            waveform = waveform.detach().cpu().numpy()
        chunks.append(np.asarray(waveform, dtype=np.float32).squeeze())
    if not chunks:
        raise RuntimeError(f"CosyVoice produced no audio for {job.output_key}")
    return np.concatenate(chunks), int(model.sample_rate)


def review_manifest(manifest: dict[str, Any], jobs: list[SampleJob]) -> dict[str, Any]:
    speakers: list[dict[str, str]] = []
    seen: set[str] = set()
    for job in jobs:
        if job.comparison_id in seen:
            continue
        seen.add(job.comparison_id)
        speakers.append({"id": job.comparison_id, "displayName": job.comparison_name})
    return {
        "model": manifest["model"],
        "pack": {
            "description": (
                "CosyVoice 3 direct short-callout comparison. Compare cross-lingual and "
                "Instruct2 output without semantic cropping or automatic tempo changes."
            )
        },
        "speakers": speakers,
        "phrases": manifest["phrases"],
        "mastering": manifest["mastering"],
    }


def main() -> int:
    args = parse_args()
    manifest = load_manifest(args.manifest.resolve())
    scratch = args.scratch.resolve()
    source = args.source.resolve()
    model_path = args.model.resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
    os.environ.setdefault("MODELSCOPE_CACHE", str(WORKBENCH / "scratch" / "cosyvoice3-modelscope"))
    details = verify_environment(manifest, scratch, source, model_path)
    print("Execution device: cpu (float32)")
    if args.verify_only:
        print(f"Environment report: {scratch / 'reports' / 'environment.json'}")
        return 0

    jobs = build_jobs(manifest, args)
    raw_dir = scratch / "raw-wav"
    ogg_dir = scratch / "ogg"
    reports = scratch / "reports"
    report_path = reports / "cosyvoice3-run.json"
    raw_dir.mkdir(parents=True, exist_ok=True)
    ogg_dir.mkdir(parents=True, exist_ok=True)
    reports.mkdir(parents=True, exist_ok=True)
    previous_report = (
        json.loads(report_path.read_text(encoding="utf-8"))
        if report_path.is_file()
        else {}
    )
    previous_samples = {
        sample.get("outputKey"): sample
        for sample in previous_report.get("samples", [])
    }
    pending = [job for job in jobs if args.force or not (raw_dir / f"{job.output_key}.wav").is_file()]
    model = load_cosyvoice(source, model_path) if pending else None
    generation_times: dict[str, float] = {}
    if model is None:
        print("All selected raw CosyVoice samples already exist; synthesis is not needed.")
    for job in pending:
        started = time.perf_counter()
        print(f"Generating {job.output_key}: {job.spoken_text!r}", flush=True)
        waveform, sample_rate = generate_raw(model, job)
        import soundfile as sf

        sf.write(raw_dir / f"{job.output_key}.wav", waveform, sample_rate, subtype="PCM_24")
        generation_times[job.output_key] = round(time.perf_counter() - started, 3)

    import imageio_ffmpeg

    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe())
    samples: list[dict[str, Any]] = []
    for job in jobs:
        raw_path = raw_dir / f"{job.output_key}.wav"
        ogg_path = ogg_dir / f"{job.output_key}.ogg"
        if not raw_path.is_file():
            raise RuntimeError(f"Expected raw sample is missing: {raw_path}")
        sample_manifest = {**manifest, "mastering": dict(manifest["mastering"])}
        effective_tempo = float(sample_manifest["mastering"]["tempo"])
        mastering = None
        if args.force or args.remaster or not ogg_path.is_file():
            print(f"Mastering {job.output_key} at {effective_tempo}x...", flush=True)
            mastering = master_audio(ffmpeg, raw_path, ogg_path, sample_manifest)
        raw_info = inspect_audio(raw_path)
        ogg_info = inspect_audio(ogg_path)
        maximum_duration = float(manifest["mastering"]["maximumDurationSeconds"])
        if manifest.get("enforceMaximumDuration") and mastering is not None:
            for _ in range(3):
                if ogg_info["durationSeconds"] <= maximum_duration:
                    break
                effective_tempo = round(
                    effective_tempo
                    * ogg_info["durationSeconds"]
                    / (maximum_duration * 0.98),
                    6,
                )
                sample_manifest["mastering"]["tempo"] = effective_tempo
                print(
                    f"Remastering {job.output_key} at {effective_tempo}x "
                    f"to satisfy the {maximum_duration}s cap...",
                    flush=True,
                )
                mastering = master_audio(ffmpeg, raw_path, ogg_path, sample_manifest)
                ogg_info = inspect_audio(ogg_path)
        previous = previous_samples.get(job.output_key)
        if previous and previous.get("rawWav", {}).get("sha256") == raw_info["sha256"]:
            if job.output_key not in generation_times:
                generation_times[job.output_key] = previous.get("generationSeconds")
        if previous and previous.get("ogg", {}).get("sha256") == ogg_info["sha256"]:
            if mastering is None:
                mastering = previous.get("mastering")
                effective_tempo = float(previous.get("tempo", effective_tempo))
        if ogg_info["channels"] != 1 or ogg_info["durationSeconds"] <= 0:
            raise RuntimeError(f"Invalid mastered audio: {ogg_path}")
        if manifest.get("enforceMaximumDuration") and ogg_info["durationSeconds"] > maximum_duration:
            raise RuntimeError(
                f"Mastered audio exceeds {maximum_duration}s for {ogg_path}: "
                f"{ogg_info['durationSeconds']}s"
            )
        if mastering:
            output_tp = float(mastering["finalPass"]["output_tp"])
            if output_tp > float(manifest["mastering"]["truePeakDb"]) + 0.1:
                raise RuntimeError(f"True peak exceeded for {ogg_path}: {output_tp} dBTP")
        samples.append(
            {
                "outputKey": job.output_key,
                "speakerId": job.comparison_id,
                "speakerSourceId": job.speaker_id,
                "speakerName": job.comparison_name,
                "phraseId": job.phrase_id,
                "displayText": job.display_text,
                "spokenText": job.spoken_text,
                "mode": job.mode_id,
                "instruction": job.instruction,
                "take": job.take,
                "seed": job.seed,
                "referenceSha256": job.reference_sha256,
                "generationSeconds": generation_times.get(job.output_key),
                "rawWav": raw_info,
                "ogg": ogg_info,
                "tempo": effective_tempo,
                "mastering": mastering,
                "meetsDurationTarget": ogg_info["durationSeconds"] <= maximum_duration,
            }
        )

    report = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "manifest": str(args.manifest.resolve()),
        "scope": manifest["scope"],
        "model": manifest["model"],
        "source": manifest["source"],
        "locale": manifest["locale"],
        "language": manifest["language"],
        "takesPerMode": manifest["takesPerMode"],
        "enforceMaximumDuration": manifest.get("enforceMaximumDuration", False),
        "mastering": manifest["mastering"],
        "environment": details,
        "samples": samples,
    }
    report_path.write_text
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    listening_page = scratch / "listening" / "index.html"
    write_listening_page(
        samples,
        listening_page,
        review_manifest(manifest, jobs),
        model_label="FunAudioLLM/Fun-CosyVoice3-0.5B-2512: cross-lingual vs Instruct2",
    )
    preferred_jobs = [
        job for job in jobs if job.mode_id == "instruct2" and job.take == 1
    ]
    preferred_ids = {job.output_key for job in preferred_jobs}
    preferred_samples = [
        sample for sample in samples if sample["outputKey"] in preferred_ids
    ]
    preferred_page = scratch / "listening" / "instruct2-take1.html"
    if preferred_samples:
        write_listening_page(
            preferred_samples,
            preferred_page,
            review_manifest(manifest, preferred_jobs),
            model_label="FunAudioLLM/Fun-CosyVoice3-0.5B-2512: Instruct2 Take 1",
        )
    failed_duration = sum(not sample["meetsDurationTarget"] for sample in samples)
    print(f"Run report: {report_path}")
    print(f"Listening page: {listening_page}")
    if preferred_samples:
        print(f"Preferred listening page: {preferred_page}")
    print(f"Samples over 1.0 seconds: {failed_duration}/{len(samples)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
