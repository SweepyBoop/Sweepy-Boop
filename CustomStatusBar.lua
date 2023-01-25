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
    if ( not ShouldShowHealthBar(unit) ) then return end

    local f = CreateFrame("StatusBar", nil, UIParent);
    f:SetSize(width, height);
    f.unit = unit;

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

local function InitializeHealthBar(frame)
    if UnitIsUnit(frame.unit, "target") then
        frame.targetBorder:Show();
    else
        frame.targetBorder:Hide();
    end

    if ( not frame.healthMax ) then
        frame.healthMax = UnitHealthMax(frame.unit);
    end

    frame:SetValue(UnitHealth(frame.unit));

    frame:Show();
end

local function HealthBarOnEvent(self, event, ...)
    local unit = ...

    if ( unit ~= self.unit ) then return end

    if ( event == "UNIT_MAXHEALTH" ) then
        self.healthMax = UnitHealthMax(unit);
        self:SetMinMaxValues(0, self.healthMax);
    end

    if ( event == "UNIT_HEALTH" ) or ( event == "UNIT_MAXHEALTH" ) then
        self:SetValue(UnitHealth(unit));
    end
end

local function RegisterHealthEvents(frame)
    frame:RegisterEvent("UNIT_HEALTH");
    frame:RegisterEvent("UNIT_MAXHEALTH");
    frame:SetScript("OnEvent", HealthBarOnEvent);

    -- Handle target border with OnUpdate, since OnEvent has a visible latency
    frame.timeElapsed = 0;
    frame:SetScript("OnUpdate", function(self, elapsed)
        frame.timeElapsed = frame.timeElapsed + elapsed;
        if frame.timeElapsed > 0.05 then
            if UnitIsUnit(self.unit, "target") then
                self.targetBorder:Show();
            else
                self.targetBorder:Hide();
            end

            frame.timeElapsed = 0;
        end
    end);
end

local testPet = nil; -- Player pet
local pets = {}; -- partypet .. 1/2

local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
refreshFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
refreshFrame:RegisterEvent("UNIT_PET");
refreshFrame:SetScript("OnEvent", function ()
    if test then
        if testPet and ( not UnitExists(testPet.unit) ) then -- Pet died
            testPet:Hide();
            testPet = nil;
        elseif ( not testPet ) or ( not UnitIsUnit(testPet.unit, "pet") ) then -- Pet changed, needs to recreate
            testPet = CreateHealthBar(0, 110, 27);
            if testPet then
                InitializeHealthBar(testPet);
                RegisterHealthEvents(testPet);
            end
        end
    else
        for i = 1, 2 do
            if pets[i] and ( not UnitExists(pets[i].unit) ) then -- Pet died
                pets[i]:Hide();
                pets[i] = nil;
            elseif ( not pets[i] ) or ( not UnitIsUnit(pets[i].unit, "partypet" .. i) ) then -- Pet changed, needs to recreate
                pets[i] = CreateHealthBar(i, 110, 27);
                if pets[i] then
                    InitializeHealthBar(testPet);
                    RegisterHealthEvents(testPet);
                end
            end
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
    local show = NS.Util_GetUnitBuff(frame.unit, "Bear Form");
    if ( not show ) then
        show = NS.Util_GetUnitBuff(frame.unit, "Cat Form");
    end

    return show;
end

local function InitializeManaBar(frame, powerType)
    UpdatePowerMax(frame, powerType);

    if ShouldShowManaBar(frame) then
        frame:Show();
    else
        frame:Hide();
    end
end

local druidManaBar = CreateDruidManaBar();
druidManaBar:SetScript("OnEvent", function(self, event, ...)
    local unit = ...;
    if ( unit ~= "player" ) then return end

    if ( event == "UNIT_POWER_FREQUENT" ) then
        UpdatePower(self, Enum.PowerType.Mana);
    elseif ( event == "UNIT_MAXPOWER" ) then
        UpdatePowerMax(self, Enum.PowerType.Mana);
    elseif ( event == "UNIT_AURA" ) or ( event == "PLAYER_ENTERING_WORLD" ) then
        if ShouldShowManaBar(self) then
            self:Show();
        else
            self:Hide();
        end
    end
end);
InitializeManaBar(druidManaBar, Enum.PowerType.Mana);
druidManaBar:RegisterEvent("UNIT_POWER_FREQUENT");
druidManaBar:RegisterEvent("UNIT_MAXPOWER");
druidManaBar:RegisterEvent("UNIT_AURA");
druidManaBar:RegisterEvent("PLAYER_ENTERING_WORLD");
