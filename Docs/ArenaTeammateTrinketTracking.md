# Arena Teammate Trinket Tracking

## Scope

SweepyBoop's teammate trinket tracker is a Retail-only, arena-only display for Blizzard CompactParty and CompactRaid frames. It shows one generic PvP trinket icon for each teammate, excludes the player, and defaults to the left side of the teammate frame.

The feature is disabled by default. Ready trinkets use a full-color icon with a fixed green glow; trinkets on cooldown use a desaturated, darkened icon with a red border and full-contrast countdown text.

## Blizzard API Contract

The implementation is based only on Blizzard's generated API documentation and default UI source.

### Arena cooldown duration

`Blizzard_APIDocumentationGenerated/PvpInfoDocumentation.lua` documents:

```text
C_PvP.GetArenaCrowdControlDuration(playerToken: UnitToken) -> LuaDurationObject
```

The argument must be untainted. SweepyBoop passes the teammate frame's readable `partyN` or `raidN` token and handles API errors or missing data without inventing a cooldown.

### Opaque cooldown rendering

`Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua` documents:

```text
Cooldown:SetCooldownFromDurationObject(duration, clearIfZero)
```

SweepyBoop passes the returned duration object directly to this method. Production code does not read start time, end time, elapsed time, remaining time, total duration, or modification rate. It polls only the documented boolean `IsActive()` state and never inspects or branches on that potentially-secret value.

`Blizzard_APIDocumentationGenerated/SimpleRegionAPIDocumentation.lua` documents `SetVertexColorFromBoolean` and `SetAlphaFromBoolean`. `Blizzard_APIDocumentationGenerated/CurveUtilDocumentation.lua` documents `EvaluateColorValueFromBoolean`. SweepyBoop passes the potentially-secret `IsActive()` result directly through those APIs to select ready or on-cooldown colors, glow alpha, and desaturation. Keeping both numeric duration data and the boolean state opaque avoids tainted access while allowing visuals to change during a round.

### Refresh events

`Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` documents `ARENA_COOLDOWNS_UPDATE` as a synchronous event with no payload. SweepyBoop therefore refreshes every tracked teammate when this event fires rather than relying on an undocumented unit argument.

`UNIT_ARENA_COOLDOWNS_UPDATE` is documented for commentator or spectator use only and is not registered.

`PVP_MATCH_STATE_CHANGED`, `GROUP_ROSTER_UPDATE`, and `PLAYER_ENTERING_WORLD` refresh visibility, roster attachment, and current duration objects. Layout work deferred during combat is reconciled on `PLAYER_REGEN_ENABLED`.

### Blizzard arena-frame precedent

`Blizzard_UnitFrame/Mainline/CompactArenaFrame.lua` demonstrates Blizzard's arena opponent CC-remover flow:

- `ARENA_CROWD_CONTROL_SPELL_UPDATE` selects the opponent remover icon.
- `ARENA_COOLDOWNS_UPDATE` refreshes its cooldown.
- `C_PvP.GetArenaCrowdControlInfo(arenaN)` supplies opponent spell/start/duration data.

This is an opponent-only implementation. Blizzard's source does not demonstrate `partyN` or `raidN` calls to `GetArenaCrowdControlDuration`.

## Experimental Teammate-Token Assumption

The generated API accepts a general `UnitToken`, but Blizzard's default arena UI only proves opponent `arenaN` usage. Useful duration data for teammate `partyN` and `raidN` tokens is therefore an experimental runtime assumption, not a Blizzard UI guarantee.

SweepyBoop handles this conservatively:

- Query through `pcall`.
- Hide the icon when the call errors or returns no duration object.
- Never substitute an assumed 90- or 120-second timer.
- Never infer use from combat logs, auras, spell casts, racials, talents, or items.
- Use spell `336126` only as a generic trinket texture; the tracker does not identify Medallion, Adaptation, or racial breakers.

## Known Limitations

- Blizzard may not provide useful teammate duration data before the match begins.
- A teammate trinket used in the starting room may not be recoverable after the match starts.
- The feature supports Blizzard CompactParty and CompactRaid frames only.
- The feature does not support third-party unit frames.
- The player is intentionally excluded.
- Numeric duration details are not exposed to addon logic; Blizzard's cooldown widget owns the sweep and countdown.

## Manual Validation

1. Enter a rated arena with Blizzard party or raid-style frames visible.
2. Confirm icons appear only on teammate frames.
3. Have each teammate use their PvP trinket after the match begins.
4. Confirm `ARENA_COOLDOWNS_UPDATE` causes the correct cooldown sweep.
5. Confirm the icon returns to a ready state when Blizzard's duration object reaches zero.
6. Test a teammate trinket used in the starting room and record whether Blizzard reports it.
7. Test 2v2, 3v3, and multi-round Solo Shuffle roster changes.
8. Confirm no icons appear in battlegrounds, dungeons, the world, or Classic clients.
