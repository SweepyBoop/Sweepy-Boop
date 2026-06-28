local _, addon = ...;

-- Draw crowd-control debuffs beside Blizzard compact raid/party frames. This mirrors the
-- compact-frame tracking model from RaidFrames/BuffHelper.lua but keeps its state separate.

local auraFilter = "HARMFUL|CROWD_CONTROL";
local iconSpacing = 2;
local frameLevelOffset = 20;
local minIconCount = 1;
local maxIconCount = 5;
local defaultPriority = 0;
local psychicScream = 8122;
local testDuration = 6;

local crowdControlPriority = {
    stun = 100,
    silence = 90,
    disorient = 80,
    incapacitate = 80,
};

local cufPool = {};    -- frame -> true: compact raid/party frames we have seen
local unitFrames = {}; -- unit token -> { [frame] = true }: frames currently showing that unit
local scanAuras = {};  -- scratch table reused while repainting one unit
local setupComplete = false;
local isTesting = false;

local eventFrame = CreateFrame("Frame");
local IsFrameVisible;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if ( value < minValue ) then return minValue end
    if ( value > maxValue ) then return maxValue end
    return value;
end

local function GetIconCount(config)
    return Clamp(config.raidFrameDebuffIconCount, minIconCount, maxIconCount);
end

local function GetFrameHeight(frame)
    local height = frame:GetHeight();
    if ( not height ) or ( height <= 0 ) then
        local _, _, _, rectHeight = frame:GetRect();
        height = rectHeight;
    end
    return ( height and height > 0 ) and height or 36;
end

local function GetIconScale(config)
    local scale = tonumber(config.raidFrameDebuffIconScale) or 0.75;
    if ( scale <= 0 ) then return 0.75 end
    return scale;
end

local function GetDispellableScale(config)
    local scale = tonumber(config.raidFrameDebuffIconDispellableScale) or 1;
    if ( scale <= 0 ) then return 1 end
    return scale;
end

local function IsEnabled()
    return GetConfig().raidFrameDebuffIconsEnabled and true or false;
end

local function StyleCooldown(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    cooldown:SetHideCountdownNumbers(false);
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(5);
    end
end

local function CreateDebuffIcon(parent, frameLevel)
    local icon = CreateFrame("Frame", nil, parent);
    icon:SetFrameLevel(frameLevel);

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    icon.texture:SetAllPoints(icon);

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    StyleCooldown(icon.cooldown);

    icon:Hide();
    return icon;
end

local function ClearIcon(icon)
    icon.texture:SetTexture(nil);
    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    end
    icon.cooldown:Hide();
    icon:Hide();
end

local function EnsureContainer(frame)
    local container = frame.sweepyBoopDebuffIcons;
    if container then return container end

    local frameLevel = frame:GetFrameLevel() + frameLevelOffset;
    container = {
        icons = {},
    };
    container.frame = CreateFrame("Frame", nil, frame);
    container.frame:SetFrameLevel(frameLevel);
    container.frame:SetSize(1, 1);
    container.frame:Hide();

    frame.sweepyBoopDebuffIcons = container;
    return container;
end

local function LayoutContainer(frame, container)
    local config = GetConfig();
    local iconCount = GetIconCount(config);
    local frameHeight = GetFrameHeight(frame);
    local maxIconSize = frameHeight * math.max(GetIconScale(config), GetDispellableScale(config));
    local frameLevel = frame:GetFrameLevel() + frameLevelOffset;

    container.frame:SetFrameLevel(frameLevel);
    container.frame:SetScale(1);
    container.frame:SetSize(( maxIconSize * iconCount ) + ( iconSpacing * ( iconCount - 1 ) ), maxIconSize);
    container.frame:ClearAllPoints();
    container.frame:SetPoint(
        "LEFT",
        frame,
        "RIGHT",
        config.raidFrameDebuffIconOffsetX or 0,
        config.raidFrameDebuffIconOffsetY or 0
    );

    for i = 1, iconCount do
        local icon = container.icons[i];
        if ( not icon ) then
            icon = CreateDebuffIcon(container.frame, frameLevel + i);
            container.icons[i] = icon;
        end

        icon:SetFrameLevel(frameLevel + i);
        icon:SetSize(maxIconSize, maxIconSize);
        icon:ClearAllPoints();
        if ( i == 1 ) then
            icon:SetPoint("LEFT", container.frame, "LEFT", 0, 0);
        else
            icon:SetPoint("LEFT", container.icons[i - 1], "RIGHT", iconSpacing, 0);
        end
    end

    for i = iconCount + 1, #container.icons do
        ClearIcon(container.icons[i]);
    end

    return iconCount;
end

local function ClearFrame(frame)
    local container = frame.sweepyBoopDebuffIcons;
    if ( not container ) then return end

    for i = 1, #container.icons do
        ClearIcon(container.icons[i]);
    end
    container.frame:Hide();
end

local function GetAuraPriority(auraData)
    local spellID = auraData.spellId;
    if ( not spellID ) or addon.IsSecretValue(spellID) then
        return defaultPriority;
    end

    if C_Spell and C_Spell.IsSpellCrowdControl then
        local isCrowdControl = C_Spell.IsSpellCrowdControl(spellID);
        if ( isCrowdControl ~= nil )
                and ( not addon.IsSecretValue(isCrowdControl) )
                and ( not isCrowdControl ) then
            return nil;
        end
    end

    local category = addon.DRList[spellID];
    return ( category and crowdControlPriority[category] ) or defaultPriority;
end

local function ScanCrowdControlAuras(unit)
    wipe(scanAuras);

    local auras = C_UnitAuras.GetUnitAuras(unit, auraFilter);
    if ( not auras ) then return scanAuras end

    for index, auraData in ipairs(auras) do
        local priority = GetAuraPriority(auraData);
        if priority then
            scanAuras[#scanAuras + 1] = {
                aura = auraData,
                index = index,
                priority = priority,
            };
        end
    end

    table.sort(scanAuras, function (left, right)
        if ( left.priority == right.priority ) then
            return left.index < right.index;
        end
        return left.priority > right.priority;
    end);

    return scanAuras;
end

local function SetIconSize(icon, frameHeight, scale)
    local shownSize = frameHeight * scale;
    icon:SetSize(shownSize, shownSize);
end

local function ClearIconCooldown(icon)
    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    end
    icon.cooldown:Hide();
end

local function SetIconAura(icon, unit, auraData, frameHeight, iconScale, dispellableScale)
    SetIconSize(icon, frameHeight, auraData.dispelName and dispellableScale or iconScale);
    icon.texture:SetTexture(auraData.icon);

    local durationObject = auraData.auraInstanceID and C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID);
    if durationObject then
        icon.cooldown:SetCooldownFromDurationObject(durationObject);
        icon.cooldown:Show();
    else
        ClearIconCooldown(icon);
    end

    icon:Show();
