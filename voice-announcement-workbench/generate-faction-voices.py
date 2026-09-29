#!/usr/bin/env python3
"""Design two original faction voices and clone them across tactical callouts."""

from __future__ import annotations

import argparse
import gc
import hashlib
import importlib.metadata
import json
import os
import platform
import shutil
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from audio_workbench import inspect_audio, master_audio, run, sha256, write_listening_page


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_MANIFEST = WORKBENCH / "faction-voice-manifest.json"
DEFAULT_SCRATCH = WORKBENCH / "scratch" / "faction-voices"


@dataclass(frozen=True)
class CloneJob:
    speaker_id: str
    speaker_name: str
    phrase_id: str
    display_text: str
    spoken_text: str
    output_key: str
    seed: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--scratch", type=Path, default=DEFAULT_SCRATCH)
    parser.add_argument("--model-cache", type=Path)
    parser.add_argument(
        "--device",
        choices=("auto", "cuda", "mps", "cpu"),
        default="auto",
        help="Inference device. Auto prefers CUDA, then Apple Metal, then CPU.",
    )
    parser.add_argument("--speaker", help="Generate one voice by manifest id.")
    parser.add_argument("--phrase", help="Generate one phrase by manifest id.")
    parser.add_argument("--force", action="store_true", help="Regenerate selected cloned audio.")
    parser.add_argument("--remaster", action="store_true", help="Rebuild OGG files from cloned WAVs.")
    parser.add_argument(
        "--redesign",
        action="store_true",
        help="Replace selected frozen references and regenerate their cloned audio.",
    )
    parser.add_argument(
        "--design-only",
        action="store_true",
        help="Create or reuse selected frozen references without cloning callouts.",
    )
    parser.add_argument("--verify-only", action="store_true", help="Verify the environment and exit.")
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
    from qwen_tts import Qwen3TTSModel

    required_methods = (
        "generate_voice_design",
        "create_voice_clone_prompt",
        "generate_voice_clone",
    )
    missing_methods = [name for name in required_methods if not hasattr(Qwen3TTSModel, name)]
    if missing_methods:
        raise RuntimeError(
            "Installed qwen-tts does not support the faction voice workflow: "
            + ", ".join(missing_methods)
        )

    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe()).resolve()
    if not ffmpeg.is_file():
        raise RuntimeError(f"Bundled ffmpeg executable is missing: {ffmpeg}")
    ffmpeg_version = run([str(ffmpeg), "-version"], capture=True).stdout.splitlines()[0]
    encoders = run([str(ffmpeg), "-hide_banner", "-encoders"], capture=True)
    if "libvorbis" not in encoders.stdout + encoders.stderr:
        raise RuntimeError(f"Bundled ffmpeg does not provide libvorbis: {ffmpeg}")

    device, dtype = resolve_execution_device(torch, requested_device)
    details = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "python": sys.version,
        "platform": platform.platform(),
        "packages": {
            name: package_version(name)
            for name in (
                "torch",
                "torchaudio",
                "qwen-tts",
                "transformers",
                "imageio-ffmpeg",
                "hf-xet",
                "soundfile",
            )
        },
        "ffmpeg": {"path": str(ffmpeg), "version": ffmpeg_version, "libvorbis": True},
        "execution": {
            "requestedDevice": requested_device,
            "device": device,
            "dtype": str(dtype).removeprefix("torch."),
        },
        "cuda": {"available": torch.cuda.is_available(), "torchCudaVersion": torch.version.cuda},
        "mps": {
            "available": bool(hasattr(torch.backends, "mps") and torch.backends.mps.is_available()),
            "built": bool(hasattr(torch.backends, "mps") and torch.backends.mps.is_built()),
        },
        "requiredApis": list(required_methods),
    }
    reports = scratch / "reports"
    reports.mkdir(parents=True, exist_ok=True)
    (reports / "environment.json").write_text(
        json.dumps(details, indent=2) + "\n", encoding="utf-8"
    )
    return details


def load_manifest(path: Path) -> dict[str, Any]:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1:
        raise ValueError("faction-voice-manifest.json must use schemaVersion 1.")
    for model_key in ("voiceDesignModel", "cloneModel"):
        model = manifest.get(model_key) or {}
        for field in ("repository", "revision", "dtype", "attentionImplementation"):
            if not isinstance(model.get(field), str) or not model[field]:
                raise ValueError(f"Manifest {model_key}.{field} must be a non-empty string.")
    if not isinstance(manifest.get("speakers"), list) or not manifest["speakers"]:
        raise ValueError("Manifest must contain at least one speaker.")
    if not isinstance(manifest.get("phrases"), list) or not manifest["phrases"]:
        raise ValueError("Manifest must contain at least one phrase.")
    return manifest


