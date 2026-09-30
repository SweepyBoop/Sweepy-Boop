#!/usr/bin/env python3
"""Create an experimental female reference with Horde content/cadence via CosyVoice VC."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
from pathlib import Path
from typing import Any

import numpy as np
import soundfile as sf

from audio_workbench import inspect_audio, sha256


WORKBENCH = Path(__file__).resolve().parent
DEFAULT_SOURCE = WORKBENCH / "scratch" / "cosyvoice3-src"
DEFAULT_MODEL = WORKBENCH / "scratch" / "cosyvoice3-models" / "fun-cosyvoice3-0.5b-29e01c4e8d00"
DEFAULT_OUTPUT = WORKBENCH / "scratch" / "cosyvoice3-vc-references"
ALLIANCE_REFERENCE = WORKBENCH / "scratch" / "faction-voices" / "references" / "alliance-commander.wav"
HORDE_REFERENCE = WORKBENCH / "scratch" / "faction-voices" / "references" / "horde-commander.wav"
ALLIANCE_SHA256 = "DCB7499F00A62577615FBB2DE32DC156BFCC56A13ECF1B5068BFC6F56C316519"
HORDE_SHA256 = "50E52EB550990CAA497B2DF10C040297989F6990C2A5BE8143973DE733C886FB"
ALLIANCE_CLEAN_START_SECONDS = 1.314
SOURCE_REVISION = "074ca6dc9e80a2f424f1f74b48bdd7d3fea531cc"
MODEL_REVISION = "29e01c4e8d000f4bcd70751be16fa94bf3d85a18"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def load_cosyvoice(source: Path, model_path: Path) -> Any:
    sys.path.insert(0, str(source / "third_party" / "Matcha-TTS"))
    sys.path.insert(0, str(source))
    from cosyvoice.cli.cosyvoice import AutoModel

    return AutoModel(
        model_dir=str(model_path),
        load_trt=False,
        load_vllm=False,
        fp16=False,
    )


def require_hash(path: Path, expected: str) -> None:
    actual = sha256(path)
    if actual != expected:
        raise ValueError(f"Unexpected reference hash for {path}: {actual}")


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    model_path = args.model.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
    os.environ.setdefault("MODELSCOPE_CACHE", str(WORKBENCH / "scratch" / "cosyvoice3-modelscope"))
    require_hash(ALLIANCE_REFERENCE, ALLIANCE_SHA256)
    require_hash(HORDE_REFERENCE, HORDE_SHA256)

    alliance_copy = output / f"alliance-original-{ALLIANCE_SHA256[:12]}.wav"
    horde_copy = output / f"horde-source-{HORDE_SHA256[:12]}.wav"
    shutil.copy2(ALLIANCE_REFERENCE, alliance_copy)
    shutil.copy2(HORDE_REFERENCE, horde_copy)

    waveform, sample_rate = sf.read(ALLIANCE_REFERENCE, dtype="float32")
    crop_frame = int(ALLIANCE_CLEAN_START_SECONDS * sample_rate)
    cleaned = waveform[crop_frame:]
    cleaned_path = output / "alliance-prompt-cleaned.wav"
    sf.write(cleaned_path, cleaned, sample_rate, subtype="PCM_24")

    converted_path = output / "alliance-vc-from-horde-v1.wav"
    generation_seconds: float | None = None
    if args.force or not converted_path.is_file():
        model = load_cosyvoice(source, model_path)
        started = time.perf_counter()
        chunks: list[np.ndarray] = []
        for result in model.inference_vc(
            source_wav=str(horde_copy),
            prompt_wav=str(cleaned_path),
            stream=False,
            speed=1.0,
        ):
            speech = result["tts_speech"]
            if hasattr(speech, "detach"):
                speech = speech.detach().cpu().numpy()
            chunks.append(np.asarray(speech, dtype=np.float32).squeeze())
        if not chunks:
            raise RuntimeError("CosyVoice voice conversion produced no audio")
        sf.write(
            converted_path,
            np.concatenate(chunks),
            int(model.sample_rate),
            subtype="PCM_24",
        )
        generation_seconds = round(time.perf_counter() - started, 3)

    report = {
        "createdUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "sourceRepository": "https://github.com/QwenAudio/CosyVoice.git",
        "sourceRevision": SOURCE_REVISION,
        "modelRepository": "FunAudioLLM/Fun-CosyVoice3-0.5B-2512",
        "modelRevision": MODEL_REVISION,
        "execution": {"device": "cpu", "fp16": False},
        "allianceOriginal": inspect_audio(alliance_copy),
        "allianceCleanStartSeconds": ALLIANCE_CLEAN_START_SECONDS,
        "allianceCleanedPrompt": inspect_audio(cleaned_path),
        "hordeSource": inspect_audio(horde_copy),
        "convertedAllianceReference": inspect_audio(converted_path),
        "generationSeconds": generation_seconds,
    }
    report_path = output / "vc-reference-report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Cleaned Alliance prompt: {cleaned_path}")
    print(f"Converted Alliance reference: {converted_path}")
    print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
