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
    if highlight.lastModified == config.lastModified then return end

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
end

local importantAuraSlotKey = "ImportantMinion";

local function EnsureImportantAuraContainer(nameplate)
    local container = nameplate.importantNpcAuraContainer;
    if container then return container end

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
    container:AddAuraSlot(importantAuraSlotKey, "HELPFUL|IMPORTANT", {
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            CreatePortraitHighlight(button);
            button:SetPoint("CENTER", container, "CENTER");
            -- Blizzard restricts later tainted access to the aura button. Keep only the
            -- presentation texture reference needed to refresh the unit portrait.
            container.sweepyBoopPortrait = button.portrait;
        end,
    });

    nameplate.importantNpcAuraContainer = container;
    return container;
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
        if highlight then highlight:SetAlpha(0) end
    end

    hooksecurefunc(CastingBarMixin, "SetIsHighlightedImportantCast", function(castBar, signal)
        local highlight = castBar.sweepyBoopImportantNpcPortrait;
        if highlight then
            ApplyAlphaSignal(highlight, signal);
        end
    end);
    -- These presentation transitions run only after Blizzard accepts the stop or
    -- interruption for the active cast. Raw event handlers may receive stale IDs.
    hooksecurefunc(CastingBarMixin, "PlayFadeAnim", ClearImportantCastPortrait);
    hooksecurefunc(CastingBarMixin, "PlayInterruptAnims", ClearImportantCastPortrait);
end

addon.ActivateImportantNpcPortrait = function(nameplate, unit, castBar)
    local container = EnsureImportantAuraContainer(nameplate);
    ApplyPortraitHighlightLayout(container, nameplate);
    SetPortraitTexture(container.sweepyBoopPortrait, unit);
    container:SetUnit(unit);
    container:SetEnabled(true);
    container:Show();
    container:UpdateAllAuras();

    if castBar then
        local previousCastBar = nameplate.importantNpcCastBar;
        if previousCastBar and previousCastBar ~= castBar then
            previousCastBar.sweepyBoopImportantNpcPortrait = nil;
        end

        local castHighlight = EnsureImportantCastPortrait(nameplate, castBar);
        SetPortraitTexture(castHighlight.portrait, unit);
        local isNewAssociation = castBar.sweepyBoopImportantNpcPortrait ~= castHighlight;
        castBar.sweepyBoopImportantNpcPortrait = castHighlight;
        nameplate.importantNpcCastBar = castBar;
        if isNewAssociation then
            castHighlight:SetAlpha(0);
            -- Re-run Blizzard's final importance decision so an already-active cast
            -- reaches the post-hook after this presentation layer is associated.
            castBar:UpdateHighlightImportantCast();
        end
    end
end

local debugNpcPortraitNameplate;

addon.HideDebugNpcPortrait = function(nameplate)
    local highlight = nameplate.debugNpcPortraitHighlight;
    if highlight then highlight:Hide() end
    if debugNpcPortraitNameplate == nameplate then
        debugNpcPortraitNameplate = nil;
    end
end

addon.DeactivateImportantNpcPortrait = function(nameplate)
    local container = nameplate.importantNpcAuraContainer;
    if container then
        container:SetEnabled(false);
        container:Hide();
    end

    local castBar = nameplate.importantNpcCastBar;
    if castBar then
        castBar.sweepyBoopImportantNpcPortrait = nil;
        nameplate.importantNpcCastBar = nil;
    end

    local castHighlight = nameplate.importantNpcCastPortrait;
    if castHighlight then
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
