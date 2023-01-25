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
    if ( not frame.healthMax ) then
        frame.healthMax = UnitHealthMax(frame.unit);
    end

    if UnitIsUnit(frame.unit, "target") then
        frame.targetBorder:Show();
    else
        frame.targetBorder:Hide();
    end

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
local pets = {};

local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
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