def select_speakers(manifest: dict[str, Any], speaker_filter: str | None) -> list[dict[str, Any]]:
    speakers = manifest["speakers"]
    if speaker_filter:
        speakers = [
            speaker
            for speaker in speakers
            if speaker_filter.casefold()
            in (str(speaker["id"]).casefold(), str(speaker["displayName"]).casefold())
        ]
    if not speakers:
        raise ValueError("The speaker filter selected no voices.")
    return speakers


def build_jobs(
    manifest: dict[str, Any],
    speakers: list[dict[str, Any]],
    phrase_filter: str | None,
) -> list[CloneJob]:
    phrases = manifest["phrases"]
    if phrase_filter:
        phrases = [
            phrase for phrase in phrases if str(phrase["id"]).casefold() == phrase_filter.casefold()
        ]
    if not phrases:
        raise ValueError("The phrase filter selected no callouts.")

    jobs: list[CloneJob] = []
    base_seed = int(manifest["seed"])
    all_phrases = manifest["phrases"]
    for speaker in speakers:
        for phrase in phrases:
            phrase_index = next(
                index for index, candidate in enumerate(all_phrases) if candidate["id"] == phrase["id"]
            )
            speaker_id = str(speaker["id"])
            phrase_id = str(phrase["id"])
            jobs.append(
                CloneJob(
                    speaker_id=speaker_id,
                    speaker_name=str(speaker["displayName"]),
                    phrase_id=phrase_id,
                    display_text=str(phrase["displayText"]),
                    spoken_text=str(phrase["spokenText"]),
                    output_key=f"{speaker_id}-{phrase_id}",
                    seed=int(
                        (speaker.get("seedOverrides") or {}).get(
                            phrase_id,
                            base_seed + int(speaker["cloneSeedOffset"]) + phrase_index,
                        )
                    ),
                )
            )
    return jobs


