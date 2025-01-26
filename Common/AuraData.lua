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
            { spellId = 185800, name = "Past Self", icon = 371869, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.HUNTER,
        auras = {
            { spellId = 105419, name = "Dire Beast: Basilisk", icon = 205691, default = addon.NpcOption.Show },

            -- Hunter pets all have the same spellId, add here so they don't get hidden in battlegrounds
            { spellId = addon.HUNTERPET, name = "Pet", icon = 267116, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.MAGE,
        auras = {
            { spellId = 208441, name = "Water Elemental", icon = 12472, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.MONK,
        auras = {
            { spellId = 63508, name = "Xuen", icon = 123904, default = addon.NpcOption.Hide },
            { spellId = 69791, name = "Storm, Earth and Fire", icon = 137639, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.PALADIN,
        auras = {
            { spellId = 114565, name = "Guardian of the Forgotten Queen", icon = 228049, default = addon.NpcOption.Highlight },
        }
    },
    {
        classID = addon.CLASSID.PRIEST,
        auras = {
            { spellId = 101398, name = "Psyfiend", icon = 199824, default = addon.NpcOption.Highlight },
            { spellId = 225672, name = "Shadow", icon = 8122, default = addon.NpcOption.Highlight }, -- casts fear
            { spellId = 224466, name = "Voidwraith", icon = 451234, default = addon.NpcOption.Show },
            { spellId = 62982, name = "Mindbender", icon = 123040, default = addon.NpcOption.Show },
            { spellId = 19668, name = "Shadowfiend", icon = 34433, default = addon.NpcOption.Show },
            { spellId = 65282, name = "Void Tendrils", icon = 108920, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.SHAMAN,
        auras = {
            { spellId = 5925, name = "Grounding Totem", icon = 204336, default = addon.NpcOption.Highlight },
            { spellId = 53006, name = "Spirit Link Totem", icon = 98008, default = addon.NpcOption.Highlight },
            { spellId = 5913, name = "Tremor Totem", icon = 8143, default = addon.NpcOption.Highlight },
            { spellId = 104818, name = "Ancestral Protection Totem", icon = 207399, default = addon.NpcOption.Highlight },
            { spellId = 61245, name = "Capacitor Totem", icon = 192058, default = addon.NpcOption.Highlight },
            { spellId = 105451, name = "Counterstrike Totem", icon = 204331, default = addon.NpcOption.Highlight },
            { spellId = 59764, name = "Healing Tide Totem", icon = 108280, default = addon.NpcOption.Highlight },

            { spellId = 179867, name = "Static Field Totem", icon = 355580, default = addon.NpcOption.Show },
            { spellId = 59712, name = "Stone Bulwark Totem", icon = 108270, default = addon.NpcOption.Show }, -- hard to kill
            { spellId = 100943, name = "Earthen Wall Totem", icon = 198838, default = addon.NpcOption.Show }, -- hard to kill, just try to fight outside of its range
            { spellId = 60561, name = "Earthgrab Totem", icon = 51485, default = addon.NpcOption.Show }, -- gets players out of stealth
            { spellId = 105427, name = "Totem of Wrath", icon = 204330, default = addon.NpcOption.Show },
            { spellId = 194117, name = "Stoneskin Totem", icon = 383017, default = addon.NpcOption.Show },
            { spellId = 5923, name = "Poison Cleansing Totem", icon = 383013, default = addon.NpcOption.Show },
            { spellId = 194118, name = "Tranquil Air Totem", icon = 383019, default = addon.NpcOption.Show },
            { spellId = 225409, name = "Surging Totem", icon = 444995, default = addon.NpcOption.Show },
            { spellId = 95061, name = "Greater Fire Elemental", icon = 198067, default = addon.NpcOption.Show },
            { spellId = 61029, name = "Primal Fire Elemental", icon = 198067, default = addon.NpcOption.Show },

            { spellId = 3527, name = "Healing Stream Totem", icon = 5394, default = addon.NpcOption.Hide },
            { spellId = 78001, name = "Cloudburst Totem", icon = 157153, default = addon.NpcOption.Hide },
            { spellId = 10467, name = "Mana Tide Totem", icon = 16191, default = addon.NpcOption.Hide },
            { spellId = 97285, name = "Wind Rush Totem", icon = 192077, default = addon.NpcOption.Hide },
            { spellId = 2630, name = "Earthbind Totem", icon = 2484, default = addon.NpcOption.Hide },
            { spellId = 97369, name = "Liquid Magma Totem", icon = 192222, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.WARLOCK,
        auras = {
            { spellId = 107100, name = "Observer", icon = 112869, default = addon.NpcOption.Highlight },
            { spellId = 135002, name = "Demonic Tyrant", icon = 265187, default = addon.NpcOption.Show },
            { spellId = 107024, name = "Fel Lord", icon = 212459, default = addon.NpcOption.Show },
            { spellId = 196111, name = "Pit Lord", icon = 138789, default = addon.NpcOption.Show },
            { spellId = 89, name = "Infernal", icon = 1122, default = addon.NpcOption.Show },

            -- Primary pets (so they don't get hidden in battlegrounds)
            { spellId = 416, name = "Imp", icon = 688, default = addon.NpcOption.Show },
            { spellId = 1860, name = "Voidwalker", icon = 697, default = addon.NpcOption.Show },
            { spellId = 417, name = "Felhunter", icon = 691, default = addon.NpcOption.Show },
            { spellId = 1863, name = "Sayaad", icon = 366222, default = addon.NpcOption.Show },
            { spellId = 17252, name = "Felguard", icon = 30146, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.WARRIOR,
        auras = {
            { spellId = 119052, name = "War Banner", icon = 236320, default = addon.NpcOption.Highlight },
        }
    },
};