# Voice Announcement Workbench

This directory contains reproducible, local-only TTS experiments for SweepyBoop arena important-aura announcements. It does not change addon runtime code or promote experimental files into the addon's shipped sound directories.

## Current promoted Cartesia review pack

The committed review pack uses:

- Provider/model: Cartesia `sonic-3.6`, API version `2026-08-14`
- Voices: Female - Gemma and Male - Archie
- Language/locale: English, `en-US`
- Delivery: plain stock-voice callouts with identical speed/volume settings
- Duration: every mastered clip is at most 1.0 seconds
- Scope: 77 curated arena callouts per voice, including cross-class trinket and all 33 retail DPS/healer specs
- Output: 154 mono OGG Vorbis review files

The committed review copy is under `Docs/VoiceAnnouncementReview-KeyAbilities`. Open its `listening/index.html` file to review both voices without an API key or local environment. The pack is review-only and is not wired into addon runtime behavior or the published addon archive.

The Qwen VoiceDesign/Base, CosyVoice, and Aiden/Sohee experiments remain reproducible historical baselines in this workbench and version control.

## Cartesia stock voice workflow

Cartesia is the preferred no-seed hosted evaluation. The workbench queries the authenticated stock catalog, selects one neutral English masculine voice and one neutral English feminine voice, and generates Adrenaline, Turtle, Fort Brew, and Tyrant with identical `sonic-3.6` settings except for voice ID.

Set up the API key from a terminal opened at the repository root:

