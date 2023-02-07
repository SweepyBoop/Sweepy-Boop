local _, NS = ...;

local cooldowns = NS.cooldownSpells;
local resets = NS.cooldownResets;

for spellID, spell in pairs(cooldowns) do
    spell.priority = spell.index or 100;

    if ( not spell.class ) then
        print("Spell missing class:", spellID);
    end

    -- Validate class
    if spell.class and ( type(spell.class) ~= "string" ) then
        print("Invalid class for spellID:", spellID);
    end
end

local growCenter = {
    diretion = "CENTER",
    anchor = "CENTER",
    margin = 3,
};

local growRight = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 3,
};

