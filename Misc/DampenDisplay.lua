local _, addon = ...;

local DAMPENING_SPELL_ID = 110310;
local UPDATE_INTERVAL = 1;
local WIDGET_OFFSET_Y = -4;

local frame;
local eventFrame;
local dampeningText;

local function GetConfig()
    return SweepyBoop.db.profile.misc;
end

local function GetDampeningText()
    if dampeningText then return dampeningText end

    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(DAMPENING_SPELL_ID);
        dampeningText = spellInfo and spellInfo.name;
    end

    return dampeningText;
end

local function ApplyFrameLayout()
    frame:ClearAllPoints();
    if UIWidgetTopCenterContainerFrame then
        frame:SetPoint(
            "TOP",
            UIWidgetTopCenterContainerFrame,
            "BOTTOM",
            0,
            WIDGET_OFFSET_Y
        );
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -100);
    end
end

local function UpdateDampeningText()
    local label = GetDampeningText();
    if ( not label )
        or ( not C_Commentator )
        or ( not C_Commentator.GetDampeningPercent ) then

        frame.Text:SetText("");
        return;
    end

    local dampeningPercent = C_Commentator.GetDampeningPercent();
    if addon.IsSecretValue(dampeningPercent) then
        frame.Text:SetText(label .. ": --%");
        return;
    end
    if dampeningPercent == nil then
        frame.Text:SetText("");
        return;
    end

    frame.Text:SetFormattedText("%s: %s%%", label, dampeningPercent);
end

local function EnsureFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", nil, UIParent);
    frame:SetSize(200, 20);
    frame:SetFrameStrata("HIGH");
    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    frame.Text:SetAllPoints();
    frame.Text:SetJustifyH("CENTER");
    frame.timeSinceLastUpdate = 0;
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed;
        if self.timeSinceLastUpdate >= UPDATE_INTERVAL then
            UpdateDampeningText();
            self.timeSinceLastUpdate = 0;
        end
    end);
    frame:Hide();
    ApplyFrameLayout();
    return frame;
end

local function UpdateDampenDisplay()
    local display = EnsureFrame();
    local _, instanceType = IsInInstance();
    if ( not GetConfig().showDampenPercentage ) or instanceType ~= "arena" then
        display:Hide();
        return;
    end

    ApplyFrameLayout();
    UpdateDampeningText();
    display.timeSinceLastUpdate = 0;
    display:Show();
end

function SweepyBoop:SetupDampenDisplay()
    if ( not addon.PROJECT_MAINLINE ) then return end

    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:SetScript("OnEvent", UpdateDampenDisplay);
    end

    eventFrame:UnregisterAllEvents();
    if GetConfig().showDampenPercentage then
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    end

    UpdateDampenDisplay();
end
