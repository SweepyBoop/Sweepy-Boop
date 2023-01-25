local function CreateHealthBar(index, width, height) -- Create StatusBar with a text overlay
    local f = CreateFrame("StatusBar", nil, UIParent);
    f:SetSize(width, height);

    --f.unit = "partypet" .. index;
    f.unit = "player";
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
        tileSize = 8,
        edgeSize = 8,
    };
    f.border:ApplyBackdrop();

    f:Show(); -- Hide initially
    return f;
end

local pet1 = CreateHealthBar(1, 110, 27);
local pet2 = CreateHealthBar(2, 110, 27);

local function HealthBarOnEvent(self, event, ...)
    local unit = ...
    if ( unit ~= self.unit ) then return end

    if ( event == "UNIT_MAXHEALTH" ) then
        self.healthMax = UnitHealthMax(unit);
        self:SetMinMaxValues(0, self.healthMax);
    end

    self:SetValue(UnitHealth(unit));
end

local function RegisterHealthEvents(frame)
    frame:RegisterEvent("UNIT_HEALTH");
    frame:RegisterEvent("UNIT_MAXHEALTH");
    frame:SetScript("OnEvent", HealthBarOnEvent);
end

RegisterHealthEvents(pet1);
RegisterHealthEvents(pet2);