local _, addon = ...;

local aggroHighlight = addon.RAID_FRAME_AGGRO_HIGHLIGHT;
local markerRenderer = addon.RaidFrameAggroMarkerRenderer;

local frameRecords = setmetatable({}, { __mode = "k" });
local enemyTargetColorsByIdentity = {};
local partyTargetColorsByIdentity = {};
local wasActive = false;
local setupComplete = false;

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

local function GetReadableUnitNameKey(unit)
    local name, realm = UnitName(unit);
    if addon.IsSecretValue(name) or addon.IsSecretValue(realm) then
        return;
    end
    if ( not name ) or ( name == "" ) then
        return;
    end

    -- UnitName may return secret values when name identity is restricted.
    -- For readable same-realm units, an omitted realm denotes the current realm.
    if ( not realm ) or ( realm == "" ) then
        realm = GetNormalizedRealmName();
        if addon.IsSecretValue(realm) or ( not realm ) then
            return;
        end
    end
    return name .. "\031" .. realm;
end

local function GetFrameUnit(frame)
    local displayedUnit = frame.displayedUnit;
    if ( not addon.IsSecretValue(displayedUnit) ) and displayedUnit then
        return displayedUnit;
    end

    local unit = frame.unit;
    if addon.IsSecretValue(unit) then
        return;
    end
    return unit;
end

local function GetFrameCategory(frame)
    local groupType = frame.groupType;
    if addon.IsSecretValue(groupType) or ( not CompactRaidGroupTypeEnum ) then
        return;
    end

    if groupType == CompactRaidGroupTypeEnum.Arena then
        return true;
    elseif ( groupType == CompactRaidGroupTypeEnum.Party )
        or ( groupType == CompactRaidGroupTypeEnum.Raid ) then

        return false;
    end
end

local function IsTrackedUnitTarget(unit)
    if addon.IsSecretValue(unit) or ( not unit ) then
        return false;
    end
    for i = 1, addon.MAX_ARENA_SIZE do
        if ( unit == "arena" .. i ) or ( unit == "party" .. i ) then
            return true;
        end
    end

    return false;
end

local function IsPlayerUnitToken(unit)
    if addon.IsSecretValue(unit) or ( not unit ) then
        return false;
    end

    return unit == "player"
        or string.match(unit, "^party%d+$") ~= nil
        or string.match(unit, "^raid%d+$") ~= nil
        or string.match(unit, "^arena%d+$") ~= nil;
end

