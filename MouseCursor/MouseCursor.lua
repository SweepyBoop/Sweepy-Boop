local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local GCD_SPELL_ID = 61304;
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8";
local TRAIL_ATLAS = "CircleMaskScalable";
local SEGMENT_COUNT = 96;
local TRAIL_POOL_SIZE = 48;
local TWO_PI = math.pi * 2;
local HALF_PI = math.pi / 2;

local cursorFrame;
local trailFrame;
local trackerFrame;
local eventFrame;
local baselineSegments = {};
local gcdSegments = {};
local trailPool = {};
local activeTrail = {};
local trailPoolInitialized = false;
local trailTimer = 0;
local lastTrailX;
local lastTrailY;
local gcdStartTime = 0;
local gcdDuration = 0;
local gcdActive = false;
local lastGCDTime = 0;

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function GetConfig()
    return SweepyBoop.db.profile.mouseCursor;
end

local function GetClassColorOrWhite(useClassColor)
    if useClassColor then
        local _, classFile = UnitClass("player");
        local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile];
        if color then
            return color.r, color.g, color.b;
        end
    end

    return 1, 1, 1;
end

local function GetTrailColor(config)
    return Clamp(config.trailColorR, 0, 1), Clamp(config.trailColorG, 0, 1), Clamp(config.trailColorB, 0, 1);
end

local function StyleTexture(texture, blendMode)
    texture:SetTexture(WHITE_TEXTURE);
    texture:SetBlendMode(blendMode or "ADD");
end

local function StyleTrailTexture(texture)
    texture:SetAtlas(TRAIL_ATLAS);
    texture:SetBlendMode("ADD");
end

local function CreateSegment(parent, layer)
    local segment = parent:CreateTexture(nil, layer or "OVERLAY");
    StyleTexture(segment);
    segment:Hide();
    return segment;
end

local function EnsureRingSegments(target, parent, layer)
    for i = #target + 1, SEGMENT_COUNT do
        target[i] = CreateSegment(parent, layer);
    end
end

local function LayoutSegments(segments, radius, thickness, alpha, r, g, b)
    local chordLength = 2 * radius * math.sin(math.pi / SEGMENT_COUNT) * 1.08;

    for i, segment in ipairs(segments) do
        local angle = HALF_PI - ( ( i - 1 ) / SEGMENT_COUNT ) * TWO_PI;
        local x = math.cos(angle) * radius;
        local y = math.sin(angle) * radius;

        segment:ClearAllPoints();
        segment:SetPoint("CENTER", cursorFrame, "CENTER", x, y);
        segment:SetSize(chordLength, thickness);
        segment:SetRotation(angle - HALF_PI);
        segment:SetVertexColor(r, g, b, alpha);
    end
end

