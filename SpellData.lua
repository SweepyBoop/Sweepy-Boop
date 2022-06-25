local _, NS = ...

NS.spellCategory = {
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
local CC = NS.spellCategory.CC;
local OFFENSIVE = NS.spellCategory.OFFENSIVE;
local OFFENSIVE_AURA = NS.spellCategory.OFFENSIVE_AURA;
local OFFENSIVE_CD = NS.spellCategory.OFFENSIVE_CD;
local INTERRUPT = NS.spellCategory.INTERRUPT;
local DISPEL = NS.spellCategory.DISPEL;
local DEFENSIVE = NS.spellCategory.DEFENSIVE;

NS.specID = {
    BALANCE = 102,
    FERAL = 103,
    RET = 70,
};
local specID = NS.specID;

-- Events (and units) to track
NS.TRACK_PET = 0; -- SPELL_CAST_SUCCESS & pet GUID
NS.TRACK_PET_AURA = 1; -- SPELL_AURA_APPLIED & pet GUID, e.g., pet kicks
NS.TRACK_AURA = 2; -- SPELL_AURA_APPLIED, e.g., chastise
NS.TRACK_AURA_FADE = 3; -- SPELL_AURA_REMOVED, e.g., prot pally silence
NS.TRACK_UNIT = 4; -- UNIT_SPELLCAST_SUCCEEDED, e.g., meta (combat log triggered by auto proc meta)
local TRACK_PET = NS.TRACK_PET;
local TRACK_PET_AURA = NS.TRACK_PET_AURA;
local TRACK_AURA = NS.TRACK_AURA;
local TRACK_AURA_FADE = NS.TRACK_AURA_FADE;
local TRACK_UNIT = NS.TRACK_UNIT;

-- dispellable: buff can be dispelled, clear on early SPELL_AURA_REMOVED
-- charges: baseline charges
-- opt_charges: optionally multiple charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind

-- TODO: implement spec override, e.g., make outlaw rogue 90s blind baseline

-- Wthin the same aura must be the same motion type, e.g., cooldown only, glow and cooldown, glow only
-- Offensive spells are more complex motion types, others are cooldown only
-- Divide offensive to sub categories
NS.SpellData = {
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

NS.RESET_FULL = 0;
local RESET_FULL = NS.RESET_FULL;

NS.SpellResets = {
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

NS.ClassId = {
    Warrior = 1,
    Paladin = 2,
    DK = 6,
    Mage = 8,
    Druid = 11,
};
local classId = NS.ClassId;

NS.RaceID = {
    Human = 1,
    Undead = 5,
};
local raceID = NS.RaceID;

NS.BaselineSpells = {
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

-- https://github.com/wardz/DRList-1.0/blob/master/DRList-1.0/Spells.lua
NS.DiminishingReturnSpells = {
    [207167]  = "disorient",       -- Blinding Sleet
    [207685]  = "disorient",       -- Sigil of Misery
    [33786]   = "disorient",       -- Cyclone
    [1513]    = "disorient",       -- Scare Beast
    [31661]   = "disorient",       -- Dragon's Breath
    [198909]  = "disorient",       -- Song of Chi-ji
    [202274]  = "disorient",       -- Incendiary Brew
    [105421]  = "disorient",       -- Blinding Light
    [10326]   = "disorient",       -- Turn Evil
    [605]     = "disorient",       -- Mind Control
    [8122]    = "disorient",       -- Psychic Scream
    [226943]  = "disorient",       -- Mind Bomb
    [2094]    = "disorient",       -- Blind
    [118699]  = "disorient",       -- Fear
    [5484]    = "disorient",       -- Howl of Terror
    [261589]  = "disorient",       -- Seduction (Grimoire of Sacrifice)
    [6358]    = "disorient",       -- Seduction (Succubus)
    [5246]    = "disorient",       -- Intimidating Shout 1
    [316593]  = "disorient",       -- Intimidating Shout 2 (TODO: not sure which one is correct in 9.0.1)
    [316595]  = "disorient",       -- Intimidating Shout 3
    [331866]  = "disorient",       -- Agent of Chaos (Venthyr Covenant)

    [217832]  = "incapacitate",    -- Imprison
    [221527]  = "incapacitate",    -- Imprison (Honor talent)
    [2637]    = "incapacitate",    -- Hibernate
    [99]      = "incapacitate",    -- Incapacitating Roar
    [3355]    = "incapacitate",    -- Freezing Trap
    [203337]  = "incapacitate",    -- Freezing Trap (Honor talent)
    [213691]  = "incapacitate",    -- Scatter Shot
    [118]     = "incapacitate",    -- Polymorph
    [28271]   = "incapacitate",    -- Polymorph (Turtle)
    [28272]   = "incapacitate",    -- Polymorph (Pig)
    [61025]   = "incapacitate",    -- Polymorph (Snake)
    [61305]   = "incapacitate",    -- Polymorph (Black Cat)
    [61780]   = "incapacitate",    -- Polymorph (Turkey)
    [61721]   = "incapacitate",    -- Polymorph (Rabbit)
    [126819]  = "incapacitate",    -- Polymorph (Porcupine)
    [161353]  = "incapacitate",    -- Polymorph (Polar Bear Cub)
    [161354]  = "incapacitate",    -- Polymorph (Monkey)
    [161355]  = "incapacitate",    -- Polymorph (Penguin)
    [161372]  = "incapacitate",    -- Polymorph (Peacock)
    [277787]  = "incapacitate",    -- Polymorph (Baby Direhorn)
    [277792]  = "incapacitate",    -- Polymorph (Bumblebee)
    [82691]   = "incapacitate",    -- Ring of Frost
    [115078]  = "incapacitate",    -- Paralysis
    [20066]   = "incapacitate",    -- Repentance
    [9484]    = "incapacitate",    -- Shackle Undead
    [200196]  = "incapacitate",    -- Holy Word: Chastise
    [1776]    = "incapacitate",    -- Gouge
    [6770]    = "incapacitate",    -- Sap
    [51514]   = "incapacitate",    -- Hex
    [196942]  = "incapacitate",    -- Hex (Voodoo Totem)
    [210873]  = "incapacitate",    -- Hex (Raptor)
    [211004]  = "incapacitate",    -- Hex (Spider)
    [211010]  = "incapacitate",    -- Hex (Snake)
    [211015]  = "incapacitate",    -- Hex (Cockroach)
    [269352]  = "incapacitate",    -- Hex (Skeletal Hatchling)
    [309328]  = "incapacitate",    -- Hex (Living Honey)
    [277778]  = "incapacitate",    -- Hex (Zandalari Tendonripper)
    [277784]  = "incapacitate",    -- Hex (Wicker Mongrel)
    [197214]  = "incapacitate",    -- Sundering
    [710]     = "incapacitate",    -- Banish
    [6789]    = "incapacitate",    -- Mortal Coil
    [107079]  = "incapacitate",    -- Quaking Palm (Pandaren racial)

    [47476]   = "silence",         -- Strangulate
    [204490]  = "silence",         -- Sigil of Silence
--      [78675]   = "silence",         -- Solar Beam (doesn't seem to DR)
    [202933]  = "silence",         -- Spider Sting
    [356727]  = "silence",         -- Spider Venom
    [217824]  = "silence",         -- Shield of Virtue
    [15487]   = "silence",         -- Silence
    [1330]    = "silence",         -- Garrote
    [196364]  = "silence",         -- Unstable Affliction Silence Effect

    [210141]  = "stun",            -- Zombie Explosion
    [334693]  = "stun",            -- Absolute Zero (Breath of Sindragosa)
    [108194]  = "stun",            -- Asphyxiate (Unholy)
    [221562]  = "stun",            -- Asphyxiate (Blood)
    [91800]   = "stun",            -- Gnaw (Ghoul)
    [91797]   = "stun",            -- Monstrous Blow (Mutated Ghoul)
    [287254]  = "stun",            -- Dead of Winter
    [179057]  = "stun",            -- Chaos Nova
    [205630]  = "stun",            -- Illidan's Grasp (Primary effect)
    [208618]  = "stun",            -- Illidan's Grasp (Secondary effect)
    [211881]  = "stun",            -- Fel Eruption
    [200166]  = "stun",            -- Metamorphosis (PvE stun effect)
    [203123]  = "stun",            -- Maim
    [163505]  = "stun",            -- Rake (Prowl)
    [5211]    = "stun",            -- Mighty Bash
    [202244]  = "stun",            -- Overrun
    [325321]  = "stun",            -- Wild Hunt's Charge
    [357021]  = "stun",            -- Consecutive Concussion
    [24394]   = "stun",            -- Intimidation
    [119381]  = "stun",            -- Leg Sweep
    [202346]  = "stun",            -- Double Barrel
    [853]     = "stun",            -- Hammer of Justice
    [255941]  = "stun",            -- Wake of Ashes
    [64044]   = "stun",            -- Psychic Horror
    [200200]  = "stun",            -- Holy Word: Chastise Censure
    [1833]    = "stun",            -- Cheap Shot
    [408]     = "stun",            -- Kidney Shot
    [118905]  = "stun",            -- Static Charge (Capacitor Totem)
    [118345]  = "stun",            -- Pulverize (Primal Earth Elemental)
    [305485]  = "stun",            -- Lightning Lasso
    [89766]   = "stun",            -- Axe Toss
    [171017]  = "stun",            -- Meteor Strike (Infernal)
    [171018]  = "stun",            -- Meteor Strike (Abyssal)
    [30283]   = "stun",            -- Shadowfury
    [46968]   = "stun",            -- Shockwave
    [132168]  = "stun",            -- Shockwave (Protection)
    [145047]  = "stun",            -- Shockwave (Proving Grounds PvE)
    [132169]  = "stun",            -- Storm Bolt
    [199085]  = "stun",            -- Warpath
    [20549]   = "stun",            -- War Stomp (Tauren)
    [255723]  = "stun",            -- Bull Rush (Highmountain Tauren)
    [287712]  = "stun",            -- Haymaker (Kul Tiran)

    [204085]  = "root",            -- Deathchill (Chains of Ice)
    [233395]  = "root",            -- Deathchill (Remorseless Winter)
    [339]     = "root",            -- Entangling Roots
    [170855]  = "root",            -- Entangling Roots (Nature's Grasp)
    [102359]  = "root",            -- Mass Entanglement
    [117526]  = "root",            -- Binding Shot
    [162480]  = "root",            -- Steel Trap
    [273909]  = "root",            -- Steelclaw Trap
--      [190927]  = "root_harpoon",    -- Harpoon (TODO: confirm)
    [212638]  = "root",            -- Tracker's Net
    [201158]  = "root",            -- Super Sticky Tar
    [122]     = "root",            -- Frost Nova
    [33395]   = "root",            -- Freeze
    [198121]  = "root",            -- Frostbite
    [342375]  = "root",            -- Tormenting Backlash (Torghast PvE)
    [233582]  = "root",            -- Entrenched in Flame
    [116706]  = "root",            -- Disable
    [324382]  = "root",            -- Clash
    [64695]   = "root",            -- Earthgrab (Totem effect)
    [285515]  = "root",            -- Surge of Power
    [39965]   = "root",            -- Frost Grenade (Item)
    [75148]   = "root",            -- Embersilk Net (Item)
    [55536]   = "root",            -- Frostweave Net (Item)
    [268966]  = "root",            -- Hooked Deep Sea Net (Item)

    [209749]  = "disarm",          -- Faerie Swarm (Balance Honor Talent)
    [207777]  = "disarm",          -- Dismantle
    [233759]  = "disarm",          -- Grapple Weapon
    [236077]  = "disarm",          -- Disarm

    [56222]   = "taunt",           -- Dark Command
    [51399]   = "taunt",           -- Death Grip
    [185245]  = "taunt",           -- Torment
    [6795]    = "taunt",           -- Growl (Druid)
    [2649]    = "taunt",           -- Growl (Hunter Pet) (TODO: confirm)
    [20736]   = "taunt",           -- Distracting Shot
    [116189]  = "taunt",           -- Provoke
    [118635]  = "taunt",           -- Provoke (Black Ox Statue)
    [196727]  = "taunt",           -- Provoke (Niuzao)
    [204079]  = "taunt",           -- Final Stand
    [62124]   = "taunt",           -- Hand of Reckoning
    [17735]   = "taunt",           -- Suffering (Voidwalker) (TODO: confirm)
    [355]     = "taunt",           -- Taunt

    -- Experimental
    [108199]  = "knockback",        -- Gorefiend's Grasp
    [202249]  = "knockback",        -- Overrun
    [61391]   = "knockback",        -- Typhoon
    [102793]  = "knockback",        -- Ursol's Vortex
    [186387]  = "knockback",        -- Bursting Shot
    [236777]  = "knockback",        -- Hi-Explosive Trap
    [157981]  = "knockback",        -- Blast Wave
    [237371]  = "knockback",        -- Ring of Peace
    [204263]  = "knockback",        -- Shining Force
    [51490]   = "knockback",        -- Thunderstorm
--      [287712]  = "knockback",        -- Haywire (Kul'Tiran Racial)
};