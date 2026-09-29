# Paid and Custom Voice Options

## Decision status

Qwen3-TTS Aiden and Sohee remain the reproducible preset-voice baseline. The preferred custom-voice experiment now uses the Apache-licensed Qwen VoiceDesign model to create original Alliance and Horde commander archetypes, then freezes those references and renders callouts with the Qwen Base clone model. This provides a distinct identity without duplicating MiniCC's ElevenLabs dependency or cloning a real performer.

Recommended evaluation order:

1. Qwen VoiceDesign plus Qwen Base cloning as the primary original-voice candidate.
2. Kokoro as a fast stock-voice comparison, with special scrutiny because its model card identifies short utterances as a weakness.
3. Chatterbox Turbo only with a clearly documented built-in voice provenance or an owned reference recording.
4. CosyVoice 3 if multilingual pronunciation control warrants its additional setup complexity.
5. Cartesia or ElevenLabs only as optional hosted quality ceilings after local candidates are reviewed.

Provider model names, prices, quotas, and commercial terms change frequently. Record the exact values visible in the account at generation time rather than treating this document as a pricing source.

## Provider shortlist

| Provider | Primary advantage | Main concern | Recommended role |
| --- | --- | --- | --- |
| Qwen VoiceDesign + Base | Original voice design, strong multilingual support, local generation, and Apache 2.0 model terms | Requires two model snapshots and a frozen reference workflow | Primary custom-voice bake-off |
| Kokoro | Tiny, fast, Apache 2.0, and many built-in voices | Its model card warns that utterances below 10-20 tokens may be weak | Fast stock-voice comparison |
| Chatterbox Turbo | Strong naturalness, expressive control, local inference, and MIT model terms | Custom identity depends on reference-audio rights; built-in voice provenance needs confirmation | Licensed-reference comparison |
| CosyVoice 3 | Multilingual cloning and direct pronunciation controls | More setup and reference-voice governance work | Localization research path |
| ElevenLabs | Strong naturalness, cloning quality, voice library, and mature API | Duplicates MiniCC's provider choice; paid-tier rights and voice eligibility must be checked | Optional hosted ceiling only |
| Cartesia | Crisp low-latency speech with useful pacing and emotion control | Voice-library and commercial terms must be checked for redistribution | Optional tactical hosted ceiling |
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
3. Chee Jee
4. Meta
5. Null Shroud
6. Bestial Wrath
7. Coordinated Assault
8. Touch of the Magi
9. Apotheosis
10. Spell Reflection

For each candidate voice:

1. Generate all ten phrases with neutral, plain delivery.
2. Keep provider-side speed at natural pace unless the provider's normal output is unusably slow.
3. Apply the same local silence trimming, 1.0x tempo, `-16 LUFS`, and `-1.5 dBTP` mastering used by the Qwen baseline.
4. Preserve the unmastered provider response separately from the mastered OGG.
5. Randomize voice/provider labels in the listening page.
6. Compare over representative arena combat audio, not only through headphones in silence.
7. Score pronunciation, consonant clarity, duration, voice consistency, fatigue, and consecutive-alert intelligibility.
8. Reject any voice with repeated words, invented syllables, unstable accent, or unexplained identity/licensing provenance.

The catalog contains little text, so evaluation should consume only a few thousand characters even with retries. An entry paid plan may be sufficient, but verify current character accounting and commercial rights before purchasing.

## Recommended comparison matrix

Evaluate at least these six rows in two manageable rounds:

| Candidate | Source | Purpose |
| --- | --- | --- |
| Aiden | Pinned Qwen CustomVoice baseline | Male preset baseline |
| Sohee | Pinned Qwen CustomVoice baseline | Female preset baseline |
| Alliance Commander | Pinned Qwen VoiceDesign reference and Base clone | Original female candidate |
| Horde Commander | Pinned Qwen VoiceDesign reference and Base clone | Original male candidate |
| Heart | Pinned Kokoro stock voice | Fast female comparison |
| Fenrir | Pinned Kokoro stock voice | Fast male comparison |

Test a hosted provider only if none of the local candidates is release quality or an external ceiling is needed to calibrate the review.

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

1. Review the committed Qwen baseline at `Docs/VoiceAnnouncementReview-KeyAbilities/listening/index.html`.
2. Read `voice-announcement-workbench/README.md` for the local mastering environment.
3. Generate the two designed faction references and ten-phrase clone set with `run-faction-voices.sh` or `run-faction-voices.ps1`.
4. Compare the designed voices with the Qwen preset baseline and the ignored Kokoro experiment.
5. Master every candidate with the same settings as the Qwen baseline.
6. Collect feedback before generating all 74 callouts.
7. If a hosted comparison is still needed, save API keys only in local environment variables and record the exact commercial terms.
8. Document the winning model, reference provenance, settings, and review result before promoting any assets.

No paid provider has been selected. The Qwen VoiceDesign-to-Base workflow is the preferred custom-voice path unless listening review shows a clear quality problem.