def snapshot_directory(model_spec: dict[str, Any], model_cache: Path, label: str) -> Path:
    from huggingface_hub import snapshot_download

    target = model_cache / f"qwen3-tts-{label}-{model_spec['revision'][:12]}"
    os.environ.setdefault("HF_XET_HIGH_PERFORMANCE", "1")
    print(f"Ensuring {model_spec['repository']} at {model_spec['revision']}...")
    snapshot_download(
        repo_id=model_spec["repository"],
        revision=model_spec["revision"],
        local_dir=target,
    )
    required = (
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
    missing = [name for name in required if not (target / name).is_file()]
    if missing:
        raise RuntimeError(f"Pinned {label} snapshot is incomplete: {', '.join(missing)}")
    return target


def set_seed(torch: Any, seed: int, device: str) -> None:
    torch.manual_seed(seed)
    if device.startswith("cuda"):
        torch.cuda.manual_seed_all(seed)


def release_device_memory(torch: Any, device: str) -> None:
    gc.collect()
    if device.startswith("cuda"):
        torch.cuda.empty_cache()
    elif device == "mps":
        torch.mps.empty_cache()


def text_sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest().upper()


def generation_arguments(manifest: dict[str, Any], max_tokens_key: str) -> dict[str, Any]:
    settings = manifest["generation"]
    return {
        "do_sample": bool(settings["doSample"]),
        "temperature": float(settings["temperature"]),
        "top_p": float(settings["topP"]),
        "top_k": int(settings["topK"]),
        "repetition_penalty": float(settings["repetitionPenalty"]),
        "subtalker_dosample": bool(settings["subtalkerDoSample"]),
        "subtalker_temperature": float(settings["subtalkerTemperature"]),
        "subtalker_top_p": float(settings["subtalkerTopP"]),
        "subtalker_top_k": int(settings["subtalkerTopK"]),
        "non_streaming_mode": bool(settings["nonStreamingMode"]),
        "max_new_tokens": int(settings[max_tokens_key]),
    }


def synthesis_text(manifest: dict[str, Any], text: str) -> str:
    if manifest["generation"].get("appendTerminalPunctuation") and text[-1:] not in ".!?":
        return text + "."
    return text


def ensure_references(
    manifest: dict[str, Any],
    speakers: list[dict[str, Any]],
    reference_dir: Path,
    model_cache: Path,
    device: str,
    dtype_name: str,
    redesign: bool,
) -> list[dict[str, Any]]:
    import soundfile as sf
    import torch
    from qwen_tts import Qwen3TTSModel

    pending = [
        speaker
        for speaker in speakers
        if redesign or not (reference_dir / f"{speaker['id']}.wav").is_file()
    ]
    timings: dict[str, float] = {}
    if pending:
        model_spec = manifest["voiceDesignModel"]
        model_path = snapshot_directory(model_spec, model_cache, "voice-design")
        print(f"Loading VoiceDesign model from {model_path}...")
        model = Qwen3TTSModel.from_pretrained(
            str(model_path),
            local_files_only=True,
            device_map=device,
            dtype=getattr(torch, dtype_name),
            attn_implementation=model_spec["attentionImplementation"],
        )
        reference_dir.mkdir(parents=True, exist_ok=True)
        for speaker in pending:
            seed = int(speaker["designSeed"])
            set_seed(torch, seed, device)
            started = time.perf_counter()
            print(f"Designing {speaker['id']} reference...", flush=True)
            wavs, sample_rate = model.generate_voice_design(
                text=str(speaker["referenceText"]),
                language=manifest["language"],
                instruct=str(speaker["designInstruction"]),
                **generation_arguments(manifest, "designMaxNewTokens"),
            )
            if device.startswith("cuda"):
                torch.cuda.synchronize()
            elif device == "mps":
                torch.mps.synchronize()
            path = reference_dir / f"{speaker['id']}.wav"
            if path.is_file():
                archive_dir = reference_dir / "archive"
                archive_dir.mkdir(parents=True, exist_ok=True)
                archived_path = archive_dir / f"{speaker['id']}-{sha256(path)[:12]}.wav"
                if not archived_path.exists():
                    shutil.copy2(path, archived_path)
                    print(f"Archived previous reference at {archived_path}")
            sf.write(path, wavs[0], sample_rate, subtype="PCM_24")
            timings[str(speaker["id"])] = round(time.perf_counter() - started, 3)
        del model
        release_device_memory(torch, device)

    references: list[dict[str, Any]] = []
    for speaker in speakers:
        path = reference_dir / f"{speaker['id']}.wav"
        if not path.is_file():
            raise RuntimeError(f"Frozen reference is missing: {path}")
        references.append(
            {
                "speakerId": speaker["id"],
                "speakerName": speaker["displayName"],
                "description": speaker["description"],
                "designInstruction": speaker["designInstruction"],
                "designInstructionSha256": text_sha256(str(speaker["designInstruction"])),
                "referenceText": speaker["referenceText"],
                "referenceTextSha256": text_sha256(str(speaker["referenceText"])),
                "designSeed": speaker["designSeed"],
                "generationSeconds": timings.get(str(speaker["id"])),
                "audio": inspect_audio(path),
            }
        )
    return references


def generate_clones(
    manifest: dict[str, Any],
    speakers: list[dict[str, Any]],
    jobs: list[CloneJob],
    reference_dir: Path,
    raw_dir: Path,
    model_cache: Path,
    device: str,
    dtype_name: str,
    force: bool,
) -> dict[str, float]:
    import soundfile as sf
    import torch
    from qwen_tts import Qwen3TTSModel

    pending = [job for job in jobs if force or not (raw_dir / f"{job.output_key}.wav").is_file()]
    if not pending:
        print("All selected cloned WAV files already exist; synthesis is not needed.")
        return {}

    model_spec = manifest["cloneModel"]
    model_path = snapshot_directory(model_spec, model_cache, "base")
    print(f"Loading Base model from {model_path}...")
    model = Qwen3TTSModel.from_pretrained(
        str(model_path),
        local_files_only=True,
        device_map=device,
        dtype=getattr(torch, dtype_name),
        attn_implementation=model_spec["attentionImplementation"],
    )
    speaker_by_id = {str(speaker["id"]): speaker for speaker in speakers}
    x_vector_only = manifest["generation"]["cloneMode"] == "x-vector-only"
    prompts = {
        speaker_id: model.create_voice_clone_prompt(
            ref_audio=str(reference_dir / f"{speaker_id}.wav"),
            ref_text=None if x_vector_only else str(speaker["referenceText"]),
            x_vector_only_mode=x_vector_only,
        )
        for speaker_id, speaker in speaker_by_id.items()
    }

    raw_dir.mkdir(parents=True, exist_ok=True)
    timings: dict[str, float] = {}
    for job in pending:
        set_seed(torch, job.seed, device)
        started = time.perf_counter()
        print(f"Cloning {job.output_key}: {job.spoken_text!r}", flush=True)
        wavs, sample_rate = model.generate_voice_clone(
            text=synthesis_text(manifest, job.spoken_text),
            language=manifest["language"],
            voice_clone_prompt=prompts[job.speaker_id],
            **generation_arguments(manifest, "cloneMaxNewTokens"),
        )
        if device.startswith("cuda"):
            torch.cuda.synchronize()
        elif device == "mps":
            torch.mps.synchronize()
        sf.write(
            raw_dir / f"{job.output_key}.wav",
            wavs[0],
            sample_rate,
            subtype="PCM_24",
        )
        timings[job.output_key] = round(time.perf_counter() - started, 3)
    del model
    release_device_memory(torch, device)
    return timings


def main() -> int:
    args = parse_args()
    scratch = args.scratch.resolve()
    model_cache = (args.model_cache or WORKBENCH / "scratch" / "models").resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    model_cache.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("HF_HOME", str(model_cache))
    os.environ.setdefault("HF_HUB_CACHE", str(model_cache / "hub"))
    os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

    details = environment_details(scratch, args.device)
    print(f"Execution device: {details['execution']['device']} ({details['execution']['dtype']})")
    if args.verify_only:
        print(f"Environment report: {scratch / 'reports' / 'environment.json'}")
        return 0

    manifest = load_manifest(args.manifest.resolve())
    speakers = select_speakers(manifest, args.speaker)
    jobs = build_jobs(manifest, speakers, args.phrase)
    reference_dir = scratch / "references"
    raw_dir = scratch / "raw-wav"
    ogg_dir = scratch / "ogg"
    reports_dir = scratch / "reports"
    device = str(details["execution"]["device"])
    dtype_name = str(details["execution"]["dtype"])

    full_report_path = reports_dir / "faction-voice-run.json"
    previous_report: dict[str, Any] = {}
    if full_report_path.is_file():
        previous_report = json.loads(full_report_path.read_text(encoding="utf-8"))

    references = ensure_references(
        manifest,
        speakers,
        reference_dir,
        model_cache,
        device,
        dtype_name,
        args.redesign,
    )
    previous_references = {
        item.get("speakerId"): item for item in previous_report.get("references", [])
    }
    for reference in references:
        previous = previous_references.get(reference["speakerId"])
        if (
            reference["generationSeconds"] is None
            and previous
            and previous.get("audio", {}).get("sha256") == reference["audio"]["sha256"]
        ):
            reference["generationSeconds"] = previous.get("generationSeconds")
    if args.design_only:
        report = {
            "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "manifest": str(args.manifest.resolve()),
            "voiceDesignModel": manifest["voiceDesignModel"],
            "generation": manifest["generation"],
            "environment": details,
            "references": references,
        }
        (reports_dir / "reference-design.json").write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8"
        )
        print(f"Reference report: {reports_dir / 'reference-design.json'}")
        return 0

    force_clones = args.force or args.redesign
    timings = generate_clones(
        manifest,
        speakers,
        jobs,
        reference_dir,
        raw_dir,
        model_cache,
        device,
        dtype_name,
        force_clones,
    )

    import imageio_ffmpeg

    ffmpeg = Path(imageio_ffmpeg.get_ffmpeg_exe())
    previous_samples = {
        item.get("outputKey"): item for item in previous_report.get("samples", [])
    }
    samples: list[dict[str, Any]] = []
    for job in jobs:
        raw_path = raw_dir / f"{job.output_key}.wav"
        ogg_path = ogg_dir / f"{job.output_key}.ogg"
        if not raw_path.is_file():
            raise RuntimeError(f"Expected cloned sample is missing: {raw_path}")
        mastering = None
        if force_clones or args.remaster or not ogg_path.is_file():
            print(f"Mastering {job.output_key}...")
            mastering = master_audio(ffmpeg, raw_path, ogg_path, manifest)
        raw_info = inspect_audio(raw_path)
        ogg_info = inspect_audio(ogg_path)
        previous = previous_samples.get(job.output_key)
        if previous and previous.get("ogg", {}).get("sha256") == ogg_info["sha256"]:
            if mastering is None:
                mastering = previous.get("mastering")
            if job.output_key not in timings:
                timings[job.output_key] = previous.get("generationSeconds")
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
                "phraseId": job.phrase_id,
                "displayText": job.display_text,
                "spokenText": job.spoken_text,
                "synthesisText": synthesis_text(manifest, job.spoken_text),
                "seed": job.seed,
                "generationSeconds": timings.get(job.output_key),
                "referenceSha256": next(
                    item["audio"]["sha256"]
                    for item in references
                    if item["speakerId"] == job.speaker_id
                ),
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
        "voiceDesignModel": manifest["voiceDesignModel"],
        "cloneModel": manifest["cloneModel"],
        "locale": manifest["locale"],
        "language": manifest["language"],
        "generation": manifest["generation"],
        "mastering": manifest["mastering"],
        "environment": details,
        "references": references,
        "samples": samples,
    }
    reports_dir.mkdir(parents=True, exist_ok=True)
    if args.speaker or args.phrase:
        selection = "-".join(value for value in (args.speaker, args.phrase) if value)
        report_path = reports_dir / f"faction-voice-run-{selection}.json"
    else:
        report_path = full_report_path
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    listening_page = scratch / "listening" / "index.html"
    write_listening_page(
        samples,
        listening_page,
        manifest,
        model_label=(
            f"{manifest['voiceDesignModel']['repository']} -> "
            f"{manifest['cloneModel']['repository']}"
        ),
    )
    print(f"Run report: {report_path}")
    print(f"Listening page: {listening_page}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
