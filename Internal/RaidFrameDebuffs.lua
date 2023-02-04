local _, NS = ...;

local centerAura = {}; -- Show an important aura at the center of a raid frame
local topRightAura = {}; -- Show a warning aura to the top right of a raid frame

local centerAuraSpells = {
    102352, -- Cenarion Ward
    774, -- Test (Rejuv)
};

local topRightSpells = {
    { spellID = 12294 }, -- Sharpen Blade
    { spellID = 354124 }, -- Hemotoxin
    { spellID = 352998, stacks = 8 }, -- Slaughterhouse
    { spellID = "Thoughtstolen" },
};

local function SetupRaidFrame(frame)
    if ( not centerAura[frame] ) then
        local centerSize = 25;
        centerAura[frame] = CreateFrame("Frame", nil, frame, "CustomCompactAuraTemplate");
        centerAura[frame]:SetSize(centerSize, centerSize);
        centerAura[frame]:SetPoint("BOTTOM", frame, "CENTER");
    end

    --[[ if ( not topRightAura[frame] ) then
        local topRightSize = 27;
        topRightAura[frame] = CreateFrame("Frame", nil, frame, "CompactBuffTemplate");
        topRightAura[frame]:SetSize(topRightSize, topRightSize);
        topRightAura[frame]:SetPoint("TOPLEFT", frame, "TOPRIGHT");
    end ]]

    return centerAura[frame], topRightAura[frame];
end

local function UpdateRaidFrame(frame)
    if ( frame:GetParent() ~= CompactPartyFrame ) then return end

    local center, topRight = SetupRaidFrame(frame);

    local centerSet;
    for _, spell in ipairs(centerAuraSpells) do
        local duration, expirationTime = NS.Util_GetUnitBuff(frame.displayedUnit, spell);
        if duration then
            center.icon:SetCooldown(expirationTime - duration, duration);
            centerSet = true;
            break;
        end
    end
    if ( not centerSet ) then
        center.icon:SetCooldown(0, 0);
    end
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", function (frame)
    if (not frame) or frame:IsForbidden() then return end
    if (not UnitIsPlayer(frame.displayedUnit)) then return end

    UpdateRaidFrame(frame);
end)