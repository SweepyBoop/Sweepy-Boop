local _, addon = ...;

local iconSize = 30;
local highlightBorderSize = 42;
local highlightAnimationThrottle = 0.02;
local highlightRippleScale = 0.22;
local highlightRippleFrequency = 0.9;
local highlightRippleDuration = 1 / ( 2 * highlightRippleFrequency );
local highlightRippleMaxAlpha = 0.82;
local highlightRippleMinAlpha = 0.22;
local highlightStaticGlowAlpha = 0.9;
local highlightStaticBorderAlpha = 0.55;
local highlightColor = { 0.85, 0.15, 1 };
local highlightBorderTexture =
    addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE;
local highlightGlowTexture =
    addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE;

local function SetupNativeAnimation(ripple)
    local animationGroup = ripple:CreateAnimationGroup();
    -- Restricted aura buttons use a preconfigured native approximation of the
    -- class-icon target highlight's ~1.11 second sinusoidal cycle.
    animationGroup:SetLooping("BOUNCE");

    local scale = animationGroup:CreateAnimation("Scale");
    scale:SetScale(1 + highlightRippleScale, 1 + highlightRippleScale);
    scale:SetDuration(highlightRippleDuration);
    scale:SetOrder(1);

    local alpha = animationGroup:CreateAnimation("Alpha");
    alpha:SetFromAlpha(highlightRippleMaxAlpha);
    alpha:SetToAlpha(highlightRippleMinAlpha);
    alpha:SetDuration(highlightRippleDuration);
    alpha:SetOrder(1);

    if scale.SetSmoothing then
        scale:SetSmoothing("IN_OUT");
        alpha:SetSmoothing("IN_OUT");
    end

    return animationGroup;
end

local function SetHighlightAnimationProgress(highlight, progress)
    local wave = 0.5 - ( 0.5 * math.cos(( progress % 1 ) * math.pi * 2) );
    local size = highlightBorderSize * ( 1 + ( highlightRippleScale * wave ) );
    local alpha = highlightRippleMaxAlpha
        - ( ( highlightRippleMaxAlpha - highlightRippleMinAlpha ) * wave );

    highlight.ripple:SetSize(size, size);
    highlight.ripple:SetAlpha(alpha);
end

local function HighlightAnimation_OnUpdate(self, elapsed)
    local highlight = self.highlight;
    if not highlight or not highlight.animationActive then
        self:SetScript("OnUpdate", nil);
        return;
    end

    highlight.animationElapsed = highlight.animationElapsed + elapsed;
    if highlight.animationElapsed < highlightAnimationThrottle then return end

    local step = highlight.animationElapsed;
    highlight.animationElapsed = 0;
    highlight.animationProgress =
        ( highlight.animationProgress + ( step * highlightRippleFrequency ) ) % 1;
    SetHighlightAnimationProgress(highlight, highlight.animationProgress);
end

local function StopHighlightAnimation(highlight)
    highlight.animationActive = false;
    if highlight.animationGroup and highlight.animationGroup:IsPlaying() then
        highlight.animationGroup:Stop();
    end
    if highlight.animationDriver then
        highlight.animationDriver:SetScript("OnUpdate", nil);
    end

    highlight.animationElapsed = 0;
    highlight.animationProgress = 0;
    highlight.ripple:SetSize(highlightBorderSize, highlightBorderSize);
    highlight.ripple:SetScale(1);
    highlight.ripple:SetAlpha(highlightRippleMaxAlpha);
end

local function StartHighlightAnimation(highlight)
    if highlight.animationActive then return end

    StopHighlightAnimation(highlight);
    highlight.animationActive = true;
    highlight.ripple:Show();
    if highlight.animationGroup then
        highlight.animationGroup:Play();
    else
        SetHighlightAnimationProgress(highlight, 0);
        highlight.animationDriver:SetScript("OnUpdate", HighlightAnimation_OnUpdate);
    end
end

