local _, addon = ...;

local GCD_SPELL_ID = 61304;
local MAX_GCD_DURATION = 1.7;
local PLAYER_GCD_PROBE_SPELLS = {
    DRUID = 5185, -- Healing Touch
    HUNTER = 75, -- Auto Shot
    MAGE = 1459, -- Arcane Intellect
    PALADIN = 635, -- Holy Light
    PRIEST = 2050, -- Lesser Heal
    ROGUE = 1752, -- Sinister Strike
    SHAMAN = 331, -- Healing Wave
    WARLOCK = 687, -- Demon Skin
    WARRIOR = 6673, -- Battle Shout
};
local GCD_REFRESH_EVENTS = {
    "ACTIONBAR_UPDATE_COOLDOWN",
    "SPELL_UPDATE_COOLDOWN",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
};
local GCD_CAST_EVENTS = {
    "UNIT_SPELLCAST_SENT",
    "UNIT_SPELLCAST_SUCCEEDED",
};
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
local gcdSpellID = GCD_SPELL_ID;

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function GetConfig()
    return SweepyBoop.db.profile.mouseCursor;
end

local function SupportsGCDRing()
    return GetSpellCooldown ~= nil or ( C_Spell and C_Spell.GetSpellCooldown ) ~= nil;
end

local function DoesSpellExist(spellID)
    if not spellID then return false end

    if C_Spell and C_Spell.DoesSpellExist then
        return C_Spell.DoesSpellExist(spellID);
    end

    return GetSpellInfo and GetSpellInfo(spellID) ~= nil;
end

local function ResolveGCDProbeSpellID()
    if DoesSpellExist(GCD_SPELL_ID) then
        return GCD_SPELL_ID;
    end

    local _, class = UnitClass("player");
    local classProbeSpellID = PLAYER_GCD_PROBE_SPELLS[class];
    if DoesSpellExist(classProbeSpellID) then
        return classProbeSpellID;
    end
end

local function RefreshGCDProbeSpell()
    gcdSpellID = ResolveGCDProbeSpellID();
    return gcdSpellID;
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
    if cooldown.SetSwipeTexture then
        cooldown:SetSwipeTexture(RING_TEXTURE);
    end
    if cooldown.SetHideCountdownNumbers then
        cooldown:SetHideCountdownNumbers(true);
    end
    if cooldown.SetDrawSwipe then
        cooldown:SetDrawSwipe(true);
    end
    if cooldown.SetDrawEdge then
        cooldown:SetDrawEdge(false);
    end
    if cooldown.SetDrawBling then
        cooldown:SetDrawBling(false);
    end
    if cooldown.SetReverse then
        cooldown:SetReverse(true);
    end
end

local function EnsureFrames()
    if cursorFrame then return end

    trailFrame = CreateFrame("Frame", "SweepyBoopMouseCursorTrailFrame", UIParent);
    if trailFrame.SetMouseClickEnabled then
        trailFrame:SetMouseClickEnabled(false);
    end
    trailFrame:EnableMouse(false);
    trailFrame:SetFrameStrata("HIGH");
    trailFrame:SetFrameLevel(80);
    trailFrame:SetAllPoints(UIParent);
    trailFrame:Hide();

    cursorFrame = CreateFrame("Frame", "SweepyBoopMouseCursorFrame", UIParent);
    if cursorFrame.SetMouseClickEnabled then
        cursorFrame:SetMouseClickEnabled(false);
    end
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
        if texture.SetAtlas then
            texture:SetAtlas(TRAIL_ATLAS);
        else
            texture:SetTexture("Interface\\Buttons\\WHITE8X8");
        end
        texture:SetBlendMode("ADD");
        texture:Hide();
        trailPool[i] = texture;
    end
end

local function ApplyCursorDefaults()
    local config = GetConfig();

    config.ringSize = config.ringSize or 48;
    config.gcdRingSize = config.gcdRingSize or 60;
    config.opacity = config.opacity or 0.85;
    config.trailDuration = config.trailDuration or 0.35;
    config.trailDensity = config.trailDensity or 0.018;
    config.trailSize = config.trailSize or 9;

    config.baselineColorR = config.baselineColorR or 1;
    config.baselineColorG = config.baselineColorG or 1;
    config.baselineColorB = config.baselineColorB or 1;
    config.trailColorR = config.trailColorR or 1;
    config.trailColorG = config.trailColorG or 1;
    config.trailColorB = config.trailColorB or 1;
    config.gcdColorR = config.gcdColorR or 0.1;
    config.gcdColorG = config.gcdColorG or 1;
    config.gcdColorB = config.gcdColorB or 0.25;
