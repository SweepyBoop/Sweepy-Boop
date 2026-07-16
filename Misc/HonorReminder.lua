local _, addon = ...;

local HONOR_CURRENCY_ID = 1792;
local HONOR_LABEL = addon.L["Honor"];
local HONOR_ICON_ATLAS = "countdown-swords";
local CURRENCY_DISPLAY_UPDATE_EVENT = "CURRENCY_DISPLAY_UPDATE";
local BASE_ICON_SIZE = addon.DEFAULT_ICON_SIZE;
local ICON_TEXT_SPACING = 8;
local PULSE_SCALE = 2;
local PULSE_DURATION = 0.3;
local TEST_HONOR_QUANTITY = 10000;
local TEST_HONOR_MAX = 15000;

local reminderFrame;
local eventFrame;
local isInTest = false;

local validAnchorPoints = {
    CENTER = true,
    TOP = true,
    BOTTOM = true,
    LEFT = true,
    RIGHT = true,
    TOPLEFT = true,
    TOPRIGHT = true,
    BOTTOMLEFT = true,
    BOTTOMRIGHT = true,
};

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function FormatNumber(value)
    value = tonumber(value) or 0;
    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(value);
    end
    return tostring(value);
end

local function GetConfig()
    return SweepyBoop.db.profile.misc;
end

local function GetThreshold()
    return Clamp(GetConfig().honorReminderThreshold, 5000, 15000);
end

local function GetFontSize()
    return Clamp(GetConfig().honorReminderFontSize, 8, 64);
end

local function GetIconSize()
    return Clamp(GetConfig().honorReminderIconSize, 16, 128);
end

local function GetAnchorPoint()
    local anchorPoint = GetConfig().honorReminderAnchorPoint or "CENTER";
    if validAnchorPoints[anchorPoint] then
        return anchorPoint;
    end
    return "CENTER";
end

local function GetHonorInfo()
    if ( not C_CurrencyInfo ) or ( not C_CurrencyInfo.GetCurrencyInfo ) then return nil end

    return C_CurrencyInfo.GetCurrencyInfo(HONOR_CURRENCY_ID);
end

local function IsRealReminderShown()
    return reminderFrame and reminderFrame:IsShown() and ( not isInTest );
end

function SweepyBoop:IsHonorReminderRealReminderShown()
    return IsRealReminderShown();
end

local function UpdateReminderWidth()
    if not reminderFrame then return end

    local iconSize = reminderFrame.iconSize or BASE_ICON_SIZE;
    local textWidth = reminderFrame.text:GetStringWidth() or 0;
    reminderFrame:SetWidth(iconSize + ICON_TEXT_SPACING + textWidth);
end

local function StopPulse()
    if ( not reminderFrame ) or ( not reminderFrame.pulse ) then return end

    reminderFrame.pulse:Stop();
    reminderFrame.iconFrame:SetScale(1);
end

local function StartPulse()
    if ( not reminderFrame ) or ( not reminderFrame.pulse ) then return end

    if not reminderFrame.pulse:IsPlaying() then
        reminderFrame.iconFrame:SetScale(1);
        reminderFrame.pulse:Play();
    end
end

local function HideReminder()
    if not reminderFrame then return end

    StopPulse();
    reminderFrame:Hide();
end

local function CreatePulseAnimation(iconFrame)
    local pulse = iconFrame:CreateAnimationGroup();
    pulse:SetLooping("REPEAT");

    local grow = pulse:CreateAnimation("Scale");
    grow:SetOrder(1);
    grow:SetDuration(PULSE_DURATION);
    grow:SetScale(PULSE_SCALE, PULSE_SCALE);
    if grow.SetOrigin then
        grow:SetOrigin("CENTER", 0, 0);
    end
    if grow.SetSmoothing then
        grow:SetSmoothing("IN_OUT");
    end

    local shrink = pulse:CreateAnimation("Scale");
    shrink:SetOrder(2);
    shrink:SetDuration(PULSE_DURATION);
    shrink:SetScale(1 / PULSE_SCALE, 1 / PULSE_SCALE);
    if shrink.SetOrigin then
        shrink:SetOrigin("CENTER", 0, 0);
    end
    if shrink.SetSmoothing then
        shrink:SetSmoothing("IN_OUT");
    end

    pulse:SetScript("OnStop", function()
        iconFrame:SetScale(1);
    end);

    return pulse;
end

