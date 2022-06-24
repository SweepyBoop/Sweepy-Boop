BoopSpellData = {};

BoopSpellData.SpellCategory = {
    CC = 1;
    -- OFFENSIVE spells have 3 different motion types (glow then cooldown, glow only, cooldown only)
    -- Different from track_* which specifies events to track
    OFFENSIVE = 2;
    OFFENSIVE_AURA = 3;
    OFFENSIVE_CD = 4;
    INTERRUPT = 5;
    DISPEL = 6;
    DEFENSIVE = 7; -- If trackType ~= TRACK_UNIT, we need to find its unitId to put in allstates, so that it can be attached to the correct arena frame.
}
local CC = BoopSpellData.SpellCategory.CC;
local OFFENSIVE = BoopSpellData.SpellCategory.OFFENSIVE;
local OFFENSIVE_AURA = BoopSpellData.SpellCategory.OFFENSIVE_AURA;
local OFFENSIVE_CD = BoopSpellData.SpellCategory.OFFENSIVE_CD;
local INTERRUPT = BoopSpellData.SpellCategory.INTERRUPT;
local DISPEL = BoopSpellData.SpellCategory.DISPEL;
local DEFENSIVE = BoopSpellData.SpellCategory.DEFENSIVE;

BoopSpellData.specID = {
    BALANCE = 102,
    FERAL = 103,
    RET = 70,
};
local specID = BoopSpellData.specID;

-- Events (and units) to track
BoopSpellData.TRACK_PET = 0; -- SPELL_CAST_SUCCESS & pet GUID
BoopSpellData.TRACK_PET_AURA = 1; -- SPELL_AURA_APPLIED & pet GUID, e.g., pet kicks
BoopSpellData.TRACK_AURA = 2; -- SPELL_AURA_APPLIED, e.g., chastise
BoopSpellData.TRACK_AURA_FADE = 3; -- SPELL_AURA_REMOVED, e.g., prot pally silence
BoopSpellData.TRACK_UNIT = 4; -- UNIT_SPELLCAST_SUCCEEDED, e.g., meta (combat log triggered by auto proc meta)
local TRACK_PET = BoopSpellData.TRACK_PET;
local TRACK_PET_AURA = BoopSpellData.TRACK_PET_AURA;
local TRACK_AURA = BoopSpellData.TRACK_AURA;
local TRACK_AURA_FADE = BoopSpellData.TRACK_AURA_FADE;
local TRACK_UNIT = BoopSpellData.TRACK_UNIT;

-- dispellable: buff can be dispelled, clear on early SPELL_AURA_REMOVED
-- charges: baseline charges
-- opt_charges: optionally multiple charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind

-- TODO: implement spec override, e.g., make outlaw rogue 90s blind baseline

