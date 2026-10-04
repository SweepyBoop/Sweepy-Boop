# Arena Important Aura Voice Announcements

## Status

The promoted review pack under `Docs/VoiceAnnouncementReview-KeyAbilities` contains 154 Cartesia `sonic-3.6` stock-voice clips: Gemma (female) and Archie (male), with 77 callouts per voice and every mastered OGG capped at one second. Qwen and CosyVoice remain historical workbench experiments.

The Mainline runtime integration is implemented on the current branch and pending in-game validation. It exposes 68 callout toggles: 67 aura callouts with 72 verified aura IDs, plus the event-backed enemy Trinket callout. Opponent buffs, including Windwalker Zenith, register on `arena1-3`, while Touch of the Magi, Breath of Eons, Deathmark, and Colossus Smash/Warbreaker register on `player`, `party1`, and `party2`. Grounding Totem and Blessing of Sanctuary are included, and Ascendance is split into Elemental, Enhancement, and Restoration controls. Enemy Trinket listens for `ARENA_COOLDOWNS_UPDATE`, but Retail 12.1 currently emits this global refresh event without the `unitTarget` documented by Warcraft Wiki. Payload-less updates cannot be attributed to an enemy and are deliberately ignored; playback requires an explicit `arena1`, `arena2`, or `arena3` token. Pet/summon abilities and other unverified totem/ground scopes remain omitted from runtime detection while their sound files stay packaged for later iterations. The feature is disabled by default; aura callouts register through Blizzard's restricted `C_UnitAuras` sound API at safe lifecycle boundaries, while Trinket never reads secret cooldown values. The Docs pack itself remains excluded from publication.

## Objective

Add optional spoken announcements for important enemy auras shown by SweepyBoop's standalone arena important-buff bars.

The feature should:

- Work with Retail's restricted aura model without reading secret aura data in addon Lua.
- Announce a curated set of important enemy aura applications.
- Support localized phrases and locale-specific voices.
- Generate all audio ahead of release with documented redistribution rights and no runtime provider dependency.
- Avoid any cloud API or per-generation service cost.
- Keep model runtimes and model weights out of the shipped addon.
- Keep the runtime small, event-driven, and consistent with existing SweepyBoop patterns.
- Allow sound packs to evolve without coupling audio production to the visual aura-bar implementation.

## Non-Goals

- Runtime speech synthesis inside WoW.
- Inspecting protected aura payloads to discover which aura appeared.
- Announcing every aura accepted by Blizzard's `HELPFUL|IMPORTANT` filter without an explicit spell registration.
- Shipping a machine-learning runtime or model weights with SweepyBoop.
- Voice cloning from a real person without documented permission.
- Guaranteeing that every localized pack ships in the first release.

## Blizzard API Contract

Retail exposes the engine-side registration API:

```lua
C_UnitAuras.AddAuraSound(trigger, soundInfo)
```

For an aura-added announcement, SweepyBoop would register:

```lua
local auraSoundID = C_UnitAuras.AddAuraSound(
    Enum.UnitAuraSoundTrigger.Added,
    {
        unitToken = "arena1",
        spellID = 190319,
        soundFileName = "Interface\\AddOns\\SweepyBoop\\Sounds\\ArenaImportantAuras\\enUS\\combustion.ogg",
        outputChannel = "Master",
    }
);
```

The generated Blizzard contract defines `UnitAuraSoundInfo` with:

- `unitToken`
- `spellID`
- `soundFileName` or `soundFileID`
- `outputChannel`

The API returns an optional registration handle. Every accepted handle must later be passed to:

```lua
C_UnitAuras.RemoveAuraSound(auraSoundID)
```

Relevant Blizzard source contracts:

- `C:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitAuraDocumentation.lua`
- `C:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitAuraConstantsDocumentation.lua`

`AddAuraSound` is restricted and only accepts untainted arguments. The addon must construct registrations from ordinary configuration, static spell IDs, static paths, and fixed unit tokens. It must not derive registration arguments from secret aura values.