end

local function SetIconTestAura(icon, frameHeight, iconScale)
    SetIconSize(icon, frameHeight, iconScale);
    icon.texture:SetTexture(addon.GetSpellTexture(psychicScream));
    icon.cooldown:SetCooldown(GetTime(), testDuration);
    icon.cooldown:Show();
    icon:Show();
end

local function IsGroupUnit(unit)
    if ( not unit ) then return false end

    local first = string.byte(unit, 1);
    if ( first == 112 ) then -- p: player / pet / party / partypet
        return ( string.sub(unit, 1, 6) == "player" )
                or ( string.sub(unit, 1, 3) == "pet" )
                or ( string.sub(unit, 1, 5) == "party" );
    elseif ( first == 114 ) then -- raid / raidpet
        return ( string.sub(unit, 1, 4) == "raid" );
    end

    return false;
end

local function ShowTestFrame(frame)
    if frame:IsForbidden() or ( not IsFrameVisible(frame) ) then return end

    local config = GetConfig();
    local container = EnsureContainer(frame);
    local iconCount = LayoutContainer(frame, container);
    local frameHeight = GetFrameHeight(frame);
    local dispellableScale = GetDispellableScale(config);

    SetIconTestAura(container.icons[1], frameHeight, dispellableScale);
    container.icons[1]:ClearAllPoints();
    container.icons[1]:SetPoint("LEFT", container.frame, "LEFT", 0, 0);

    for i = 2, iconCount do
        ClearIcon(container.icons[i]);
    end

    container.frame:Show();
end

