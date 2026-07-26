local _, addon = ...;

local explicitFramePrefixes = {
    "CompactPartyFrameMember",
    "CompactArenaFrameMember",
};

local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local TEXTURE_RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons";
local ICON_ALPHA = 1;
local ICON_BORDER_SIZE = 1;
local OVERLAY_FRAME_LEVEL_OFFSET = 50;
local MAX_RAID_FRAME_INDEX = addon.MAX_ARENA_SIZE * 2; -- players plus pets
local RAID_FRAME_FLASH_TARGETER_COUNT = 3;
local ARENA_FRAME_FLASH_TARGETER_COUNT = 2;
local DOT_FLASH_SECONDS = 0.85;
local DOT_FLASH_MIN_ALPHA = 0.35;

local RAID_ICON_INDICES = {
    Star = 1,
    Circle = 2,
    Diamond = 3,
    Triangle = 4,
    Moon = 5,
    Square = 6,
    Cross = 7,
    Skull = 8,
    Flag = 15,
    Murloc = 16,
};

local trackedFrames = {};
local targeters = {};
local classColors = {};
local wasActive = false;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function GetFrameConfigPrefix(isArenaFrame)
    return isArenaFrame and "raidFrameAggroHighlightArenaFrames" or "raidFrameAggroHighlightRaidFrames";
end

local function IsFrameTypeEnabled(config, isArenaFrame)
    return config[GetFrameConfigPrefix(isArenaFrame) .. "Shape"] ~= "Disabled";
end

local function GetFrameConfigValue(config, isArenaFrame, key)
    return config[GetFrameConfigPrefix(isArenaFrame) .. key];
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

local function IsArenaFrame(frame, unit)
    if IsArenaUnit(unit) then
        return true;
    end

    local name = frame and frame.GetName and frame:GetName();
    return name and string.find(name, "^CompactArenaFrameMember") ~= nil;
end

local function AddTargetingClassForFrame(classColors, frameUnit, targeter)
    if addon.UnitIsUnitSecretValueSafe(targeter.target, frameUnit) then
        table.insert(classColors, targeter.color);
    end
end

local function GetTargetingClasses(frameUnit, isArenaFrame)
    wipe(classColors);
    local showEnemyTargeters = not isArenaFrame;

    for i = 1, #targeters do
        local targeter = targeters[i];
        if targeter.isEnemy == showEnemyTargeters then
            AddTargetingClassForFrame(classColors, frameUnit, targeter);
        end
    end

    return classColors;
end

local function NormalizeMarkerShape(shape)
    return RAID_ICON_INDICES[shape] and shape or "Circle";
end

local function UnmaskLayer(texture, mask)
    if mask then
        mask:Hide();
        texture:RemoveMaskTexture(mask);
    end
end

local function PaintSolidLayer(texture, r, g, b, alpha)
    texture:SetTexture(TEXTURE_WHITE);
    texture:SetTexCoord(0, 1, 0, 1);
    texture:SetVertexColor(r, g, b, alpha);
    texture:Show();
end

local function ResizeMarkerLayers(marker, width, height)
    local inset = ICON_BORDER_SIZE;
    local fillWidth = math.max(0, width - ( 2 * inset ));
    local fillHeight = math.max(0, height - ( 2 * inset ));

    marker.outline:ClearAllPoints();
    marker.outline:SetAllPoints(marker);

    marker.fill:ClearAllPoints();
    marker.fill:SetPoint("CENTER", marker, "CENTER", 0, 0);
    marker.fill:SetSize(fillWidth, fillHeight);

    return fillWidth, fillHeight;
end

local function MoveRaidMarkerMask(mask, owner, markerIndex, width, height)
    local column = ( markerIndex - 1 ) % 4;
    local row = math.floor(( markerIndex - 1 ) / 4);

    mask:SetTexture(TEXTURE_RAID_ICONS, "CLAMP", "CLAMP");
    mask:SetSize(width * 4, height * 4);
    mask:ClearAllPoints();
    mask:SetPoint("TOPLEFT", owner, "TOPLEFT", -column * width, row * height);
    mask:Show();
