local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local enabled = false;
local hookInstalled = false;

local trackedUnits = { "player", "target", "focus" };

local function GetHealthBar(unit)
    if unit == "player" then
        return PlayerFrame.healthbar;
    elseif unit == "target" then
        return TargetFrame.healthbar;
    elseif unit == "focus" then
        return FocusFrame.healthbar;
    end
end

local function ResetHealthBar(unit)
    local healthBar = GetHealthBar(unit);
    if not healthBar then return end

    if healthBar.lockColor then
        healthBar:SetStatusBarDesaturated(false);
        healthBar:SetStatusBarColor(1, 1, 1, 1);
    elseif UnitExists(unit) and ( not UnitIsConnected(unit) ) then
        healthBar:SetStatusBarDesaturated(false);
        healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1);
    else
        healthBar:SetStatusBarDesaturated(false);
        healthBar:SetStatusBarColor(0, 1, 0, 1);
    end
end

local function PaintHealthBar(unit)
    local healthBar = GetHealthBar(unit);
    if not healthBar then return end

    if ( not UnitExists(unit) ) or ( not UnitIsPlayer(unit) ) then
        ResetHealthBar(unit);
        return;
    end

    local class = addon.GetUnitClass(unit);
    local classColor = class and RAID_CLASS_COLORS[class];
    if not classColor then
        ResetHealthBar(unit);
        return;
    end

    healthBar:SetStatusBarDesaturated(true);
    healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, classColor.a or 1);
end

local function PaintAllHealthBars()
    for _, unit in ipairs(trackedUnits) do
        PaintHealthBar(unit);
    end
end

local function ResetAllHealthBars()
    for _, unit in ipairs(trackedUnits) do
        ResetHealthBar(unit);
    end
end

local function EnsureHookInstalled()
    if hookInstalled then return end

    hooksecurefunc("UnitFrameHealthBar_Update", function(healthBar, unit)
        if ( not enabled ) or ( not unit ) then return end

        if healthBar == GetHealthBar(unit) then
            PaintHealthBar(unit);
        end
    end);

    hookInstalled = true;
end

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", function(_, event)
    if event == addon.PLAYER_TARGET_CHANGED then
        PaintHealthBar("target");
    elseif event == addon.PLAYER_FOCUS_CHANGED then
        PaintHealthBar("focus");
    else
        PaintAllHealthBars();
    end
end);

function SweepyBoop:SetupClassColorUnitFrames()
    enabled = SweepyBoop.db.profile.misc.classColorUnitFrames;

    eventFrame:UnregisterAllEvents();
    if enabled then
        EnsureHookInstalled();
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
        eventFrame:RegisterEvent(addon.PLAYER_FOCUS_CHANGED);
        PaintAllHealthBars();
    else
        ResetAllHealthBars();
    end
end
