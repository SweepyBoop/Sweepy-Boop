local _, NS = ...;

local CreateFrame = CreateFrame;
local CompactPartyFrame = CompactPartyFrame;
local hooksecurefunc = hooksecurefunc;
local UnitIsPlayer = UnitIsPlayer;

local test = false;

local centerAura = {}; -- Show an important aura at the center of a raid frame
local topRightAura = {};

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

local topRightAuraSpells = {
    48792, -- Icebound Fortitude
    51052, -- Anti-Magic Zone
    48707, -- Anti-Magic Shell

    196555, -- Netherwalk
    196718, -- Darkness
    198589, -- Blur

    102342, -- Ironbark
    61336, -- Survival Instincts

    363916, -- Obsidian Scales

    186265, -- Aspect of the Turtle
    53480, -- Roar of Sacrifice

    45438, -- Ice Block
    342245, -- Alter Time

    122470, -- Touch of Karma
    116849, -- Life Cacoon

    642, -- Divine Shield
    1022, -- Blessing of Protection
    184662, -- Shield of Vengeance

    47788, -- Guardian Spirit
    33206, -- Pain Suppression
    47585, -- Dispersion

    31224, -- Cloak of Shadows
    5277, -- Evasion
    1856, -- Vanish

    108271, -- Astral Shift
    210918, -- Ethereal Form

    108416, -- Dark Pact
    104773, -- Unending Resolve
    212295, -- Nether Ward

    118038, -- Die by the Sword
    184364, -- Enraged Regeneration
    97462, -- Rallying Cry

    345231, -- Gladiator's Emblem
};
if test then
    table.insert(topRightAuraSpells, 8936); -- Regrowth (test)
    table.insert(topRightAuraSpells, 774); -- Rejuv (test)
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

    if ( not topRightAura[frame] ) then
        topRightAura[frame] = CreateFrame("Frame", nil, frame, "CustomCompactAuraTemplate");
        SetAuraFrame(topRightAura[frame]);
        topRightAura[frame]:SetPoint("TOPLEFT", frame, "TOPRIGHT");
        topRightAura[frame]:Hide();
    end

    return centerAura[frame], topRightAura[frame];
end

local function UpdateRaidFrame(frame)
    if ( frame:GetParent() ~= CompactPartyFrame ) then return end

    local center, topRight = SetupRaidFrame(frame);

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

    local topRightSet;
    for _, spell in ipairs(topRightAuraSpells) do
        local name, icon, _, _, duration, expirationTime, source = NS.Util_GetUnitBuff(frame.displayedUnit, spell);
        if duration then
            topRight.icon:SetTexture(icon);
            topRight.cooldown:SetCooldown(expirationTime - duration, duration);
            topRight:Show();
            topRightSet = true;
            break;
        end
    end

    if ( not topRightSet ) then
        topRight:Hide();
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", function (frame)
    if (not frame) or frame:IsForbidden() then return end
    if (not UnitIsPlayer(frame.displayedUnit)) then return end

    UpdateRaidFrame(frame);
end)
