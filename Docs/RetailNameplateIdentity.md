# Retail Nameplate Identity and Important Summon Detection

This document summarizes the Retail 12.1 investigation into reliable enemy-nameplate identity, arena-player correlation, and important summon highlighting. It is based on Blizzard's generated API contracts, Blizzard UI source, source-history comparison, and in-game testing.

Source snapshots investigated:

- Retail `12.1.0.69273`: original runtime testing.
- Retail `12.1.0.69299`: follow-up API-contract, render-only presentation, and source-history investigation.

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

- `/Users/kunhouseliu/wow/sweepy-boop`

Blizzard source:

- `/Users/kunhouseliu/wow/wow-ui-source`

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

- `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/NameplateFilter.lua`

The caller and nameplate lifecycle are in:

- `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/Nameplates.lua`

### Verified runtime and source facts

- `UnitName("arenaN")` and enemy-player `UnitName("nameplateN")` are readable inside arenas.
- `UnitCreatureID(unit)` is a real global API introduced during the Retail 12.0 development cycle. It is absent from the investigated 11.2.x snapshots and present in the first available 12.0.0 snapshot, build `63534` dated October 2, 2025.
- The current `UnitCreatureID` contract is identity-restricted and requires identity access. It is exact when available, but it can return no value for hostile non-player summons in restricted PvP.
- A secret hostile non-player `UnitName` result can be forwarded directly to an addon-owned `FontString:SetText`. This renders the exact protected name without making it readable to addon Lua.
- `SetPortraitTexture(texture, unit)` is a plausible render-only unit portrait path, but its restricted-PvP output, uniqueness, and cleanup behavior still require in-game testing.
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
2. Attempt exact Retail classification with a non-secret `UnitCreatureID(unit)` result, with readable GUID parsing only as a compatibility fallback.
3. Preserve any unit whose exact identity or required classification is unavailable, unknown, or secret.
4. Preserve confirmed other-player pets, known primary pets, valuable classifications, marked units, and readable target/focus matches.
5. Treat confirmed `UnitClassification(unit) == "minus"` suppression as an optional clutter tradeoff, not the strict safety default, until important summons are proven not to overlap that classification.
6. Leave other uncertain minions visible and unhighlighted.
7. Where exact identity is protected, optionally provide a fixed-layout protected name label for human recognition without using the name in addon logic.
8. If a generic marker is retained, label it visually and semantically as a generic minion marker, never as a specific or important summon.

Do not start implementation without confirming the desired visibility policy. The main product decision still open is:

> Should Retail automatically hide only confirmed minus units, or should it leave every uncertain non-pet minion visible?

### Acceptance criteria

A proposed implementation should satisfy all of the following:

- No specific summon icon is produced from a generic aura, cast, channel, portrait, model, or timing correlation.
- A specific summon icon requires an exact, non-secret creature ID or another documented exact readable identity.
- Unknown and secret values never cause an important unit to be hidden.
- Primary pets remain visible.
- Current target and focus remain visible when their comparisons are readable; unknown comparison state fails open.
- Unknown or secret raid-marker state fails open.
- Any protected name label uses fixed geometry, never inspects text-derived state, and calls `ClearText()` on removal or reassignment.
- Nameplate frame reuse clears all addon-owned highlight and protected-presentation state.
- Classic/non-Mainline exact NPC-ID behavior is unchanged.
- Restricted PvP code never compares, concatenates, formats, indexes, measures, or branches on a secret value.
- In-game tests cover arena, battleground, target/focus changes, raid markers, nameplate recycling, and at least Grounding and Tremor Totems.

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

Check the exact creature-ID API without comparing or printing a secret result:

```text
/run local id=UnitCreatureID("target"); if issecretvalue(id) then print("secret") elseif id then print(id) else print("unavailable") end
```

Check the governing identity predicate:

