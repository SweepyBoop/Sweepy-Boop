# Voice Announcement Workbench

This directory contains the reproducible, local-only Qwen3-TTS workbench for SweepyBoop arena important-aura announcements. It does not change addon runtime code or promote experimental files into the addon's shipped sound directories.

## Current results

The selected key-ability pack uses:

- Model: `Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice`
- Revision: `0c0e3051f131929182e2c023b9537f8b1c68adfe`
- Voices: Aiden and Sohee
- Language: English
- Delivery: plain, with no instruction prompt
- Tempo: natural 1.0x
- Scope: 74 curated callouts covering all 33 retail DPS and healer specs
- Output: 148 mono 24 kHz OGG Vorbis files

The committed review copy is under `Docs/VoiceAnnouncementReview-KeyAbilities`. Open its `listening/index.html` file to review every Aiden and Sohee clip without installing Python or downloading the model.

The next quality comparison uses two original faction-flavored voices created with Qwen VoiceDesign and then held consistent with Qwen Base voice cloning. See `faction-voice-manifest.json` and the workflow below. `PAID_VOICE_OPTIONS.md` remains a record of external and alternative models, but ElevenLabs is not the preferred path because MiniCC already uses it.

## Faction voice study

The tracked faction-voice experiment defines two original archetypes rather than imitating named Warcraft characters or performers:

- `Alliance Commander`: a clear adult female studio voice with a polished midrange, even pace, precise consonants, and quiet authority.
- `Horde Commander`: a clear adult male studio voice with a warm baritone, even pace, firm consonants, and quiet authority.

Both descriptions explicitly request plain delivery with minimal emotion and exclude dramatic emphasis, character acting, accent imitation, and incidental vocalizations. The manifest also pins conservative sampling settings, bounded output lengths, terminal punctuation, and reviewed phrase-specific seed overrides. `Cheejee` is synthesized as one token with fixed seeds to avoid an exaggerated internal pause.

`Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign` creates one reference WAV for each archetype. `Qwen/Qwen3-TTS-12Hz-1.7B-Base` then extracts the speaker embedding from that frozen reference and renders the ten difficult comparison callouts. Speaker-embedding-only cloning is intentional: full in-context continuation produced breaths, vocalizations, and exaggerated pauses before very short phrases. Existing references are never replaced unless `--redesign` is passed; changing a reference also forces regeneration of its selected callouts.

Validate and generate the complete comparison on macOS:

```bash
voice-announcement-workbench/scratch/python/bin/python \
  voice-announcement-workbench/validate-faction-voices.py
bash voice-announcement-workbench/run-faction-voices.sh
```

Useful focused runs:

```bash
# Design or inspect references without loading the clone model.
bash voice-announcement-workbench/run-faction-voices.sh --design-only

# Generate one voice or one phrase.
bash voice-announcement-workbench/run-faction-voices.sh --speaker alliance-commander
bash voice-announcement-workbench/run-faction-voices.sh --phrase combustion

# Explicitly replace a selected reference, or remaster without synthesizing again.
bash voice-announcement-workbench/run-faction-voices.sh --speaker alliance-commander --redesign
bash voice-announcement-workbench/run-faction-voices.sh --remaster
```

Generated references, cloned WAVs, mastered OGG files, reports, model snapshots, and the listening page remain under `voice-announcement-workbench/scratch/`. The manifest records reproducible inputs, while the run report records the exact generated reference and output hashes. Because synthesis may vary across devices, an approved reference WAV must eventually be exported with the release provenance rather than recreated from its seed alone.

The revised 2026-09-29 Apple Metal run produced two references and 20 mastered comparison clips. The current Alliance reference SHA-256 is `DCB7499F00A62577615FBB2DE32DC156BFCC56A13ECF1B5068BFC6F56C316519`; the current Horde reference SHA-256 is `50E52EB550990CAA497B2DF10C040297989F6990C2A5BE8143973DE733C886FB`. Superseded references are preserved under `scratch/faction-voices/references/archive/`. These local artifacts do not promote either voice into shipped assets.

## Repository contract

- Keep durable documentation, manifests, and automation in this directory.
- Keep Python environments, model weights, caches, raw audio, mastered working audio, and reports under `scratch/`.
- `scratch/` is intentionally ignored because model weights and environments are too large for source control.
- Keep explicitly selected review artifacts under `Docs/VoiceAnnouncementReview-KeyAbilities` so they are available on another checkout.
- This entire workbench is excluded from addon deployment and publication.
- Do not copy audio into the addon's runtime sound directories until a human has reviewed and approved it.

