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

A Retail visibility and presentation implementation is now present for in-game validation. It keeps Hunter primary-pet filtering separate from the repaintable portrait paths.

## Current SweepyBoop Behavior

The renderer in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/PetIcons.lua` uses three presentations:

- The player's pet uses the Mend Pet icon when **Special icon for my pet** is enabled and its portrait when disabled.
- Other players' non-Hunter pets use repaintable portraits.
- Other players' Hunter primary pets use a static Call Pet icon inside the secure family-aura gate.

Retail pet eligibility is decided in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/Nameplates.lua` using two separate readable classifications:

```lua
local isMyPet = addon.UnitIsUnitReadable(frame.unit, "pet");
local isOtherPlayersPet = UnitIsOtherPlayersPet(frame.unit);
```

The local-pet path deliberately retains the direct `"pet"` comparison. It does not use `UnitIsOwnerOrControllerOfUnit("player", frame.unit)`, because ownership includes guardians and other controlled units in addition to the player's pet.

An other-player unit is considered for a pet icon only after `UnitIsOtherPlayersPet` returns true. SweepyBoop then creates overlapping presentation gates for `party1` through `party4`, reads each party member's class, and forwards `UnitIsOwnerOrControllerOfUnit(partyN, frame.unit)` directly to that gate's `SetAlphaFromBoolean`. The ownership result is never inspected by addon Lua. Non-Hunter owner gates contain an ordinary repaintable portrait. Hunter owner gates contain Blizzard's custom aura presentations described below.

Ownership is not used as the pet classifier. Because the outer `UnitIsOtherPlayersPet` check has already established that the remote unit is a pet, guardians and other controlled units do not enter these owner-class routing gates.

Classic clients retain the previous `pet`, `partypet1`, and `partypet2` comparison path.

`addon.UnitIsUnitReadable` is defined in `/Users/kunhouseliu/wow/sweepy-boop/Common/UnitInfoHelpers.lua`:

```lua
addon.UnitIsUnitReadable = function(unitA, unitB)
    local isSameUnit = UnitIsUnit(unitA, unitB);
    if addon.IsSecretValue(isSameUnit) then return false end
    return isSameUnit;
end
```

The helper prevents callers from branching on a secret Boolean. It cannot make an incomparable token pair comparable or make a secret result readable.

**Show my pet only** suppresses the `UnitIsOtherPlayersPet` branch while leaving the direct local-pet branch eligible. **Special icon for my pet** independently selects Mend Pet versus portrait presentation for that local branch. Party roster, pet, and portrait updates trigger a hide-first nameplate refresh so reused party indices, pet swaps, and portrait changes cannot retain stale presentation.

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

This explains the missing party-pet icon: the current eligibility condition receives no positive `partypetN` match, so `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/PetIcons.lua` is never asked to show the icon.

## Blizzard Pet Predicates

### `UnitIsOtherPlayersPet`

`UnitIsOtherPlayersPet(unit)` is declared in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua` without `RequiresComparableUnitTokens` or a secrecy annotation. Blizzard also uses it to select the `OTHERPET` unit-menu type in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua`.

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

A Hunter primary pet was observed with a permanent helpful pet-family aura. If that aura is absent from a Beast Mastery secondary pet, its presence could be a stronger primary-pet signal than broad predicates or pet-name matching. This is currently an observation and hypothesis, not a confirmed classifier.

Candidate spell IDs collected for runtime verification are:

```text
264662
264656
264663
284301
```

The current Blizzard UI source does not contain spell-data records that establish the names, scope, or completeness of these IDs. None should be used until the game client confirms the spell name and the aura's presence on primary and secondary pets.

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

The current Retail implementation uses separate custom aura slots for the fixed Call Pet artwork and its target ring without exposing aura presence to ordinary addon logic. Both visuals are created during `initializeFrame`, before Blizzard applies access restrictions. Each button remains a presentation boundary: SweepyBoop does not inspect its visibility, selected aura, texture, frame occupancy, or other restricted state to derive a readable primary-pet value.

The implementation keeps each ordinary parent transparent across a full update turn after rebinding its aura container. Blizzard processes a full aura rebuild on the container's next visible update, so revealing on the following update prevents a recycled slot from briefly presenting its previous assignment. The arming callbacks validate only ordinary assignment-generation state and never inspect the aura buttons.

This mechanism still depends on all of the following runtime facts:

- The complete current spell-ID set is known.
- Every intended Hunter primary pet has one of the filtered auras.
- A BM secondary pet does not have the same filtered aura.
- Exact filtering and presentation work on a friendly pet's `nameplateN` token during an active Shuffle round.
- The fixed mend-pet icon and target-ring children remain correctly controlled by their secure aura buttons in active Shuffle.

Even if confirmed, the signal is Hunter-specific unless an equivalent supported marker is found and verified for other pet classes. Other classes' pets currently remain visible through their protected party-owner gates.

## Creature Family

`UnitCreatureFamily(unit)` is declared in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`. It returns a localized family name and numeric family ID and is guarded by:

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

That result rules out selecting a family icon from the targeted/nameplate-related unit during the active round. Querying a stable token such as `"pet"` may behave differently, but data from `pet` or `partypetN` still cannot be attached to a particular `nameplateN` through the tested incomparable token pair.

## Portrait Rendering

Blizzard declares `SetPortraitTexture(texture, unit)` in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`. Its contract accepts a unit token directly and does not declare an identity-access precondition.

Blizzard's portrait lifecycle in `/Users/kunhouseliu/wow/wow-ui-source/Interface/AddOns/Blizzard_UnitFrame/Mainline/UnitFrame.lua` refreshes portraits on:

- `UNIT_PORTRAIT_UPDATE`
- `PORTRAITS_UPDATED`

