local _, addon = ...;

local iconSize = 30;
local iconInset = 2;
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

local function CreateIconHighlight(parent)
    parent:SetSize(iconSize, iconSize);
    parent:SetMouseClickEnabled(false);

    parent.icon = parent:CreateTexture(nil, "ARTWORK");
    parent.icon:SetPoint("TOPLEFT", parent, "TOPLEFT", iconInset, -iconInset);
    parent.icon:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -iconInset, iconInset);

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

local function CreatePortraitHighlight(parent)
    CreateIconHighlight(parent);
    parent.portrait = parent.icon;
end

local function ApplyHighlightLayout(highlight, nameplate)
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

-- This is the complete Mainline presentation policy. Entries render independently.
-- Cast/static icons render above aura icons, which render above unit portraits; any
-- overlapping additive halos intentionally become brighter. A future blacklist should
-- use only readable predicates and run
-- before this whitelist is activated; unknown/protected facts must fail open.
local importantMinionWhitelist = {
    {
        key = "shamanImportantAura",
        ownerClass = addon.SHAMAN,
        signal = "aura",
        filter = "HELPFUL|IMPORTANT",
        presentation = "auraIcon",
    },
    {
        key = "warlockPrimaryPetCast",
        ownerClass = addon.WARLOCK,
        primaryPet = true,
        signal = "cast",
        presentation = "portrait",
    },
    {
        key = "magePrimaryPetCast",
        ownerClass = addon.MAGE,
        primaryPet = true,
        signal = "cast",
        presentation = "portrait",
        -- Test rule: Mage primary pets are common and make this path easy to verify.
    },
    {
        key = "afflictionMinionCast",
        ownerSpec = addon.SPECID.AFFLICTION,
        primaryPet = false,
        signal = "cast",
        presentation = "portrait",
    },
    {
        key = "shamanMinionCast",
        ownerClass = addon.SHAMAN,
        signal = "cast",
        presentation = "castIcon",
    },
    {
        key = "shadowMinionChannel",
        ownerSpec = addon.SPECID.SHADOW,
        primaryPet = false,
        signal = "channel",
        requireNotInterruptible = true,
        presentation = "staticIcon",
        -- Psyfiend's canonical Retail summon spell. This is presentation-only;
        -- the spell ID is never used to infer the minion's identity.
        iconSpellID = 211522,
    },
};

local function RuleMatchesOwner(rule, specID)
    if rule.ownerSpec then
        return specID == rule.ownerSpec;
    end
    return addon.SPECID_TO_CLASS[specID] == rule.ownerClass;
end

local function RuleMatchesPetState(rule, isOtherPlayersPet)
    return rule.primaryPet == nil or rule.primaryPet == isOtherPlayersPet;
end

local function EnsureAuraRuleGate(nameplate, rule, arenaSlot)
    local ruleGates = nameplate.importantMinionAuraGates;
    if not ruleGates then
        ruleGates = {};
        nameplate.importantMinionAuraGates = ruleGates;
    end

    local gates = ruleGates[rule.key];
    if not gates then
        gates = {};
        ruleGates[rule.key] = gates;
    end

    local gate = gates[arenaSlot];
    if gate then return gate end

    gate = CreateFrame("Frame", nil, nameplate);
    gate:SetFrameStrata("HIGH");
    gate:SetFrameLevel(nameplate:GetFrameLevel() + 10);
    gate:SetSize(iconSize, iconSize);
    gate:SetAlpha(0);
    gate:Hide();

    local container = CreateFrame(
        "AuraContainer",
        nil,
        gate,
        "CustomAuraContainerTemplate"
    );
    container:SetAllPoints(gate);
    container:SetEnabled(false);
    container:Hide();
    gate.container = container;

    container:AddAuraSlot(rule.key, rule.filter, {
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            button:SetPoint("CENTER", container, "CENTER");
            CreateIconHighlight(button);

            -- Blizzard securely owns both the selected aura icon and button visibility.
            -- Configure this inbound texture once, then never inspect or mutate the
            -- restricted aura descendants from ordinary addon execution.
            button:SetIcon(button.icon);
        end,
    });

    gates[arenaSlot] = gate;
    return gate;
end

local function DeactivateAuraRules(nameplate)
    local ruleGates = nameplate.importantMinionAuraGates;
    if not ruleGates then return end

    for _, gates in pairs(ruleGates) do
        for _, gate in pairs(gates) do
            -- Hiding and disabling the root is sufficient. Its icon and halo belong
            -- to Blizzard's restricted aura button and must not be mutated after setup.
            gate.container:SetEnabled(false);
            gate.container:Hide();
            gate:SetAlpha(0);
            gate:Hide();
        end
    end
end

