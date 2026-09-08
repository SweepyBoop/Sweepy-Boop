# Friendly Pet Nameplate Identity

This document records the Retail 12.1 investigation into reliable friendly-pet detection and differentiated pet icons on nameplates.

Every claim below is based on one of these evidence sources:

- Current SweepyBoop behavior in `/Users/kunhouseliu/wow/sweepy-boop`.
- Blizzard-generated API contracts and Blizzard UI code in `/Users/kunhouseliu/wow/wow-ui-source`.
- Direct in-game observations recorded during this investigation.

## Objective

Improve friendly pet icons so that:

- Friendly primary pets are detected reliably in arenas and Solo Shuffle.
- Different pets can use portraits or family-specific icons where Blizzard permits it.
- The existing mend-pet icon can optionally remain a special icon for the player's pet.
- **Special icon for my pet** controls presentation independently from **Show my pet only**, which controls visibility.
- Secondary pets and temporary summons are not described as primary pets without a supported signal.

A Retail visibility and presentation implementation is now present for in-game validation. It keeps the exact-aura-filtered Hunter presentation separate from the repaintable portrait paths.

## Current SweepyBoop Behavior

The renderer in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/PetIcons.lua` uses three presentations:

- The player's pet uses the Mend Pet icon when **Special icon for my pet** is enabled. When disabled, a Hunter pet uses Call Pet and other classes' pets use portraits.
- Other players' non-Hunter pets use repaintable portraits.
- Other players' Hunter pets that pass the exact-aura filter use a static Call Pet icon inside the secure aura gate.

Retail pet eligibility is decided in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/Nameplates.lua` using two separate readable classifications:

```lua
local isMyPet = addon.UnitIsUnitReadable(frame.unit, "pet");
local isOtherPlayersPet = UnitIsOtherPlayersPet(frame.unit);
```

The local-pet path uses a direct comparison with the `"pet"` token. It does not use the owner-or-controller predicate for local classification.

An other-player unit is considered for a pet icon only after `UnitIsOtherPlayersPet` returns true. SweepyBoop then creates overlapping presentation gates for `party1` through `party4`, reads each party member's class, and forwards `UnitIsOwnerOrControllerOfUnit(partyN, frame.unit)` directly to that gate's `SetAlphaFromBoolean`. The ownership result is never inspected by addon Lua. Non-Hunter owner gates contain an ordinary repaintable portrait. Hunter owner gates contain Blizzard's custom aura presentations described below.

Ownership is not used as the pet classifier. The remote routing gates are entered only after `UnitIsOtherPlayersPet` classifies the unit as another player's pet.

Classic clients use the `pet`, `partypet1`, and `partypet2` comparison path.

`addon.UnitIsUnitReadable` is defined in `/Users/kunhouseliu/wow/sweepy-boop/Common/UnitInfoHelpers.lua`:

```lua
addon.UnitIsUnitReadable = function(unitA, unitB)
    local isSameUnit = UnitIsUnit(unitA, unitB);
    if addon.IsSecretValue(isSameUnit) then return false end
    return isSameUnit;
end
```

The helper prevents callers from branching on a secret Boolean. It cannot make an incomparable token pair comparable or make a secret result readable.

**Show my pet only** suppresses the `UnitIsOtherPlayersPet` branch while leaving the direct local-pet branch eligible. **Special icon for my pet** independently selects Mend Pet versus the class-appropriate default presentation for that local branch. Party roster, pet, and portrait updates trigger a hide-first nameplate refresh so reused party indices, pet swaps, and portrait changes cannot retain stale presentation.

## Blizzard `UnitIsUnit` Contract

`UnitIsUnit` is declared in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` with two independent guards:

```lua
RequiresComparableUnitTokens = true
SecretWhenUnitComparisonRestricted = true
```

The guards are documented in:

- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua`
- `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua`

The contract distinguishes two questions:

1. `C_Secrets.CanCompareUnitTokens(unitA, unitB)` reports whether the token pair may be compared at all.
2. `C_Secrets.ShouldUnitComparisonBeSecret(unitA, unitB)` reports whether comparison results are secret in the current context.

If the tokens are not comparable, the `RequiresComparableUnitTokens` precondition makes `UnitIsUnit` return no value. If they are comparable but restricted, `UnitIsUnit` can return a secret Boolean that addon logic must not inspect.

