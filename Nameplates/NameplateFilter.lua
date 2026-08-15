local _, addon = ...;

local iconSize = 30;
local highlightHaloSize = 50;
local highlightPulseScale = 1.07;
local highlightPulseDuration = 0.42;
local highlightColor = { 0.85, 0.15, 1 };

local function SetupAnimation(halo)
    local animationGroup = halo:CreateAnimationGroup();
    animationGroup:SetLooping("BOUNCE");

    local pulse = animationGroup:CreateAnimation("Scale");
    pulse:SetScale(highlightPulseScale, highlightPulseScale);
    pulse:SetDuration(highlightPulseDuration);
    if pulse.SetSmoothing then
        pulse:SetSmoothing("IN_OUT");
    end

    return animationGroup;
end

local function StopHighlightAnimation(highlight)
    if highlight.animationGroup:IsPlaying() then
        highlight.animationGroup:Stop();
    end
    highlight.halo:SetScale(1);
end

local function CreatePortraitHighlight(parent)
    parent:SetSize(iconSize, iconSize);
    parent:SetMouseClickEnabled(false);

    parent.portrait = parent:CreateTexture(nil, "ARTWORK");
    parent.portrait:SetAllPoints(parent);

    parent.halo = CreateFrame("Frame", nil, parent);
    parent.halo:SetMouseClickEnabled(false);
    parent.halo:SetSize(highlightHaloSize, highlightHaloSize);
    parent.halo:SetPoint("CENTER", parent);

    parent.glowTexture = parent.halo:CreateTexture(nil, "OVERLAY");
    parent.glowTexture:SetAllPoints(parent.halo);
    parent.glowTexture:SetBlendMode("ADD");
    parent.glowTexture:SetAtlas("clickcast-highlight-spellbook");
    parent.glowTexture:SetDesaturated(true);
    parent.glowTexture:SetVertexColor(unpack(highlightColor));

    parent.animationGroup = SetupAnimation(parent.halo);
    parent.animationGroup:Play();
end

local function ApplyPortraitHighlightLayout(highlight, nameplate)
    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if highlight.layoutApplied and highlight.lastModified == config.lastModified then return end

    highlight:SetScale(config.npcHighlightScale);
    highlight:ClearAllPoints();
    highlight:SetPoint(
        "BOTTOM",
        nameplate,
        "TOP",
        config.npcHighlightHorizontalOffset or 0,
        config.npcHighlightOffset or 0
    );
    highlight.lastModified = config.lastModified;
    highlight.layoutApplied = true;
end

local function ApplyAlphaSignal(frame, signal)
    if addon.IsSecretValue(signal) then
        frame:SetAlphaFromBoolean(signal, 1, 0);
    elseif signal then
        frame:SetAlpha(1);
    else
        frame:SetAlpha(0);
    end
end

local function ApplyInverseAlphaSignal(frame, signal)
    if addon.IsSecretValue(signal) then
        frame:SetAlphaFromBoolean(signal, 0, 1);
    elseif signal then
        frame:SetAlpha(0);
    else
        frame:SetAlpha(1);
    end
end

-- Blizzard-important aura and cast portraits are the default path. These
-- overrides add known false negatives without claiming exact summon identity.
local summonPresentationOverrides = {
    {
        key = "warlockPrimaryPetCast",
        ownerClass = addon.WARLOCK,
        primaryPet = true,
        signal = "casting",
        -- A casting Warlock primary pet is Succubus-oriented, but also includes
        -- truthful portraits such as an Imp casting Firebolt.
    },
    {
        key = "afflictionMinionCast",
        ownerSpec = addon.SPECID.AFFLICTION,
        primaryPet = false,
        signal = "casting",
        -- An Affliction non-primary casting minion is Darkglare-oriented; its
        -- primary-pet classification still requires in-game verification.
    },
    {
        key = "shamanMinionCast",
        ownerClass = addon.SHAMAN,
        signal = "casting",
        -- A casting Shaman minion is Capacitor-oriented, not exact totem identity.
    },
    {
        key = "shadowMinionChannel",
        ownerSpec = addon.SPECID.SHADOW,
        primaryPet = false,
        signal = "channeling",
        requireNotInterruptible = true,
        -- A protected Shadow-owned channel is Psyfiend-oriented, not exact identity.
    },
};

