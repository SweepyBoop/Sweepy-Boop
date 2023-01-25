local _, NS = ...;

local test = false;

local function CreateHealthBar(index, width, height) -- Create StatusBar with a text overlay
    local f = CreateFrame("StatusBar", nil, UIParent);
    f:SetSize(width, height);

    f.unit = ( test and "pet" ) or ( "partypet" .. index );
    -- Initialize max health
    f.healthMax = UnitHealthMax(f.unit);
    f:SetMinMaxValues(0, f.healthMax);

    if ( index == 1 ) then
        f:SetPoint("TOPRIGHT", PlayerFrame.portrait, "TOPLEFT", 0, 0);
    elseif ( index == 2 ) then
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

local pet1 = CreateHealthBar(1, 110, 27);
local pet2 = CreateHealthBar(2, 110, 27);

local function ShouldShowHealthBar(unit)
    if ( not UnitExists(unit) ) then
        return false
    end

    local partyUnitId = ( test and "player" ) or ( "party" .. string.sub(unit, -1, -1) );
    local class = select(3, UnitClass(partyUnitId));
    return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock ) or ( class == NS.classId.Shaman );
end

local function HealthBarOnEvent(self, event, ...)
    if ( event == "UNIT_PET" ) or ( event == "GROUP_ROSTER_UPDATE" ) or ( event == "PLAYER_ENTERING_WORLD" ) then
        -- Event is fired for pet dismiss as well
        if ShouldShowHealthBar(self.unit) then
            self:Show();
        else
            self:Hide();
            return;
        end
    end

    if ( event == "UNIT_TARGET" ) or ( event == "PLAYER_ENTERING_WORLD" ) then
        if UnitIsUnit(self.unit, "target") then
            self.targetBorder:Show();
        else
            self.targetBorder:Hide();
        end
    end

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
    frame:RegisterEvent("UNIT_MAXHEALTH"); -- not fired on login
    frame:RegisterEvent("UNIT_PET"); -- unitTarget is the summoner
    frame:RegisterEvent("UNIT_TARGET");
    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("GROUP_ROSTER_UPDATE");
    frame:SetScript("OnEvent", HealthBarOnEvent);
end

RegisterHealthEvents(pet1);
RegisterHealthEvents(pet2);