local function CreateSquareBorders(parent, useNativeAnimation)
    parent.staticGlow = parent:CreateTexture(nil, "BORDER");
    parent.staticGlow:SetSize(highlightBorderSize, highlightBorderSize);
    parent.staticGlow:SetPoint("CENTER", parent);
    parent.staticGlow:SetTexture(highlightGlowTexture);
    parent.staticGlow:SetBlendMode("ADD");
    parent.staticGlow:SetVertexColor(
        highlightColor[1],
        highlightColor[2],
        highlightColor[3],
        highlightStaticGlowAlpha
    );

    parent.staticBorder = parent:CreateTexture(nil, "OVERLAY", nil, 1);
    parent.staticBorder:SetSize(highlightBorderSize, highlightBorderSize);
    parent.staticBorder:SetPoint("CENTER", parent);
    parent.staticBorder:SetTexture(highlightBorderTexture);
    parent.staticBorder:SetBlendMode("ADD");
    parent.staticBorder:SetVertexColor(
        highlightColor[1],
        highlightColor[2],
        highlightColor[3],
        highlightStaticBorderAlpha
    );

    parent.ripple = CreateFrame("Frame", nil, parent);
    parent.ripple:SetMouseClickEnabled(false);
    parent.ripple:SetSize(highlightBorderSize, highlightBorderSize);
    parent.ripple:SetPoint("CENTER", parent);
    parent.ripple:SetAlpha(highlightRippleMaxAlpha);

    parent.rippleTexture = parent.ripple:CreateTexture(nil, "OVERLAY", nil, 2);
    parent.rippleTexture:SetAllPoints(parent.ripple);
    parent.rippleTexture:SetTexture(highlightGlowTexture);
    parent.rippleTexture:SetBlendMode("ADD");
    parent.rippleTexture:SetVertexColor(unpack(highlightColor));

    if useNativeAnimation then
        parent.animationGroup = SetupNativeAnimation(parent.ripple);
    else
        parent.animationDriver = CreateFrame("Frame", nil, parent);
        parent.animationDriver:SetAllPoints(parent);
        parent.animationDriver.highlight = parent;
    end
end

local function SetHighlightAnimated(highlight, shouldAnimate)
    highlight.staticGlow:Show();
    highlight.staticBorder:Show();
    if shouldAnimate then
        StartHighlightAnimation(highlight);
    else
        StopHighlightAnimation(highlight);
        highlight.ripple:Hide();
    end
end

local function CreateIconHighlight(parent, shouldAnimate, useNativeAnimation)
    parent:SetSize(iconSize, iconSize);
    parent:SetMouseClickEnabled(false);

    parent.icon = parent:CreateTexture(nil, "ARTWORK");
    parent.icon:SetAllPoints(parent);

    CreateSquareBorders(parent, useNativeAnimation);
    SetHighlightAnimated(parent, shouldAnimate ~= false);
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
            CreateIconHighlight(button, true, true);

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
                        StartHighlightAnimation(frame.highlight);
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

local debugNpcHighlightNameplate;

local function EnsureDebugActionHighlight(nameplate, key, frameLevelOffset)
    local highlights = nameplate.debugNpcHighlights;
    if not highlights then
        highlights = {};
        nameplate.debugNpcHighlights = highlights;
    end

    local highlight = highlights[key];
    if highlight then return highlight end

    highlight = CreateFrame("Frame", nil, nameplate);
    highlight:SetFrameStrata("HIGH");
    highlight:SetFrameLevel(nameplate:GetFrameLevel() + frameLevelOffset);
    CreateIconHighlight(highlight);
    highlight:Hide();
    highlights[key] = highlight;
    return highlight;
end

local function EnsureDebugAuraContainer(nameplate, shouldAnimate)
    local containers = nameplate.debugNpcAuraContainers;
    if not containers then
        containers = {};
        nameplate.debugNpcAuraContainers = containers;
    end

    local key = shouldAnimate and "animated" or "static";
    local container = containers[key];
    if container then return container end

    container = CreateFrame(
        "AuraContainer",
        nil,
        nameplate,
        "CustomAuraContainerTemplate"
    );
    container:SetFrameStrata("HIGH");
    container:SetFrameLevel(nameplate:GetFrameLevel() + 10);
    container:SetSize(iconSize, iconSize);
    container:SetEnabled(false);
    container:Hide();
    container:AddAuraSlot("DebugImportantAura" .. key, "HELPFUL|IMPORTANT", {
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            button:SetPoint("CENTER", container, "CENTER");
            CreateIconHighlight(button, shouldAnimate, true);
            button:SetIcon(button.icon);
        end,
    });

    containers[key] = container;
    return container;
end

addon.HideDebugNpcPortrait = function(nameplate)
    local highlights = nameplate.debugNpcHighlights;
    if highlights then
        for _, highlight in pairs(highlights) do
            StopHighlightAnimation(highlight);
            highlight.icon:SetTexture(nil);
            highlight:Hide();
        end
    end

    local containers = nameplate.debugNpcAuraContainers;
    if containers then
        for _, container in pairs(containers) do
            container:SetEnabled(false);
            container:Hide();
        end
    end

    if debugNpcHighlightNameplate == nameplate then
        debugNpcHighlightNameplate = nil;
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

        nameplate.npcHighlight.customIcon =
            nameplate.npcHighlight:CreateTexture(nil, "ARTWORK");
        nameplate.npcHighlight.customIcon:SetAllPoints(nameplate.npcHighlight);

        CreateSquareBorders(nameplate.npcHighlight);
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
        SetHighlightAnimated(highlight, animation);
        highlight:Show();
    end
end