local importantAuraSlotKey = "ImportantMinion";

local function EnsureImportantAuraContainer(nameplate, unit)
    local container = nameplate.importantNpcAuraContainer;
    if container then
        container.currentUnit = unit;
        return container, false;
    end

    container = CreateFrame(
        "AuraContainer",
        nil,
        nameplate,
        "CustomAuraContainerTemplate"
    );
    container:SetFrameStrata("HIGH");
    container:SetSize(iconSize, iconSize);
    container:SetEnabled(false);
    container:Hide();
    container.currentUnit = unit;
    container.portraits = {};
    container:AddAuraSlot(importantAuraSlotKey, "HELPFUL|IMPORTANT", {
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            CreatePortraitHighlight(button);
            button:SetPoint("CENTER", container, "CENTER");
            -- The portrait is not registered as Blizzard's aura icon. Blizzard's
            -- protected slot visibility instead gates this child portrait.
            SetPortraitTexture(button.portrait, container.currentUnit);
            table.insert(container.portraits, button.portrait);
        end,
    });

    nameplate.importantNpcAuraContainer = container;
    return container, true;
end

local function DeactivateImportantAuraContainer(nameplate)
    local container = nameplate.importantNpcAuraContainer;
    if not container then return end

    container:SetEnabled(false);
    container:Hide();
end

local function OverrideMatchesOwner(override, specID)
    if override.ownerSpec then
        return specID == override.ownerSpec;
    end
    return addon.SPECID_TO_CLASS[specID] == override.ownerClass;
end

local function OverrideMatchesPetState(override, isOtherPlayersPet)
    return override.primaryPet == nil or override.primaryPet == isOtherPlayersPet;
end

local function GetCastPresentationState(unit)
    -- UnitCastingInfo and UnitChannelInfo mark return 6 (isTradeskill) as
    -- NeverSecret and non-nilable when the corresponding result exists. Both APIs
    -- return no tuple without an active cast/channel, as Blizzard's castbar also
    -- assumes. This tests only that public sentinel, never protected cast details.
    local castingPresence = select(6, UnitCastingInfo(unit));
    local channelPresence, channelNotInterruptible =
        select(6, UnitChannelInfo(unit));

    -- UnitChannelInfo return 7 is nilable and may be secret. Never compare or
    -- branch on it; the Shadow override forwards it only to an alpha sink.
    return castingPresence ~= nil,
        channelPresence ~= nil,
        channelNotInterruptible;
end

local function OverrideIsActive(override, isCasting, isChanneling)
    if override.signal == "casting" then return isCasting end
    return isChanneling;
end

local function EnsureSummonPresentationGate(nameplate, override, arenaSlot)
    local ruleGates = nameplate.summonPresentationGates;
    if not ruleGates then
        ruleGates = {};
        nameplate.summonPresentationGates = ruleGates;
    end

    local gates = ruleGates[override.key];
    if not gates then
        gates = {};
        ruleGates[override.key] = gates;
    end

    local gate = gates[arenaSlot];
    if gate then return gate end

    gate = CreateFrame("Frame", nil, nameplate);
    gate:SetFrameStrata("HIGH");
    gate:SetSize(iconSize, iconSize);
    gate.overrideGate = CreateFrame("Frame", nil, gate);
    gate.overrideGate:SetAllPoints(gate);
    gate:Hide();
    gates[arenaSlot] = gate;
    return gate;
end

local function EnsureRulePortrait(gate)
    if gate.highlight then return gate.highlight end

    local highlight = CreateFrame("Frame", nil, gate.overrideGate);
    highlight:SetPoint("CENTER", gate.overrideGate);
    CreatePortraitHighlight(highlight);
    gate.highlight = highlight;
    return highlight;
end

local function DeactivateSummonPresentationGate(gate)
    if gate.highlight then
        StopHighlightAnimation(gate.highlight);
        gate.highlight.portrait:SetTexture(nil);
        gate.highlight:SetAlpha(0);
    end
    gate:Hide();
end