-- Wthin the same aura must be the same motion type, e.g., cooldown only, glow and cooldown, glow only
-- Offensive spells are more complex motion types, others are cooldown only
-- Divide offensive to sub categories
BoopSpellData.SpellData = {
    -- General
    -- Offensive
    -- Resonator
    [363481] = {
        category = OFFENSIVE,
        duration = 4,
        cooldown = 120,
        index = 1,
    },

    -- DK
    -- Crowd Control
    -- Strangulate
    [47476] = {
        category = CC,
        cooldown = 60,
    },
    -- Grip (icon is very close to Asphyxiate, so do not track that one...)
    [49576] = {
        category = CC,
        cooldown = 25,
        opt_charges = true,
    },
    -- Slappy Hands
    [315443] = {
        category = CC,
        cooldown = 120,
    },
    -- Offensive (Unholy)
    -- Unholy Assult
    [207289] = {
        category = OFFENSIVE_AURA,
        duration = 12,
    },
    -- Raise Abom
    [288853] = {
        category = OFFENSIVE_AURA,
        duration = 25,
    },
    -- Apoc
    [275699] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Offensive (Frost)
    -- Pillar
    [51271] = {
        category = OFFENSIVE_AURA,
        duration = 12,
    },
    -- Empower
    [47568] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Chill Streak
    [305392] = {
        category = OFFENSIVE_AURA,
        duration = 4,
        index = 2,
        sound = true,
    },
    -- Interrupt
    [47528] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Shambling Rush
    [91807] = {
        category = INTERRUPT,
        cooldown = 30,
        trackType = TRACK_PET_AURA,
    },

    -- DH
    -- CC
    -- Fel Eruption
    [211881] = {
        category = CC,
        cooldown = 30,
    },
    -- Imprison
    [221527] = {
        category = CC,
        cooldown = 45,
    },
    -- Offensive
    -- The Hunt
    [323639] = {
        category = OFFENSIVE_CD,
        cooldown = 90,
        index = 1,
    },
    -- Meta
    [191427] = {
        category = OFFENSIVE_AURA,
        trackType = TRACK_UNIT,
        duration = 30,
    },
    -- Demon Soul
    [347765] = {
        category = OFFENSIVE_AURA,
        duration = 31, -- 20 baseline, 11 from soulbind
    },
    -- Interrupt
    [183752] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Netherwalk
    [196555] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 180,
    },

    -- Druid
    -- CC
    -- Mighty Bash
    [5211] = {
        category = CC,
        cooldown = 48,
    },
    -- Solar Beam
    [78675] = {
        category = CC,
        cooldown = 60,
    },
    -- Maim
    [22570] = {
        category = CC,
        cooldown = 20,
    },
    -- Incap Roar
    [99] = {
        category = CC,
        cooldown = 30,
    },
    -- Offensive
    -- Berserk
    [106951] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- King of the Jungle
    [102543] = {
        category = OFFENSIVE_AURA,
        duration = 30,
    },
    -- Celestial Alignment
    [194223] = {
        category = OFFENSIVE_AURA,
        duration = 30,
    },
    -- Incarnation
    [102560] = {
        category = OFFENSIVE_AURA,
        duration = 40,
    },
    -- Kindred Spirits
    [338142] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Convoke
    [323764] = {
        category = OFFENSIVE_CD,
        cooldown = 60,
        spec = { specID.BALANCE, specID.FERAL },
        index = 1,
    },
    -- Interrupt
    -- Skull Bash
    [106839] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Dispel
    -- Nature's Cure
    [88423] = {
        category = DISPEL,
        cooldown = 8,
    },
    -- Defensive
    -- Ironbark
    [102342] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 90,
    },
    -- Survival Instincts
    [61336] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 180,
    },

    -- Hunter
    -- CC
    -- Intimidation
    [19577] = {
        category = CC,
        cooldown = 60,
    },
    -- Freezing Trap
    [187650] = {
        category = CC,
        cooldown = 25,
    },
    -- Offensive
    -- Bestial Wrath
    [19574] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Coordinated Assult
    [266779] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Trueshot
    [288613] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Interrupt
    -- Feign Death
    [5348] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Muzzle
    [187707] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Counter Shot
    [147362] = {
        category = INTERRUPT,
        cooldown = 24,
    },
    -- Defensive
    -- Turtle
    [186265] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 180,
    },

    -- Mage
    -- CC
    -- Dragon's Breath
    [31661] = {
        category = CC,
        cooldown = 20,
    },
    -- Ring of Frost
    [113724] = {
        category = CC,
        cooldown = 45,
    },
    -- Offensive
    -- Necrolord
    [324220] = {
        category = OFFENSIVE_AURA,
        duration = 40,
        index = 2,
    },
    -- Icy Veins
    [12472] = {
        category = OFFENSIVE_AURA,
        duration = 20,
        dispellable = true,
    },
    -- Ice Form
    [198144] = {
        category = OFFENSIVE_AURA,
        duration = 12,
        dispellable = true,
    },
    -- Arcane Power
    [12042] = {
        category = OFFENSIVE_AURA,
        duration = 10,
        dispellable = true,
    },
    -- Interrupt
    -- CS
    [2139] = {
        category = INTERRUPT,
        cooldown = 24,
    },
    -- Defensive
    -- Cauterize
    [87024] = {
        category = DEFENSIVE,
        cooldown = 300,
        trackType = TRACK_AURA,
    },

    -- Monk
    -- CC
    -- Paralysis
    [115078] = {
        category = CC,
        cooldown = 30,
    },
    -- Leg Sweep
    [119381] = {
        category = CC,
        cooldown = 60,
    },
    -- RoP
    [116844] = {
        category = CC,
        cooldown = 45,
    },
    -- Offensive
    -- Images (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        category = OFFENSIVE,
        duration = 15,
        cooldown = 90,
        charges = true,
    },
    -- Serenity
    [152173] = {
        category = OFFENSIVE,
        duration = 12,
        cooldown = 90,
    },
    -- Xuen
    [123904] = {
        category = OFFENSIVE_AURA,
        duration = 24,
    },
    -- Bonedust Brew
    [325216] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Interrupt
    -- Spear hand Strike
    [116705] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
    -- Karma
    [122470] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 90,
    },
    -- Cacoon
    [116849] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 120,
    },
    -- Dispel
    -- Detox
    [115450] = {
        category = DISPEL,
        cooldown = 8,
    },

    -- Paladin
    -- CC
    -- Silence
    [215652] = {
        category = CC,
        cooldown = 45,
        trackType = TRACK_AURA_FADE,
    },
    -- Blind
    [115750] = {
        category = CC,
        cooldown = 90,
    };
    -- HOJ has special calculation based on holy power spent and is made into a seperate table
    -- Offensive
    -- Wing
    [31884] = {
        category = OFFENSIVE,
        duration = 20,
        cooldown = 120,
        sound = true,
        index = 1,
        spec = { specID.RET },
    },
    -- Divine Toll
    [304971] = {
        category = OFFENSIVE_CD,
        spec = { specID.RET },
        cooldown = 50,
    },
    -- Interrupt
    -- Rebuke
    [96231] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Dispel
    -- Cleanse
    [4987] = {
        category = DISPEL,
        cooldown = 8,
    },
    -- Sanct
    [210256] = {
        category = DISPEL,
        cooldown = 45,
    },

    -- Priest
    -- CC
    -- Chastise
    [200196] = {
        category = CC,
        cooldown = 30,
        trackType = TRACK_AURA,
    },
    -- Chastise (Censure)
    [200200] = {
        category = CC,
        cooldown = 30,
        trackType = TRACK_AURA,
    },
    -- Fear
    [8122] = {
        category = CC,
        cooldown = 60,
        opt_lower_cooldown = 30,
    },
    -- Stun
    [64044] = {
        category = CC,
        cooldown = 45,
    },
    -- Silence
    [15487] = {
        category = CC,
        cooldown = 45,
        opt_lower_cooldown = 30,
    },
    -- Mind Bomb
    [205369] = {
        category = CC,
        cooldown = 30,
    },
    -- Offensive
    -- Mindgames
    [323673] = {
        category = OFFENSIVE_CD,
        cooldown = 45,
    },
    -- Dispel
    -- MD
    [32375] = {
        category = DISPEL,
        cooldown = 45,
    },
    -- Purify
    [527] = {
        category = DISPEL,
        cooldown = 8,
        opt_charges = true,
    },
    -- Defensive
    -- PS
    [33206] = {
        category = DEFENSIVE,
        cooldown = 180,
    },
    -- GS
    [47788] = {
        category = DEFENSIVE,
        cooldown = 60, -- Assume it didn't proc
    },
    -- Dispersion
    [47585] = {
        category = DEFENSIVE,
        cooldown = 90, -- Assume playing short dispersion
    },

    -- Rogue
    -- CC
    -- Blind
    [2094] = {
        category = CC,
        cooldown = 120,
        opt_lower_cooldown = 90,
    },
    -- Kidney
    [408] = {
        category = CC,
        cooldown = 20,
    },
    -- Smoke Bomb
    [212182] = {
        category = CC,
        cooldown = 180,
    },
    -- Offensive
    -- Shadow Blades
    [121471] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Echoing
    [323547] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Adrenaline Rush
    [13750] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Flag
    [323654] = {
        category = OFFENSIVE,
        duration = 12,
        cooldown = 90,
        index = 1,
    },
    -- Sepsis
    [328305] = {
        category = OFFENSIVE,
        duration = 10,
        cooldown = 90,
        index = 1,
    },
    -- Interrupt
    -- Kick
    [1766] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
    -- Evasion
    [5277] = {
        category = DEFENSIVE,
        cooldown = 120,
    },
    -- Cloak
    [31224] = {
        category = DEFENSIVE,
        cooldown = 120,
    },
    -- Vanish
    [1856] = {
        category = DEFENSIVE,
        cooldown = 120,
    },

    -- Shaman
    -- Offensive
    -- Ascendance
    [114051] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Chain Harvest
    [320674] = {
        category = OFFENSIVE_CD,
        cooldown = 90,
    },
    -- Doom Winds
    [335903] = {
        category = OFFENSIVE,
        trackType = TRACK_AURA,
        duration = 12,
        cooldown = 60,
        index = 2,
    },
    -- Stormkeeper
    [191634] = {
        category = OFFENSIVE_AURA,
        duration = 15,
        dispellable = true,
    },
    -- Echoing Shock
    [320125] = {
        category = OFFENSIVE_AURA,
        duration = 5, -- Normally chained with another instant spell, give 5s reaction time for myself
    },
    -- Defensive
    -- Astral Shift
    [108271] = {
        category = DEFENSIVE,
        cooldown = 90,
    },
    -- Spirit Link Totem
    [98008] = {
        category = DEFENSIVE,
        cooldown = 180,
    },
    -- Ethereal Form
    [210918] = {
        category = DEFENSIVE,
        cooldown = 45,
    },
    -- Interrupt
    -- Grounding Totem
    [204336] = {
        category = INTERRUPT,
        cooldown = 30,
    },
    -- Wind Shear
    [57994] = {
        category = INTERRUPT,
        cooldown = 12,
    },
    -- Dispel
    -- Purify Spirit
    [77130] = {
        category = DISPEL,
        cooldown = 8,
    },

    -- Warlock
    -- CC
    -- Mortal Coil
    [6789] = {
        category = CC,
        cooldown = 45,
    },
    -- Howl of Terror
    [5484] = {
        category = CC,
        cooldown = 40,
    },
    -- Offensive
    -- Dark Soul: Misery
    [113860] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Summon Darkglare
    [205180] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Dark Soul: Instability
    [113858] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Summon Infernal
    [1122] = {
        category = OFFENSIVE_AURA,
        duration = 30,
    },
    -- Summon Demonic Tyrant
    [265187] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Interrupt
    -- Call Felhunter
    [212619] = {
        category = INTERRUPT,
        cooldown = 24,
    },
    -- Spell Lock
    [19647] = { -- Found by "if sourceGUID == UnitGUID("pet") then print(spellID) print(subEvent) end"
        category = INTERRUPT,
        cooldown = 24,
        trackType = TRACK_PET,
    },
    -- Nether Ward
    [212295] = {
        category = INTERRUPT,
        cooldown = 24,
    },
    -- Defensive
    -- Unending Resolve
    [104773] = {
        category = DEFENSIVE,
        cooldown = 180,
    },

    -- Warrior
    -- CC
    -- Storm Bolt
    [107570] = {
        category = CC,
        cooldown = 30,
    },
    -- Intimidating Shout
    [5246] = {
        category = CC,
        cooldown = 90,
    },
    -- Spear of Bastion
    [307865] = {
        category = CC,
        cooldown = 50,
    },
    -- Offensive
    -- Banner
    [324143] = {
        category = OFFENSIVE,
        duration = 15,
        cooldown = 120,
        index = 1,
    },
    -- Warbreaker
    [262161] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Smash
    [167105] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Avatar
    [107574] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Reckless
    [1719] = {
        category = OFFENSIVE_AURA,
        cooldown = 90,
        duration = 12,
    },
    -- Siege Breaker
    [280772] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Interrupt
    -- Pummel
    [6552] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Spell Reflect
    [23920] = {
        category = INTERRUPT,
        cooldown = 25,
    },
    -- Charge
    [100] = {
        category = INTERRUPT,
        cooldown = 20,
        opt_charges = true,
        opt_lower_cooldown = 17,
    },
    -- Defensive
    -- Die by the Sword
    [118038] = {
        category = DEFENSIVE,
        cooldown = 80, -- Conduit
    },
    -- Enraged Regeneration
    [184364] = {
        category = DEFENSIVE,
        cooldown = 80, -- Conduit
    },
};

