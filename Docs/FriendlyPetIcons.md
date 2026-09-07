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

No implementation decision has been finalized.

## Current SweepyBoop Behavior

The renderer in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/PetIcons.lua` always assigns the fixed mend-pet texture:

```lua
nameplate.FriendlyPetIcon.icon:SetTexture(addon.ICON_ID_PET);
```

Pet eligibility is decided earlier in `/Users/kunhouseliu/wow/sweepy-boop/Nameplates/Nameplates.lua`:

```lua
addon.UnitIsUnitReadable(frame.unit, "pet")
    or addon.UnitIsUnitReadable(frame.unit, "partypet1")
    or addon.UnitIsUnitReadable(frame.unit, "partypet2")
```

`addon.UnitIsUnitReadable` is defined in `/Users/kunhouseliu/wow/sweepy-boop/Common/UnitInfoHelpers.lua`:

```lua
addon.UnitIsUnitReadable = function(unitA, unitB)
    local isSameUnit = UnitIsUnit(unitA, unitB);
    if addon.IsSecretValue(isSameUnit) then return false end
    return isSameUnit;
end
```

The helper prevents callers from branching on a secret Boolean. It cannot make an incomparable token pair comparable or make a secret result readable. A `nil` or secret result is false in the current eligibility condition, so the pet icon is not shown.

Two additional limitations are visible in the current code:

- Only `partypet1` and `partypet2` are checked. `partypet3` and `partypet4` are omitted.
- **Show my pet only** still evaluates a comparison with `"pet"` in arenas even though its tooltip says that the option is unavailable there. If that comparison is unavailable, the option hides the icon.

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

The proposed options represent separate decisions:

- **Special icon for my pet** controls whether the player's pet uses the existing mend-pet icon instead of the ordinary pet presentation.
- **Show my pet only** controls whether icons for other players' pets are hidden.

The special icon could default to enabled to preserve the current appearance. Final defaults and arena behavior have not been decided.

Neither option should imply that SweepyBoop can distinguish another player's primary pet from secondary pets unless Blizzard exposes a confirmed signal.

## Confirmed Findings

- Pet rendering is not the cause of the missing friendly party-pet icon; current eligibility fails before rendering.
- `UnitIsUnitReadable` is a safety wrapper, not a secrecy or token-comparability bypass.
- The tested `nameplate1` and `partypet1` pair was incomparable during an active arena round and was also marked secret.
- `UnitIsOtherPlayersPet` returned `true` for both BM Hunter pets and cannot distinguish the primary pet.
- `UnitCreatureFamily` returned a family for at least Hunter and Warlock pets outside restricted PvP.
- `UnitCreatureFamily("target")` returned secret values for a friendly Hunter pet during an active arena round.
- `C_CreatureInfo.GetCreatureFamilyInfo` may omit `iconFile`.
- `SetPortraitTexture` avoids the need to read family identity, but its active-arena behavior still requires testing.

## Open Questions

- Does `UnitPlayerOrPetInParty("target")` return `true` for both BM Hunter pets during an active Shuffle round?
- Does any documented, non-secret API distinguish another player's primary pet from their secondary pets during an active Shuffle round?
- Does `SetPortraitTexture` render correctly and distinctly for friendly primary and secondary pets during an active Shuffle round?
- Is `UnitIsUnit(nameplateN, "pet")` comparable and readable for the player's own pet during an active round? Only the `partypet1` pair has been tested so far.

## Next Runtime Tests

Target each BM Hunter pet during an active Shuffle round and run:

```text
/dump UnitPlayerOrPetInParty("target")
```

If both return `true`, this API is also a broad membership predicate and cannot identify the primary pet.

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
- Do not use rendered portrait state as an identity signal.
- Prefer broad but truthful pet presentation over labeling a secondary pet as primary.
- Keep pet eligibility, owner filtering, primary-pet classification, and icon presentation as separate concerns.
