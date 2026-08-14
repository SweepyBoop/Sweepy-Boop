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
        local nameplate = C_NamePlate.GetNamePlateForUnit("target");
        if not nameplate then
            print("SweepyBoop: current target has no visible nameplate");
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
            iconTexture or addon.GetSpellTexture(
                addon.PROJECT_MAINLINE and 204336 or 8177
            ),
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