local function ActivateAuraRules(nameplate, unit, isOtherPlayersPet)
    DeactivateAuraRules(nameplate);
    if not IsActiveBattlefieldArena() then return end

    for _, rule in ipairs(importantMinionWhitelist) do
        if rule.signal == "aura"
            and RuleMatchesPetState(rule, isOtherPlayersPet) then

            for arenaSlot = 1, addon.MAX_ARENA_SIZE do
                if RuleMatchesOwner(rule, GetArenaOpponentSpec(arenaSlot)) then
                    local gate = EnsureAuraRuleGate(nameplate, rule, arenaSlot);
                    ApplyHighlightLayout(gate, nameplate);
                    gate:SetAlphaFromBoolean(
                        UnitIsOwnerOrControllerOfUnit(
                            "arena" .. arenaSlot,
                            unit
                        ),
                        1,
                        0
                    );
                    gate.container:SetUnit(unit);
                    gate.container:SetEnabled(true);
                    gate.container:Show();
                    gate.container:UpdateAllAuras();
                    gate:Show();
                end
            end
        end
    end
end

local function GetCastPresentationState(unit)
    -- Texture returns may be protected and remain opaque. Return 6 is NeverSecret
    -- and serves only as the public tuple-presence sentinel documented by Blizzard.
    local _, _, castingTexture, _, _, castingPresence = UnitCastingInfo(unit);
    local _, _, channelTexture, _, _, channelPresence,
        channelNotInterruptible = UnitChannelInfo(unit);

    -- UnitChannelInfo return 7 may be protected. It is forwarded only to an alpha
    -- sink for entries that explicitly require a non-interruptible channel.
    return castingPresence ~= nil,
        channelPresence ~= nil,
        castingTexture,
        channelTexture,
        channelNotInterruptible;
end

local function RuleIsActive(rule, isCasting, isChanneling)
    if rule.signal == "cast" then return isCasting end
    if rule.signal == "channel" then return isChanneling end
    return false;
end

local function EnsureActionRuleFrame(nameplate, rule, ownerSlot)
    local ruleFrames = nameplate.importantMinionActionFrames;
    if not ruleFrames then
        ruleFrames = {};
        nameplate.importantMinionActionFrames = ruleFrames;
    end

    local frames = ruleFrames[rule.key];
    if not frames then
        frames = {};
        ruleFrames[rule.key] = frames;
    end

    local frame = frames[ownerSlot];
    if frame then return frame end

    frame = CreateFrame("Frame", nil, nameplate);
    frame:SetFrameStrata("HIGH");
    local frameLevelOffset = rule.presentation == "portrait" and 5 or 20;
    frame:SetFrameLevel(nameplate:GetFrameLevel() + frameLevelOffset);
    frame:SetSize(iconSize, iconSize);
    frame:SetAlpha(0);

    -- The nested alpha parent composes protected channel interruptibility with
    -- protected ownership without calculating their conjunction in Lua.
    frame.interruptibilityGate = CreateFrame("Frame", nil, frame);
    frame.interruptibilityGate:SetAllPoints(frame);
    frame.interruptibilityGate:SetAlpha(rule.requireNotInterruptible and 0 or 1);

    frame.highlight = CreateFrame("Frame", nil, frame.interruptibilityGate);
    frame.highlight:SetPoint("CENTER", frame.interruptibilityGate);
    CreateIconHighlight(frame.highlight);
    frame:Hide();

    frames[ownerSlot] = frame;
    return frame;
end

local function PrepareActionRuleFrames(nameplate, isOtherPlayersPet)
    for _, rule in ipairs(importantMinionWhitelist) do
        if rule.signal ~= "aura" and RuleMatchesPetState(rule, isOtherPlayersPet) then
            if rule.ownerClass or rule.ownerSpec then
                if IsActiveBattlefieldArena() then
                    for arenaSlot = 1, addon.MAX_ARENA_SIZE do
                        if RuleMatchesOwner(rule, GetArenaOpponentSpec(arenaSlot)) then
                            EnsureActionRuleFrame(nameplate, rule, arenaSlot);
                        end
                    end
                end
            else
                EnsureActionRuleFrame(nameplate, rule, 0);
            end
        end
    end
end

local function SetActionPresentation(
    highlight,
    rule,
    unit,
    castingTexture,
    channelTexture
)
    if rule.presentation == "portrait" then
        SetPortraitTexture(highlight.icon, unit);
    elseif rule.presentation == "staticIcon" then
        highlight.icon:SetTexture(addon.GetSpellTexture(rule.iconSpellID));
    elseif rule.signal == "cast" then
        highlight.icon:SetTexture(castingTexture);
    else
        highlight.icon:SetTexture(channelTexture);
    end
end

local function DeactivateActionRuleFrame(frame)
    StopHighlightAnimation(frame.highlight);
    frame.highlight.icon:SetTexture(nil);
    frame:SetAlpha(0);
    frame:Hide();
end

local function DeactivateActionRules(nameplate)
    local ruleFrames = nameplate.importantMinionActionFrames;
    if not ruleFrames then return end

    for _, frames in pairs(ruleFrames) do
        for _, frame in pairs(frames) do
            DeactivateActionRuleFrame(frame);
        end
    end
end