local function UpdateFrame(frame)
    if frame:IsForbidden() then return end

    if isTesting then
        ShowTestFrame(frame);
        return;
    end

    local unit = frame.displayedUnit or frame.unit;
    if ( not IsEnabled() )
            or ( not unit ) or ( not UnitExists(unit) )
            or ( not IsGroupUnit(unit) ) then
        ClearFrame(frame);
        return;
    end

    local dead = UnitIsDeadOrGhost(unit);
    if ( not addon.IsSecretValue(dead) ) and dead then
        ClearFrame(frame);
        return;
    end

    local config = GetConfig();
    local container = EnsureContainer(frame);
    local iconCount = LayoutContainer(frame, container);
    local frameHeight = GetFrameHeight(frame);
    local iconScale = GetIconScale(config);
    local dispellableScale = GetDispellableScale(config);
    local auras = ScanCrowdControlAuras(unit);

    if ( #auras == 0 ) then
        ClearFrame(frame);
        return;
    end

    local shown = 0;
    local previousIcon;
    for i = 1, iconCount do
        local aura = auras[i] and auras[i].aura;
        local icon = container.icons[i];
        if aura then
            SetIconAura(icon, unit, aura, frameHeight, iconScale, dispellableScale);
            icon:ClearAllPoints();
            if previousIcon then
                icon:SetPoint("LEFT", previousIcon, "RIGHT", iconSpacing, 0);
            else
                icon:SetPoint("LEFT", container.frame, "LEFT", 0, 0);
            end
            previousIcon = icon;
            shown = shown + 1;
        else
            ClearIcon(icon);
        end
    end

    if ( shown > 0 ) then
        container.frame:Show();
    else
        ClearFrame(frame);
    end
end

local function MapFrameUnit(frame)
    local unit = frame.displayedUnit or frame.unit;
    if ( frame.sweepyBoopDebuffIconsUnit == unit ) then return end

    if frame.sweepyBoopDebuffIconsUnit and unitFrames[frame.sweepyBoopDebuffIconsUnit] then
        unitFrames[frame.sweepyBoopDebuffIconsUnit][frame] = nil;
    end

    frame.sweepyBoopDebuffIconsUnit = unit;
    if unit then
        unitFrames[unit] = unitFrames[unit] or {};
        unitFrames[unit][frame] = true;
    end
end

local function TrackFrame(frame)
    cufPool[frame] = true;
    MapFrameUnit(frame);
    UpdateFrame(frame);
end

local function UntrackFrame(frame)
    cufPool[frame] = nil;
    if frame.sweepyBoopDebuffIconsUnit and unitFrames[frame.sweepyBoopDebuffIconsUnit] then
        unitFrames[frame.sweepyBoopDebuffIconsUnit][frame] = nil;
    end
    frame.sweepyBoopDebuffIconsUnit = nil;
    ClearFrame(frame);
end

function IsFrameVisible(frame)
    local shown = frame:IsShown();
    return ( not addon.IsSecretValue(shown) ) and shown;
end

local function UpdateVisibleFrame(frame)
    if IsFrameVisible(frame) then
        UpdateFrame(frame);
    elseif isTesting then
        ClearFrame(frame);
    end
end

local function ShouldTrackFrameName(name)
    if ( not name ) or ( string.byte(name, 1) ~= 67 ) then return false end -- C: CompactPartyFrame / CompactRaid
    return ( string.sub(name, 1, 17) == "CompactPartyFrame" )
            or ( string.sub(name, 1, 11) == "CompactRaid" );
end

local function UpdateUnitFrames(unit)
    if ( not IsGroupUnit(unit) ) then return end

    local frames = unitFrames[unit];
    if frames then
        for frame in pairs(frames) do
            UpdateVisibleFrame(frame);
        end
    end
end

local function RefreshAllFrames()
    for frame in pairs(cufPool) do
        MapFrameUnit(frame);
        UpdateFrame(frame);
    end
end

function SweepyBoop:SetupRaidFrameDebuffIcons()
    if ( not addon.PROJECT_MAINLINE ) or setupComplete then return end
    setupComplete = true;

    hooksecurefunc("CompactUnitFrame_UpdateAll", function (frame)
        if ( not frame ) then return end

        if frame:IsForbidden() then
            UntrackFrame(frame);
            return;
        end

        local name = frame:GetName();
        if ShouldTrackFrameName(name) then
            TrackFrame(frame);
        else
            UntrackFrame(frame);
        end
    end)

    eventFrame:RegisterEvent(addon.UNIT_AURA);
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:SetScript("OnEvent", function (_, event, unitTarget)
        if ( event == addon.UNIT_AURA ) then
            if unitTarget then
                UpdateUnitFrames(unitTarget);
            end
        else
            RefreshAllFrames();
        end
    end)
end

function SweepyBoop:RefreshRaidFrameDebuffIcons()
    if IsEnabled() then
        RefreshAllFrames();
        return;
    end

    for frame in pairs(cufPool) do
        ClearFrame(frame);
    end
end

function SweepyBoop:TestRaidFrameDebuffIcons()
    isTesting = true;
    for frame in pairs(cufPool) do
        if IsFrameVisible(frame) then
            ShowTestFrame(frame);
        else
            ClearFrame(frame);
        end
    end

    C_Timer.After(testDuration, function ()
        if isTesting then
            SweepyBoop:HideTestRaidFrameDebuffIcons();
        end
    end);
end

function SweepyBoop:HideTestRaidFrameDebuffIcons()
    isTesting = false;
    RefreshAllFrames();
end
