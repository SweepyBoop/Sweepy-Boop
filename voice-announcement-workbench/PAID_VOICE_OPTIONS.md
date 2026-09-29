# Paid and Custom Voice Options

## Decision status

Qwen3-TTS Aiden and Sohee remain the reproducible, free local baseline. Before promoting audio into the addon, run a small blind comparison against paid providers that offer stronger voice identity, pronunciation controls, and short-phrase consistency.

Recommended evaluation order:

1. ElevenLabs as the primary quality-first candidate.
2. Cartesia as a crisp tactical-callout alternative.
3. Resemble AI if consent, provenance, and commercial voice governance are the deciding factors.
4. PlayHT as an additional library and cloning comparison.

Provider model names, prices, quotas, and commercial terms change frequently. Record the exact values visible in the account at generation time rather than treating this document as a pricing source.

## Provider shortlist

| Provider | Primary advantage | Main concern | Recommended role |
| --- | --- | --- | --- |
| ElevenLabs | Strong naturalness, cloning quality, voice library, pronunciation dictionaries, and mature API | Paid-tier rights and custom-voice eligibility must be checked; public-figure impersonation may be restricted | First paid bake-off |
| Cartesia | Crisp low-latency speech with useful pacing and emotion control | Voice-library and commercial terms must be checked for redistribution | Tactical-callout comparison |
| Resemble AI | Custom voices with stronger consent and enterprise provenance workflows | More setup and potentially higher cost | Governed custom voice |
| PlayHT | Broad voice selection and cloning options | Short-word consistency and current redistribution rights require testing | Optional fourth comparison |
| Azure Custom Neural Voice | Formal consent and deployment controls | Approval process and integration overhead are high | Future licensed production voice |
| Fish Speech, F5-TTS, or CosyVoice | More local customization without per-generation API charges | More engineering, hardware, model-license, and voice-rights work | Research path, not the first paid test |

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

Evaluate at least these four rows:

| Candidate | Source | Purpose |
| --- | --- | --- |
| Aiden | Pinned local Qwen baseline | Male free baseline |
| Sohee | Pinned local Qwen baseline | Female free baseline |
| Paid voice A | ElevenLabs current highest-quality eligible model | Quality ceiling |
| Paid voice B | Cartesia current production model | Crisp tactical alternative |

Add Resemble or PlayHT only if neither paid candidate is clearly better than the Qwen baseline or if their licensing workflow provides a material advantage.

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
3. Choose one eligible ElevenLabs voice and one eligible Cartesia voice.
4. Save API keys only in local environment variables or an ignored secrets file.
5. Generate the ten-phrase bake-off under an ignored directory such as `voice-announcement-workbench/scratch/paid-evaluation`.
6. Master every candidate with the same settings as the Qwen baseline.
7. Build a blind listening page and collect feedback before generating all 74 callouts.
8. Document the winning provider, model, voice rights, settings, cost, and review result before promoting any assets.

No paid provider has been selected yet. Qwen remains the fallback until the blind test demonstrates a clear quality improvement with acceptable rights and redistribution terms.
