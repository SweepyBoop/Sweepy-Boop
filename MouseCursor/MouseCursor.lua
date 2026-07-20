local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local GCD_SPELL_ID = 61304;
local RING_TEXTURE = addon.INTERFACE_SWEEPY .. "Art/MouseCursorRing";
local TRAIL_ATLAS = "CircleMaskScalable";
local TRAIL_POOL_SIZE = 48;

local cursorFrame;
local baselineRing;
local gcdRing;
local trailFrame;
local trackerFrame;
local eventFrame;
local trailPool = {};
local activeTrail = {};
local trailPoolInitialized = false;
local trailTimer = 0;
local lastTrailX;
local lastTrailY;
local lastGCDTime = 0;
local pendingGCDCheck = false;

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function GetConfig()
    return SweepyBoop.db.profile.mouseCursor;
end

local function GetBaselineColor(config)
    return Clamp(config.baselineColorR, 0, 1), Clamp(config.baselineColorG, 0, 1), Clamp(config.baselineColorB, 0, 1);
end

local function GetGCDColor(config)
    return Clamp(config.gcdColorR, 0, 1), Clamp(config.gcdColorG, 0, 1), Clamp(config.gcdColorB, 0, 1);
end

local function GetTrailColor(config)
    return Clamp(config.trailColorR, 0, 1), Clamp(config.trailColorG, 0, 1), Clamp(config.trailColorB, 0, 1);
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
    if not gcdRing then return end

    gcdRing:Hide();
    gcdRing:SetCooldown(0, 0);
end

local function StyleGCDRing(cooldown)
    cooldown:SetSwipeTexture(RING_TEXTURE);
    cooldown:SetHideCountdownNumbers(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetDrawEdge(false);
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
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

    baselineRing = cursorFrame:CreateTexture(nil, "ARTWORK");
    baselineRing:SetTexture(RING_TEXTURE);
    baselineRing:SetPoint("CENTER", cursorFrame, "CENTER");
    baselineRing:SetBlendMode("ADD");
    baselineRing:SetVertexColor(1, 1, 1, 1);

    gcdRing = CreateFrame("Cooldown", "SweepyBoopMouseCursorGCDRing", cursorFrame, "CooldownFrameTemplate");
    gcdRing:SetPoint("CENTER", cursorFrame, "CENTER");
    gcdRing:SetFrameLevel(cursorFrame:GetFrameLevel() + 1);
    StyleGCDRing(gcdRing);
    gcdRing:Hide();
end

local function EnsureTrailPool()
    if trailPoolInitialized then return end

    trailPoolInitialized = true;
    for i = 1, TRAIL_POOL_SIZE do
        local texture = trailFrame:CreateTexture(nil, "ARTWORK");
        texture:SetAtlas(TRAIL_ATLAS);
        texture:SetBlendMode("ADD");
        texture:Hide();
        trailPool[i] = texture;
    end
end

local function ApplyCursorDefaults()
    local config = GetConfig();
    if config.visualDefaultsVersion == 4 then return end

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

    config.baselineColorR = config.baselineColorR or 1;
    config.baselineColorG = config.baselineColorG or 1;
    config.baselineColorB = config.baselineColorB or 1;
    config.trailColorR = config.trailColorR or 0.72;
    config.trailColorG = config.trailColorG or 0.9;
    config.trailColorB = config.trailColorB or 1;
    config.gcdColorR = config.gcdColorR or 0.1;
    config.gcdColorG = config.gcdColorG or 1;
    config.gcdColorB = config.gcdColorB or 0.25;
    config.visualDefaultsVersion = 4;
    config.lastModified = GetTime();
end

local function RefreshVisuals()
    EnsureFrames();
    ApplyCursorDefaults();

    local config = GetConfig();
    local opacity = Clamp(config.opacity, 0.2, 1);
    local ringSize = Clamp(config.ringSize, 28, 90);
    local baselineR, baselineG, baselineB = GetBaselineColor(config);
    local gcdR, gcdG, gcdB = GetGCDColor(config);
    local gcdSize = ringSize + Clamp(config.ringThickness, 2, 6) * 4;

    cursorFrame:SetSize(gcdSize, gcdSize);
    cursorFrame:SetScale(Clamp(config.scale, 0.5, 2));
    trailFrame:SetAlpha(opacity);

    baselineRing:SetSize(ringSize, ringSize);
    baselineRing:SetVertexColor(baselineR, baselineG, baselineB, opacity * 0.72);
    baselineRing:SetShown(config.showBaseline);

    gcdRing:SetSize(gcdSize, gcdSize);
    gcdRing:SetSwipeColor(gcdR, gcdG, gcdB, opacity);
    if not config.showGCD then
        HideGCDRing();
    end

    if not config.showTrail then
        ClearTrail();
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

local function OnUpdate(_, elapsed)
    local config = GetConfig();
    if not config.enabled then return end

    if cursorFrame.lastModified ~= config.lastModified then
        RefreshVisuals();
    end

    UpdateCursorPosition();
    UpdateTrail(elapsed);
end

local function StartGCD(startTime, duration)
    local config = GetConfig();
    if ( not config.enabled ) or ( not config.showGCD ) then return false end
    if ( not startTime ) or ( not duration ) or duration <= 0 then return false end

    if cursorFrame.lastModified ~= config.lastModified then
        RefreshVisuals();
    end

    gcdRing:SetCooldown(startTime, duration);
    gcdRing:Show();
    return true;
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

local function TryStartGCD()
    return StartGCD(GetGCDCooldown());
end

local function QueueGCDCheck()
    if pendingGCDCheck then return end

    pendingGCDCheck = true;
    C_Timer.After(0, function()
        pendingGCDCheck = false;
        TryStartGCD();
    end);
end

local function OnEvent(_, event, unit)
    if unit and unit ~= "player" then return end
    if event == "SPELL_UPDATE_COOLDOWN" then
        TryStartGCD();
        return;
    end
    if event ~= "UNIT_SPELLCAST_SENT" and event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end
    if GetTime() - lastGCDTime < 0.05 then return end

    lastGCDTime = GetTime();
    if not TryStartGCD() then
        QueueGCDCheck();
    end
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
            eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
            eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
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
