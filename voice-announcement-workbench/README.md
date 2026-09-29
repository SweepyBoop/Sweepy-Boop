# Voice Announcement Workbench

This directory contains a reproducible, local-only Qwen3-TTS experiment for SweepyBoop arena important-aura announcements. It generates a small English listening set without changing addon runtime code or promoting experimental files into the addon's shipped sound directories.

## Repository contract

- Keep durable documentation, manifests, and automation in this directory.
- Keep Python environments, model weights, caches, raw audio, mastered audio, and reports under `scratch/`.
- `scratch/` is intentionally ignored because model weights and environments are too large for source control.
- This entire workbench is excluded from addon deployment and publication.
- Do not copy audio into the addon until a human has reviewed and approved it.

## Initial comparison

The first batch uses:

- Model: `Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice`
- Revision: `0c0e3051f131929182e2c023b9537f8b1c68adfe`
- Voices: Aiden, Vivian, and Serena
- Language: English
- Displayed abilities: Avenging Wrath, Combustion, Chi-Ji, Nullifying Shroud, and Trueshot
- Spoken callouts: Wings, Combustion, Chee Jee, Null Shroud, and Trueshot

The model runs locally. No paid synthesis API is used.

## Environment

The first experiment targets:

- Windows 11
- NVIDIA GeForce RTX 5080 with 16 GB VRAM
- Python 3.10
- PyTorch 2.9.1 with CUDA 12.8
- Qwen TTS 0.1.1
- `imageio-ffmpeg` 0.6.0
- `hf-xet` 1.6.0 for resumable Hugging Face model downloads

FlashAttention is intentionally not part of the first Windows setup. The generator uses PyTorch SDPA with `bfloat16` and batch size one.

## Setup

From PowerShell:

```powershell
& .\voice-announcement-workbench\setup-environment.ps1
```

The first setup installs packages into `scratch/python`. The first generation explicitly downloads and validates the complete pinned model snapshot under `scratch/models` before loading it. Both operations can take several minutes.

To rebuild only the isolated Python environment:

```powershell
& .\voice-announcement-workbench\setup-environment.ps1 -Recreate
```

## Generate samples

Generate or reuse all fifteen samples and open the listening page:

```powershell
& .\voice-announcement-workbench\run-samples.ps1
```

Force synthesis and mastering regeneration:

```powershell
& .\\voice-announcement-workbench\\run-samples.ps1 -Force
```

Rebuild mastered OGG files while preserving the raw model output:

```powershell
& .\\voice-announcement-workbench\\run-samples.ps1 -Remaster
```

Generate one voice or phrase:

```powershell
& .\voice-announcement-workbench\run-samples.ps1 -Speaker Vivian
& .\voice-announcement-workbench\run-samples.ps1 -Phrase chi-ji
```

Skip opening the listening page:

```powershell
& .\voice-announcement-workbench\run-samples.ps1 -NoOpen
```

The runner also accepts `-ManifestPath` and `-ScratchPath` for an isolated pack while reusing the environment and pinned model cache under the workbench's main `scratch/` directory.

## Key ability pack

`key-abilities-manifest.json` is the curated Aiden and Sohee pack at natural 1.0x tempo. It covers all 33 retail DPS and healer specs with no more than two offensive and two defensive callouts per spec. Spell Reflection, Grounding Totem, and Nether Ward are mandatory utility callouts. Tank specs are intentionally excluded.

Validate the manifest and generate its coverage report before synthesis:

```powershell
& .\voice-announcement-workbench\scratch\python\Scripts\python.exe `
  .\voice-announcement-workbench\validate-key-abilities.py
```

Generate the full isolated pack:

```powershell
& .\voice-announcement-workbench\run-samples.ps1 `
  -ManifestPath .\voice-announcement-workbench\key-abilities-manifest.json `
  -ScratchPath .\voice-announcement-workbench\scratch\key-abilities
```

The key-ability output contains 148 mastered clips: 74 callouts in each of the two selected voices. The coverage report and listening page include the callout category, spell IDs, and specialization mappings. The earlier five-phrase experiment remains under the default `scratch/` paths.

After a complete generation run, create the review archive containing mastered OGG files, the manifest, coverage matrix, and provenance report:

```powershell
& .\voice-announcement-workbench\package-key-abilities.ps1
```

## Outputs

```text
scratch/
|-- python/                 # isolated Python environment
|-- models/                 # pinned Hugging Face model cache
|-- pip-cache/              # package download cache
|-- raw-wav/                # untouched pre-mastering model output
|-- ogg/                    # mastered OGG Vorbis samples
|-- listening/index.html    # Aiden/Vivian/Serena comparison page
`-- reports/
    |-- environment.json
    |-- pip-freeze.txt
    `-- sample-run.json
```

Mastered clips currently preserve the model's natural 1.0x tempo, then target `-16 LUFS` integrated loudness and a `-1.5 dBTP` true-peak ceiling. Raw WAV files remain available so synthesis can be evaluated separately from tempo and loudness processing.

## Review guidance

Listen for:

- Correct pronunciation, especially Chi-Ji.
- Clear consonants over combat audio.
- Consistent voice identity between phrases.
- Unwanted pauses, breaths, repeated words, or invented words.
- Excessive dramatic delivery or listening fatigue.
- Whether Aiden, Vivian, or Serena remains clearer during rapid consecutive alerts.

A model-generated pronunciation is not accepted merely because it sounds plausible. Localized packs require review by fluent speakers before release.

## Troubleshooting

If CUDA is unavailable, rerun setup and confirm the environment contains the CUDA 12.8 PyTorch build rather than a CPU build. The environment report records the detected device and CUDA versions.

If the RTX 5080 runs out of memory, close GPU-heavy applications before generation. The 1.7B model runs one phrase at a time and does not need to coexist with the WoW client.

Pronunciation and shorthand are controlled by `spokenText` in the selected manifest, while `displayText` remains the canonical ability name. The Chi-Ji override is `Chee Jee`.

If OGG encoding fails, inspect the ffmpeg encoder list recorded during environment verification. The workbench uses the binary bundled by `imageio-ffmpeg` and does not require a global ffmpeg installation.

## Promotion boundary

This experiment does not modify SweepyBoop's Lua runtime, TOC files, or shipped sound assets. Promotion into the addon is a separate reviewed change after voice quality, phrase selection, Blizzard API behavior, package size, and licensing provenance are accepted.