local function AddTargeter(targetColorsByIdentity, unit, isArenaUnit)
    local exists = UnitExists(unit);
    if addon.IsSecretValue(exists) or ( not exists ) then
        return;
    end

    local class;
    if isArenaUnit then
        class = addon.GetClassForPlayerOrArena(unit);
    else
        class = addon.GetUnitClass(unit);
    end
    if addon.IsSecretValue(class) then
        return;
    end

    local classColor = class and RAID_CLASS_COLORS[class];
    if not classColor then
        return;
    end

    local targetIdentity = GetReadableUnitNameKey(unit .. "target");
    if not targetIdentity then
        return;
    end

    local colors = targetColorsByIdentity[targetIdentity];
    if not colors then
        colors = {};
        targetColorsByIdentity[targetIdentity] = colors;
    end
    colors[#colors + 1] = classColor;
end

local function BuildTargeters()
    wipe(enemyTargetColorsByIdentity);
    wipe(partyTargetColorsByIdentity);

    for i = 1, addon.MAX_ARENA_SIZE do
        AddTargeter(enemyTargetColorsByIdentity, "arena" .. i, true);
        AddTargeter(partyTargetColorsByIdentity, "party" .. i, false);
    end
end

local function GetTargetingClasses(frameUnit, isArenaFrame)
    local frameIdentity = GetReadableUnitNameKey(frameUnit);
    if not frameIdentity then
        return;
    end

    local targetColorsByIdentity = isArenaFrame
        and partyTargetColorsByIdentity
        or enemyTargetColorsByIdentity;
    return targetColorsByIdentity[frameIdentity];
end

local function OnFrameRecordUpdate(record, elapsed)
    local lane = record.activeLane;
    if ( not lane ) or ( not lane.shouldFlash ) then
        return;
    end

    record.flashElapsed = record.flashElapsed + elapsed;
    local progress = ( record.flashElapsed % aggroHighlight.FLASH_SECONDS ) / aggroHighlight.FLASH_SECONDS;
    local pulse = aggroHighlight.FLASH_MIN_ALPHA + ( ( 1 - aggroHighlight.FLASH_MIN_ALPHA ) * ( 0.5 + ( 0.5 * math.sin(progress * math.pi * 2) ) ) );
    local alpha = lane.flashMaxAlpha * pulse;
    for i = 1, #lane.icons do
        lane.icons[i]:SetAlpha(alpha);
    end
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
    return ( ( not isArenaFrame ) and ( iconCount == aggroHighlight.RAID_FRAME_FLASH_TARGETER_COUNT ) )
        or ( isArenaFrame and ( iconCount == aggroHighlight.ARENA_FRAME_FLASH_TARGETER_COUNT ) );
end

local function GetLayoutConfig(isArenaFrame)
    local config = GetConfig();
    local layoutConfig = {
        anchor = GetFrameConfigValue(config, isArenaFrame, "Anchor"),
        relativePoint = GetFrameConfigValue(config, isArenaFrame, "RelativePoint"),
        growDirection = GetFrameConfigValue(config, isArenaFrame, "GrowDirection"),
        offsetX = GetFrameConfigValue(config, isArenaFrame, "OffsetX"),
        offsetY = GetFrameConfigValue(config, isArenaFrame, "OffsetY"),
        spacing = GetFrameConfigValue(config, isArenaFrame, "Spacing"),
        size = GetFrameConfigValue(config, isArenaFrame, "Size"),
        borderThickness = GetFrameConfigValue(config, isArenaFrame, "BorderThickness"),
        alpha = aggroHighlight.MARKER_ALPHA,
        shape = markerRenderer.NormalizeShape(GetFrameConfigValue(config, isArenaFrame, "Shape")),
    };
    layoutConfig.signature = table.concat({
        layoutConfig.anchor,
        layoutConfig.relativePoint,
        layoutConfig.growDirection,
        layoutConfig.offsetX,
        layoutConfig.offsetY,
        layoutConfig.spacing,
        layoutConfig.size,
        layoutConfig.borderThickness,
        layoutConfig.shape,
    }, "\031");
    return layoutConfig;
end

local function ConfigureLane(lane, frame, iconCount, isArenaFrame, layoutConfig)
    LayoutContainer(lane, frame, iconCount, layoutConfig);
    lane.shouldFlash = ShouldFlashDots(isArenaFrame, iconCount);
    lane.flashMaxAlpha = layoutConfig.alpha;

    local previousIcon;
    for i = 1, iconCount do
        local icon = lane.icons[i] or markerRenderer.CreateMarker(lane);
        local width, height = GetIconSize(layoutConfig.shape, layoutConfig);
        SetTargetIconPoint(icon, lane, previousIcon, i, layoutConfig);
        markerRenderer.ConfigureMarker(icon, layoutConfig.shape, { r = 1, g = 1, b = 1 }, layoutConfig.alpha, width, height, layoutConfig.borderThickness);
        lane.icons[i] = icon;
        previousIcon = icon;
    end
end

local function ConfigureFrameRecord(record, frame, isArenaFrame, layoutConfig)
    for iconCount = 1, addon.MAX_ARENA_SIZE do
        ConfigureLane(record.lanes[iconCount], frame, iconCount, isArenaFrame, layoutConfig);
    end
    record.isArenaFrame = isArenaFrame;
    record.layoutSignature = layoutConfig.signature;
end

local function CreateFrameRecord(frame, isArenaFrame, layoutConfig)
    if InCombatLockdown() then
        return;
    end

    local overlay = CreateFrame("Frame", nil, frame);
    overlay:EnableMouse(false);
    overlay:SetFrameLevel(frame:GetFrameLevel() + aggroHighlight.OVERLAY_FRAME_LEVEL_OFFSET);

    local record = {
        overlay = overlay,
        lanes = {},
        flashElapsed = 0,
    };
    overlay:SetScript("OnUpdate", function(_, elapsed)
        OnFrameRecordUpdate(record, elapsed);
    end);
    for iconCount = 1, addon.MAX_ARENA_SIZE do
        local lane = CreateFrame("Frame", nil, overlay);
        lane.icons = {};
        lane:SetAlpha(0);
        lane:Show();
        record.lanes[iconCount] = lane;
    end

    ConfigureFrameRecord(record, frame, isArenaFrame, layoutConfig);
    overlay:Show();
    return record;
end

local function ClearFrameRecord(record)
    if not record then
        return;
    end

    for _, lane in pairs(record.lanes) do
        lane:SetAlpha(0);
        for i = 1, #lane.icons do
            lane.icons[i]:SetAlpha(1);
        end
    end
    record.activeLane = nil;
    record.flashElapsed = 0;
end

local function ShowCustomAggroHighlight(record, targetingClassColors)
    local iconCount = #targetingClassColors;
    local lane = record.lanes[iconCount];
    if not lane then
        ClearFrameRecord(record);
        return;
    end

    if record.activeLane and record.activeLane ~= lane then
        record.activeLane:SetAlpha(0);
    end

    record.flashElapsed = 0;
    lane:SetAlpha(1);
    for i = 1, iconCount do
        local color = targetingClassColors[i];
        lane.icons[i].fill:SetVertexColor(color.r, color.g, color.b, aggroHighlight.MARKER_ALPHA);
        lane.icons[i]:SetAlpha(1);
    end
    record.activeLane = lane;
end

local function IsActive()
    local config = GetConfig();
    return IsActiveBattlefieldArena()
        and ( IsFrameTypeEnabled(config, false) or IsFrameTypeEnabled(config, true) );
end

local function UpdateFrame(frame, record)
    local unit = GetFrameUnit(frame);
    if unit and IsFrameTypeEnabled(GetConfig(), record.isArenaFrame) then
        local targetingClassColors = GetTargetingClasses(unit, record.isArenaFrame);
        if targetingClassColors and ( #targetingClassColors > 0 ) then
            ShowCustomAggroHighlight(record, targetingClassColors);
            return;
        end
    end

    ClearFrameRecord(record);
end

local function TrackFrame(frame, isArenaFrame, refreshAfterTracking)
    if ( not frame ) or addon.IsSecretValue(frame) then
        return;
    end

    local forbidden = frame:IsForbidden();
    if addon.IsSecretValue(forbidden) or forbidden then
        return;
    end

    if isArenaFrame == nil then
        isArenaFrame = GetFrameCategory(frame);
    end
    if isArenaFrame == nil then
        return;
    end

    local unit = GetFrameUnit(frame);
    if ( not IsPlayerUnitToken(unit) ) then
        return;
    end

    local record = frameRecords[frame];
    if ( not record ) and ( not wasActive ) then
        return;
    end

    local layoutConfig = GetLayoutConfig(isArenaFrame);
    if not record then
        record = CreateFrameRecord(frame, isArenaFrame, layoutConfig);
        if not record then
            return;
        end
        frameRecords[frame] = record;
    elseif ( record.isArenaFrame ~= isArenaFrame )
        or ( record.layoutSignature ~= layoutConfig.signature ) then

        if not InCombatLockdown() then
            ClearFrameRecord(record);
            ConfigureFrameRecord(record, frame, isArenaFrame, layoutConfig);
        end
    end

    if wasActive and refreshAfterTracking then
        BuildTargeters();
        UpdateFrame(frame, record);
    end
end

local function AddExplicitFrames()
    if CompactPartyFrame and CompactPartyFrame.memberUnitFrames then
        for _, frame in ipairs(CompactPartyFrame.memberUnitFrames) do
            TrackFrame(frame, false);
        end
    end

    if CompactArenaFrame and CompactArenaFrame.memberUnitFrames then
        for _, frame in ipairs(CompactArenaFrame.memberUnitFrames) do
            TrackFrame(frame, true);
        end
    end

    if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
        CompactRaidFrameContainer:ApplyToFrames("all", TrackFrame);
    end
end

local function HideAllFrames()
    for _, record in pairs(frameRecords) do
        ClearFrameRecord(record);
    end
end

local function UpdateAllFrames()
    BuildTargeters();
    AddExplicitFrames();

    for frame, record in pairs(frameRecords) do
        UpdateFrame(frame, record);
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
    if setupComplete then return end
    setupComplete = true;

    -- CompactUnitFrame_SetUnit is Blizzard's assignment point for protected compact frames.
    -- The post-hook observes assignments. Marker state is stored on addon-owned child regions.
    hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
        TrackFrame(frame, nil, true);
    end);

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    if addon.PROJECT_MAINLINE then -- Refresh opponent assignments between Solo Shuffle rounds.
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
    end
    eventFrame:RegisterEvent(addon.UNIT_TARGET);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED); -- Refresh when a stealthed opponent appears without changing target.
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

    self:RefreshRaidFrameAggroHighlight();
end