local function ClearTrail()
    for i = #activeTrail, 1, -1 do
        local element = activeTrail[i];
        element:Hide();
        activeTrail[i] = nil;
        trailPool[#trailPool + 1] = element;
    end
end

local function HideGCDRing()
    gcdActive = false;
    for _, segment in ipairs(gcdSegments) do
        segment:Hide();
    end
end

local function EnsureFrames()
    if cursorFrame then return end

    trailFrame = CreateFrame("Frame", "SweepyBoopMouseCursorTrailFrame", UIParent);
    trailFrame:SetMouseClickEnabled(false);
    trailFrame:EnableMouse(false);
    trailFrame:SetFrameStrata("HIGH");
    trailFrame:SetFrameLevel(80);
    trailFrame:SetAllPoints(UIParent);
    trailFrame:Hide();

    cursorFrame = CreateFrame("Frame", "SweepyBoopMouseCursorFrame", UIParent);
    cursorFrame:SetMouseClickEnabled(false);
    cursorFrame:EnableMouse(false);
    cursorFrame:SetFrameStrata("HIGH");
    cursorFrame:SetFrameLevel(90);
    cursorFrame:Hide();

    EnsureRingSegments(baselineSegments, cursorFrame, "ARTWORK");
    EnsureRingSegments(gcdSegments, cursorFrame, "OVERLAY");
end

local function EnsureTrailPool()
    if trailPoolInitialized then return end

    trailPoolInitialized = true;
    for i = 1, TRAIL_POOL_SIZE do
        local texture = trailFrame:CreateTexture(nil, "ARTWORK");
        StyleTrailTexture(texture);
        texture:Hide();
        trailPool[i] = texture;
    end
end

local function ApplyCursorDefaults()
    local config = GetConfig();
    if config.visualDefaultsVersion == 2 then return end

    if config.ringSize == nil or config.ringSize == 70 then
        config.ringSize = 48;
    end
    if config.ringThickness == nil or config.ringThickness == 4 then
        config.ringThickness = 3;
    end
    if config.opacity == nil or config.opacity == 0.9 then
        config.opacity = 0.85;
    end
    if config.trailDuration == nil or config.trailDuration == 0.45 then
        config.trailDuration = 0.35;
    end
    if config.trailDensity == nil or config.trailDensity == 0.015 then
        config.trailDensity = 0.018;
    end
    if config.trailSize == nil or config.trailSize == 12 then
        config.trailSize = 9;
    end

    config.trailColorR = config.trailColorR or 0.72;
    config.trailColorG = config.trailColorG or 0.9;
    config.trailColorB = config.trailColorB or 1;
    config.visualDefaultsVersion = 2;
    config.lastModified = GetTime();
end

local function RefreshVisuals()
    EnsureFrames();
    ApplyCursorDefaults();

    local config = GetConfig();
    local opacity = Clamp(config.opacity, 0.2, 1);
    local ringSize = Clamp(config.ringSize, 28, 90);
    local thickness = Clamp(config.ringThickness, 2, 6);
    local r, g, b = GetClassColorOrWhite(config.useClassColor);

    cursorFrame:SetSize(ringSize + thickness * 4, ringSize + thickness * 4);
    cursorFrame:SetScale(Clamp(config.scale, 0.5, 2));
    trailFrame:SetAlpha(opacity);

    LayoutSegments(baselineSegments, ringSize / 2, thickness, opacity * 0.72, r, g, b);
    LayoutSegments(gcdSegments, ( ringSize / 2 ) - thickness - 2, thickness + 1, opacity, 1, 0.82, 0.12);

    if config.showBaseline then
        for _, segment in ipairs(baselineSegments) do
            segment:Show();
        end
    else
        for _, segment in ipairs(baselineSegments) do
            segment:Hide();
        end
    end

    if not config.showTrail then
        ClearTrail();
    end

    if not config.showGCD then
        HideGCDRing();
    end

    cursorFrame.lastModified = config.lastModified;
end

local function UpdateCursorPosition()
    if not cursorFrame then return end

    local config = GetConfig();
    local cursorX, cursorY = GetCursorPosition();
    local uiScale = UIParent:GetEffectiveScale();
    local frameScale = Clamp(config.scale, 0.5, 2);

    cursorFrame:ClearAllPoints();
    cursorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ( cursorX / uiScale ) / frameScale, ( cursorY / uiScale ) / frameScale);
end

