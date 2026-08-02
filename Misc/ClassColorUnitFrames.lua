local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local enabled = false;
local hookInstalled = false;

local unitToHealthBar = {
    player = PlayerFrame.healthbar,
    target = TargetFrame.healthbar,
    focus = FocusFrame.healthbar,
};

local function RestoreDefaultColor(healthBar)
    if not healthBar then return end

    healthBar:SetStatusBarDesaturated(false);
end

local function ApplyClassColor(unit, healthBar)
    if not healthBar then return end

    if ( not UnitExists(unit) ) or ( not UnitIsPlayer(unit) ) then
        RestoreDefaultColor(healthBar);
        return;
    end

    local class = addon.GetUnitClass(unit);
    local classColor = class and RAID_CLASS_COLORS[class];
    if not classColor then
        RestoreDefaultColor(healthBar);
        return;
    end

    healthBar:SetStatusBarDesaturated(true);
    healthBar:SetStatusBarColor(classColor.r, classColor.g, classColor.b, classColor.a or 1);
end

local function UpdateUnit(unit)
    ApplyClassColor(unit, unitToHealthBar[unit]);
end

local function UpdateAll()
    for unit in pairs(unitToHealthBar) do
        UpdateUnit(unit);
    end
end

local function RestoreAll()
    for unit, healthBar in pairs(unitToHealthBar) do
        RestoreDefaultColor(healthBar);
    end
end

local function EnsureHookInstalled()
    if hookInstalled then return end

    hooksecurefunc("UnitFrameHealthBar_Update", function(healthBar, unit)
        if ( not enabled ) or ( not unit ) then return end

        for trackedUnit, trackedHealthBar in pairs(unitToHealthBar) do
            if healthBar == trackedHealthBar and unit == trackedUnit then
                ApplyClassColor(trackedUnit, trackedHealthBar);
                return;
            end
        end
    end);

    hookInstalled = true;
end

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", function(_, event)
    if event == addon.PLAYER_TARGET_CHANGED then
        UpdateUnit("target");
    elseif event == addon.PLAYER_FOCUS_CHANGED then
        UpdateUnit("focus");
    else
        UpdateAll();
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
        UpdateAll();
    else
        RestoreAll();
    end
end