local function DeactivateSummonPresentationOverrides(nameplate)
    local ruleGates = nameplate.summonPresentationGates;
    if not ruleGates then return end

    for _, override in ipairs(summonPresentationOverrides) do
        local gates = ruleGates[override.key];
        if gates then
            for _, gate in pairs(gates) do
                DeactivateSummonPresentationGate(gate);
            end
        end
    end
end

local function UpdateOverrideImportantCastSignal(nameplate, signal)
    local ruleGates = nameplate.summonPresentationGates;
    if not ruleGates then return end

    for _, override in ipairs(summonPresentationOverrides) do
        local gates = ruleGates[override.key];
        if gates then
            for _, gate in pairs(gates) do
                ApplyInverseAlphaSignal(gate.overrideGate, signal);
            end
        end
    end
end

local function UpdateSummonPresentationOverrides(nameplate, unit, castBar, isOtherPlayersPet)
    if not IsActiveBattlefieldArena() then
        DeactivateSummonPresentationOverrides(nameplate);
        return;
    end

    local isCasting, isChanneling, channelNotInterruptible =
        GetCastPresentationState(unit);

    local ruleGates = nameplate.summonPresentationGates;
    for _, override in ipairs(summonPresentationOverrides) do
        local overrideActive = OverrideMatchesPetState(override, isOtherPlayersPet)
            and OverrideIsActive(override, isCasting, isChanneling);
        local gates = ruleGates and ruleGates[override.key];

        for arenaSlot = 1, addon.MAX_ARENA_SIZE do
            local gate = gates and gates[arenaSlot];
            if overrideActive and OverrideMatchesOwner(override, GetArenaOpponentSpec(arenaSlot)) then
                gate = gate or EnsureSummonPresentationGate(nameplate, override, arenaSlot);
                ApplyPortraitHighlightLayout(gate, nameplate);
                gate:SetAlphaFromBoolean(
                    UnitIsOwnerOrControllerOfUnit("arena" .. arenaSlot, unit),
                    1,
                    0
                );
                -- Overrides are fallbacks for Blizzard false negatives. Reverse the
                -- protected important-cast signal without exposing it to Lua.
                ApplyInverseAlphaSignal(
                    gate.overrideGate,
                    castBar:GetIsHighlightedImportantCast()
                );

                local highlight = EnsureRulePortrait(gate);
                SetPortraitTexture(highlight.portrait, unit);
                if override.requireNotInterruptible then
                    ApplyAlphaSignal(highlight, channelNotInterruptible);
                else
                    highlight:SetAlpha(1);
                end
                if not highlight.animationGroup:IsPlaying() then
                    highlight.animationGroup:Play();
                end
                highlight:Show();
                gate:Show();
            elseif gate then
                DeactivateSummonPresentationGate(gate);
            end
        end
    end
end

local function EnsureImportantCastPortrait(nameplate, castBar)
    local highlight = nameplate.importantNpcCastPortrait;
    if not highlight then
        highlight = CreateFrame("Frame", nil, castBar);
        highlight:SetFrameStrata("HIGH");
        highlight:SetIgnoreParentAlpha(true);
        CreatePortraitHighlight(highlight);
        highlight:Show();
        nameplate.importantNpcCastPortrait = highlight;
    elseif highlight:GetParent() ~= castBar then
        highlight:SetParent(castBar);
    end

    ApplyPortraitHighlightLayout(highlight, nameplate);
    return highlight;
end