Blizzard documents comparisons involving `player` or `target` as permitted examples and `nameplate3` versus `boss1` as an invalid example. The generated documentation does not publish a complete token-pair matrix.

### Confirmed arena result

The following probe was run while targeting a friendly pet during an active arena round:

```text
/run local p=C_NamePlate.GetNamePlateForUnit("target");local u=p and p.UnitFrame.unit;print(u,C_Secrets.CanCompareUnitTokens(u,"partypet1"),C_Secrets.ShouldUnitComparisonBeSecret(u,"partypet1"))
```

Observed output:

```text
nameplate1 false true
```

For the tested pair:

- The nameplate token was `nameplate1`.
- `CanCompareUnitTokens("nameplate1", "partypet1")` returned `false`.
- `ShouldUnitComparisonBeSecret("nameplate1", "partypet1")` returned `true`.

The failed comparability precondition is sufficient to rule out `UnitIsUnit(nameplateN, partypetN)` as an association mechanism for this case. The comparison cannot establish equality even before considering secrecy.

For the tested token pair, a `partypetN` comparison could not produce a positive match. This result established that the comparison was unsuitable for associating that friendly pet nameplate with its party owner.

## Blizzard Pet Predicates

### `UnitIsOtherPlayersPet`

`UnitIsOtherPlayersPet(unit)` is declared in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` without `RequiresComparableUnitTokens` or a secret-return predicate. Its arguments are marked `AllowedWhenUntainted`. Blizzard also uses it to select the `OTHERPET` unit-menu type in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua`.

It answers whether a unit is another player's pet. It does not promise that the unit is the owner's primary pet.

Direct in-game testing on a Beast Mastery Hunter established:

- The primary pet returned `true`.
- The secondary pet also returned `true`.

Therefore, `UnitIsOtherPlayersPet` is suitable for broad pet detection but cannot satisfy a primary-pets-only requirement.

### `UnitPlayerOrPetInParty`

Blizzard declares these APIs in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`:

```lua
UnitPlayerOrPetInParty(unit)
UnitPlayerOrPetInRaid(unit)
```

Neither declaration has an identity-secrecy or comparison-secrecy annotation. Both functions are also included in Blizzard's restricted addon environment in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua`.

The APIs include players as well as pets. SweepyBoop already distinguishes players before entering the pet path, but the contract does not state whether BM secondary pets are included. That behavior requires an in-game test.

## Permanent Hunter Pet-Family Auras

A Hunter primary pet was observed with a permanent helpful pet-family aura. The current implementation applies an exact spell-ID allowlist through Blizzard's custom aura container. This note does not claim that the individual IDs or the completeness of that allowlist were established by Blizzard UI source or by the runtime observations recorded here.

The direct result established during this investigation is narrower: in one active-arena test with a `party1` BM Hunter, the combined filter displayed its marker on the primary pet and not on the secondary pet.

### Direct aura access

The generated contracts in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua` annotate ordinary unit-aura queries with `RequiresUnitAuraAccess`, and relevant results with `SecretWhenUnitAuraRestricted`. Addon Lua therefore cannot assume that directly enumerating a friendly pet's auras will produce readable data during an active PvP round.

### Blizzard custom aura presentation

Blizzard provides a security-partitioned presentation path in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_AuraContainer`:

- `CustomAuraContainerTemplate` delegates its public interface into Blizzard's forbidden partition.
- An aura slot owns one `CustomAuraButtonTemplate` and is documented as suitable for indicators for specific spell IDs.
- `candidateFilters.includeSpellIDs` accepts an exact spell-ID set.
- `AuraContainerUtil.CanApplyIdentityCandidateFilters` explicitly permits identity filters for helpful auras on the active player, group members, or their pets.
- `CustomAuraButtonPrivateMixin:ApplyVisibility` applies aura presence through `secretwrap(auraData ~= nil)`.
- Aura-derived icon textures are also assigned through `secretwrap`.
- Generated buttons receive `DenyTaintedAccessWhenAurasAreSecret` after their initialization callback runs.