## Pick up on another device

After the branch containing these files has been committed and pushed, run the following on the other device:

```bash
git clone https://github.com/SweepyBoop/Sweepy-Boop.git
cd Sweepy-Boop
git fetch origin
git switch tts
git pull --ff-only
```

If the repository already exists:

```bash
cd /path/to/Sweepy-Boop
git fetch origin
git switch tts
git pull --ff-only
```

Reviewing the committed assets does not require the generation environment:

```bash
open Docs/VoiceAnnouncementReview-KeyAbilities/listening/index.html
```

The page uses relative links to the committed OGG files. If a browser blocks local media, open the same file in another browser or run `python3 -m http.server` from the repository root and visit `http://localhost:8000/Docs/VoiceAnnouncementReview-KeyAbilities/listening/`.

## macOS prerequisites

Apple Silicon is preferred. Generation uses Metal Performance Shaders (`mps`) when available and falls back to CPU. The pinned 1.7B model is substantially slower on a MacBook than on the original RTX 5080 workstation, and a machine with at least 24 GB unified memory is recommended. Reviewing the committed assets has no such requirement.

Install the command-line tools, Homebrew, and Python 3.10 if they are not already present:

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python@3.10
```

If `python3.10` is not on `PATH`, provide the Homebrew executable explicitly:

```bash
PYTHON_BIN="$(brew --prefix python@3.10)/bin/python3.10" \
  bash voice-announcement-workbench/setup-environment.sh
```

Otherwise, set up the isolated environment with:

```bash
bash voice-announcement-workbench/setup-environment.sh
```

This creates `voice-announcement-workbench/scratch/python`, installs the pinned Python dependencies, and verifies the detected device and bundled ffmpeg. The first generation downloads and validates the complete pinned model under `voice-announcement-workbench/scratch/models`. Allow at least 12 GB of free disk space for the preset-voice workflow. The faction-voice workflow pins separate VoiceDesign and Base snapshots; allow at least 24 GB for both models, the environment, caches, and generated working files.

To recreate only the ignored Python environment:

```bash
bash voice-announcement-workbench/setup-environment.sh --recreate
```

## Generate on macOS

Validate the curated manifest first:

```bash
voice-announcement-workbench/scratch/python/bin/python \
  voice-announcement-workbench/validate-key-abilities.py
```

Generate or reuse the complete Aiden and Sohee key-ability pack:

```bash
bash voice-announcement-workbench/run-samples.sh --key-abilities
```

The runner selects CUDA first, then Apple Metal, then CPU. To make the choice explicit:

```bash
bash voice-announcement-workbench/run-samples.sh --key-abilities --device mps
bash voice-announcement-workbench/run-samples.sh --key-abilities --device cpu
```

Generate one voice or one phrase while reviewing pronunciation:

```bash
bash voice-announcement-workbench/run-samples.sh --key-abilities --speaker Sohee
bash voice-announcement-workbench/run-samples.sh --key-abilities --phrase invoke-chi-ji
```

Force synthesis, remaster retained WAVs, or skip opening the page:

```bash
bash voice-announcement-workbench/run-samples.sh --key-abilities --force
bash voice-announcement-workbench/run-samples.sh --key-abilities --remaster
bash voice-announcement-workbench/run-samples.sh --key-abilities --no-open
```

Package a complete generated run for external review:

```bash
bash voice-announcement-workbench/package-key-abilities.sh
```

The archive is written to `voice-announcement-workbench/scratch/key-abilities/aiden-sohee-key-abilities-1.0x.zip` and contains the 148 mastered OGG files, curated manifest, coverage matrix, and provenance report.

## Refresh the Docs review copy

After a complete, reviewed generation run, export a sanitized and portable copy for source control:

```bash
voice-announcement-workbench/scratch/python/bin/python \
  voice-announcement-workbench/export-review-assets.py
```

On Windows:

```powershell
& .\voice-announcement-workbench\scratch\python\Scripts\python.exe `
  .\voice-announcement-workbench\export-review-assets.py
```

This replaces only `Docs/VoiceAnnouncementReview-KeyAbilities`, copies all 148 mastered OGG files and the listening page, removes machine-specific paths from the review report, and creates a portable ZIP plus its SHA-256 file. Review the resulting changes before committing them.

## Generate on Windows