1. Open [Cartesia API Keys](https://play.cartesia.ai/keys), create a key, and copy the secret when it is displayed. Never paste the key into chat or commit it to the repository.
2. Create the isolated local environment:

```bash
bash voice-announcement-workbench/setup-cartesia-environment.sh
```

3. Enter the key without displaying it or adding it to shell history:

```bash
unset CARTESIA_API_KEY
read -s "CARTESIA_API_KEY?Paste Cartesia API key: "
echo
export CARTESIA_API_KEY
printf 'Cartesia API key loaded: %d characters\n' "${#CARTESIA_API_KEY}"
```

4. Verify catalog access without generating billable audio:

```bash
bash voice-announcement-workbench/run-cartesia-samples.sh --discover-only
```

5. Generate and validate the four-phrase comparison:

```bash
bash voice-announcement-workbench/run-cartesia-samples.sh
```

The export applies only to the current terminal session. Repeat step 3 after opening a new terminal or restarting the shell.

The key is read only from the process environment and is never stored in manifests or reports. Provider WAVs, catalog metadata, mastered OGGs, provenance, and the blind listening page remain under ignored `voice-announcement-workbench/scratch/cartesia-bakeoff/`.

The approved sample voices are Female - Gemma and Male - Archie. Generate or resume the full 77-callout-per-voice candidate with:

```bash
bash voice-announcement-workbench/run-cartesia-samples.sh --full
```

To generate only selected additions, create a local text file containing one manifest phrase ID per line. Blank lines and text after `#` are ignored. The selected results are merged into the existing full report instead of replacing it:

```bash
bash voice-announcement-workbench/run-cartesia-samples.sh \
  --phrases-file voice-announcement-workbench/scratch/cartesia-full-pack/selected-phrases.txt
```

Full-pack provider WAVs

Full-pack provider WAVs, mastered OGGs, reports, and the listening page remain under ignored `voice-announcement-workbench/scratch/cartesia-full-pack/`. The approved pack was promoted to `Docs/VoiceAnnouncementReview-KeyAbilities` on 2026-10-01 after the user confirmed their Cartesia tier permits committing and redistributing the generated OGG files.

## Next model: CosyVoice 3

See `COSYVOICE_NEXT_STEPS.md` for the current findings, reference-audio options, and the recommended next experiment.

The next prototype uses pinned `FunAudioLLM/Fun-CosyVoice3-0.5B-2512` with the existing synthetic Alliance and Horde references. The first bake-off covers four phrases that exposed Qwen failures, two prompt-audio modes, and two takes per mode, for 32 samples that measure repeatability rather than selecting only the best take.

Acceptance criteria:

- Clean word onsets without sacrificial prefixes, semantic cropping, or manual repair.
- Stable speaker identity and cadence across repeated generations.
- Correct game-term pronunciation, using English phoneme inpainting where needed.
- Natural mastered duration at or below 1.0 seconds.
- Apache 2.0 model and dependency provenance captured before promotion.

If zero-shot cloning is not stable enough, build a reviewed sentence-length synthetic corpus for each voice and evaluate CosyVoice speaker adaptation or fine-tuning. Chatterbox Turbo is the secondary local candidate; Cartesia is the preferred hosted fallback.

Set up the isolated CPU environment and run the comparison on macOS:

```bash
bash voice-announcement-workbench/setup-cosyvoice3-environment.sh
bash voice-announcement-workbench/run-cosyvoice3-samples.sh
```

A smaller smoke test can select one voice, phrase, mode, or take:

```bash
bash voice-announcement-workbench/run-cosyvoice3-samples.sh \
  --speaker alliance-commander \
  --phrase adrenaline-rush \
  --take 1
```

CosyVoice currently uses CPU rather than Apple Metal on macOS. The setup script installs a pinned local Python 3.10 runtime when one is not already available. Its source checkout, environment, model snapshot, generated WAV/OGG files, reports, and listening page remain under ignored `voice-announcement-workbench/scratch/cosyvoice3-*` paths.

The first 32-sample run completed successfully. All 16 Instruct2 samples were naturally below one second (`0.29-0.72s`), while 9 of 16 cross-lingual samples exceeded one second and several exhibited repetition or incorrect content. Instruct2 Take 1 is the selected mode because listening review found more clipped initial syllables in Take 2. Regenerating Take 1 with the same seeds produced identical raw WAV hashes on the same machine; OGG container hashes may still change when remastered. Review the original bake-off at `scratch/cosyvoice3-zero-shot/listening/index.html`.

The full 74-callout-per-voice Instruct2 Take 1 candidate is generated under `scratch/cosyvoice3-instruct2/`. Run or resume it with:

```bash
bash voice-announcement-workbench/run-cosyvoice3-samples.sh --full
```

The full-pack manifest enforces the one-second mastered duration cap. Review all 148 candidates at `scratch/cosyvoice3-instruct2/listening/index.html`. Automated Whisper transcription triage flagged 45 clips below the conservative similarity threshold, including several likely repetition or pronunciation failures; this is a review queue rather than an automatic rejection because very short game terms are difficult for ASR. No CosyVoice output has been promoted.

## Historical Qwen faction voice study

The tracked faction-voice experiment defines two original archetypes rather than imitating named Warcraft characters or performers:

- `Alliance Commander`: a clear adult female studio voice with a polished midrange, even pace, precise consonants, and quiet authority.
- `Horde Commander`: a clear adult male studio voice with a warm baritone, even pace, firm consonants, and quiet authority.

Both descriptions explicitly request plain delivery with minimal emotion and exclude dramatic emphasis, character acting, accent imitation, and incidental vocalizations. The manifest also pins conservative sampling settings, bounded output lengths, terminal punctuation, reviewed phrase-specific seed overrides, and a `1.12x` minimum mastering tempo for Coordinated Assault. Every clip is capped at `1.0s`; only clips exceeding that limit receive the minimum additional tempo increase needed to fit. `Cheejee` is synthesized as one token with fixed seeds to avoid an exaggerated internal pause.

`Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign` creates one reference WAV for each archetype. `Qwen/Qwen3-TTS-12Hz-1.7B-Base` then extracts the speaker embedding from that frozen reference and renders the complete 74-callout catalog. Speaker-embedding-only cloning is intentional: full in-context continuation produced breaths, vocalizations, and exaggerated pauses before very short phrases. Each synthesis request starts with a disposable `Ready.` utterance separated from the callout by a hard line break; the generator detects the resulting silence boundary, preserves 20 ms of clean lead-in, and masters only the callout. Failed boundary detection triggers a bounded deterministic seed retry instead of accepting or hanging on malformed audio. Existing references are never replaced unless `--redesign` is passed; changing a reference also forces regeneration of its selected callouts.

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

Generated working files, reports, model snapshots, and the listening page remain under `voice-announcement-workbench/scratch/`. The manifest records reproducible inputs, while the run report records the exact generated reference and output hashes. Because synthesis may vary across devices, the approved reference WAVs are also committed in the portable review pack rather than recreated from their seeds alone.

The promoted 2026-09-29 Apple Metal run contains two references and 148 mastered clips. The Alliance reference SHA-256 is `DCB7499F00A62577615FBB2DE32DC156BFCC56A13ECF1B5068BFC6F56C316519`; the Horde reference SHA-256 is `50E52EB550990CAA497B2DF10C040297989F6990C2A5BE8143973DE733C886FB`. Superseded references remain only under ignored `scratch/faction-voices/references/archive/`. The committed files are review assets and are not shipped by the addon.

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

This replaces only `Docs/VoiceAnnouncementReview-KeyAbilities`, copies the 20 approved mastered OGG files, two frozen reference WAVs, listening page, manifest, and sanitized provenance, and creates `alliance-horde-faction-voices-1.0s.zip` plus its SHA-256 file. The exporter builds and validates a staging tree before replacing the prior review pack. Review the resulting changes before committing them.

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
|   |-- padded-wav/                 # untouched `Ready.` plus callout generations
|   |-- raw-wav/                    # deterministically cropped callouts
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
