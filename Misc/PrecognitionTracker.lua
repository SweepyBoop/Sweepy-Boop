local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;
local precognitionSpellID = 377362;
local greenGlowColor = { 0, 1, 0, 1 };

local containerFrame;
local isInTest = false;

local function HideIcon()
    if not containerFrame then return end

    containerFrame.cooldown:Clear();
    addon.HideProcGlow(containerFrame);
    containerFrame:Hide();
    isInTest = false;
end

local function CreateContainerFrame()
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:SetSize(iconSize, iconSize);

    frame.icon = frame:CreateTexture(nil, "BORDER");
    frame.icon:SetSize(iconSize, iconSize);
    frame.icon:SetAllPoints(frame);
    frame.icon:SetTexture(addon.GetSpellTexture(precognitionSpellID));

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(true);
    frame.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    frame.cooldown:SetReverse(true);
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.5);
    frame.cooldown:SetHideCountdownNumbers(true);
    frame.cooldown.noCooldownCount = true;
    frame.cooldown:SetScript("OnCooldownDone", function()
        HideIcon();
    end);

    frame:Hide();
    return frame;
end

local function UpdatePosition()
    if not containerFrame then return end

    local config = SweepyBoop.db.profile.misc;
    local scale = config.precognitionTrackerSize / iconSize;
    containerFrame:SetScale(scale);
    containerFrame:ClearAllPoints();
    containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.precognitionTrackerOffsetX / scale, config.precognitionTrackerOffsetY / scale);
    containerFrame.lastModified = config.lastModified;
end

local function GetPrecognitionAura()
    if not C_UnitAuras.GetPlayerAuraBySpellID then return end
    return C_UnitAuras.GetPlayerAuraBySpellID(precognitionSpellID);
end

local function ShowIcon(durationObject, startTime, duration)
    containerFrame = containerFrame or CreateContainerFrame();
    if containerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified then
        UpdatePosition();
    end

    if durationObject then
        containerFrame.cooldown:SetCooldownFromDurationObject(durationObject);
        containerFrame.cooldown:Show();
    elseif startTime and duration then
        containerFrame.cooldown:SetCooldown(startTime, duration);
        containerFrame.cooldown:Show();
    else
        containerFrame.cooldown:Clear();
        containerFrame.cooldown:Hide();
    end

    addon.ShowProcGlow(containerFrame, greenGlowColor);
    containerFrame:Show();
end

function SweepyBoop:UpdatePrecognitionTracker()
    if ( not addon.PROJECT_MAINLINE ) or ( not SweepyBoop.db.profile.misc.precognitionTracker ) then
        HideIcon();
        return;
    end

    local auraData = GetPrecognitionAura();
    if auraData then
        isInTest = false;
        local durationObject = auraData.auraInstanceID and C_UnitAuras.GetAuraDuration("player", auraData.auraInstanceID);
        ShowIcon(durationObject);
    elseif isInTest then
        UpdatePosition();
    else
        HideIcon();
    end
end

function SweepyBoop:TestPrecognitionTracker()
    ShowIcon(nil, GetTime(), 8);
    isInTest = true;
end

local eventFrame;
function SweepyBoop:SetupPrecognitionTracker()
    if not eventFrame then
        eventFrame = CreateFrame("Frame");
        eventFrame:SetScript("OnEvent", function(_, event, unit)
            if ( event == addon.UNIT_AURA ) and ( unit ~= "player" ) then return end
            SweepyBoop:UpdatePrecognitionTracker();
        end);
    end

    eventFrame:UnregisterAllEvents();
    if addon.PROJECT_MAINLINE and SweepyBoop.db.profile.misc.precognitionTracker then
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterUnitEvent(addon.UNIT_AURA, "player");
        SweepyBoop:UpdatePrecognitionTracker();
    else
        HideIcon();
    end
end