Blizzard performs the aura match and audio playback internally. This is the essential privacy boundary: SweepyBoop registers known `(unit token, spell ID, sound)` tuples but does not learn which registered aura triggered playback. Generated callouts default to `arena1-3`; hostile debuffs that land on the friendly team explicitly override that scope with `player`, `party1`, and `party2`.

Blizzard also exposes `C_VoiceChat.SpeakText`, but that API only speaks text immediately. It does not create reusable audio files and cannot replace `AddAuraSound` when the triggering aura is secret. Offline audio assets are therefore required.

## Existing SweepyBoop Precedent

`C:\Users\kunhouseliu\Documents\GitHub\Sweepy-Boop\Misc\HealerInCrowdControl.lua` already uses the same Blizzard mechanism for a non-voice alert:

- Registers `Enum.UnitAuraSoundTrigger.Added` for known spell IDs.
- Stores returned aura-sound handles.
- Removes handles before rebuilding registrations.
- Defers registration refreshes that cannot safely run during combat.
- Uses fixed unit tokens and avoids branching on secret aura data.

The important-aura voice feature should preserve those lifecycle principles. Shared registration plumbing may be extracted only if doing so meaningfully reduces duplication without changing the existing healer-CC behavior.

## Audio Generation Choice

The selected review source is Cartesia `sonic-3.6` using stock voices Gemma (Alliance) and Archie (Horde). Both voices use identical `en-US`, speed, volume, output-format, and mastering settings; voice ID is the only provider-request difference for a given phrase. Provider WAVs are generated offline during the asset build, converted to mono OGG Vorbis, and never requested by the addon at runtime.

Reasons:

- Stock voices remove the prompt/seed-voice quality problem entirely.
- Short tactical phrases remained intelligible without sacrificial prefixes, semantic cropping, phoneme overrides, or seed selection.
- Male/female delivery stays consistent because request settings are identical except for voice ID.
- The full pack passed human listening review across 154 clips.
- Every mastered clip is capped at one second; clips already within the cap remain at natural tempo.
- Provider WAVs, request fingerprints, selected voice IDs, API/model versions, mastering measurements, and hashes are recorded in the workbench report.

The promoted portable review pack records Cartesia API version `2026-08-14`, model `sonic-3.6`, both stock voice IDs, voice-independent request fingerprints, provider-original hashes, mastered hashes/durations/tempos, and the user's 2026-10-01 redistribution-rights confirmation. Qwen and CosyVoice results remain historical baselines in version control and the workbench.

## Voice Direction

The target sound should be a concise tactical callout rather than conversational narration.

Initial direction:

```text
Clear competitive game announcer. Calm urgency, crisp consonants,
neutral delivery, no introductory phrase, no trailing commentary,
and minimal silence before and after the ability name.
```

Before committing to a voice, produce a small blind comparison set using abilities with difficult pronunciation and different rhythms, such as:

- Avenging Wrath
- Bestial Wrath
- Combustion
- Chi-Ji
- Metamorphosis
- Nullifying Shroud
- Power Infusion
- Shadow Blades
- Trueshot
- Yu'lon

Evaluate intelligibility over combat audio, consistency between clips, pronunciation, fatigue, and duration. Prefer clarity over dramatic expression.

If the selected CosyVoice voice is not sufficiently consistent across languages, evaluate speaker adaptation with a reviewed synthetic corpus before cross-language synthesis. Do not use a real-person reference recording unless SweepyBoop has explicit permission covering model use and redistribution.

## Source Manifest

Maintain a human-authored, provider-neutral manifest as the source of truth. JSON is preferred because it is easy to validate and consume from generation tools without executing addon code.

Proposed shape:

```json
{
  "schemaVersion": 1,
  "callouts": {
    "combustion": {
      "spellIds": [190319],
      "text": {
        "enUS": "Combustion",
        "deDE": "Einäschern",
        "esES": "Combustión",
        "frFR": "Combustion"
      },
      "enabled": true
    }
  }
}
```

Manifest rules:

