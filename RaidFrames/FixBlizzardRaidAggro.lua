local _, addon = ...;

local explicitFramePrefixes = {
    "CompactPartyFrameMember",
    "CompactArenaFrameMember",
};

local TEXTURE_RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons";
local ICON_ALPHA = 0.9;
local MAX_RAID_FRAME_INDEX = addon.MAX_ARENA_SIZE * 2; -- players plus pets
local TRIPLE_TARGETER_COUNT = 3;
local SKULL_PULSE_SECONDS = 0.85;
local SKULL_PULSE_MIN_ALPHA = 0.35;

local RAID_ICON_INDICES = {
    Star = 1,
    Circle = 2,
    Diamond = 3,
    Square = 6,
    Skull = 8,
};

local trackedFrames = {};
local targeters = {};
local classColors = {};
local wasActive = false;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function AddTargeter(unit, isEnemy)
    -- Arena-frame indicators should only count party-member targeters, not the player's current target.
    if ( unit == "player" ) or ( unit == "target" ) then
        return;
    end

    if ( not UnitExists(unit) ) then
        return;
    end

    local class = addon.GetUnitClass(unit);
    if addon.IsSecretValue(class) then
        return;
    end

    local classColor = class and RAID_CLASS_COLORS[class];
    if not classColor then
        return;
    end

    table.insert(targeters, {
        unit = unit,
        target = unit .. "target",
        color = classColor,
        isEnemy = isEnemy,
    });
end

local function BuildTargeters()
    wipe(targeters);
    for i = 1, addon.MAX_ARENA_SIZE do
        AddTargeter("arena" .. i, true);
        AddTargeter("party" .. i, false);
    end
end

local function IsTrackedUnitTarget(unit)
    if unit == "player" then
        return true;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if ( unit == "arena" .. i ) or ( unit == "party" .. i ) then
            return true;
        end
    end

    return false;
end

local function IsArenaUnit(unit)
    if not unit then
        return false;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if ( unit == "arena" .. i ) or addon.UnitIsUnitSecretValueSafe(unit, "arena" .. i) then
            return true;
        end
    end

    return false;
end

local function AddTargetingClassForFrame(classColors, frameUnit, targeter)
    if addon.UnitIsUnitSecretValueSafe(targeter.target, frameUnit) then
        table.insert(classColors, targeter.color);
    end
end

local function GetTargetingClasses(frameUnit)
    wipe(classColors);
    local isArenaFrame = IsArenaUnit(frameUnit);
    local showEnemyTargeters = not isArenaFrame;

    for i = 1, #targeters do
        local targeter = targeters[i];
        if targeter.isEnemy == showEnemyTargeters then
            AddTargetingClassForFrame(classColors, frameUnit, targeter);
        end
    end

    return classColors, isArenaFrame;
end

local function GetRaidIconTexCoord(index)
    local column = ( index - 1 ) % 4;
    local row = math.floor(( index - 1 ) / 4);
    return column / 4, ( column + 1 ) / 4, row / 4, ( row + 1 ) / 4;
end

local function ApplyRaidIconTexture(icon, shape, color, alpha)
    local index = RAID_ICON_INDICES[shape] or RAID_ICON_INDICES.Circle;
    icon:SetTexture(TEXTURE_RAID_ICONS);
    icon:SetTexCoord(GetRaidIconTexCoord(index));
    icon:SetDesaturated(shape ~= "Skull");

    if shape == "Skull" then
        icon:SetVertexColor(1, 1, 1, 1);
    else
        icon:SetVertexColor(color.r, color.g, color.b, alpha);
    end
end

local function EnsureTargetIcon(container, index)
    if container.icons[index] then
        return container.icons[index];
    end

    local icon = container:CreateTexture(nil, "OVERLAY");
    container.icons[index] = icon;
    return icon;
end

local function StopSkullPulse(container)
    if container.pulseIcon then
        container.pulseIcon:SetAlpha(1);
    end

    container.pulseIcon = nil;
    container:SetScript("OnUpdate", nil);
end