The current Retail implementation uses separate custom aura slots for the fixed Call Pet artwork, its border, and its target ring without exposing aura presence to ordinary addon logic. All three visuals are created during `initializeFrame`, before Blizzard applies access restrictions. Each button remains a presentation boundary: SweepyBoop does not inspect its visibility, selected aura, texture, frame occupancy, or other restricted state to derive a readable classification value.

The implementation keeps each ordinary parent transparent across a full update turn after rebinding its aura container. Blizzard processes dirty container state on a deferred visible update; the additional transparent update turn mitigates a recycled slot briefly presenting its previous assignment. The arming callbacks validate only ordinary assignment-generation state and never inspect the aura buttons.

The active-arena `party1` BM test confirms the combined filter for that one observed primary/secondary pair. Broader reliability still depends on the allowlist covering intended Hunter pets without matching secondary pets across other families and specializations. The fixed Call Pet icon, border, and target-ring presentations also require continued validation across those cases.

Even if confirmed, the signal is Hunter-specific unless an equivalent supported marker is found and verified for other pet classes. Other classes' pets currently remain visible through their protected party-owner gates.

## Creature Family

`UnitCreatureFamily(unit)` is declared in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`. It returns a family name and numeric family ID and is guarded by:

```lua
SecretWhenUnitIdentityRestricted = true
```

It is not limited to Hunter pets.

### Confirmed unrestricted result

Outside restricted PvP, targeting a Warlock Felguard returned:

```text
"Felguard", 29
```

Blizzard also exposes `C_CreatureInfo.GetCreatureFamilyInfo(familyID)`. Its result structure is documented in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/CreatureInfoDocumentation.lua`:

```lua
{
    id = number,
    name = string,
    iconFile = fileID?,
}
```

`iconFile` is optional. Confirmed examples:

- Wind Serpent family ID `27` returned `iconFile = 132202`.
- Felguard family ID `29` did not return an `iconFile`.

Blizzard family metadata can therefore provide some family icons but cannot guarantee complete icon coverage.

### Confirmed arena result

During an active arena or Shuffle round, `UnitCreatureFamily("target")` was tested on a friendly Hunter pet. Both the family name and family ID were secret.

That result rules out selecting a family icon from the tested `"target"` token during the active round. Querying a stable token may behave differently, but data from the tested `partypet1` token could not be attached to `nameplate1` through that incomparable token pair.

## Portrait Rendering

Blizzard declares `SetPortraitTexture(texture, unit)` in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`. Its contract accepts a unit token directly and does not declare an identity-access precondition.

Blizzard's portrait lifecycle in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Mainline/UnitFrame.lua` refreshes portraits on:

- `UNIT_PORTRAIT_UPDATE`
- `PORTRAITS_UPDATED`

