local _, NS = ...;

local SPELLCATEGORY = NS.SPELLCATEGORY;
local POWERTYPE = Enum.PowerType;

NS.cooldownSpells = {
    -- General

    -- DK
    -- Interrupt
    -- Mind Freeze
    [47528] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.INTERRUPT,
        cooldown = 15,
    },
    -- Shambling Rush
    [91807] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.INTERRUPT,
        cooldown = 30,
    },
    -- Disrupt
    -- Death Grip
    [49576] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.DISRUPT,
        cooldown = 25,
        charges = true,
    },
    -- Crowd Control
    -- Strangulate
    [47476] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.CROWDCONTROL,
        cooldown = 60,
    },
    -- Blinding Sleet
    [207167] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.CROWDCONTROL,
        cooldown = 60,
    },
    -- Asphyxiate
    [221562] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.CROWDCONTROL,
        cooldown = 60,
    },
    -- Defensive
    -- Icebound Fortitude
    [48792] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.DEFENSIVE,
        cooldown = 120,
        index = 1,
    },
    -- Lichborne
    [49039] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.DEFENSIVE,
        cooldown = 120,
        index = 2,
    },


    -- Demon Hunter
    -- Interrupt
    -- Disrupt
    [183752] = {
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
    -- Netherwalk
    [196555] = {
        cooldown = 180, 
        class = "DEMONHUNTER", 
        category = SPELLCATEGORY.DEFENSIVE
    },
    -- Crowd Control
    -- Imprison
    [217832] = {
        cooldown = 45, 
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Imprison (Detainment)
    [221527] = {
        cooldown = 45, 
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.CROWDCONTROL,
    },

    -- Priest
    -- Dispel
    -- Mass Dispel
    [32375] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.DISPEL,
    },
    -- Purify
    [527] = {
        cooldown = 8,
        class = "PRIEST",
        category = SPELLCATEGORY.DISPEL,
        opt_charges = true,
    },
    -- Crowd Control
    -- Psychic Scream
    [8122] = {
        cooldown = 30,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Holy Word: Chastise
    [88625] = {
        cooldown = 60,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Silence
    [15487] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
        opt_lower_cooldown = 30,
    },
    -- Psychic Horror
    [64044] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Defensive
    -- Void Shift
    [108968] = {
        cooldown = 300,
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Pain Suppression
    [33206] = {
        cooldown = 180,
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Guardian Spirit
    [47788] = {
        cooldown = 60, -- Assume it didn't proc
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Dispersion
    [47585] = {
        cooldown = 90,
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Disrupt
    -- Holy Ward
    [213610] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.DISRUPT, 
    },

    -- Paladin
    -- Defensive
    -- Divine Shield
    [642] = {
        cooldown = 210,
        class = "PALADIN",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Blessing of Protection
    [1022] = {
        cooldown = 240,
        class = "PALADIN",
        category = SPELLCATEGORY.DEFENSIVE,
        opt_charges = true,
    },
    -- Crowd Control
    -- Hammer of Justice
    [853] = {
        cooldown = 60,
        class = "PALADIN",
        category = SPELLCATEGORY.CROWDCONTROL,
        reduce_power_type = POWERTYPE.HolyPower;
        reduce_amount = 2, -- Each holy power spent reduces the cooldown by 2 sec.
    },
    -- Blinding Light
    [115750] = {
        cooldown = 90,
        class = "PALADIN",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Shield of Virtue
    [215652] = {
        cooldown = 45,
        class = "PALADIN",
        category = SPELLCATEGORY.CROWDCONTROL,
        trackEvent = "SPELL_AURA_REMOVED",
    },
    -- Interrupt
    -- Rebuke
    [96231] = {
        cooldown = 15,
        class = "PALADIN",
        category = SPELLCATEGORY.INTERRUPT,
    },

    
};

if NS.isTestMode then
    local testCategory = SPELLCATEGORY.INTERRUPT;
    -- Test
    -- Mark of the Wild
    NS.cooldownSpells[1126] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 30,
        sound = true,
    };
    -- Regrowth
    NS.cooldownSpells[8936] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 10,
    };
    -- Rejuv
    NS.cooldownSpells[774] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 45,
    };
    -- Wild Growth
    NS.cooldownSpells[48438] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 7,
    };
end

NS.cooldownResets = {

};