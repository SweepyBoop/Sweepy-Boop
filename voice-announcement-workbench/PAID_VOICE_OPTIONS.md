# Paid and Custom Voice Options

## Decision status

The Alliance Commander and Horde Commander Qwen pack is retained as the historical custom-voice baseline, but it is not the production recommendation. Repeated short-utterance onset artifacts and fragile alignment made Qwen Base cloning too costly to stabilize. The next evaluation will use the Apache-licensed CosyVoice 3 model with the same synthetic references.

Recommended evaluation order:

1. CosyVoice 3 zero-shot cloning as the primary local candidate.
2. CosyVoice 3 speaker adaptation or fine-tuning if zero-shot identity is not stable enough.
3. Cartesia as the preferred hosted fallback for crisp short-form speech.
4. Chatterbox Turbo as a secondary local comparison.
5. Qwen and Kokoro as historical baselines only.
6. ElevenLabs only as an optional quality ceiling because MiniCC already uses it.

Provider model names, prices, quotas, and commercial terms change frequently. Record the exact values visible in the account at generation time rather than treating this document as a pricing source.

## Provider shortlist

| Provider | Primary advantage | Main concern | Recommended role |
| --- | --- | --- | --- |
| CosyVoice 3 | Apache 2.0, multilingual cloning, speaker adaptation, and English phoneme controls | More setup and training workflow work | Primary production candidate |
| Cartesia | Crisp low-latency speech with useful pacing and emotion control | Hosted service; redistribution rights must be confirmed | Preferred hosted fallback |
| Chatterbox Turbo | Strong naturalness, expressive control, local inference, and MIT model terms | Short-callout stability still requires measurement | Secondary local comparison |
| Qwen VoiceDesign + Base | Original local voice design and Apache 2.0 model terms | Short utterances required fragile prefix generation and alignment | Historical custom-voice baseline |
| Kokoro | Tiny, fast, Apache 2.0, and many built-in voices | Its model card warns that utterances below 10-20 tokens may be weak | Historical stock-voice baseline |
| ElevenLabs | Strong naturalness, cloning quality, voice library, and mature API | Duplicates MiniCC's provider choice; paid-tier rights and voice eligibility must be checked | Optional hosted ceiling only |
| Fish Speech or F5-TTS | Capable local customization | Current pretrained-weight terms are non-commercial or research-restricted | Do not use for distributed addon audio |

Do not select a provider only from long-form demos. Arena callouts expose different failure modes: one-word duration, incorrect stress, clipped consonants, invented syllables, and inconsistent delivery across consecutive alerts.

## Public figures and recognizable voices

Do not ship or distribute a voice that identifies itself as a real public figure unless all of the following are documented:

- The voice owner or authorized rights holder has granted appropriate permission.
- The provider permits the specific cloning and distribution use.
- Right-of-publicity, trademark, advertising, and applicable synthetic-media requirements have been reviewed.
- The generated assets can be redistributed with the addon under the selected paid plan.

A safer creative direction is a non-identifying original voice described by attributes such as `bombastic older statesman`, `clipped cadence`, or `confident arena commentator`. The result must not be marketed as, named after, or intentionally tuned to be a close impersonation of a real person.

Stock provider voices, commissioned voice actors with written synthetic-voice permission, and provider-created synthetic voices are preferred over scraped or community-supplied public-figure clones.

## Blind bake-off

Use ten difficult, representative callouts before paying to render the complete catalog:

1. Wings
2. Combustion
3. Cheejee
4. Metamorphosis
5. Null Shroud
6. Bestial Wrath
7. Coordinated Assault
8. Touch of the Magi
9. Apotheosis
10. Spell Reflection

For each candidate voice:

1. Generate all ten phrases with neutral, plain delivery.
2. Keep provider-side speed at natural pace unless the provider's normal output is unusably slow.
3. Apply the same `-16 LUFS`, `-1.5 dBTP`, and at-most-1.0-second mastering contract used by the historical Qwen faction pack, but reject any model that requires semantic onset cropping.
4. Preserve the unmastered provider response separately from the mastered OGG.
5. Randomize voice/provider labels in the listening page.
6. Compare over representative arena combat audio, not only through headphones in silence.
7. Score pronunciation, consonant clarity, duration, voice consistency, fatigue, and consecutive-alert intelligibility.
8. Reject any voice with repeated words, invented syllables, unstable accent, or unexplained identity/licensing provenance.

The catalog contains little text, so evaluation should consume only a few thousand characters even with retries. An entry paid plan may be sufficient, but verify current character accounting and commercial rights before purchasing.

## Recommended comparison matrix

Evaluate at least these four rows first:

| Candidate | Source | Purpose |
| --- | --- | --- |
| Alliance Commander | CosyVoice 3 with the approved synthetic reference | Primary female candidate |
| Horde Commander | CosyVoice 3 with the approved synthetic reference | Primary male candidate |
| Alliance Commander | Historical Qwen VoiceDesign/Base pack | Failure-rate and identity baseline |
| Horde Commander | Historical Qwen VoiceDesign/Base pack | Failure-rate and identity baseline |

Generate each test phrase multiple times and compare failure rate, not only the best take. Test Cartesia next if CosyVoice zero-shot or adapted output is not release quality.

## Provenance requirements

For every paid evaluation run, record:

- Provider and API endpoint.
- Exact model identifier and version if exposed.
- Voice identifier, display name, and whether it is stock, synthetic, instant-cloned, or professionally cloned.
- Voice owner consent or provider eligibility record for any custom voice.
- Account tier and the commercial/redistribution terms in effect on the generation date.
- Generation date, locale, text, pronunciation dictionary, style, stability, similarity, speed, and seed where supported.
- Original provider format and SHA-256 hash.
- Mastered OGG settings, duration, and SHA-256 hash.
- Human reviewer decision and any rejected pronunciations.

API keys, billing data, private consent documents, and proprietary reference recordings must stay outside the repository. Store only non-secret provenance summaries and links to the controlled records.

## MacBook pickup workflow

1. Review the promoted faction pack at `Docs/VoiceAnnouncementReview-KeyAbilities/listening/index.html`.
2. Read `voice-announcement-workbench/README.md` for the local generation and mastering environment.
3. Regenerate the faction set with `run-faction-voices.sh` or `run-faction-voices.ps1` only when intentionally changing a prompt, reference, phrase, or mastering rule.
4. Compare material changes against the committed pack and the historical preset/Kokoro experiments.
5. Export an approved run with `export-review-assets.py`, which preserves the exact references and sanitized provenance.
6. If a hosted comparison is still needed, save API keys only in local environment variables and record the exact commercial terms.

No paid provider has been selected. CosyVoice 3 is the selected next evaluation path; the Qwen VoiceDesign-to-Base pack remains historical comparison material.