- The stable callout key determines the output filename.
- Multiple spell IDs may map to one callout when they represent the same announced ability.
- Localized text is reviewed data, not generated by translating the English string during the build.
- Locales may override pronunciation separately from visible text.
- Spell IDs are explicit and reviewable.
- Disabled or retired entries remain representable without deleting historical context.
- The manifest must not infer its production spell catalog by parsing comments from Lua source.

A separate voice configuration should map each supported locale to a model voice, generation instructions, language code, and optional pronunciation overrides.

## Locale Strategy

Target WoW locales incrementally:

- Phase 1: `enUS` and `enGB`, initially sharing English assets unless separate pronunciation is warranted.
- Phase 2: `deDE`, `esES`, `esMX`, `frFR`, `itIT`, and `ptBR`.
- Phase 3: `koKR`, `ruRU`, `zhCN`, and `zhTW`.

CosyVoice's language and pronunciation controls do not by themselves guarantee correct game terminology or regional pronunciation. Each locale requires a fluent reviewer before release.

`GetLocale()` should select the installed locale pack. Locale fallback behavior must be explicit:

- Recommended default: use the exact locale pack when available.
- If unavailable, disable voice announcements and explain the missing pack in options.
- Optionally allow users to select an installed language manually.
- Do not silently switch a non-English client to English speech.

Localized audio can initially ship in the main addon. If package size becomes material, move non-default locales into companion voice-pack addons behind a small registration API. Make that packaging decision from measured compressed size rather than assuming it is necessary.

## Offline Generation Pipeline

Add a development-only generator that performs these steps:

1. Load and validate the source manifest and locale voice configuration.
2. Resolve the phrase and pronunciation instructions for each callout and locale.
3. Generate lossless WAV output with a pinned CosyVoice 3 model revision.
4. Remove excessive leading and trailing silence without clipping consonants.
5. Normalize perceived loudness using EBU R128.
6. Apply a conservative true-peak limiter.
7. Convert to WoW-compatible OGG Vorbis with `ffmpeg`.
8. Cache each result using a hash of the model revision, voice, locale, phrase, instructions, seed, and generation settings.
9. Emit a machine-generated Lua manifest mapping locale and spell ID to addon-relative sound paths.
10. Emit a report listing generated, reused, missing, and obsolete assets.

Generation should be incremental. Existing clips should not change unless their relevant inputs change or the developer explicitly requests regeneration.

Proposed output layout:

```text
Sounds/ArenaImportantAuras/enUS/combustion.ogg
Sounds/ArenaImportantAuras/frFR/combustion.ogg
Sounds/ArenaImportantAuras/koKR/combustion.ogg
```

The model, Python environment, and `ffmpeg` are development dependencies only. The shipped addon contains OGG files and generated Lua data, not Python packages, model weights, or inference code.

## Reproducibility

The generator should record:

- Manifest schema version.
- Generator version.
- CosyVoice model, tokenizer, and speech-tokenizer identifiers.
- Exact model revisions.
- Voice identifier or synthetic voice reference identifier.
- Generation prompt and settings.
- Random seed where supported.
- Post-processing settings.
- SHA-256 hash and duration of each final OGG file.
- License identifiers and source URLs for the generation stack.

Generated speech may not be bit-for-bit deterministic across hardware or dependency versions. Committed audio files are therefore release artifacts. CI validates them but does not regenerate them.

## Runtime Architecture

Create a focused arena-important-aura sound controller rather than coupling sound registration to icon frames.

Responsibilities:

- Resolve the selected locale or language override.
- Resolve enabled callouts and per-spell mute settings.
- Register every enabled spell for `arena1`, `arena2`, and `arena3`.
- Retain every returned registration handle.
- Remove all retained handles before rebuilding or disabling the feature.
- Rebuild when the feature, locale, output channel, mute list, or relevant arena lifecycle changes.
- Defer unsafe registration work until combat restrictions permit it.
- Avoid querying aura instances or icon occupancy.

