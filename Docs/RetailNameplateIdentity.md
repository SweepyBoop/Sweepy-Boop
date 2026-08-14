# Retail Nameplate Identity and Important Summon Detection

This document summarizes the Retail 12.1 investigation into reliable enemy-nameplate identity, arena-player correlation, and important summon highlighting. It is based on Blizzard's generated API contracts, Blizzard UI source, and in-game testing.

Source snapshot investigated: Retail `12.1.0.69273`.

## AI Agent Handoff

### Objective

Improve Retail enemy-minion nameplate handling without displaying incorrect Grounding Totem, Tremor Totem, Capacitor Totem, Psyfiend, or other summon icons.

The reliability requirement is strict:

- A missing highlight is preferable to a wrong specific icon.
- Unknown or secret identity must fail open by leaving the unit visible.
- Do not introduce cast/channel/timing correlation as identity.
- Do not infer secure aura-container occupancy through frame state.

### Repository state

Repository:

- `c:\Users\kunhouseliu\Documents\GitHub\Sweepy-Boop`

Blizzard source:

- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source`

Topic branch at the time this document was written:

- `nameplate-highlight-explore`

The arena-player resolver work is already landed on `main`. It uses readable normalized name and realm and has passed arena and Solo Shuffle testing. Do not replace it with class/race/honor inference or `UnitIsUnit("nameplateN", "arenaN")`.

### Current unresolved behavior

The current Mainline classifier is in:

- `c:\Users\kunhouseliu\Documents\GitHub\Sweepy-Boop\Common\NpcData.lua`
  - `GetFirstAuraMatching`
  - `GetPriorityAuraIcon`
  - `ClassifyMainlineNpc`

Current behavior:

1. Require a readable `UnitIsMinion` result.
2. Preserve other players' pets and known Shaman primary pets.
3. Read the first `HELPFUL|IMPORTANT` aura.
4. If present, return `NpcOption.Highlight` with that aura icon.
5. Otherwise preserve the current target and hide the remaining confirmed minion.

Problem:

- An important helpful aura is not summon identity.
- An unrelated important buff can produce a bogus NPC highlight icon.
- Absence of a readable important aura does not prove that a minion is disposable.

The renderer is in:

- `c:\Users\kunhouseliu\Documents\GitHub\Sweepy-Boop\Nameplates\NameplateFilter.lua`

The caller and nameplate lifecycle are in:

- `c:\Users\kunhouseliu\Documents\GitHub\Sweepy-Boop\Nameplates\Nameplates.lua`

### Verified runtime facts

- `UnitName("arenaN")` and enemy-player `UnitName("nameplateN")` are readable inside arenas.
- Grounding Totem spell ID `204336` reports `ContextuallySecret` (`2`).
- Tremor Totem spell ID `8143` reports `ContextuallySecret` (`2`).
- `HELPFUL|IMPORTANT` is too broad for summon identity.
- `CustomAuraContainer` exact spell-ID filtering is not reliable for contextually secret helpful auras on hostile/non-assistable units.
- No public hostile-totem API exists. Totem-slot APIs describe only the local player's managed totems.
- No exact non-aura join exists between an observed enemy summon cast and the spawned `nameplateN`.

### Rejected approaches

Do not implement these as exact identity:

- Any channel means Psyfiend.
- Any cast means Capacitor Totem.
- Any important helpful aura means Grounding Totem.
- The next minion nameplate after a shaman cast is that summoned totem.
- Unit model, health, duration, insertion order, or owner class identifies a summon.
- A secret texture or secure button's shown state can be read back as identity.
- `candidateFilters.includeSpellIDs` is an exact hostile-helpful whitelist for contextually secret auras.

### Recommended next task

Refactor Mainline NPC visibility and highlighting so aura presentation is not used as unit identity.

Conservative implementation direction:

1. Remove the `GetPriorityAuraIcon` decision from `ClassifyMainlineNpc`.
2. Preserve any unit whose identity or classification is unknown or secret.
3. Preserve confirmed other-player pets, known primary pets, valuable classifications, marked units, and readable target/focus matches.
4. Decide whether confirmed `UnitClassification(unit) == "minus"` is narrow enough for automatic suppression.
5. Leave other uncertain minions visible and unhighlighted.
6. Keep exact NPC-ID rules only in environments where identity is readable.
7. If a generic marker is retained, label it visually and semantically as a generic minion marker, never as a specific or important summon.

Do not start implementation without confirming the desired visibility policy. The main product decision still open is:

> Should Retail automatically hide only confirmed minus units, or should it leave every uncertain non-pet minion visible?

### Acceptance criteria

A proposed implementation should satisfy all of the following:

- No specific summon icon is produced from a generic aura, cast, or channel.
- Unknown and secret values never cause an important unit to be hidden.
- Primary pets remain visible.
- Current target remains visible when the comparison is readable.
- Nameplate frame reuse clears all addon-owned highlight state.
- Classic/non-Mainline exact NPC-ID behavior is unchanged.
- Restricted PvP code never compares, concatenates, indexes, or branches on a secret value.
- In-game tests cover arena, battleground, target changes, nameplate recycling, and at least Grounding and Tremor Totems.

### Useful in-game commands

Check aura secrecy metadata:

```text
/dump C_Secrets.GetSpellAuraSecrecy(204336)
/dump C_Secrets.GetSpellAuraSecrecy(8143)
```

Check whether a targeted unit name is readable:

```text
/run local n,r=UnitName("target"); print("name secret:",issecretvalue(n),"realm secret:",issecretvalue(r))
```

Inspect readable helpful aura IDs outside restricted PvP:

```text
/run AuraUtil.ForEachAura("target","HELPFUL",nil,function(a) local s=C_Secrets.GetSpellAuraSecrecy(a.spellId) print(a.spellId,a.name,s,s==0 and "NeverSecret" or s==1 and "AlwaysSecret" or "ContextuallySecret") end)
```

### Agent reading order

1. Read this handoff section.
2. Read `Common\NpcData.lua` Mainline classifier.
3. Read `Nameplates\NameplateFilter.lua` renderer lifecycle.
4. Read `Nameplates\Nameplates.lua` NPC caller and nameplate add/remove paths.
5. Consult the detailed findings below before proposing a new identity signal.
6. Inspect Blizzard contracts directly rather than assuming an API declassifies protected data.

## Summary

Retail exposes enough readable information to classify a hostile unit broadly, but not enough to identify a hostile non-player summon exactly in restricted PvP.

The important distinction is:

- `UnitIsMinion` can establish that a unit is broadly a player pet, guardian, or totem.
- It cannot establish that the unit is Grounding Totem, Tremor Totem, Capacitor Totem, Psyfiend, or another specific summon.
- Aura and cast importance describe a current aura or action. They do not establish persistent unit identity.
- Secure UI can render protected information without making that information readable to addon Lua.

For reliability, SweepyBoop should never assign a specific summon icon from a generic cast, channel, or important aura.

## Secret-Value Rules

### Hostile non-player identity

The normal unit-identity secrecy rule applies to hostile NPCs, guardians, and totems. Identity-grade values may be unavailable or secret, including:

- `UnitGUID`
- Creature ID derived from a GUID
- `UnitName`
- Creature family and creature type
- Owner/controller relationships
- Tooltip name, owner, or GUID fields

A secret value must not be:

- Compared
- Concatenated
- Converted to a string
- Used as a table key
- Used for ordinary branching
- Parsed to recover identity

A render method accepting a secret value does not make the value readable.

### Player-name PvP exception

`UnitName` has a narrower contract than general identity APIs. Blizzard documents an exception to ordinary name-identity secrecy in PvP when the queried unit is a player.

This supports exact arena-player matching by normalized character name and realm. It does not apply to Grounding Totem, Tremor Totem, or any other non-player summon.

Relevant Blizzard contracts:

- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\UnitDocumentation.lua`
- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\SecretPredicatesDocumentation.lua`

## Arena Player Resolution

Inside an arena, `UnitName("arenaN")` and `UnitName("nameplateN")` were confirmed readable for enemy players.

SweepyBoop therefore maps arena players using normalized name and realm rather than demographic inference or `UnitIsUnit`:

1. Read both values returned by `UnitName`.
2. Reject either value if secret.
3. Reject missing or empty names.
4. Replace an omitted same-realm value with `GetNormalizedRealmName()`.
5. Compare the complete name-realm identity.
6. Cache only stable `arenaN` identities; never cache recycled `nameplateN` identities.

The cache is invalidated on:

- `PLAYER_ENTERING_WORLD`
- `GROUP_ROSTER_UPDATE`
- `ARENA_PREP_OPPONENT_SPECIALIZATIONS`

Arena and Solo Shuffle testing confirmed that Blizzard's normal nameplate updates repaint arena numbers and spec icons after these resets.

`UnitIsUnit("nameplateN", "arenaN")` is not a replacement. The API requires comparable token families and may return nothing when that precondition is not met.

## Available Summon Signals

### Classification-grade signals

These signals are useful for conservative visibility policy but not exact summon identity:

| Signal | Meaning | Safe use |
|---|---|---|
| `UnitIsMinion(unit)` | Player pet, guardian, or totem | Establish broad minion eligibility |
| `UnitIsOtherPlayersPet(unit)` | Another player's pet | Preserve ordinary player pets |
| `UnitClassification(unit)` | Normal, minus, elite, rare, rare elite, or world boss | Preserve valuable classifications; optionally suppress confirmed minus units |
| `UnitIsBossMob(unit)` | Boss classification | Preserve the unit |
| `UnitIsLieutenant(unit)` | Lieutenant classification | Preserve the unit |
| Target or focus state | User-selected importance | Preserve the unit when comparison is readable |
| Raid marker | User-assigned importance | Preserve or emphasize, but not identify automatically |

A false or missing pet result does not prove that a minion is disposable.

### Identity-grade signals

These would identify a summon exactly if readable:

- GUID and creature ID
- Localized unit name
- Tooltip GUID or equivalent identity
- Exact summon event joined to the spawned unit GUID

They are not reliable in restricted Retail PvP. SweepyBoop may use exact identity where it is readable, but must fail open when it is unavailable or secret.

## Aura Findings

### Important auras are not summon identity

`HELPFUL|IMPORTANT` means that Blizzard considers a helpful aura important. It does not mean:

- The aura defines the summon.
- The unit is Grounding Totem.
- The unit itself should receive a specific important-summon icon.

A minion can carry an unrelated important aura. Using the first important helpful aura as the summon icon can therefore produce a semantically bogus highlight even when the displayed aura icon is technically accurate.

### `CustomAuraContainer`

`CustomAuraContainer` can securely select and render protected auras. It is appropriate when the intended output is explicitly an aura display.

It does not expose a supported occupancy callback or readable selected aura identity. Addon code must not infer occupancy by reading:

- `IsShown()`
- Alpha
- Frame count
- Size
- Anchors
- Texture state
- Child visibility

The secure aura button itself may render an icon, cooldown, border, or glow. Its state must not be mirrored into ordinary addon classification logic.

Relevant Blizzard implementation:

- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_AuraContainer\Blizzard_CustomAuraContainer.lua`
- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_AuraContainer\Blizzard_CustomAuraButton.lua`
- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_AuraContainer\Blizzard_AuraContainerUtil.lua`