end

local function ApplyRaidMarkerMask(marker, shape, width, height, fillWidth, fillHeight)
    -- The raid-marker atlas is used only as a silhouette mask; visible pixels come from our solid layers.
    local markerIndex = RAID_ICON_INDICES[shape];
    if not markerIndex then
        return;
    end

    if not marker.outlineMask then marker.outlineMask = marker:CreateMaskTexture() end
    if not marker.fillMask then marker.fillMask = marker:CreateMaskTexture() end

    MoveRaidMarkerMask(marker.outlineMask, marker, markerIndex, width, height);
    MoveRaidMarkerMask(marker.fillMask, marker.fill, markerIndex, fillWidth, fillHeight);

    marker.outline:AddMaskTexture(marker.outlineMask);
    marker.fill:AddMaskTexture(marker.fillMask);
end

local function DrawTargetMarker(marker, shape, color, alpha, width, height)
    UnmaskLayer(marker.outline, marker.outlineMask);
    UnmaskLayer(marker.fill, marker.fillMask);

    PaintSolidLayer(marker.outline, 0, 0, 0, alpha);
    PaintSolidLayer(marker.fill, color.r, color.g, color.b, alpha);

    local fillWidth, fillHeight = ResizeMarkerLayers(marker, width, height);
    ApplyRaidMarkerMask(marker, NormalizeMarkerShape(shape), width, height, fillWidth, fillHeight);
    marker:SetAlpha(1);
end

local function EnsureTargetIcon(container, index)
    if container.icons[index] then
        return container.icons[index];
    end

    local marker = CreateFrame("Frame", nil, container);
    marker.outline = marker:CreateTexture(nil, "BACKGROUND");
    marker.fill = marker:CreateTexture(nil, "ARTWORK");
    marker.outline:SetBlendMode("BLEND");
    marker.fill:SetBlendMode("BLEND");
    container.icons[index] = marker;
    return marker;
end

local function StopDotFlash(container)
    if container.flashIcons then
        for i = 1, #container.flashIcons do
            container.flashIcons[i]:SetAlpha(1);
        end
        wipe(container.flashIcons);
    end

    container:SetScript("OnUpdate", nil);
end

local function StartDotFlash(container, maxAlpha)
    container.flashElapsed = 0;
    container.flashMaxAlpha = maxAlpha;
    container:SetScript("OnUpdate", function(self, elapsed)
        self.flashElapsed = self.flashElapsed + elapsed;
        local progress = ( self.flashElapsed % DOT_FLASH_SECONDS ) / DOT_FLASH_SECONDS;
        local pulse = DOT_FLASH_MIN_ALPHA + ( ( 1 - DOT_FLASH_MIN_ALPHA ) * ( 0.5 + ( 0.5 * math.sin(progress * math.pi * 2) ) ) );
        local alpha = self.flashMaxAlpha * pulse;
        for i = 1, #self.flashIcons do
            self.flashIcons[i]:SetAlpha(alpha);
        end
    end);
end

local function SetTargetIconPoint(icon, container, previousIcon, index, layoutConfig)
    icon:ClearAllPoints();

    local spacing = layoutConfig.spacing;
    local growDirection = layoutConfig.growDirection;
    if index == 1 then
        if growDirection == "CENTER_HORIZONTAL" then
            icon:SetPoint("LEFT", container, "LEFT", 0, 0);
        elseif growDirection == "CENTER_VERTICAL" then
            icon:SetPoint("TOP", container, "TOP", 0, 0);
        else
            icon:SetPoint(layoutConfig.anchor, container, layoutConfig.anchor, 0, 0);
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

local function GetIconSize(shape, layoutConfig)
    return layoutConfig.size, layoutConfig.size;
end

