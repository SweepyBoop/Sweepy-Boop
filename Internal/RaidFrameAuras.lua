local _, NS = ...;

local CreateFrame = CreateFrame;
local CompactPartyFrame = CompactPartyFrame;
local hooksecurefunc = hooksecurefunc;
local UnitIsPlayer = UnitIsPlayer;

local test = false;

local centerAura = {}; -- Show an important aura at the center of a raid frame

-- topRightAura removed since those debuffs are covered by BigDebuffs
-- Hemotoxin is combined into Shiv debuff
-- Mortal Strike gives 50% healing reduction baseline

local centerAuraSpells = {
    102352, -- Cenarion Ward
    194384,  -- Atonement
};
if test then
    table.insert(centerAuraSpells, 8936); -- Regrowth (test)
    table.insert(centerAuraSpells, 774); -- Rejuv (test)
end

local function SetAuraFrame(frame)
    local size = 22;
    frame:SetSize(size, size);
    frame.cooldown:SetDrawEdge(false);
    frame.cooldown:SetAlpha(1);
    frame.cooldown:SetDrawBling(false);
    frame.cooldown:SetDrawSwipe(true);
    frame.cooldown:SetReverse(true);
end

local function SetupRaidFrame(frame)
    if ( not centerAura[frame] ) then
        centerAura[frame] = CreateFrame("Frame", nil, frame, "CustomCompactAuraTemplate");
        SetAuraFrame(centerAura[frame]);
        centerAura[frame]:SetPoint("BOTTOM", frame, "CENTER");
        centerAura[frame]:Hide();
    end

    return centerAura[frame];
end

local function UpdateRaidFrame(frame)
    if ( frame:GetParent() ~= CompactPartyFrame ) then return end

    local center = SetupRaidFrame(frame);

    local centerSet;
    for _, spell in ipairs(centerAuraSpells) do
        local name, icon, _, _, duration, expirationTime, source = NS.Util_GetUnitBuff(frame.displayedUnit, spell);
        if duration and ( source == "player" ) then
            center.icon:SetTexture(icon);
            center.cooldown:SetCooldown(expirationTime - duration, duration);
            center:Show();
            centerSet = true;
            break;
        end
    end

    if ( not centerSet ) then
        center:Hide();
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", function (frame)
    if (not frame) or frame:IsForbidden() then return end
    if (not UnitIsPlayer(frame.displayedUnit)) then return end

    UpdateRaidFrame(frame);
end)