From PowerShell, create the CUDA environment:

```powershell
& .\voice-announcement-workbench\setup-environment.ps1
```

Validate and generate the key-ability pack:

```powershell
& .\voice-announcement-workbench\scratch\python\Scripts\python.exe `
  .\voice-announcement-workbench\validate-key-abilities.py

& .\voice-announcement-workbench\run-samples.ps1 `
  -ManifestPath .\voice-announcement-workbench\key-abilities-manifest.json `
  -ScratchPath .\voice-announcement-workbench\scratch\key-abilities
```

Create the review archive:

```powershell
& .\voice-announcement-workbench\package-key-abilities.ps1
```

The original Aiden, Vivian, and Serena five-phrase comparison remains available through the default runner invocation:

```powershell
& .\voice-announcement-workbench\run-samples.ps1
```

## Output layout

```text
voice-announcement-workbench/scratch/
|-- python/                         # isolated Python environment
|-- models/                         # shared pinned Hugging Face model cache
|-- pip-cache/                      # package download cache
|-- key-abilities/
|   |-- raw-wav/                    # untouched model output
|   |-- ogg/                        # mastered Aiden and Sohee clips
|   |-- listening/index.html        # local comparison page
|   `-- reports/                    # environment, coverage, and run provenance
|-- faction-voices/
|   |-- references/                 # frozen VoiceDesign reference WAVs
|   |-- raw-wav/                    # untouched Base-cloned callouts
|   |-- ogg/                        # mastered faction-voice callouts
|   |-- listening/index.html        # two-voice comparison page
|   `-- reports/                    # environment, reference, run, and validation data
`-- raw-wav, ogg, listening, reports # original five-phrase experiment
```

Mastered clips preserve natural 1.0x tempo, target `-16 LUFS` integrated loudness, and enforce a `-1.5 dBTP` true-peak ceiling. Raw WAV files remain available so synthesis can be evaluated separately from mastering.

## Reproducibility notes

The manifest fixes the model revision, voices, spoken text, seeds, and mastering settings. `seedOverrides` records scoped retries for a single voice and phrase without changing other clips. The generated report records the final WAV and OGG SHA-256 hashes.

Generated speech is not guaranteed to be bit-for-bit identical across CUDA, Apple Metal, and CPU or across dependency builds. Treat the committed files under `Docs/VoiceAnnouncementReview-KeyAbilities` as the review baseline. A newly generated Mac pack should be reviewed rather than assumed equivalent because it used the same seed.

For designed voices, the reference WAV is part of the voice identity. Reuse the frozen file under `scratch/faction-voices/references` for every comparison run and use `--redesign` only when intentionally evaluating a new identity. The run report records the exact reference SHA-256 used by each cloned sample.

The generator uses `bfloat16` on CUDA and conservative `float32` on Apple Metal or CPU. `PYTORCH_ENABLE_MPS_FALLBACK=1` allows unsupported Metal operations to fall back to CPU. If MPS generation fails or produces invalid audio, rerun the selected phrase with `--device cpu`.

## Review guidance

Listen for correct pronunciation, clear consonants over combat audio, consistent voice identity, unwanted pauses or repeated words, and fatigue during rapid consecutive alerts. Pay particular attention to Chi-Ji, class-specific names, and one-word shorthand.

A model-generated pronunciation is not accepted merely because it sounds plausible. Localized packs require review by fluent speakers before release.

## Troubleshooting

If setup cannot find Python, set `PYTHON_BIN` to the absolute Python 3.10 executable. If model download is interrupted, rerun generation; `hf-xet` resumes the pinned snapshot download in the ignored model cache.

If a MacBook runs out of unified memory, close memory-heavy applications and retry one phrase with `--device cpu`. The generator processes one phrase at a time. Do not substitute the 0.6B model without creating a separate manifest and review baseline.

Pronunciation and shorthand are controlled by `spokenText` in the selected manifest, while `displayText` remains the canonical ability name. The Chi-Ji pronunciation is represented as `Chee Jee`.

If OGG encoding fails, inspect `scratch/reports/environment.json`. The workbench uses the ffmpeg binary bundled by `imageio-ffmpeg` and does not require a global ffmpeg installation.

## Promotion boundary

This experiment does not modify SweepyBoop's Lua runtime, TOC files, or shipped sound assets. Promotion into the addon is a separate reviewed change after voice quality, phrase selection, Blizzard API behavior, package size, and licensing provenance are accepted.
