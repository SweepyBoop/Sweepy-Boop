local _, NS = ...;
local test = false;

local centerAura = {}; -- Show an important aura at the center of a raid frame
local topRightAura = {}; -- Show a warning aura to the top right of a raid frame

local centerAuraSpells = {
    102352, -- Cenarion Ward
};
if test then
    table.insert(centerAuraSpells, 8936); -- Regrowth (test)
    table.insert(centerAuraSpells, 774); -- Rejuv (test)
end

local topRightSpells = {
    { spellID = 12294 }, -- Sharpen Blade
    { spellID = 354124 }, -- Hemotoxin
    { spellID = 352998, stacks = 8 }, -- Slaughterhouse

    -- Thoughtstolen
    { spellID = 322459 }, -- Shaman
    { spellID = 322464 }, -- Mage
    { spellID = 322442 }, -- Druid
    { spellID = 322462 }, -- Priest - Holy
    { spellID = 322457 }, -- Paladin
    { spellID = 322463 }, -- Warlock
    { spellID = 322461 }, -- Priest - Discipline
    { spellID = 322458 }, -- Monk
    { spellID = 322460 }, -- Priest - Shadow
    { spellID = 394902 }, -- Evoker
};

if test then
    table.insert(topRightSpells, {spellID = 145152, stacks = 2}); -- Bloodtalons (test)
    table.insert(topRightSpells, {spellID = 774}); -- Rejuv (test)
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
        topRightAura[frame] = CreateFrame("Frame", nil, frame, "CustomCompactDebuffTemplate");
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
    for _, spell in ipairs(topRightSpells) do
        local name, icon, count, _, duration, expirationTime = NS.Util_GetUnitAura(frame.displayedUnit, spell.spellID, "HARMFUL");
        if duration and ( ( not spell.count ) or ( count >= spell.count ) ) then
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