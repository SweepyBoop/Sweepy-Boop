local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

addon.SpellData = {
};

addon.SpellResets = {
};

for _, spell in pairs(addon.SpellData) do
    -- Fill default glow duration for burst abilities
    if spell.category == category.BURST and ( not spell.duration ) then
        spell.duration = 3;
    end
end

for _, spell in pairs(addon.SpellData) do
    -- Fill options from parent
    if spell.parent then
        local parent = addon.SpellData[spell.parent];

        spell.cooldown = spell.cooldown or parent.cooldown;
        spell.duration = spell.duration or parent.duration;
        spell.class = spell.class or parent.class;
        spell.spec = spell.spec or parent.spec;
        spell.category = spell.category or parent.category;
        spell.trackPet = spell.trackPet or parent.trackPet;
        spell.trackEvent = spell.trackEvent or parent.trackEvent;
        spell.baseline = spell.baseline or parent.baseline;
        spell.index = spell.index or parent.index;
        spell.default = spell.default or parent.default;
    end
end