BoopSpellData.RESET_FULL = 0;
local RESET_FULL = BoopSpellData.RESET_FULL;

BoopSpellData.SpellResets = {
    -- Shifting Power
    [314791] = {
        [31661] = 10, -- Dragon's Breath
        [113724] = 10, -- Ring of Frost
        [2139] = 10, -- Counterspell
        [45438] = 10, -- Ice Block
    },
    -- Cold Snap
    [235219] = {
        [45438] = RESET_FULL,
    },

    -- Apotheosis
    [200183] = {
        [200196] = RESET_FULL,
        [200200] = RESET_FULL,
    },

    -- Vanish (Memory of Invigorating Shadowdust)
    [1856] = {
        [2094] = 20, -- Blind
        [408] = 20, -- Kidney
        [212182] = 20, -- Smoke Bomb
    },
};

BoopSpellData.ClassId = {
    Warrior = 1,
    Paladin = 2,
    DK = 6,
    Mage = 8,
    Druid = 11,
};
local classId = BoopSpellData.ClassId;

BoopSpellData.RaceID = {
    Human = 1,
    Undead = 5,
};
local raceID = BoopSpellData.RaceID;

BoopSpellData.BaselineSpells = {
    -- Stun breakers
    -- Human racial
    [59752] = {
        race = raceID.Human,
        cooldown = 180,
        index = 1,
    },
    -- IBF
    [48792] = {
        class = classId.DK,
        cooldown = 140,
        index = 2,
    },
    -- Bubble
    [642] = {
        class = classId.Paladin,
        cooldown = 210,
        index = 2,
    },
    -- BOP
    [1022] = {
        class = classId.Paladin,
        cooldown = 300,
        opt_charges = true,
        index = 2,
    },
    -- Block
    [45438] = {
        class = classId.Mage,
        cooldown = 240,
        index = 2,
    },

    -- Fear breakers
    -- Undead
    [7744] = {
        race = raceID.Undead,
        cooldown = 120,
        index = 3,
    },
    -- Lich
    [49039] = {
        class = classId.DK,
        cooldown = 120,
        index = 4,
    },
    -- Berserker
    [18499] = {
        class = classId.Warrior,
        cooldown = 60,
        index = 4,
    },
};