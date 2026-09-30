# CosyVoice Next Steps

## Current conclusion

Do not promote the current CosyVoice full pack yet.

The selected `FunAudioLLM/Fun-CosyVoice3-0.5B-2512` checkpoint is a zero-shot voice-cloning model. It does not contain built-in production speakers (`spk2info.pt` is absent), so the supplied prompt WAV determines voice identity. The shared Instruct2 description controls delivery but does not create distinct male and female voices by itself.

The current references came from the earlier Qwen VoiceDesign experiment:

- Alliance Commander: `scratch/faction-voices/references/alliance-commander.wav`
- Horde Commander: `scratch/faction-voices/references/horde-commander.wav`

Automated transcription found an unintended word at the start of the Alliance reference:

```text
court. Today we are checking a clear and steady voice...
```

The Horde reference transcribes correctly, but its downstream short-callout pronunciation remains inconsistent. This means reference quality is a likely contributor, but not necessarily the only source of errors.

## Options for the next session

### 1. Replace both references with clean licensed recordings (recommended)

Record or commission one neutral 5-10 second English prompt for each voice. Use the same script and recording conditions for both speakers. Requirements:

- Clean start and ending with no breaths, clicks, filler, room noise, or clipped consonants.
- Steady conversational cadence rather than character acting.
- Mono lossless WAV at a supported sample rate.
- Exact transcript recorded with the file.
- Written permission covering voice-model use and redistribution of generated clips.

This gives CosyVoice the strongest chance of stable cloning and removes Qwen from the production voice lineage.

### 2. Clean and shorten the current synthetic references

Create new experimental references from verified clean portions of the existing Qwen WAVs. Remove the unintended Alliance onset and use a shorter phoneme-rich excerpt for each voice.

This is inexpensive and preserves the current voice identities, but it does not eliminate Qwen from the provenance chain. Run the four-phrase bake-off again before deciding whether the cleaned references are sufficient.

### 3. Evaluate an older CosyVoice SFT checkpoint

`CosyVoice-300M-SFT` exposes built-in speaker IDs through `list_available_spks()`. It is a different and older checkpoint than CosyVoice 3, and its built-in English voice availability and quality must be verified before use.

Use this only as a quick reference-quality comparison. Do not assume its built-in voices are suitable for the Alliance/Horde identities or redistribution without checking their provenance.

### 4. Use a hosted non-ElevenLabs provider

Cartesia remains the preferred hosted fallback for concise tactical speech. Confirm custom-voice consent and generated-audio redistribution rights before producing a full pack.

### 5. Record the final callouts directly

A commissioned actor recording all 74 phrases per voice provides the strongest stability and eliminates TTS onset, hallucination, and pronunciation failures. This has the highest coordination cost but the lowest technical risk.

## Recommended next experiment

1. Obtain or prepare two clean replacement reference WAVs.
2. Keep the same generic Instruct2 instruction for both voices so only reference identity differs.
3. Generate two takes for these four phrases:
   - Adrenaline
   - Turtle
   - Fort Brew
   - Tyrant
4. Reject a reference if either take has a missing syllable, added word, filler sound, or meaningful identity drift.
5. If both references pass, test the remaining six difficult phrases before generating the full catalog.
6. Promote nothing until the complete selected pack receives human listening review.

## Existing artifacts

- Comparison page: `scratch/cosyvoice3-zero-shot/listening/index.html`
- Preferred Take 1 page: `scratch/cosyvoice3-zero-shot/listening/instruct2-take1.html`
- Full Instruct2 candidate: `scratch/cosyvoice3-instruct2/listening/index.html`
- Automated transcription triage: `scratch/cosyvoice3-instruct2/reports/asr-audit.json`
- CosyVoice setup: `setup-cosyvoice3-environment.sh`
- Comparison manifest: `cosyvoice3-sample-manifest.json`
- Full-pack manifest: `cosyvoice3-pack-manifest.json`

The current Qwen review pack under `Docs/VoiceAnnouncementReview-KeyAbilities` remains historical evaluation material and should not be used as the production source.