end

local function RefreshVisuals()
    EnsureFrames();
    ApplyCursorDefaults();

    local config = GetConfig();
    local opacity = Clamp(config.opacity, 0.2, 1);
    local ringSize = Clamp(config.ringSize, 28, 90);
    local gcdSize = Clamp(config.gcdRingSize, 28, 110);
    local baselineR, baselineG, baselineB = GetBaselineColor(config);
    local gcdR, gcdG, gcdB = GetGCDColor(config);

    cursorFrame:SetSize(gcdSize, gcdSize);
    cursorFrame:SetScale(Clamp(config.scale, 0.5, 2));
    trailFrame:SetAlpha(opacity);

    baselineRing:SetSize(ringSize, ringSize);
    baselineRing:SetVertexColor(baselineR, baselineG, baselineB, opacity * 0.72);
    if config.showBaseline then
        baselineRing:Show();
    else
        baselineRing:Hide();
    end

    gcdRing:SetSize(gcdSize, gcdSize);
    if gcdRing.SetSwipeColor then
        gcdRing:SetSwipeColor(gcdR, gcdG, gcdB, opacity);
    end
    if ( not SupportsGCDRing() ) or ( not config.showGCD ) then
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
    if ( not SupportsGCDRing() ) or ( not config.enabled ) or ( not config.showGCD ) then return false end
    if ( not startTime ) or ( not duration ) or duration <= 0 or duration > MAX_GCD_DURATION then return false end

    if cursorFrame.lastModified ~= config.lastModified then
        RefreshVisuals();
    end

    gcdRing:SetCooldown(startTime, duration);
    gcdRing:Show();
    return true;
end

local function IsActiveGCD(startTime, duration)
    if ( not startTime ) or ( not duration ) or duration <= 0 or duration > MAX_GCD_DURATION then return false end

    return ( startTime + duration ) > ( GetTime() + 0.05 );
end

local function GetGCDCooldown()
    local spellID = gcdSpellID or RefreshGCDProbeSpell();
    if not spellID then return end

    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID);
        if type(info) == "table" then
            return info.startTime, info.duration;
        end
    end

    if GetSpellCooldown then
        local startTime, duration = GetSpellCooldown(spellID);
        return startTime, duration;
    end
end

local function SyncGCDRing()
    if not SupportsGCDRing() then
        HideGCDRing();
        return false;
    end

    local startTime, duration = GetGCDCooldown();
    if IsActiveGCD(startTime, duration) then
        return StartGCD(startTime, duration);
    end

    HideGCDRing();
    return false;
end

local function QueueGCDCheck()
    if pendingGCDCheck then return end

    pendingGCDCheck = true;
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            pendingGCDCheck = false;
            SyncGCDRing();
        end);
    else
        pendingGCDCheck = false;
        SyncGCDRing();
    end
end

local function OnEvent(_, event, unit)
    if unit and unit ~= "player" then return end

    if event == "SPELLS_CHANGED" then
        RefreshGCDProbeSpell();
        return;
    end

    if event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        SyncGCDRing();
        return;
    end
    if event ~= "UNIT_SPELLCAST_SENT" and event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end
    if GetTime() - lastGCDTime < 0.05 then return end

    lastGCDTime = GetTime();
    if not SyncGCDRing() then
        QueueGCDCheck();
    end
end

function SweepyBoop:UpdateMouseCursor()
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
    EnsureFrames();
    ApplyCursorDefaults();
    trackerFrame = trackerFrame or CreateFrame("Frame");
    eventFrame = eventFrame or CreateFrame("Frame");
    eventFrame:SetScript("OnEvent", OnEvent);

    local config = GetConfig();
    eventFrame:UnregisterAllEvents();

    if config.enabled then
        trackerFrame:SetScript("OnUpdate", OnUpdate);
        if SupportsGCDRing() and config.showGCD then
            RefreshGCDProbeSpell();
            eventFrame:RegisterEvent("SPELLS_CHANGED");
            for _, event in ipairs(GCD_REFRESH_EVENTS) do
                eventFrame:RegisterEvent(event);
            end
            for _, event in ipairs(GCD_CAST_EVENTS) do
                eventFrame:RegisterEvent(event);
            end
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