### Exact spell-ID candidate filters

`CustomAuraContainer` supports `candidateFilters.includeSpellIDs`, but Blizzard restricts identity-based filtering by unit disposition.

Spell-ID matching is normally permitted for:

- Helpful buffs on assistable units
- Harmful auras on non-assistable units

A summon-defining aura on an enemy totem is a helpful aura on a non-assistable unit. For contextually secret auras, Blizzard skips the exact spell-ID include/exclude test rather than treating the aura as rejected. An unrelated aura can therefore remain eligible.

The exception is an aura whose secrecy metadata is `Enum.SecrecyLevel.NeverSecret`. Exact spell-ID filtering can be trusted only when every relevant aura ID is known to be never secret.

### Grounding and Tremor tests

In-game tests returned `Enum.SecrecyLevel.ContextuallySecret` (`2`) for:

- Grounding Totem spell ID `204336`
- Tremor Totem spell ID `8143`

Commands:

```text
/dump C_Secrets.GetSpellAuraSecrecy(204336)
/dump C_Secrets.GetSpellAuraSecrecy(8143)
```

Secrecy levels:

- `0`: `NeverSecret`
- `1`: `AlwaysSecret`
- `2`: `ContextuallySecret`

The spawned unit's defining aura can theoretically use a different spell ID. Outside restricted PvP, target the summon and inspect its helpful aura IDs and secrecy metadata:

```text
/run AuraUtil.ForEachAura("target","HELPFUL",nil,function(a) local s=C_Secrets.GetSpellAuraSecrecy(a.spellId) print(a.spellId,a.name,s,s==0 and "NeverSecret" or s==1 and "AlwaysSecret" or "ContextuallySecret") end)
```

Unless the actual defining aura is `NeverSecret`, it cannot provide a reliable exact hostile-aura whitelist.

## Cast and Channel Findings

A cast or channel can describe what a unit is currently doing. It does not generally identify the unit.

Unsafe identity assumptions include:

- Any casting minion is Capacitor Totem.
- Any channeling minion is Psyfiend.
- A recently observed shaman cast belongs to the next minion nameplate added.

Even when an enemy player's cast spell is readable, there is no exact public join key between that cast and the spawned `nameplateN`. Joining by time, insertion order, owner class, or expected duration is heuristic and fails with simultaneous summons, delayed nameplate creation, multiple shamans, range changes, and recycled frames.

Blizzard can highlight a current cast through `C_Spell.IsSpellImportant`. That means the cast is important, not that the caster is a particular summon.

## Totem APIs

Retail exposes global totem-slot functions such as:

- `GetNumTotemSlots()`
- `GetTotemInfo(slot)`
- `GetTotemDuration(slot)`
- `GetTotemTimeLeft(slot)`
- `TargetTotem(slot)`
- `DestroyTotem(slot)`