local function UpdateActionRules(
    nameplate,
    unit,
    isOtherPlayersPet
)
    local isCasting, isChanneling, castingTexture, channelTexture,
        channelNotInterruptible = GetCastPresentationState(unit);

    PrepareActionRuleFrames(nameplate, isOtherPlayersPet);
    local ruleFrames = nameplate.importantMinionActionFrames;

    for _, rule in ipairs(importantMinionWhitelist) do
        if rule.signal ~= "aura" then
            local active = RuleMatchesPetState(rule, isOtherPlayersPet)
                and RuleIsActive(rule, isCasting, isChanneling);
            local frames = ruleFrames and ruleFrames[rule.key];

            if frames then
                for ownerSlot, frame in pairs(frames) do
                    local ownerMatches = ownerSlot == 0
                        or RuleMatchesOwner(rule, GetArenaOpponentSpec(ownerSlot));

                    if active and ownerMatches then
                        ApplyHighlightLayout(frame, nameplate);
                        if ownerSlot == 0 then
                            frame:SetAlpha(1);
                        else
                            frame:SetAlphaFromBoolean(
                                UnitIsOwnerOrControllerOfUnit(
                                    "arena" .. ownerSlot,
                                    unit
                                ),
                                1,
                                0
                            );
                        end

                        if rule.requireNotInterruptible then
                            ApplyAlphaSignal(
                                frame.interruptibilityGate,
                                channelNotInterruptible
                            );
                        else
                            frame.interruptibilityGate:SetAlpha(1);
                        end

                        SetActionPresentation(
                            frame.highlight,
                            rule,
                            unit,
                            castingTexture,
                            channelTexture
                        );
                        if not frame.highlight.animationGroup:IsPlaying() then
                            frame.highlight.animationGroup:Play();
                        end
                        frame.highlight:Show();
                        frame:Show();
                    else
                        DeactivateActionRuleFrame(frame);
                    end
                end
            end
        end
    end
end

if addon.PROJECT_MAINLINE then
    local function IsForbiddenSafe(frame)
        if addon.IsSecretValue(frame) then return true end
        return frame:IsForbidden();
    end

    local function ClearActionRules(castBar)
        if IsForbiddenSafe(castBar) then return end
        local nameplate = castBar.sweepyBoopImportantNpcNameplate;
        if nameplate then
            DeactivateActionRules(nameplate);
        end
    end

    -- These hooks are update notifications only. Current action state and texture
    -- always come from UnitCastingInfo/UnitChannelInfo, never castbar lifecycle fields.
    hooksecurefunc(NamePlateCastingBarMixin, "OnEvent", function(castBar, event)
        if IsForbiddenSafe(castBar) then return end
        local nameplate = castBar.sweepyBoopImportantNpcNameplate;
        if not nameplate then return end

        if event == addon.UNIT_SPELLCAST_STOP
            or event == addon.UNIT_SPELLCAST_INTERRUPTED
            or event == addon.UNIT_SPELLCAST_CHANNEL_STOP then
            return;
        end

        UpdateActionRules(
            nameplate,
            castBar.unit,
            nameplate.importantNpcIsOtherPlayersPet
        );
    end);
    -- These transitions occur after Blizzard accepts the active cast stop or interrupt.
    hooksecurefunc(NamePlateCastingBarMixin, "PlayFadeAnim", ClearActionRules);
    hooksecurefunc(NamePlateCastingBarMixin, "PlayInterruptAnims", ClearActionRules);

    hooksecurefunc(NamePlateUnitFrameMixin, "OnUnitCleared", function(unitFrame)
        if IsForbiddenSafe(unitFrame) then return end
        local nameplate = unitFrame:GetNamePlateFrame();
        if nameplate then
            addon.DeactivateImportantNpcPortrait(nameplate);
        end
    end);
end

addon.ActivateImportantNpcPortrait = function(nameplate, unit, castBar, isOtherPlayersPet)
    -- A future readable blacklist belongs here, before any whitelist entry activates.
    -- Never use protected or unknown identity facts as blacklist predicates.
    ActivateAuraRules(nameplate, unit, isOtherPlayersPet);
    nameplate.importantNpcIsOtherPlayersPet = isOtherPlayersPet;

    local previousCastBar = nameplate.importantNpcCastBar;
    if previousCastBar and previousCastBar ~= castBar then
        previousCastBar.sweepyBoopImportantNpcNameplate = nil;
    end

    if castBar then
        castBar.sweepyBoopImportantNpcNameplate = nameplate;
        nameplate.importantNpcCastBar = castBar;
        UpdateActionRules(
            nameplate,
            unit,
            isOtherPlayersPet
        );
    else
        if previousCastBar then
            previousCastBar.sweepyBoopImportantNpcNameplate = nil;
            nameplate.importantNpcCastBar = nil;
        end
        DeactivateActionRules(nameplate);
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
    DeactivateAuraRules(nameplate);
    DeactivateActionRules(nameplate);
    nameplate.importantNpcIsOtherPlayersPet = nil;

    local castBar = nameplate.importantNpcCastBar;
    if castBar then
        castBar.sweepyBoopImportantNpcNameplate = nil;
        nameplate.importantNpcCastBar = nil;
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
            ApplyHighlightLayout(highlight, nameplate);
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