if addon.PROJECT_MAINLINE then
    local function ClearImportantCastPortrait(castBar)
        local highlight = castBar.sweepyBoopImportantNpcPortrait;
        if highlight then
            StopHighlightAnimation(highlight);
            highlight.portrait:SetTexture(nil);
            highlight:SetAlpha(0);
        end

        local nameplate = castBar.sweepyBoopImportantNpcNameplate;
        if nameplate then
            DeactivateSummonPresentationOverrides(nameplate);
        end
    end

    -- The hook is only an update notification after Blizzard processes the event.
    -- Override state comes from GetCastPresentationState, never from castbar fields.
    hooksecurefunc(NamePlateCastingBarMixin, "OnEvent", function(castBar)
        local nameplate = castBar.sweepyBoopImportantNpcNameplate;
        if nameplate then
            UpdateSummonPresentationOverrides(
                nameplate,
                castBar.unit,
                castBar,
                nameplate.importantNpcIsOtherPlayersPet
            );
        end
    end);
    hooksecurefunc(NamePlateCastingBarMixin, "SetIsHighlightedImportantCast", function(castBar, signal)
        local highlight = castBar.sweepyBoopImportantNpcPortrait;
        if highlight then
            ApplyAlphaSignal(highlight, signal);
            if not highlight.animationGroup:IsPlaying() then
                highlight.animationGroup:Play();
            end
        end
        local nameplate = castBar.sweepyBoopImportantNpcNameplate;
        if nameplate then
            UpdateOverrideImportantCastSignal(nameplate, signal);
        end
    end);
    -- These presentation transitions run only after Blizzard accepts the stop or
    -- interruption for the active cast. Raw event handlers may receive stale IDs.
    hooksecurefunc(NamePlateCastingBarMixin, "PlayFadeAnim", ClearImportantCastPortrait);
    hooksecurefunc(NamePlateCastingBarMixin, "PlayInterruptAnims", ClearImportantCastPortrait);

    hooksecurefunc(NamePlateUnitFrameMixin, "OnUnitCleared", function(unitFrame)
        local nameplate = unitFrame:GetNamePlateFrame();
        if nameplate then
            addon.DeactivateImportantNpcPortrait(nameplate);
        end
    end);
end

addon.ActivateImportantNpcPortrait = function(nameplate, unit, castBar, isOtherPlayersPet)
    local container, isNewContainer = EnsureImportantAuraContainer(nameplate, unit);
    ApplyPortraitHighlightLayout(container, nameplate);
    if not isNewContainer then
        -- This unregistered child remains a prototype: verify that restricted aura
        -- buttons permit portrait refreshes when a pooled nameplate changes units.
        for _, portrait in ipairs(container.portraits) do
            SetPortraitTexture(portrait, unit);
        end
    end
    container:SetUnit(unit);
    container:SetEnabled(true);
    container:Show();
    container:UpdateAllAuras();

    nameplate.importantNpcIsOtherPlayersPet = isOtherPlayersPet;
    if castBar then
        local previousCastBar = nameplate.importantNpcCastBar;
        if previousCastBar and previousCastBar ~= castBar then
            previousCastBar.sweepyBoopImportantNpcPortrait = nil;
            previousCastBar.sweepyBoopImportantNpcNameplate = nil;
        end

        local castHighlight = EnsureImportantCastPortrait(nameplate, castBar);
        SetPortraitTexture(castHighlight.portrait, unit);
        local isNewAssociation = castBar.sweepyBoopImportantNpcPortrait ~= castHighlight;
        castBar.sweepyBoopImportantNpcPortrait = castHighlight;
        castBar.sweepyBoopImportantNpcNameplate = nameplate;
        nameplate.importantNpcCastBar = castBar;
        if isNewAssociation then
            -- Blizzard has already computed this value in untainted execution. Forward
            -- it only to SweepyBoop's secret-safe alpha sink; recomputing here would make
            -- Blizzard's own SetShown call consume a secret from tainted execution.
            ApplyAlphaSignal(castHighlight, castBar:GetIsHighlightedImportantCast());
        end
        if not castHighlight.animationGroup:IsPlaying() then
            castHighlight.animationGroup:Play();
        end

        UpdateSummonPresentationOverrides(nameplate, unit, castBar, isOtherPlayersPet);
    else
        DeactivateSummonPresentationOverrides(nameplate);
    end
end

local debugNpcPortraitNameplate;

addon.HideDebugNpcPortrait = function(nameplate)
    local highlight = nameplate.debugNpcPortraitHighlight;
    if highlight then
        StopHighlightAnimation(highlight);
        highlight.portrait:SetTexture(nil);
        highlight:Hide();
    end
    if debugNpcPortraitNameplate == nameplate then
        debugNpcPortraitNameplate = nil;
    end
end

