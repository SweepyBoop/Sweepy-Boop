local _, NS = ...;

local test = false;

local function ShouldShowHealthBar(unit)
    if ( not UnitExists(unit) ) then
        return false
    end

    local partyUnitId = ( unit == "pet" and "player" ) or ( "party" .. string.sub(unit, -1, -1) );
    local class = select(3, UnitClass(partyUnitId));
    return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock ) or ( class == NS.classId.Shaman and NS.IsShamanPrimaryPet(unit) );
end

local function CreateHealthBar(index, width, height) -- Create StatusBar with a text overlay
    local unit = ( index == 0 and "pet" ) or ( "partypet" .. index );

    local f = CreateFrame("StatusBar", nil, UIParent);
    f.unit = unit;
    f:SetSize(width, height);

    if ( index < 2 ) then
        f:SetPoint("TOPRIGHT", PlayerFrame.portrait, "TOPLEFT", 0, 0);
    else
        f:SetPoint("BOTTOMRIGHT", PlayerFrame.portrait, "BOTTOMLEFT", 0, 0);
    end

    f:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill");
    f:SetStatusBarColor(0, 1, 0); -- Green

    f.Text = f:CreateFontString();
    f.Text:SetFontObject(GameFontNormal);
    f.Text:SetPoint("LEFT", 10, 0);
    f.Text:SetJustifyH("LEFT");
    f.Text:SetJustifyV("CENTER");
    f.Text:SetText(index);
    f.Text:SetTextColor(1, 1, 1);

    f.border = CreateFrame("Frame", nil, f, "BackdropTemplate");
    f.border:SetFrameStrata("BACKGROUND");
    f.border:SetFrameLevel(1);
    f.border:SetPoint("TOPLEFT", -2, 2);
    f.border:SetPoint("BOTTOMRIGHT", 2, -2);
    f.border.backdropInfo = {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tileEdge = true,
        edgeSize = 16,
    };
    f.border:ApplyBackdrop();

    f.targetBorder = CreateFrame("Frame", nil, f, "NamePlateFullBorderTemplate");
    f.targetBorder:SetBorderSizes(2, 2, 2, 2);
    f.targetBorder:UpdateSizes();
    f.targetBorder:Hide();

    f:Hide(); -- Hide initially
    return f;
end

-- Update when unit changes
local function UpdateProperties(frame)
    if ShouldShowHealthBar(frame.unit) then
        frame:Show();
    else
        frame:Hide();
        return;
    end

    if UnitIsUnit(frame.unit, "target") then
        frame.targetBorder:Show();
    else
        frame.targetBorder:Hide();
    end

    frame.healthMax = UnitHealthMax(frame.unit);
    frame:SetMinMaxValues(0, frame.healthMax);
    frame:SetValue(UnitHealth(frame.unit));
end

local function HealthBarOnEvent(self, event, ...)
            self.targetBorder:Show();
        else
            self.targetBorder:Hide();
        end
        return;
    end

    local unit = ...

    if ( unit ~= self.unit ) then return end

    if ( event == "UNIT_MAXHEALTH" ) then
        self.healthMax = UnitHealthMax(unit);
        self:SetMinMaxValues(0, self.healthMax);
    end

    self:SetValue(UnitHealth(unit));
end

-- Update health values
local function RegisterHealthEvents(frame)
    frame:RegisterEvent("UNIT_HEALTH");
    frame:RegisterEvent("UNIT_MAXHEALTH");
    frame:RegisterEvent("PLAYER_TARGET_CHANGED"); -- Use this instead of UNIT_TARGET
    frame:SetScript("OnEvent", HealthBarOnEvent);
end

local testPet = nil; -- Player pet
local partyPets = {}; -- partypet .. 1/2

if test then
    testPet = CreateHealthBar(0, 110, 27);
    UpdateProperties(testPet);
    RegisterHealthEvents(testPet);
else
    for i = 1, 2 do
        partyPets[i] = CreateHealthBar(i, 110, 27);
        UpdateProperties(partyPets[i]);
        RegisterHealthEvents(partyPets[i]);
    end
end

local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
refreshFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
refreshFrame:RegisterEvent("UNIT_PET");
refreshFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
refreshFrame:SetScript("OnEvent", function ()
    if test then
        UpdateProperties(testPet);
    else
        for i = 1, 2 do
            UpdateProperties(partyPets[i]);
        end
    end
end)

local function CreateDruidManaBar() -- Create StatusBar with a text overlay
    local f = CreateFrame("StatusBar", nil, UIParent);
    f.unit = "player";
    local playerPortrait = PlayerFrame.portrait;
    local size = select(1, playerPortrait:GetSize());
    f:SetSize(size, size / 3);
    f:SetPoint("TOP", playerPortrait, "BOTTOM", 0, -10);

    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    f:SetStatusBarColor(0, 102/255, 204/255); -- Blue

    f.Text = f:CreateFontString();
    f.Text:SetFontObject(GameFontNormal);
    f.Text:SetAllPoints();
    f.Text:SetJustifyH("CENTER");
    f.Text:SetJustifyV("CENTER");
    f.Text:SetTextColor(1, 1, 1);

    f.border = CreateFrame("Frame", nil, f, "NamePlateFullBorderTemplate");
    f.border:SetBorderSizes(0.5, 0.5, 0.5, 0.5);
    f.border:UpdateSizes();
    f.border:Show();

    f:Hide(); -- Hide initially
    return f;
end

local function UpdatePower(frame, powerType)
    local power = UnitPower(frame.unit, powerType or Enum.PowerType.Mana);
    frame:SetValue(power);
    local powerPercent = math.floor(power * 100 / frame.powerMax);
    frame.Text:SetText(powerPercent);
end

local function UpdatePowerMax(frame, powerType)
    frame.powerMax = UnitPowerMax(frame.unit, powerType or Enum.PowerType.Mana);
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
        frame:Show();
    else
        frame:Hide();
    end
end

local class = select(3, UnitClass("player"));
if ( class == NS.classId.Druid ) then
    local druidManaBar = CreateDruidManaBar();
    druidManaBar:SetScript("OnEvent", function(self, event, ...)
        if ( event == "UPDATE_SHAPESHIFT_FORM" ) or ( event == "PLAYER_ENTERING_WORLD" ) then
            if ShouldShowManaBar(self) then
                self:Show();
            else
                self:Hide();
            end

            return;
        end

        local unit = ...;
        if ( unit ~= "player" ) then return end

        if ( event == "UNIT_POWER_FREQUENT" ) then
            UpdatePower(self, Enum.PowerType.Mana);
        elseif ( event == "UNIT_MAXPOWER" ) then
            UpdatePowerMax(self, Enum.PowerType.Mana);
        end
    end);
    InitializeManaBar(druidManaBar, Enum.PowerType.Mana);
    druidManaBar:RegisterEvent("UNIT_POWER_FREQUENT");
    druidManaBar:RegisterEvent("UNIT_MAXPOWER");
    druidManaBar:RegisterEvent("UPDATE_SHAPESHIFT_FORM"); -- Fired when the current form changes
    druidManaBar:RegisterEvent("PLAYER_ENTERING_WORLD");
end