local function StartSkullPulse(container, icon, maxAlpha)
    container.pulseIcon = icon;
    container.pulseElapsed = 0;
    container.pulseMaxAlpha = maxAlpha;
    container:SetScript("OnUpdate", function(self, elapsed)
        self.pulseElapsed = self.pulseElapsed + elapsed;
        local progress = ( self.pulseElapsed % SKULL_PULSE_SECONDS ) / SKULL_PULSE_SECONDS;
        local pulse = SKULL_PULSE_MIN_ALPHA + ( ( 1 - SKULL_PULSE_MIN_ALPHA ) * ( 0.5 + ( 0.5 * math.sin(progress * math.pi * 2) ) ) );
        self.pulseIcon:SetAlpha(self.pulseMaxAlpha * pulse);
    end);
end

local function SetTargetIconPoint(icon, container, previousIcon, index, config)
    icon:ClearAllPoints();

    local spacing = config.raidFrameAggroHighlightSpacing;
    local growDirection = config.raidFrameAggroHighlightGrowDirection;
    if index == 1 then
        if growDirection == "CENTER_HORIZONTAL" then
            icon:SetPoint("LEFT", container, "LEFT", 0, 0);
        elseif growDirection == "CENTER_VERTICAL" then
            icon:SetPoint("TOP", container, "TOP", 0, 0);
        else
            icon:SetPoint(config.raidFrameAggroHighlightAnchor, container, config.raidFrameAggroHighlightAnchor, 0, 0);
        end
        return;
    end

    if ( growDirection == "RIGHT" ) or ( growDirection == "CENTER_HORIZONTAL" ) then
        icon:SetPoint("LEFT", previousIcon, "RIGHT", spacing, 0);
    elseif growDirection == "UP" then
        icon:SetPoint("BOTTOM", previousIcon, "TOP", 0, spacing);
    elseif ( growDirection == "DOWN" ) or ( growDirection == "CENTER_VERTICAL" ) then
        icon:SetPoint("TOP", previousIcon, "BOTTOM", 0, -spacing);
    else
        icon:SetPoint("RIGHT", previousIcon, "LEFT", -spacing, 0);
    end
end

local function LayoutContainer(container, frame, iconCount, config)
    local size = config.raidFrameAggroHighlightSize;
    local spacing = config.raidFrameAggroHighlightSpacing;
    local growDirection = config.raidFrameAggroHighlightGrowDirection;
    local totalSpacing = math.max(0, iconCount - 1) * spacing;
    local width = size;
    local height = size;

    if ( growDirection == "UP" ) or ( growDirection == "DOWN" ) or ( growDirection == "CENTER_VERTICAL" ) then
        height = ( iconCount * size ) + totalSpacing;
    else
        width = ( iconCount * size ) + totalSpacing;
    end

    container:ClearAllPoints();
    if ( growDirection == "CENTER_HORIZONTAL" ) or ( growDirection == "CENTER_VERTICAL" ) then
        container:SetPoint(
            "CENTER",
            frame,
            config.raidFrameAggroHighlightRelativePoint,
            config.raidFrameAggroHighlightOffsetX,
            config.raidFrameAggroHighlightOffsetY
        );
    else
        container:SetPoint(
            config.raidFrameAggroHighlightAnchor,
            frame,
            config.raidFrameAggroHighlightRelativePoint,
            config.raidFrameAggroHighlightOffsetX,
            config.raidFrameAggroHighlightOffsetY
        );
    end
    container:SetSize(width, height);
end

local function ShouldShowPulseSkull(config, isArenaFrame, iconCount)
    return config.raidFrameAggroHighlightPulseSkullOnThreeEnemyTargeters and ( not isArenaFrame ) and ( iconCount == TRIPLE_TARGETER_COUNT );
end