addon.DeactivateImportantNpcPortrait = function(nameplate)
    DeactivateImportantAuraContainer(nameplate);
    DeactivateSummonPresentationOverrides(nameplate);
    nameplate.importantNpcIsOtherPlayersPet = nil;

    local castBar = nameplate.importantNpcCastBar;
    if castBar then
        castBar.sweepyBoopImportantNpcPortrait = nil;
        castBar.sweepyBoopImportantNpcNameplate = nil;
        nameplate.importantNpcCastBar = nil;
    end

    local castHighlight = nameplate.importantNpcCastPortrait;
    if castHighlight then
        StopHighlightAnimation(castHighlight);
        castHighlight.portrait:SetTexture(nil);
        castHighlight:SetAlpha(0);
    end
end

local function EnsureNpcHighlight(nameplate)
    local config = SweepyBoop.db.profile.nameplatesEnemy;

    if ( not nameplate.npcHighlight ) then
        nameplate.npcHighlight = CreateFrame("Frame", nil, nameplate);
        nameplate.npcHighlight:SetMouseClickEnabled(false);
        nameplate.npcHighlight:SetSize(iconSize, iconSize);
        nameplate.npcHighlight:SetFrameStrata("HIGH");
        nameplate.npcHighlight:SetPoint("BOTTOM", nameplate, "TOP", config.npcHighlightHorizontalOffset or 0, config.npcHighlightOffset or 0);

        nameplate.npcHighlight.customIcon = nameplate.npcHighlight:CreateTexture(nil, "OVERLAY");
        nameplate.npcHighlight.customIcon:SetAllPoints(nameplate.npcHighlight);

        nameplate.npcHighlight.halo = CreateFrame("Frame", nil, nameplate.npcHighlight);
        nameplate.npcHighlight.halo:SetMouseClickEnabled(false);
        nameplate.npcHighlight.halo:SetSize(highlightHaloSize, highlightHaloSize);
        nameplate.npcHighlight.halo:SetPoint("CENTER", nameplate.npcHighlight);

        nameplate.npcHighlight.glowTexture = nameplate.npcHighlight.halo:CreateTexture(nil, "OVERLAY");
        nameplate.npcHighlight.glowTexture:SetAllPoints(nameplate.npcHighlight.halo);
        nameplate.npcHighlight.glowTexture:SetBlendMode("ADD");
        if addon.PROJECT_MAINLINE then
            nameplate.npcHighlight.glowTexture:SetAtlas("clickcast-highlight-spellbook");
        else
            nameplate.npcHighlight.glowTexture:SetAtlas("Forge-ColorSwatchSelection");
            nameplate.npcHighlight.glowTexture:SetScale(0.4);
        end
        nameplate.npcHighlight.glowTexture:SetDesaturated(true);
        nameplate.npcHighlight.glowTexture:SetVertexColor(unpack(highlightColor));

        nameplate.npcHighlight.animationGroup = SetupAnimation(nameplate.npcHighlight.halo);

        nameplate.npcHighlight:Hide();
    end

    if ( nameplate.npcHighlight.lastModified ~= config.lastModified ) then
        nameplate.npcHighlight:SetScale(config.npcHighlightScale);
        nameplate.npcHighlight:SetPoint("BOTTOM", nameplate, "TOP", config.npcHighlightHorizontalOffset or 0, config.npcHighlightOffset or 0);
        nameplate.npcHighlight.lastModified = config.lastModified;
    end

    return nameplate.npcHighlight;
end

addon.UpdateNpcHighlight = function(nameplate, iconTexture, highlightKey)
    -- Parented to UnitFrame to inherit the visibility
    local highlight = EnsureNpcHighlight(nameplate);
    if addon.PROJECT_MAINLINE then
        -- SetTexture accepts secret aura textures; do not inspect them in Lua.
        highlight.customIcon:SetTexture(iconTexture);
        return;
    end

    if ( not iconTexture ) then
        local npcID = addon.GetNpcIdFromUnit(nameplate.UnitFrame.unit);
        highlightKey = tostring(npcID);
        iconTexture = addon.iconTexture[highlightKey]; -- nil if no texture found
    end

    if ( highlight.currentKey ~= highlightKey ) or ( highlight.currentTexture ~= iconTexture ) then
        highlight.customIcon:SetTexture(iconTexture);
        highlight.currentKey = highlightKey;
        highlight.currentTexture = iconTexture;
    end
