local function CreateBar(index, width, height, color) -- Create StatusBar with a text overlay
    local f = CreateFrame("StatusBar", nil, UIParent);
    f:SetSize(width, height);

    if ( index == 1 ) then
        f:SetPoint("TOPRIGHT", PlayerFrame.portrait, "TOPLEFT", 0, 0);
    elseif ( index == 2 ) then
        f:SetPoint("BOTTOMRIGHT", PlayerFrame.portrait, "BOTTOMLEFT", 0, 0);
    end

    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");

    local barColor = color or "green";
    if ( barColor == "green" ) then
        f:SetStatusBarColor(0, 1, 0);
    elseif ( barColor == "blue" ) then
        f:SetStatusBarColor(0, 0, 1);
    end

    f.Text = f:CreateFontString();
    f.Text:SetFontObject(GameFontNormal);
    f.Text:SetPoint("LEFT", 10, 0);
    f.Text:SetJustifyH("LEFT");
    f.Text:SetJustifyV("CENTER");
    f.Text:SetText(index);
    f.Text:SetTextColor(1, 1, 1);
    f:Hide(); -- Hide initially
    return f;
end

local pet1 = CreateBar(1, 110, 28);
local pet2 = CreateBar(2, 110, 28);