local function SpawnTrailElement(x, y, config, r, g, b)
    EnsureTrailPool();

    local element = trailPool[#trailPool];
    if not element then return end

    trailPool[#trailPool] = nil;
    activeTrail[#activeTrail + 1] = element;

    local duration = Clamp(config.trailDuration, 0.1, 0.8);
    local size = Clamp(config.trailSize, 4, 20);

    element.duration = duration;
    element.remaining = duration;
    element.baseSize = size;
    element:ClearAllPoints();
    element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);
    element:SetSize(size, size);
    element:SetVertexColor(r, g, b, Clamp(config.opacity, 0.2, 1));
    element:SetAlpha(1);
    element:Show();
end

local function UpdateTrail(elapsed)
    local config = GetConfig();

    for i = #activeTrail, 1, -1 do
        local element = activeTrail[i];
        element.remaining = element.remaining - elapsed;

        if element.remaining <= 0 then
            element:Hide();
            table.remove(activeTrail, i);
            trailPool[#trailPool + 1] = element;
        else
            local progress = element.remaining / element.duration;
            local size = math.max(2, element.baseSize * progress);
            element:SetSize(size, size);
            element:SetAlpha(progress * Clamp(config.opacity, 0.2, 1));
        end
    end

    if not config.showTrail then return end

    trailTimer = trailTimer + elapsed;
    local density = Clamp(config.trailDensity, 0.005, 0.06);
    if trailTimer < density then return end

    local cursorX, cursorY = GetCursorPosition();
    local uiScale = UIParent:GetEffectiveScale();
    local x = cursorX / uiScale;
    local y = cursorY / uiScale;
    local minMovement = Clamp(config.trailMinMovement, 0.5, 20);

    if lastTrailX and lastTrailY then
        local dx = x - lastTrailX;
        local dy = y - lastTrailY;
        if ( dx * dx + dy * dy ) < ( minMovement * minMovement ) then
            return;
        end
    end

    local r, g, b = GetTrailColor(config);
    trailTimer = 0;
    lastTrailX = x;
    lastTrailY = y;
    SpawnTrailElement(x, y, config, r, g, b);
end

local function UpdateGCDRing()
    local config = GetConfig();
    if ( not gcdActive ) or ( not config.showGCD ) then return end

    local progress = ( GetTime() - gcdStartTime ) / gcdDuration;
    if progress >= 1 then
        HideGCDRing();
        return;
    end

    local visibleSegments = math.ceil(SEGMENT_COUNT * ( 1 - Clamp(progress, 0, 1)));
    for i, segment in ipairs(gcdSegments) do
        if i <= visibleSegments then
            segment:Show();
        else
            segment:Hide();
        end
    end
end

local function OnUpdate(_, elapsed)
    local config = GetConfig();
    if ( not config.enabled ) then return end

    if cursorFrame.lastModified ~= config.lastModified then
        RefreshVisuals();
    end

    UpdateCursorPosition();
    UpdateTrail(elapsed);
    UpdateGCDRing();
end

local function StartGCD(startTime, duration)
    local config = GetConfig();
    if ( not config.enabled ) or ( not config.showGCD ) then return end
    if ( not startTime ) or ( not duration ) or duration <= 0 then return end

    gcdStartTime = startTime;
    gcdDuration = duration;
    gcdActive = true;
    UpdateGCDRing();
end

local function GetGCDCooldown()
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(GCD_SPELL_ID);
        if type(info) == "table" then
            return info.startTime, info.duration;
        end
    end

    if GetSpellCooldown then
        local startTime, duration = GetSpellCooldown(GCD_SPELL_ID);
        return startTime, duration;
    end
end

local function OnEvent(_, event, unit)
    if event ~= "UNIT_SPELLCAST_SENT" then return end
    if unit and unit ~= "player" then return end
    if GetTime() - lastGCDTime < 0.1 then return end

    lastGCDTime = GetTime();
    StartGCD(GetGCDCooldown());
end

function SweepyBoop:UpdateMouseCursor()
    if not addon.PROJECT_MAINLINE then return end

    EnsureFrames();
    ApplyCursorDefaults();
    local config = GetConfig();
    RefreshVisuals();

    if config.enabled then
        cursorFrame:Show();
        trailFrame:Show();
        UpdateCursorPosition();
    else
        cursorFrame:Hide();
        trailFrame:Hide();
        ClearTrail();
        HideGCDRing();
    end
end

function SweepyBoop:SetupMouseCursor()
    if not addon.PROJECT_MAINLINE then return end

    EnsureFrames();
    ApplyCursorDefaults();
    trackerFrame = trackerFrame or CreateFrame("Frame");
    eventFrame = eventFrame or CreateFrame("Frame");
    eventFrame:SetScript("OnEvent", OnEvent);

    local config = GetConfig();
    eventFrame:UnregisterAllEvents();

    if config.enabled then
        trackerFrame:SetScript("OnUpdate", OnUpdate);
        if config.showGCD then
            eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
        end
    else
        trackerFrame:SetScript("OnUpdate", nil);
    end

    self:UpdateMouseCursor();
end

function SweepyBoop:RefreshMouseCursor()
    HideGCDRing();
    ClearTrail();
    self:SetupMouseCursor();
end

function SweepyBoop:TestMouseCursorGCD()
    if not addon.PROJECT_MAINLINE then return end

    self:SetupMouseCursor();
    StartGCD(GetTime(), 1.5);
end