local function LayoutContainer(container, frame, iconCount, layoutConfig)
    local iconWidth, iconHeight = GetIconSize(layoutConfig.shape, layoutConfig);
    local spacing = layoutConfig.spacing;
    local growDirection = layoutConfig.growDirection;
    local totalSpacing = math.max(0, iconCount - 1) * spacing;
    local width = iconWidth;
    local height = iconHeight;

    if ( growDirection == "UP" ) or ( growDirection == "DOWN" ) or ( growDirection == "CENTER_VERTICAL" ) then
        height = ( iconCount * iconHeight ) + totalSpacing;
    else
        width = ( iconCount * iconWidth ) + totalSpacing;
    end

    container:ClearAllPoints();
    if ( growDirection == "CENTER_HORIZONTAL" ) or ( growDirection == "CENTER_VERTICAL" ) then
        container:SetPoint(
            "CENTER",
            frame,
            layoutConfig.relativePoint,
            layoutConfig.offsetX,
            layoutConfig.offsetY
        );
    else
        container:SetPoint(
            layoutConfig.anchor,
            frame,
            layoutConfig.relativePoint,
            layoutConfig.offsetX,
            layoutConfig.offsetY
        );
    end
    container:SetSize(width, height);
end

local function ShouldFlashDots(isArenaFrame, iconCount)
    return ( ( not isArenaFrame ) and ( iconCount == RAID_FRAME_FLASH_TARGETER_COUNT ) )
        or ( isArenaFrame and ( iconCount == ARENA_FRAME_FLASH_TARGETER_COUNT ) );
end

local function ShowCustomAggroHighlight(frame, classColors, isArenaFrame)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight.icons = {};
        customAggroHighlight.flashIcons = {};
        frame.customAggroHighlight = customAggroHighlight;
    end

    local config = GetConfig();
    local container = frame.customAggroHighlight;
    local layoutConfig = {
        anchor = GetFrameConfigValue(config, isArenaFrame, "Anchor"),
        relativePoint = GetFrameConfigValue(config, isArenaFrame, "RelativePoint"),
        growDirection = GetFrameConfigValue(config, isArenaFrame, "GrowDirection"),
        offsetX = GetFrameConfigValue(config, isArenaFrame, "OffsetX"),
        offsetY = GetFrameConfigValue(config, isArenaFrame, "OffsetY"),
        spacing = GetFrameConfigValue(config, isArenaFrame, "Spacing"),
        size = GetFrameConfigValue(config, isArenaFrame, "Size"),
        alpha = ICON_ALPHA,
        shape = NormalizeMarkerShape(GetFrameConfigValue(config, isArenaFrame, "Shape")),
    };
    container:SetFrameLevel(frame:GetFrameLevel() + OVERLAY_FRAME_LEVEL_OFFSET);
    local iconCount = #classColors;
    local previousIcon;

    LayoutContainer(container, frame, iconCount, layoutConfig);
    StopDotFlash(container);

    for i = 1, iconCount do
        local icon = EnsureTargetIcon(container, i);
        local width, height = GetIconSize(layoutConfig.shape, layoutConfig);
        icon:SetAlpha(1);
        icon:SetSize(width, height);
        SetTargetIconPoint(icon, container, previousIcon, i, layoutConfig);
        DrawTargetMarker(icon, layoutConfig.shape, classColors[i], layoutConfig.alpha, width, height);
        icon:Show();
        if ShouldFlashDots(isArenaFrame, iconCount) then
            table.insert(container.flashIcons, icon);
        end
        previousIcon = icon;
    end

    if #container.flashIcons > 0 then
        StartDotFlash(container, layoutConfig.alpha);
    end

    for i = iconCount + 1, #container.icons do
        container.icons[i]:Hide();
    end

    container:Show();
end

local function HideCustomAggroHighlight(frame)
    if frame.customAggroHighlight then
        StopDotFlash(frame.customAggroHighlight);
        frame.customAggroHighlight:Hide();
    end
end

local function IsActive()
    local config = GetConfig();
    return IsActiveBattlefieldArena()
        and ( IsFrameTypeEnabled(config, false) or IsFrameTypeEnabled(config, true) );
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
        local isArenaFrame = IsArenaFrame(frame, unit);
        local targetingClassColors = GetTargetingClasses(unit, isArenaFrame);
        if ( not IsFrameTypeEnabled(GetConfig(), isArenaFrame) ) then
            HideCustomAggroHighlight(frame);
            return;
        end

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