local function ShowCustomAggroHighlight(frame, classColors, isArenaFrame)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetFrameLevel(frame:GetFrameLevel() + 10);
        customAggroHighlight.icons = {};
        frame.customAggroHighlight = customAggroHighlight;
    end

    local config = GetConfig();
    local container = frame.customAggroHighlight;
    local alpha = config.raidFrameAggroHighlightAlpha or ICON_ALPHA;
    local iconCount = #classColors;
    local showPulseSkull = ShouldShowPulseSkull(config, isArenaFrame, iconCount);
    local visibleIconCount = showPulseSkull and 1 or iconCount;
    local previousIcon;

    LayoutContainer(container, frame, visibleIconCount, config);
    StopSkullPulse(container);

    if showPulseSkull then
        local icon = EnsureTargetIcon(container, 1);
        icon:SetSize(config.raidFrameAggroHighlightSize, config.raidFrameAggroHighlightSize);
        SetTargetIconPoint(icon, container, nil, 1, config);
        ApplyRaidIconTexture(icon, "Skull", classColors[1], alpha);
        icon:Show();
        StartSkullPulse(container, icon, alpha);
    else
        for i = 1, iconCount do
            local icon = EnsureTargetIcon(container, i);
            icon:SetAlpha(1);
            icon:SetSize(config.raidFrameAggroHighlightSize, config.raidFrameAggroHighlightSize);
            SetTargetIconPoint(icon, container, previousIcon, i, config);
            ApplyRaidIconTexture(icon, config.raidFrameAggroHighlightShape, classColors[i], alpha);
            icon:Show();
            previousIcon = icon;
        end
    end

    for i = visibleIconCount + 1, #container.icons do
        container.icons[i]:Hide();
    end

    container:Show();
end

local function HideCustomAggroHighlight(frame)
    if frame.customAggroHighlight then
        StopSkullPulse(frame.customAggroHighlight);
        frame.customAggroHighlight:Hide();
    end
end

local function IsActive()
    return IsActiveBattlefieldArena() and SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled;
end

local function UpdateFrame(frame)
    if frame:IsForbidden() then
        trackedFrames[frame] = nil;
        return;
    end

    if frame.aggroHighlight then
        frame.aggroHighlight:SetAlpha(0);
    end

    local unit = frame.displayedUnit or frame.unit;
    if unit then
        local targetingClassColors, isArenaFrame = GetTargetingClasses(unit);
        if #targetingClassColors > 0 then
            ShowCustomAggroHighlight(frame, targetingClassColors, isArenaFrame);
            return;
        end
    end

    HideCustomAggroHighlight(frame);
end

local function TrackFrame(frame)
    if frame and ( not frame:IsForbidden() ) then
        trackedFrames[frame] = true;
        if wasActive then
            BuildTargeters();
            UpdateFrame(frame);
        end
    end
end

local function AddExplicitFrames()
    for prefixIndex = 1, #explicitFramePrefixes do
        local prefix = explicitFramePrefixes[prefixIndex];
        for i = 1, MAX_RAID_FRAME_INDEX do
            TrackFrame(_G[prefix .. i]);
        end
    end
end

local function HideAllFrames()
    AddExplicitFrames();
    for frame in pairs(trackedFrames) do
        if frame:IsForbidden() then
            trackedFrames[frame] = nil;
        else
            if frame.aggroHighlight then
                frame.aggroHighlight:SetAlpha(1);
            end
            HideCustomAggroHighlight(frame);
        end
    end
end

local function UpdateAllFrames()
    AddExplicitFrames();
    BuildTargeters();

    for frame in pairs(trackedFrames) do
        UpdateFrame(frame);
    end
end

function SweepyBoop:RefreshRaidFrameAggroHighlight()
    if IsActive() then
        wasActive = true;
        UpdateAllFrames();
    elseif wasActive then
        HideAllFrames();
        wasActive = false;
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    hooksecurefunc("CompactUnitFrame_UpdateAll", function (frame)
        if ( not frame ) or addon.IsSecretValue(frame) or frame:IsForbidden() then return end
        if ( not IsTrackedUnitTarget(frame.unit) ) and ( not IsTrackedUnitTarget(frame.displayedUnit) ) then return end

        local name = frame.GetName and frame:GetName();
        if name and string.find(name, "^Compact") then -- CompactPartyFrameMemberN, CompactRaidFrameN, CompactArenaFrameMemberN, ...
            TrackFrame(frame);
        end
    end)

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    if addon.PROJECT_MAINLINE then -- Between solo shuffle rounds (retail only)
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    end
    eventFrame:RegisterEvent(addon.UNIT_TARGET);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED); -- For cases when stealthy classes appear (we need to run an update before they change target)
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        if not IsActive() then
            if wasActive then
                HideAllFrames();
                wasActive = false;
            end
            return;
        end

        wasActive = true;
        if ( event ~= addon.UNIT_TARGET ) or IsTrackedUnitTarget(unitId) then
            UpdateAllFrames();
        end
    end);
end
