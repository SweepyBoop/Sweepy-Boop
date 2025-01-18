local _, addon = ...;

local POWERTYPE = Enum.PowerType;

local function CreateDruidManaBar() -- Create StatusBar with a text overlay
    local f = CreateFrame("StatusBar", nil, UIParent);
    f:SetMouseClickEnabled(false);
    f.unit = "player";
    local playerPortrait = PlayerFrame.portrait;
    local size = playerPortrait:GetWidth();
    f:SetSize(size, size / 3);
    f:SetPoint("TOP", playerPortrait, "BOTTOM", 0, -5);

    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    f:SetStatusBarColor(0, 102/255, 204/255); -- Blue

    f.Text = f:CreateFontString();
    f.Text:SetFontObject(GameFontNormal);
    f.Text:SetAllPoints();
    f.Text:SetJustifyH("CENTER");
    f.Text:SetJustifyV("MIDDLE");
    f.Text:SetTextColor(1, 1, 1);

    f.border = CreateFrame("Frame", nil, f, "NamePlateFullBorderTemplate");
    f.border:SetBorderSizes(0.5, 0.5, 0.5, 0.5);
    f.border:UpdateSizes();
    f.border:Show();

    f:SetAlpha(0); -- Hide initially
    return f;
end

local function UpdatePower(frame, powerType)
    local power = UnitPower(frame.unit, powerType or POWERTYPE.Mana);
    frame:SetValue(power);
    local powerPercent = math.floor(power * 100 / frame.powerMax);
    frame.Text:SetText(powerPercent);
end

local function UpdatePowerMax(frame, powerType)
    frame.powerMax = UnitPowerMax(frame.unit, powerType or POWERTYPE.Mana);
    frame:SetMinMaxValues(0, frame.powerMax);
    UpdatePower(frame, powerType);
end

local function ShouldShowManaBar(frame)
    local form = GetShapeshiftForm();

    return ( form == 1 ) or ( form == 2 );
end

local function InitializeManaBar(frame, powerType)
    UpdatePowerMax(frame, powerType);

    if ShouldShowManaBar(frame) then
        frame:SetAlpha(1);
    else
        frame:SetAlpha(0);
    end
end

local class = select(2, UnitClass("player"));
if ( class == addon.DRUID ) then
    local druidManaBar = CreateDruidManaBar();
    druidManaBar:SetScript("OnEvent", function(self, event, ...)
        if ( event == addon.UPDATE_SHAPESHIFT_FORM ) or ( event == addon.PLAYER_ENTERING_WORLD ) then
            if ShouldShowManaBar(self) then
                self:SetAlpha(1);
            else
                self:SetAlpha(0);
            end

            return;
        end

        local unit = ...;
        if ( unit ~= "player" ) then return end

        if ( event == addon.UNIT_POWER_FREQUENT ) then
            UpdatePower(self, POWERTYPE.Mana);
        elseif ( event == addon.UNIT_MAXPOWER ) then
            UpdatePowerMax(self, POWERTYPE.Mana);
        end
    end);
    InitializeManaBar(druidManaBar, POWERTYPE.Mana);
    druidManaBar:RegisterEvent(addon.UNIT_POWER_FREQUENT);
    druidManaBar:RegisterEvent(addon.UNIT_MAXPOWER);
    druidManaBar:RegisterEvent(addon.UPDATE_SHAPESHIFT_FORM); -- Fired when the current form changes
    druidManaBar:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
end