```text
/dump C_Secrets.ShouldUnitIdentityBeSecret("target")
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
- `UnitCreatureID` is an exact identity API and should be preferred over GUID string parsing when its result is available and non-secret.
- `UnitCreatureID` does not bypass restricted-PvP identity secrecy and may return no value when identity access is denied.
- Aura and cast importance describe a current aura or action. They do not establish persistent unit identity.
- Protected UI sinks can render an exact secret name, aura, cast, or possibly portrait without making that information readable to addon Lua.

For reliability, SweepyBoop should never assign a specific summon icon from a generic cast, channel, important aura, portrait, or model.

## Secret-Value Rules

### Hostile non-player identity

The normal unit-identity secrecy rule applies to hostile NPCs, guardians, and totems. Identity-grade values may be unavailable or secret, including:

- `UnitCreatureID`
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

- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`
- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua`

## `UnitCreatureID` Contract

### Availability and history

`UnitCreatureID(unit)` is a real global API that returns a nilable numeric creature ID. Source-history comparison found:

- It is absent from the investigated Retail `11.2.0`, `11.2.5`, and `11.2.7` snapshots.
- It is present in the earliest available Retail `12.0.0` snapshot containing the API, build `63534` dated October 2, 2025.
- It remains present in Retail `12.1.0.69299`.

This places the API's introduction in the Retail 12.0 development cycle. Build `63534` is the earliest occurrence in the available source history, not necessarily the first publicly deployed client build.

### Current contract

Retail `12.1.0.69299` declares:

```lua
{
    Name = "UnitCreatureID",
    Type = "Function",
    SecretWhenUnitIdentityRestricted = true,
    RequiresUnitIdentityAccess = true,
    SecretArguments = "AllowedWhenUntainted",

    Arguments =
    {
        { Name = "unit", Type = "UnitToken", Nilable = false },
    },

    Returns =
    {
        { Name = "creatureID", Type = "number", Nilable = true },
    },
},
```

Source:

- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`

The initial 12.0 contract already protected non-player units and minions during combat through `SecretNonPlayerUnitOrMinionWhileInCombat`. Later 12.0 snapshots generalized this to `SecretWhenUnitIdentityRestricted`, and the current contract also requires identity access.

`RequiresUnitIdentityAccess` means a protected API can return no values when the caller lacks access. Therefore:

- A non-secret numeric result is exact and is the preferred Retail NPC identity key.
- A secret result is unavailable to addon logic.
- `nil` or no return may mean identity access was denied; it does not prove that the unit is unimportant or lacks a creature ID.
- `UnitCreatureID` is not a restricted-PvP bypass for hostile Grounding, Tremor, Capacitor, Psyfiend, or similar summons.

A secret-safe read should reject secret and missing results before comparison or table lookup:

```lua
local creatureID = UnitCreatureID(unit);
if issecretvalue(creatureID) or creatureID == nil then
    return nil;
end

return creatureID;
```

When available, prefer `UnitCreatureID` over parsing a GUID string. A readable `UnitGUID` may remain a compatibility fallback, but neither a secret GUID nor tooltip data may be treated as a declassification path.

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

- `UnitCreatureID(unit)`
- Readable GUID followed by creature-ID extraction
- Localized unit name
- Tooltip GUID or equivalent identity
- Exact summon event joined to the spawned unit GUID

They are not reliable in restricted Retail PvP. SweepyBoop may use exact identity where it is readable, but must fail open when it is unavailable or secret.

Recommended exact-identity order on Retail:

1. Use a non-secret `UnitCreatureID(unit)` result.
2. Fall back to a non-secret readable GUID only for compatibility.
3. Apply an NPC-specific icon or visibility rule only after obtaining an exact readable ID.
4. Preserve the unit when neither exact path is available.

## Protected Presentation

### Exact protected name

Retail supports a one-way presentation path for hostile non-player names even when the name is secret:

- `UnitName(unit)` is callable by tainted addon code and may return a secret string.
- `FontString:SetText` accepts a secret string and adds `Enum.SecretAspect.Text` to the destination font string.
- `FontString:GetText` remains secret while that aspect is present.

Relevant contracts:

- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`
- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua`

The supported pattern is unconditional direct forwarding:

```lua
protectedName:SetText((UnitName(unit)));
```

This can tell the player that a nameplate is Grounding Totem, Tremor Totem, Capacitor Totem, or Psyfiend without revealing that identity to addon Lua. It cannot drive a specific icon, color, visibility rule, cache key, or other branch.