local function CreateReminderFrame()
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:SetSize(BASE_ICON_SIZE + 160, BASE_ICON_SIZE);
    frame:Hide();

    frame.iconFrame = CreateFrame("Frame", nil, frame);
    frame.iconFrame:SetMouseClickEnabled(false);
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0);
    frame.iconFrame:SetSize(BASE_ICON_SIZE, BASE_ICON_SIZE);

    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK");
    frame.icon:SetAllPoints(frame.iconFrame);
    frame.icon:SetAtlas(HONOR_ICON_ATLAS);

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    frame.text:SetPoint("LEFT", frame.iconFrame, "RIGHT", ICON_TEXT_SPACING, 0);
    frame.text:SetJustifyH("LEFT");
    frame.text:SetTextColor(1, 0.82, 0, 1);
    frame.text:SetShadowOffset(1, -1);
    frame.text:SetText("");

    local font, _, flags = frame.text:GetFont();
    frame.textFont = font or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF";
    frame.textFlags = flags or "OUTLINE";

    frame.pulse = CreatePulseAnimation(frame.iconFrame);
    return frame;
end

local function EnsureReminderFrame()
    reminderFrame = reminderFrame or CreateReminderFrame();
    return reminderFrame;
end

local function RefreshReminderLayout()
    local frame = EnsureReminderFrame();
    local config = GetConfig();
    local fontSize = GetFontSize();
    local iconSize = GetIconSize();

    frame.iconSize = iconSize;
    frame:SetHeight(iconSize);
    frame.iconFrame:SetSize(iconSize, iconSize);
    frame.iconFrame:ClearAllPoints();
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0);

    frame.text:SetFont(frame.textFont, fontSize, frame.textFlags);
    frame.text:ClearAllPoints();
    frame.text:SetPoint("LEFT", frame.iconFrame, "RIGHT", ICON_TEXT_SPACING, 0);

    UpdateReminderWidth();

    local anchorPoint = GetAnchorPoint();
    frame:ClearAllPoints();
    frame:SetPoint(anchorPoint, UIParent, anchorPoint, config.honorReminderOffsetX or 0, config.honorReminderOffsetY or 0);
    frame.lastModified = config.lastModified;
end

local function ShowReminder(quantity, denominator, currencyName)
    local frame = EnsureReminderFrame();
    local config = GetConfig();
    if frame.lastModified ~= config.lastModified then
        RefreshReminderLayout();
    end

    frame.icon:SetAtlas(HONOR_ICON_ATLAS);
    frame.text:SetText(format("%s %s / %s", currencyName or HONOR_LABEL, FormatNumber(quantity), FormatNumber(denominator)));
    UpdateReminderWidth();

    frame:Show();
    StartPulse();
end

function SweepyBoop:UpdateHonorReminder()
    if ( not addon.PROJECT_MAINLINE ) or ( not GetConfig().honorReminder ) then
        isInTest = false;
        HideReminder();
        return;
    end

    if isInTest then
        ShowReminder(TEST_HONOR_QUANTITY, TEST_HONOR_MAX, HONOR_LABEL);
        return;
    end

    local currencyInfo = GetHonorInfo();
    if not currencyInfo then
        HideReminder();
        return;
    end

    local quantity = tonumber(currencyInfo.quantity) or 0;
    local threshold = GetThreshold();
    if quantity < threshold then
        HideReminder();
        return;
    end

    local denominator = tonumber(currencyInfo.maxQuantity) or 0;
    if denominator <= 0 then
        denominator = threshold;
    end

    ShowReminder(quantity, denominator, currencyInfo.name or HONOR_LABEL);
end

function SweepyBoop:TestHonorReminder()
    if ( not addon.PROJECT_MAINLINE ) or IsRealReminderShown() then return end

    isInTest = true;
    ShowReminder(TEST_HONOR_QUANTITY, TEST_HONOR_MAX, HONOR_LABEL);
end

function SweepyBoop:HideTestHonorReminder()
    if IsRealReminderShown() then return end

    isInTest = false;
    HideReminder();
    SweepyBoop:UpdateHonorReminder();
end

function SweepyBoop:RefreshHonorReminder()
    isInTest = false;
    HideReminder();
    SweepyBoop:SetupHonorReminder();
end

function SweepyBoop:SetupHonorReminder()
    if not eventFrame then
        eventFrame = CreateFrame("Frame");
        eventFrame:SetScript("OnEvent", function(_, event, currencyType)
            if ( event == CURRENCY_DISPLAY_UPDATE_EVENT ) and currencyType and ( tonumber(currencyType) ~= HONOR_CURRENCY_ID ) then
                return;
            end
            SweepyBoop:UpdateHonorReminder();
        end);
    end

    eventFrame:UnregisterAllEvents();
    if addon.PROJECT_MAINLINE and GetConfig().honorReminder then
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(CURRENCY_DISPLAY_UPDATE_EVENT);
        SweepyBoop:UpdateHonorReminder();
    else
        isInTest = false;
        HideReminder();
    end
end