SweepyBoop already calls `SetPortraitTexture` in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/NameplateFilter.lua`.

The current implementation uses portraits because `SetPortraitTexture` does not require addon-readable family, GUID, NPC ID, or name data. Its behavior on these addon-owned textures still needs direct validation during an active Shuffle round. The rendered texture must not be inspected as an identity side channel.

For recycled nameplate frames, the current implementation:

- Binds the portrait to the current nameplate unit.
- Refreshes it on relevant portrait events.
- Clears the texture when the nameplate is removed or reassigned.

Portrait rendering can differentiate appearances after a unit has been accepted as a pet. It does not determine whether that pet is primary or secondary.

## Option Semantics Under Investigation

The implemented options represent separate decisions:

- **Special icon for my pet** controls whether the player's pet uses the existing Mend Pet icon instead of the ordinary pet presentation.
- **Show my pet only** controls whether icons for other players' pets are hidden.

The special icon defaults to enabled, which displays Mend Pet for the player's pet. Disabling it uses Call Pet for a Hunter's local pet and a portrait for other classes' local pets. Other players' non-Hunter pets use portraits, while remote Hunter pets that pass the exact-aura filter use the same static Call Pet icon.

Neither option by itself distinguishes another player's primary pet from secondary pets. The remote Hunter result depends on the separate exact-aura filter and has been directly confirmed only for the recorded `party1` BM case.

## Confirmed Findings

- Retail eligibility no longer depends on comparing `nameplateN` with `partypetN`.
- `UnitIsUnitReadable` is a safety wrapper, not a secrecy or token-comparability bypass.
- The tested `nameplate1` and `partypet1` pair was incomparable during an active arena round and was also marked secret.
- `UnitIsOtherPlayersPet` returned `true` for both BM Hunter pets and cannot distinguish the primary pet by itself.
- Other-player pets are now routed through per-party protected ownership gates after readable `UnitIsOtherPlayersPet` classification; ownership results are used only by `SetAlphaFromBoolean` and are never inspected.
- During direct runtime testing, a Destruction Warlock teammate's pet displayed the icon, confirming the implemented non-Hunter remote-pet path in that scenario.
- Blizzard's custom aura container supports exact spell-ID presentation for helpful auras on the active player, group members, or their pets without exposing aura presence as an ordinary Lua Boolean.
- During direct active-arena testing with a `party1` BM Hunter, the current candidate aura set displayed the Call Pet marker on the primary pet and no marker on the secondary pet. This confirms the combined filter for that observed case, not the completeness or individual contribution of every candidate ID.
- `UnitCreatureFamily` returned a family for a Warlock Felguard outside restricted PvP.
- `UnitCreatureFamily("target")` returned secret values for a friendly Hunter pet during an active arena round.
- `C_CreatureInfo.GetCreatureFamilyInfo` may omit `iconFile`.
- `SetPortraitTexture` avoids the need to read family identity, but its active-arena behavior still requires testing.

## Open Questions

- Which permanent helpful aura IDs are present on a Hunter primary pet, and which of those are absent from a BM secondary pet?
- What does `C_Secrets.GetSpellAuraSecrecy(spellID)` report for each confirmed candidate?
- Does the current custom aura filter continue to select only the primary pet across other Hunter pet families and Hunter specializations?
- Do the `party2` through `party4` protected ownership gates associate BM Hunter pets with the correct Hunter owner during an active Shuffle round?
- Does any documented, non-secret API distinguish another player's primary pet from their secondary pets during an active Shuffle round?
- Does `SetPortraitTexture` render correctly and distinctly for friendly primary and secondary pets during an active Shuffle round?
- Is `UnitIsUnit(nameplateN, "pet")` comparable and readable for the player's own pet during an active round? Only the `partypet1` pair has been tested so far.

## Next Runtime Tests

Outside restricted PvP, target the Hunter primary pet and enumerate its permanent helpful auras. Repeat without changing the owner or specialization while targeting the BM secondary pet. Record spell IDs only when their values are readable, and identify candidates present only on the primary pet.

For each confirmed candidate, resolve its current client name and aura secrecy:

```text
/dump C_Spell.GetSpellName(spellID), C_Secrets.GetSpellAuraSecrecy(spellID)
```

Continue testing the existing exact-ID `CustomAuraContainerTemplate` filter across Hunter pet families and specializations. During active Shuffle rounds, confirm only the securely driven visual result; do not query the button's visibility, texture, aura instance, or assignment state from addon Lua.

Repeat the BM primary-versus-secondary visual check for `party2` through `party4`. Do not print, store, compare, or otherwise inspect `UnitIsOwnerOrControllerOfUnit` results. The secure family-aura slots are responsible for visually distinguishing the primary pet.

Target the player's own pet during an active round and test the local-pet token pair separately:

```text
/run local p=C_NamePlate.GetNamePlateForUnit("target");local u=p and p.UnitFrame.unit;print(u,C_Secrets.CanCompareUnitTokens(u,"pet"),C_Secrets.ShouldUnitComparisonBeSecret(u,"pet"))
```

Validate the current portrait presentation on an addon-owned texture during an active round. Do not inspect the resulting texture as identity.

## Reliability Rules

Until Blizzard exposes or testing confirms a supported primary-pet signal:

- Do not interpret `UnitIsOtherPlayersPet` as primary-pet identity.
- Do not infer primary status from NPC ID, creature family, name, model, portrait, health, creation order, or proximity.
- Do not inspect or branch on secret values.
- Do not read restricted custom-aura button state back into ordinary Lua as an identity signal.
- Do not use rendered portrait state as an identity signal.
- Prefer broad but truthful pet presentation over labeling a secondary pet as primary.
- Keep pet eligibility, owner filtering, primary-pet classification, and icon presentation as separate concerns.
