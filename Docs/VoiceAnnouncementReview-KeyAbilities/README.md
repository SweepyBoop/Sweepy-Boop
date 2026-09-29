# Alliance and Horde Commander Voice Review

This portable review pack contains 10 arena callouts for each of two original
faction-flavored voices, for 20 mastered OGG files total.

Open `listening/index.html` in a browser to compare both voices by ability.
No Python environment or model download is required for listening.

The exact frozen VoiceDesign inputs used by the Base clone model are under
`references/`. Keep them with the provenance report; regenerating from a seed
alone is not guaranteed to preserve voice identity across devices.

Every mastered clip is at most 1.0 seconds. Generation uses a disposable spoken
prefix that is removed at a validated silence boundary before mastering.

The files under `ogg/` are review assets only. They are not wired into the addon
runtime or included in the published addon package.

See `reports/validation-summary.md` for human-readable hashes and durations, and
`reports/review-run.json` for portable model, reference, generation, crop, seed,
tempo, and mastering provenance.