addon.HideNpcHighlight = function(nameplate)
    local highlight = nameplate.npcHighlight;
    if highlight then
        StopHighlightAnimation(highlight);
        highlight.ripple:Hide();
        highlight.staticGlow:Hide();
        highlight.staticBorder:Hide();
        highlight.customIcon:Hide();
        highlight:Hide();
    end
end

if addon.internal then
    -- Internal preview; first target a unit with a visible nameplate.
    -- Portrait: /run SweepyBoop:DebugNpcHighlight(true, false, "portrait")
    -- Cast: /run SweepyBoop:DebugNpcHighlight(true, true, "cast")
    -- Aura: /run SweepyBoop:DebugNpcHighlight(true, false, "aura")
    -- Static spell: /run SweepyBoop:DebugNpcHighlight(true, true, "static", 211522)
    -- All layers: /run SweepyBoop:DebugNpcHighlight(true, false, "all", 211522)
    -- Classic custom icon: /run SweepyBoop:DebugNpcHighlight(true, false)
    -- Hide: /run SweepyBoop:DebugNpcHighlight(false)
    function SweepyBoop:DebugNpcHighlight(
        shouldShow,
        shouldAnimate,
        representation,
        spellID
    )
        if addon.PROJECT_MAINLINE and shouldShow == false then
            if debugNpcHighlightNameplate then
                addon.HideDebugNpcPortrait(debugNpcHighlightNameplate);
            end
            print("SweepyBoop: NPC highlight preview hidden");
            return;
        end

        local nameplate = C_NamePlate.GetNamePlateForUnit("target");
        if not nameplate then
            print("SweepyBoop: current target has no visible nameplate");
            return;
        end

        if addon.PROJECT_MAINLINE then
            if debugNpcHighlightNameplate then
                addon.HideDebugNpcPortrait(debugNpcHighlightNameplate);
            end

            representation = representation or "portrait";
            if shouldAnimate == nil then
                shouldAnimate = true;
            end

            local showAll = representation == "all";
            local validRepresentation = showAll
                or representation == "portrait"
                or representation == "cast"
                or representation == "static"
                or representation == "aura";
            if not validRepresentation then
                print(
                    "SweepyBoop: representation must be portrait, cast, static, aura, or all"
                );
                return;
            end

            if showAll or representation == "portrait" then
                local highlight = EnsureDebugActionHighlight(nameplate, "portrait", 5);
                ApplyHighlightLayout(highlight, nameplate);
                SetPortraitTexture(highlight.icon, "target");
                SetHighlightAnimated(highlight, shouldAnimate);
                highlight:Show();
            end

            if showAll or representation == "aura" then
                local container = EnsureDebugAuraContainer(
                    nameplate,
                    shouldAnimate
                );
                ApplyHighlightLayout(container, nameplate);
                container:SetUnit("target");
                container:SetEnabled(true);
                container:Show();
                container:UpdateAllAuras();
            end

            if showAll or representation == "static" then
                local highlight = EnsureDebugActionHighlight(nameplate, "static", 20);
                ApplyHighlightLayout(highlight, nameplate);
                highlight.icon:SetTexture(
                    addon.GetSpellTexture(spellID or 211522)
                );
                SetHighlightAnimated(highlight, shouldAnimate);
                highlight:Show();
            end

            if showAll or representation == "cast" then
                local isCasting, isChanneling, castingTexture, channelTexture =
                    GetCastPresentationState("target");
                local highlight = EnsureDebugActionHighlight(nameplate, "cast", 20);
                ApplyHighlightLayout(highlight, nameplate);
                if isCasting then
                    highlight.icon:SetTexture(castingTexture);
                elseif isChanneling then
                    highlight.icon:SetTexture(channelTexture);
                else
                    highlight.icon:SetTexture(nil);
                    highlight:Hide();
                    print("SweepyBoop: current target is not casting or channeling");
                end
                if isCasting or isChanneling then
                    SetHighlightAnimated(highlight, shouldAnimate);
                    highlight:Show();
                end
            end

            debugNpcHighlightNameplate = nameplate;
            print(
                "SweepyBoop: showing "
                    .. representation
                    .. (shouldAnimate and " animated" or " static")
                    .. " NPC highlight preview on current target"
            );
            return;
        end

        if shouldShow == false then
            addon.HideNpcHighlight(nameplate);
            print("SweepyBoop: NPC highlight preview hidden");
            return;
        end

        if shouldAnimate == nil then
            shouldAnimate = true;
        end
        addon.ShowNpcHighlight(
            nameplate,
            shouldAnimate,
            representation or addon.GetSpellTexture(8177),
            "debug"
        );
        print(
            "SweepyBoop: showing "
                .. (shouldAnimate and "animated" or "static")
                .. " NPC highlight on current target"
        );
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