The sound controller should not require the standalone visual bars to be visible. The two features may share the semantic spell catalog, but visual presentation and voice playback have separate enable settings and lifecycles.

Registration failures should be contained:

- A failed registration must not prevent remaining spells or units from registering.
- Nil handles must not be stored.
- Removal should tolerate handles that Blizzard no longer accepts.
- Repeated failures should not flood chat.
- Debug logging may report counts and static spell IDs, but never secret aura values.

## Arena Lifecycle

Initial lifecycle events should be based on the existing arena and healer-CC patterns:

- Initialize or reconcile on `PLAYER_ENTERING_WORLD`.
- Reconcile arena slots on `ARENA_PREP_OPPONENT_SPECIALIZATIONS`.
- Reconcile relevant configuration changes immediately when safe.
- Drain deferred work on `PLAYER_REGEN_ENABLED`.
- Remove registrations when leaving the applicable instance or disabling the feature.

The implementation should determine through testing whether registrations need rebuilding between Solo Shuffle rounds. Because registrations target stable tokens rather than resolved player identities, avoid unnecessary churn unless Blizzard's runtime behavior proves it necessary.

The sound lifecycle must remain independent of the standalone bar's `SetUnit("none")` aura-container refresh. Aura containers and aura-sound registrations are different Blizzard systems and should not be made to refresh each other without evidence.

## Configuration

Proposed user-facing controls:

- Enable important-aura voice announcements.
- Announcement language: automatic or an installed language.
- Voice selection when a locale ships more than one voice.
- Output channel.
- Per-spell enable or mute controls.
- Preview selected voice.
- Preview individual callouts.

Defaults:

- Voice announcements disabled by default for existing profiles.
- Output channel `Master` unless existing SweepyBoop audio conventions indicate otherwise.
- All curated important callouts enabled after the category switch is enabled.
- No automatic announcement of spells absent from the static generated registry.

Options previews should call `PlaySoundFile` directly. They should not create temporary aura-sound registrations.

## Spell Catalog Policy

The visual bar can display any aura selected by Blizzard's important filter, while voice registration requires explicit spell IDs. The spoken catalog is therefore deliberately curated.

A spell should be included when:

- It is a meaningful enemy PvP event that benefits from immediate audio awareness.
- Its aura spell ID has been verified in current Retail data or in-game testing.
- The phrase is short and understandable during combat.
- Duplicate spell variants can be mapped safely to one semantic callout.
- False or redundant announcements are unlikely.

The catalog should be reviewed each major patch. Unknown Blizzard-important auras may still appear visually without being announced.

## Packaging and Addon Metadata

The final OGG files must be included in release packaging and available at fixed addon paths.

If companion voice packs are introduced later, define a narrow registration contract containing:

- Pack identifier.
- Supported WoW locales.
- Display name.
- Spell-ID-to-file mapping.
- Preview sound path.
- Pack version compatible with the core manifest schema.

The core addon should validate pack metadata and reject duplicate or malformed registrations predictably.

## Licensing and Provenance

Before the first generated asset is distributed:

- Save the applicable CosyVoice 3 model card and Apache 2.0 license revision.
- Confirm licenses for all tokenizer, phonemizer, and generation dependencies.
- Record which built-in voice or synthetic reference produced each pack.
- Do not use an identifiable real person's voice without explicit written permission.
- Confirm that localized phrases may be distributed and do not contain third-party contributed text with incompatible terms.
- Add required notices to SweepyBoop's release package.

Generated audio should carry a provenance manifest even if the model license does not require attribution. This protects maintainability when tools, models, or maintainers change.

## Validation

### Static validation

- Every spell ID is a positive integer and appears in at most one active callout.
- Every enabled callout has an audio file for each declared complete locale.
- Every generated Lua path resolves to a packaged file.
- No orphaned OGG files remain after catalog changes.
- Audio files decode as OGG Vorbis.
- Duration, sample rate, channel count, loudness, peak level, and leading/trailing silence stay within configured limits.
- Generated Lua contains no locale text or path derived from unescaped input.

### Listening validation

For every locale:

- A fluent reviewer verifies translation and pronunciation.
- Each phrase remains intelligible over representative arena combat audio.
- Similar abilities are audibly distinguishable where necessary.
- Clips do not contain hallucinated words, breaths, clicks, or excessive silence.
- Loudness is consistent across spells and locales.
- Rapid consecutive announcements remain understandable.

### In-game validation

Test at minimum:

- Normal rated arena.
- Multiple Solo Shuffle rounds with arena-token occupant changes.
- Stealthed opponents during preparation and combat.
- Simultaneous important aura applications on different opponents.
- Reapplication of the same aura.
- Feature enable and disable outside combat.
- Configuration changes during combat and deferred reconciliation afterward.
- Leaving and re-entering an arena.
- Missing locale pack and explicit language override.
- Full client restart after adding new audio files.

Verify that:

- The engine announces only registered aura additions.
- No stale registrations survive feature disable or instance exit.
- No secret values reach addon control flow.
- Visual bars continue working independently.
- Existing healer crowd-control sounds do not regress.

## Implementation Phases

### Phase 1: Audio Selection (complete)

- Retain the completed Qwen and CosyVoice prototypes as historical comparison material.
- Use the promoted Cartesia Gemma/Archie review pack as the selected audio source.
- Preserve the pinned provider model/API version, stock voice IDs, request fingerprints, and redistribution verification.
- Validate the complete 77-callout-per-voice catalog and one-second mastered cap.

Exit criteria met: the selected English audio passed listening and static validation.

### Phase 2: English Runtime (implementation complete, in-game validation pending)

- Package all 154 validated OGGs under `Sounds/ArenaImportantAuras`; retain currently unsupported callouts for later pet, summon, totem, special arena-cooldown, and additional unit scopes.
- Generate runtime data for 67 aura toggles and 72 aura spell IDs across opponent-buff and friendly-debuff scopes.
- Implement the combat-deferred arena sound controller and handle cleanup.
- Add master enable, Female/Male voice selection, and 67 grouped aura toggles, including separate Ascendance controls, Zenith, and four friendly-team debuff callouts.
- Use the Master output channel for phase 1 runtime behavior.
- Test normal arenas and multi-round Solo Shuffle.

Exit criteria: the English feature passes in-game validation and remains disabled by default.

### Phase 3: Localization Pipeline

- Add localized manifest fields and pronunciation overrides.
- Add locale completeness checks and reviewer sign-off records.
- Implement automatic locale selection and explicit language override.
- Generate the first non-English pack with a fluent reviewer.

Exit criteria: one non-English locale demonstrates the complete translation, generation, review, packaging, and runtime workflow.

### Phase 4: Locale Expansion

- Add remaining supported locales in reviewed batches.
- Measure release-package size.
- Introduce companion voice packs only if size or update cadence justifies them.
- Establish a patch-cycle process for catalog and pronunciation updates.

## Open Decisions

Resolve these during the prototype:

- Exact CosyVoice 3 model revision and pinned dependency set.
- Zero-shot cloning versus an adapted or fine-tuned CosyVoice speaker.
- Which synthetic Alliance and Horde references or training corpus pass listening review.
- Target loudness, true-peak ceiling, sample rate, and maximum clip duration.
- Whether `enGB` should share `enUS` assets.
- Whether unavailable locales should expose an opt-in English fallback.
- Whether output channel should be feature-specific or shared with other SweepyBoop alerts.
- Whether the existing healer-CC registration lifecycle warrants a small shared helper.
- Whether localized assets remain in the main addon or move to companion packs.

## Recommended First Step

Build a fresh ten-callout CosyVoice 3 bake-off before touching addon runtime code. Generate each difficult phrase multiple times and measure failure rate rather than selecting only the best take. The prototype must produce clean word onsets directly, stable identity, correct pronunciation, and natural sub-one-second delivery without semantic cropping. Once that exit criterion is met, generate the full catalog and implement the smallest `C_UnitAuras.AddAuraSound` integration against fixed arena tokens.
