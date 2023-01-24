local function CreateBar(previous) -- Create StatusBar with a text overlay
    local f = CreateFrame("StatusBar", nil, UIParent)
    f:SetSize(150, 30)
    if not previous then
        f:SetPoint("LEfT", 10, 0)
    else
        f:SetPoint("TOP", previous, "BOTTOM", 0, 10)
    end
    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.Text = f:CreateFontString()
    f.Text:SetFontObject(GameFontNormal)
    f.Text:SetPoint("LEFT", 10, 0)
    f.Text:SetJustifyH("LEFT")
    f.Text:SetJustifyV("CENTER")
    f:Hide() -- Hide initially
    return f
end