These functions describe the local player's managed totem slots. They do not accept an enemy unit, nameplate token, GUID, or owner and cannot identify hostile totems.

Relevant Blizzard contract:

- `c:\Users\kunhouseliu\Documents\GitHub\wow-ui-source\Interface\AddOns\Blizzard_APIDocumentationGenerated\TotemDocumentation.lua`

There is no public hostile-totem lookup or `C_Totem` identity namespace in the investigated source.

## Other Rejected Detection Paths

| Candidate | Limitation |
|---|---|
| `UnitName` | Exact when readable, but hostile non-player names can be secret in restricted PvP |
| GUID or creature ID | Exact when readable, but identity-restricted |
| Tooltip GUID/name/owner | Not a guaranteed readable identity bypass |
| `C_NamePlate` | Exposes frames and dimensions, not summon identity |
| Owner/controller APIs | Identity-restricted and insufficient to distinguish multiple summons |
| Combat log `SPELL_SUMMON` | Restricted in scoped PvP; still requires a readable join to the nameplate |
| `C_CombatLogSecure` | Secure-only and does not expose a raw addon-readable identity join |
| Model, health, or texture | Collision-prone heuristic or render-only state |
| Macro targeting | Secure action, not an addon-readable identity result |
| Blizzard simplified-nameplate state | Presentation policy, not exact identity |

## Reliability-First Policy

### Visibility

Always preserve a unit when:

- It is not a confirmed minion.
- It is another player's confirmed pet.
- Any required signal is secret or unknown.
- It is elite, rare, rare elite, world boss, boss, or lieutenant.
- It is the current target or focus and that comparison is readable.
- It carries a raid marker.

Do not automatically suppress a unit solely because:

- `UnitIsMinion` is true.
- `UnitIsOtherPlayersPet` is false.
- No readable important aura exists.
- No readable cast exists.
- Blizzard simplified the nameplate.

If automatic suppression is retained, a confirmed `"minus"` classification is a narrower candidate than the broad non-pet-minion bucket, but it remains classification rather than exact identity.

### Highlighting

A specific summon icon should require exact readable identity. If exact identity is unavailable:

- Leave the unit visible and unhighlighted; or
- Use an explicitly generic minion marker that makes no importance or identity claim.

Do not assign:

- Grounding styling from arbitrary important helpful auras.
- Capacitor styling from arbitrary casts.
- Psyfiend styling from arbitrary channels.
- Tremor styling from a generic helpful aura.

Blizzard's native important-aura and important-cast presentation can remain visible independently. Those systems accurately describe the aura or cast they display, but SweepyBoop should not reinterpret them as summon identity.

## Current SweepyBoop Implication

The current Mainline priority-aura classifier in:

- `c:\Users\kunhouseliu\Documents\GitHub\Sweepy-Boop\Common\NpcData.lua`

can still produce bogus summon highlights because it treats the first `HELPFUL|IMPORTANT` aura as an NPC highlight icon.

The reliability-first follow-up is to remove aura-driven specific highlighting from NPC classification. Unknown minions should fail open. Exact identity rules may remain available in environments where GUID or creature ID is readable.

## Decision Record

The investigated Retail 12.1 contract does not provide an exact, addon-readable Grounding/Tremor/Psyfiend/Capacitor detector for hostile nameplates in restricted PvP.

Therefore:

1. Do not reintroduce generic cast/channel identity guesses.
2. Do not treat `HELPFUL|IMPORTANT` as summon identity.
3. Do not use secure rendering state as a classification side channel.
4. Prefer missing a highlight over displaying a wrong specific icon.
5. Preserve uncertain units rather than hiding them.
6. Revisit exact detection only if Blizzard introduces a documented hostile-summon identity API or relevant defining auras become `NeverSecret`.