Rules for an addon-owned protected name label:

- Use fixed geometry; do not size or position the label from its text.
- Do not compare, concatenate, format, log, index, or call `tostring` on the name.
- Do not call `GetText`, `GetStringWidth`, `GetStringHeight`, `GetNumLines`, `IsTruncated`, character-coordinate APIs, or other text-derived inspection methods.
- Show or hide the outer container only from non-secret configuration, broad classification, and nameplate lifecycle state.
- Hide the container first during reassignment, then call `ClearText()` before binding the next unit.
- Use `ClearText()`, not merely `SetText("")`, because `ClearText()` is the documented operation that removes the text secret aspect.
- Never cache the protected name as the identity of a recycled `nameplateN` token.

### Unit portrait

`SetPortraitTexture(texture, unit)` accepts a unit token directly and does not declare `RequiresUnitIdentityAccess` or `RequiresDeclassifiedUnitIdentity`. This makes it a plausible human-facing render-only aid without first reading a GUID, creature ID, or name.

However, source inspection does not prove that its restricted-PvP result is exact, nonblank, stable, or visually unique among important summons. It also does not authorize reading texture state back as identity. Before production use, test:

- Grounding, Tremor, Capacitor, and Psyfiend during active arena or battleground restrictions.
- Multiple Shaman races and visually similar totems.
- `UNIT_PORTRAIT_UPDATE`, `PORTRAITS_UPDATED`, and nameplate recycling.
- Hiding first and clearing with `SetTexture(nil)` on removal or reassignment.

`PlayerModel:SetUnit` is not an alternative. Its contract explicitly requires declassified unit identity.

Neither protected names nor portraits provide addon-readable identity. They are recognition aids for the player only.

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

- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`
- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua`
- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua`

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

- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/TotemDocumentation.lua`

There is no public hostile-totem lookup or `C_Totem` identity namespace in the investigated source.

## Other Rejected Detection Paths

| Candidate | Limitation |
|---|---|
| `UnitName` | Exact when readable; a secret result may be rendered to a protected font string but cannot drive addon logic |
| `UnitCreatureID` | Preferred exact numeric identity when available; identity-restricted and may return no value |
| `UnitGUID` or GUID-derived creature ID | Exact when readable, but identity-restricted; use only as a compatibility fallback |
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

If automatic suppression is retained, a confirmed `"minus"` classification is a narrower candidate than the broad non-pet-minion bucket, but it remains classification rather than exact identity. Until runtime tests prove that important hostile summons do not overlap `"minus"`, the strict safety default is to leave every exact-unknown non-pet minion visible.

### Highlighting

A specific summon icon should require exact readable identity, preferably a non-secret `UnitCreatureID` result. If exact identity is unavailable:

- Leave the unit visible and unhighlighted; or
- Use an explicitly generic minion marker that makes no importance or identity claim; and
- Optionally render the exact protected unit name as a fixed-layout human-recognition aid without inspecting it.

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

The reliability-first follow-up is to remove aura-driven specific highlighting from NPC classification. Unknown minions should fail open. On Retail, exact rules should use a non-secret `UnitCreatureID` first and readable GUID parsing only as a compatibility fallback. When exact identity is protected, an addon-owned protected name label may provide truthful recognition without granting addon-readable identity.

## Decision Record

The investigated Retail 12.1 contract does not provide an exact, addon-readable Grounding/Tremor/Psyfiend/Capacitor detector for hostile nameplates in restricted PvP.

Therefore:

1. Do not reintroduce generic cast/channel identity guesses.
2. Do not treat `HELPFUL|IMPORTANT` as summon identity.
3. Do not use secure rendering state as a classification side channel.
4. Prefer missing a highlight over displaying a wrong specific icon.
5. Preserve uncertain units rather than hiding them.
6. Use `UnitCreatureID` for exact rules only when its result is available and non-secret; treat missing access as unknown.
7. A protected name or portrait may help the player recognize a summon, but must never be inspected or converted into addon classification.
8. Revisit unrestricted exact detection only if Blizzard changes the hostile-summon identity contract or relevant defining auras become `NeverSecret`.