SweepyBoop already calls `SetPortraitTexture` in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/NameplateFilter.lua`.

A portrait is a candidate presentation path because it does not require addon-readable family, GUID, NPC ID, or name data. It still needs an in-game test on an addon-owned texture during an active Shuffle round. The rendered texture must not be inspected as an identity side channel.

If used for recycled nameplate frames, the implementation must:

- Bind the portrait to the current nameplate unit.
- Refresh it on relevant portrait events.
- Clear the texture when the nameplate is removed or reassigned.

Portrait rendering can differentiate appearances after a unit has been accepted as a pet. It does not determine whether that pet is primary or secondary.

## Option Semantics Under Investigation

The implemented options represent separate decisions:

- **Special icon for my pet** controls whether the player's pet uses the existing mend-pet icon instead of the ordinary pet presentation.
- **Show my pet only** controls whether icons for other players' pets are hidden.

The special icon defaults to enabled to preserve the player's current Mend Pet appearance. Disabling it uses the local pet portrait. Other players' non-Hunter pets always use portraits, while Hunter primary pets use a static Call Pet icon so their secure aura filtering remains valid.

Neither option should imply that SweepyBoop can distinguish another player's primary pet from secondary pets unless Blizzard exposes a confirmed signal.

## Confirmed Findings

- The previous missing friendly party-pet icon occurred because eligibility failed before rendering.
- Retail eligibility no longer depends on comparing `nameplateN` with `partypetN`.
- `UnitIsUnitReadable` is a safety wrapper, not a secrecy or token-comparability bypass.
- The tested `nameplate1` and `partypet1` pair was incomparable during an active arena round and was also marked secret.
- `UnitIsOtherPlayersPet` returned `true` for both BM Hunter pets and cannot distinguish the primary pet by itself.
- Other-player pets are now routed through per-party protected ownership gates after readable `UnitIsOtherPlayersPet` classification; ownership results are used only by `SetAlphaFromBoolean` and are never inspected.
- During direct runtime testing, a Destruction Warlock teammate's pet displayed the icon, confirming the implemented non-Hunter remote-pet path in that scenario.
- Blizzard's custom aura container supports exact spell-ID presentation for helpful auras on assistable friendly units without exposing aura presence as an ordinary Lua Boolean.
- Candidate permanent Hunter pet-family aura IDs and their primary-versus-secondary behavior remain unverified.
- `UnitCreatureFamily` returned a family for at least Hunter and Warlock pets outside restricted PvP.
- `UnitCreatureFamily("target")` returned secret values for a friendly Hunter pet during an active arena round.
- `C_CreatureInfo.GetCreatureFamilyInfo` may omit `iconFile`.
- `SetPortraitTexture` avoids the need to read family identity, but its active-arena behavior still requires testing.

## Open Questions

- Which permanent helpful aura IDs are present on a Hunter primary pet, and which of those are absent from a BM secondary pet?
- What does `C_Secrets.GetSpellAuraSecrecy(spellID)` report for each confirmed candidate?
- Can the custom aura slot filter and present the confirmed aura on a friendly pet's `nameplateN` token during an active Shuffle round?
- Do the `party1` through `party4` protected ownership gates associate both BM Hunter pets with the correct Hunter owner during an active Shuffle round?
- Does any documented, non-secret API distinguish another player's primary pet from their secondary pets during an active Shuffle round?
- Does `SetPortraitTexture` render correctly and distinctly for friendly primary and secondary pets during an active Shuffle round?
- Is `UnitIsUnit(nameplateN, "pet")` comparable and readable for the player's own pet during an active round? Only the `partypet1` pair has been tested so far.

## Next Runtime Tests

Outside restricted PvP, target the Hunter primary pet and enumerate its permanent helpful auras. Repeat without changing the owner or specialization while targeting the BM secondary pet. Record spell IDs only when their values are readable, and identify candidates present only on the primary pet.

For each confirmed candidate, resolve its current client name and aura secrecy:

```text
/dump C_Spell.GetSpellName(spellID), C_Secrets.GetSpellAuraSecrecy(spellID)
```

Then prototype one `CustomAuraContainerTemplate` aura slot with an exact `includeSpellIDs` set. During an active Shuffle round, confirm only the securely driven visual result; do not query the button's visibility, texture, aura instance, or assignment state from addon Lua.

Target each BM Hunter pet during an active Shuffle round and visually verify that the protected owner gate routes both pets through the Hunter path. Do not print, store, compare, or otherwise inspect `UnitIsOwnerOrControllerOfUnit` results. The secure family-aura slots are responsible for visually distinguishing the primary pet.

Target the player's own pet during an active round and test the local-pet token pair separately:

```text
/run local p=C_NamePlate.GetNamePlateForUnit("target");local u=p and p.UnitFrame.unit;print(u,C_Secrets.CanCompareUnitTokens(u,"pet"),C_Secrets.ShouldUnitComparisonBeSecret(u,"pet"))
```

Test portrait presentation on an addon-owned texture during an active round before relying on it in production. Do not inspect the resulting texture as identity.

## Reliability Rules

Until Blizzard exposes or testing confirms a supported primary-pet signal:

- Do not interpret `UnitIsOtherPlayersPet` as primary-pet identity.
- Do not infer primary status from NPC ID, creature family, name, model, portrait, health, creation order, or proximity.
- Do not inspect or branch on secret values.
- Do not read restricted custom-aura button state back into ordinary Lua as an identity signal.
- Do not use rendered portrait state as an identity signal.
- Prefer broad but truthful pet presentation over labeling a secondary pet as primary.
- Keep pet eligibility, owner filtering, primary-pet classification, and icon presentation as separate concerns.