end

addon.ShowNpcHighlight = function(nameplate, animation, iconTexture, highlightKey)
    addon.UpdateNpcHighlight(nameplate, iconTexture, highlightKey);
    local highlight = nameplate.npcHighlight;

    if highlight then
        highlight.customIcon:Show();
        if animation then
            highlight.halo:Show();
            if not highlight.animationGroup:IsPlaying() then
                StopHighlightAnimation(highlight);
                highlight.animationGroup:Play();
            end
        else
            StopHighlightAnimation(highlight);
            highlight.halo:Hide();
        end
        highlight:Show();
    end
end

addon.HideNpcHighlight = function(nameplate)
    local highlight = nameplate.npcHighlight;
    if highlight then
        StopHighlightAnimation(highlight);
        highlight.halo:Hide();
        highlight.customIcon:Hide();
        highlight:Hide();
    end
end

if addon.internal then
    function SweepyBoop:DebugNpcHighlight(shouldShow, iconTexture)
        if addon.PROJECT_MAINLINE and shouldShow == false then
            if debugNpcPortraitNameplate then
                addon.HideDebugNpcPortrait(debugNpcPortraitNameplate);
            end
            print("SweepyBoop: NPC portrait highlight preview hidden");
            return;
        end

        local nameplate = C_NamePlate.GetNamePlateForUnit("target");
        if not nameplate then
            print("SweepyBoop: current target has no visible nameplate");
            return;
        end

        if addon.PROJECT_MAINLINE then
            if debugNpcPortraitNameplate and debugNpcPortraitNameplate ~= nameplate then
                addon.HideDebugNpcPortrait(debugNpcPortraitNameplate);
            end

            local highlight = nameplate.debugNpcPortraitHighlight;
            if not highlight then
                highlight = CreateFrame("Frame", nil, nameplate);
                highlight:SetFrameStrata("HIGH");
                CreatePortraitHighlight(highlight);
                nameplate.debugNpcPortraitHighlight = highlight;
            end
            ApplyPortraitHighlightLayout(highlight, nameplate);
            SetPortraitTexture(highlight.portrait, "target");
            if not highlight.animationGroup:IsPlaying() then
                highlight.animationGroup:Play();
            end
            highlight:Show();
            debugNpcPortraitNameplate = nameplate;
            print("SweepyBoop: showing animated NPC portrait on current target");
            return;
        end

        if shouldShow == false then
            addon.HideNpcHighlight(nameplate);
            print("SweepyBoop: NPC highlight preview hidden");
            return;
        end

        addon.ShowNpcHighlight(
            nameplate,
            true,
            iconTexture or addon.GetSpellTexture(8177),
            "debug"
        );
        print("SweepyBoop: showing animated NPC highlight on current target");
    end
end

local scaleFactor = 0.5; -- Smaller icons for critters

local function EnsureIcon(nameplate)
    if ( not nameplate.EnemyCritterIcon ) then
        nameplate.EnemyCritterIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER", false);
        nameplate.EnemyCritterIcon.icon:SetAtlas(addon.ICON_CRITTER);
        nameplate.EnemyCritterIcon:Hide();
    end

    return nameplate.EnemyCritterIcon;
end

addon.UpdateCritterIcon = function(nameplate)
    -- Only update if config changes (we have separated out pet icon from class / healer / flag carrier icons, and pet icon has fixed texture)
    local iconFrame = EnsureIcon(nameplate);
    local lastModifiedEnemy = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
    if ( iconFrame.lastModifiedEnemy ~= lastModifiedEnemy ) then
        iconFrame:SetScale(SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100 * scaleFactor);
        iconFrame.lastModifiedEnemy = lastModifiedEnemy;
    end
end

addon.ShowCritterIcon = function (nameplate)
    addon.UpdateCritterIcon(nameplate);
    if nameplate.EnemyCritterIcon then
        nameplate.EnemyCritterIcon:Show();
    end
end

addon.HideCritterIcon = function(nameplate)
    if nameplate.EnemyCritterIcon then
        nameplate.EnemyCritterIcon:Hide();
    end
end
