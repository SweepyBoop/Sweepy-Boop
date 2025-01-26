local _, addon = ...;

addon.AuraList = { -- Use table with consecutive indexes to preserve the order
    {
        classID = addon.CLASSID.DEATHKNIGHT,
        auras = {
            { spellId = 45524, default = true }, -- Chains of Ice
            -- Unholy
            { spellId = 77575, default = true }, -- Virulent Plague
            { spellId = 197147, defualt = true }, -- Festering Wound
            -- Frost
            { spellId = 55095, default = true }, -- Frost Fever
            -- Blood
            { spellId = 55078, default = true }, -- Blood Plague
        }
    },
    {
        classID = addon.CLASSID.EVOKER,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.HUNTER,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.MAGE,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.MONK,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.PALADIN,
        auras = {
            
        }
    },
    {
        classID = addon.CLASSID.PRIEST,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.SHAMAN,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.WARLOCK,
        auras = {

        }
    },
    {
        classID = addon.CLASSID.WARRIOR,
        auras = {

        }
    },
};