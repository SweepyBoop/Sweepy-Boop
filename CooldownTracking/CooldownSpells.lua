local _, NS = ...;

local SPELLCATEGORY = NS.SPELLCATEGORY;

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

};

NS.cooldownResets = {

};