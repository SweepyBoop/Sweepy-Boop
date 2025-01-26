local _, addon = ...;

addon.AuraList = { -- Use table with consecutive indexes to preserve the order
    {
        classID = addon.CLASSID.DEATHKNIGHT,
        auras = {
            { npcID = 106041, name = "Reanimation", icon = 210128, default = addon.NpcOption.Highlight }, -- stuns for 3s and takes 10% HP
            { npcID = 149555, name = "Raise Abomination", icon = 455395, default = addon.NpcOption.Show },
            { npcID = 26125, name = "Raise Dead", icon = 46585, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.EVOKER,
        auras = {
            { npcID = 185800, name = "Past Self", icon = 371869, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.HUNTER,
        auras = {
            { npcID = 105419, name = "Dire Beast: Basilisk", icon = 205691, default = addon.NpcOption.Show },

            -- Hunter pets all have the same npcID, add here so they don't get hidden in battlegrounds
            { npcID = addon.HUNTERPET, name = "Pet", icon = 267116, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.MAGE,
        auras = {
            { npcID = 208441, name = "Water Elemental", icon = 12472, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.MONK,
        auras = {
            { npcID = 63508, name = "Xuen", icon = 123904, default = addon.NpcOption.Hide },
            { npcID = 69791, name = "Storm, Earth and Fire", icon = 137639, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.PALADIN,
        auras = {
            { npcID = 114565, name = "Guardian of the Forgotten Queen", icon = 228049, default = addon.NpcOption.Highlight },
        }
    },
    {
        classID = addon.CLASSID.PRIEST,
        auras = {
            { npcID = 101398, name = "Psyfiend", icon = 199824, default = addon.NpcOption.Highlight },
            { npcID = 225672, name = "Shadow", icon = 8122, default = addon.NpcOption.Highlight }, -- casts fear
            { npcID = 224466, name = "Voidwraith", icon = 451234, default = addon.NpcOption.Show },
            { npcID = 62982, name = "Mindbender", icon = 123040, default = addon.NpcOption.Show },
            { npcID = 19668, name = "Shadowfiend", icon = 34433, default = addon.NpcOption.Show },
            { npcID = 65282, name = "Void Tendrils", icon = 108920, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.SHAMAN,
        auras = {
            { npcID = 5925, name = "Grounding Totem", icon = 204336, default = addon.NpcOption.Highlight },
            { npcID = 53006, name = "Spirit Link Totem", icon = 98008, default = addon.NpcOption.Highlight },
            { npcID = 5913, name = "Tremor Totem", icon = 8143, default = addon.NpcOption.Highlight },
            { npcID = 104818, name = "Ancestral Protection Totem", icon = 207399, default = addon.NpcOption.Highlight },
            { npcID = 61245, name = "Capacitor Totem", icon = 192058, default = addon.NpcOption.Highlight },
            { npcID = 105451, name = "Counterstrike Totem", icon = 204331, default = addon.NpcOption.Highlight },
            { npcID = 59764, name = "Healing Tide Totem", icon = 108280, default = addon.NpcOption.Highlight },

            { npcID = 179867, name = "Static Field Totem", icon = 355580, default = addon.NpcOption.Show },
            { npcID = 59712, name = "Stone Bulwark Totem", icon = 108270, default = addon.NpcOption.Show }, -- hard to kill
            { npcID = 100943, name = "Earthen Wall Totem", icon = 198838, default = addon.NpcOption.Show }, -- hard to kill, just try to fight outside of its range
            { npcID = 60561, name = "Earthgrab Totem", icon = 51485, default = addon.NpcOption.Show }, -- gets players out of stealth
            { npcID = 105427, name = "Totem of Wrath", icon = 204330, default = addon.NpcOption.Show },
            { npcID = 194117, name = "Stoneskin Totem", icon = 383017, default = addon.NpcOption.Show },
            { npcID = 5923, name = "Poison Cleansing Totem", icon = 383013, default = addon.NpcOption.Show },
            { npcID = 194118, name = "Tranquil Air Totem", icon = 383019, default = addon.NpcOption.Show },
            { npcID = 225409, name = "Surging Totem", icon = 444995, default = addon.NpcOption.Show },
            { npcID = 95061, name = "Greater Fire Elemental", icon = 198067, default = addon.NpcOption.Show },
            { npcID = 61029, name = "Primal Fire Elemental", icon = 198067, default = addon.NpcOption.Show },

            { npcID = 3527, name = "Healing Stream Totem", icon = 5394, default = addon.NpcOption.Hide },
            { npcID = 78001, name = "Cloudburst Totem", icon = 157153, default = addon.NpcOption.Hide },
            { npcID = 10467, name = "Mana Tide Totem", icon = 16191, default = addon.NpcOption.Hide },
            { npcID = 97285, name = "Wind Rush Totem", icon = 192077, default = addon.NpcOption.Hide },
            { npcID = 2630, name = "Earthbind Totem", icon = 2484, default = addon.NpcOption.Hide },
            { npcID = 97369, name = "Liquid Magma Totem", icon = 192222, default = addon.NpcOption.Hide },
        }
    },
    {
        classID = addon.CLASSID.WARLOCK,
        auras = {
            { npcID = 107100, name = "Observer", icon = 112869, default = addon.NpcOption.Highlight },
            { npcID = 135002, name = "Demonic Tyrant", icon = 265187, default = addon.NpcOption.Show },
            { npcID = 107024, name = "Fel Lord", icon = 212459, default = addon.NpcOption.Show },
            { npcID = 196111, name = "Pit Lord", icon = 138789, default = addon.NpcOption.Show },
            { npcID = 89, name = "Infernal", icon = 1122, default = addon.NpcOption.Show },

            -- Primary pets (so they don't get hidden in battlegrounds)
            { npcID = 416, name = "Imp", icon = 688, default = addon.NpcOption.Show },
            { npcID = 1860, name = "Voidwalker", icon = 697, default = addon.NpcOption.Show },
            { npcID = 417, name = "Felhunter", icon = 691, default = addon.NpcOption.Show },
            { npcID = 1863, name = "Sayaad", icon = 366222, default = addon.NpcOption.Show },
            { npcID = 17252, name = "Felguard", icon = 30146, default = addon.NpcOption.Show },
        }
    },
    {
        classID = addon.CLASSID.WARRIOR,
        auras = {
            { npcID = 119052, name = "War Banner", icon = 236320, default = addon.NpcOption.Highlight },
        }
    },
};