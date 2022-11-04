local _, NS = ...

NS.isTestMode = true;

NS.spellCategory = {
    CC = 1,
    -- OFFENSIVE spells have 3 different motion types (glow then cooldown, glow only, cooldown only)
    -- Different from track_* which specifies events to track
    OFFENSIVE = 2,
    OFFENSIVE_AURA = 3,
    OFFENSIVE_CD = 4,
    OFFENSIVE_PET = 5, -- e.g., Psyfiend, Vesper Totem (match with NPC ID instead of spellID).
    INTERRUPT = 6,
    DISPEL = 7,
    DEFENSIVE = 8, -- If trackType ~= TRACK_UNIT, we need to find its unitId to put in allstates, so that it can be attached to the correct arena frame.
    OFFENSIVE_SPECIAL = 9,
}
local CC = NS.spellCategory.CC;
local OFFENSIVE = NS.spellCategory.OFFENSIVE;
local OFFENSIVE_AURA = NS.spellCategory.OFFENSIVE_AURA;
local OFFENSIVE_CD = NS.spellCategory.OFFENSIVE_CD;
local OFFENSIVE_PET = NS.OFFENSIVE_PET;
local INTERRUPT = NS.spellCategory.INTERRUPT;
local DISPEL = NS.spellCategory.DISPEL;
local DEFENSIVE = NS.spellCategory.DEFENSIVE;
local OFFENSIVE_SPECIAL = NS.spellCategory.OFFENSIVE_SPECIAL;

-- Event name constants
NS.PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD";
NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS";
NS.UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED";
NS.COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED";
NS.GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE";
NS.NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED";
NS.NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED";
-- Sub event name constants
NS.SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS";
NS.SPELL_AURA_APPLIED = "SPELL_AURA_APPLIED";
NS.SPELL_AURA_REMOVED = "SPELL_AURA_REMOVED";
NS.SPELL_DAMAGE = "SPELL_DAMAGE";
NS.SPELL_CAST_START = "SPELL_CAST_START";

NS.specID = {
    BALANCE = 102,
    FERAL = 103,
    RET = 70,
    BM = 253,
    WW = 269,
};
local specID = NS.specID;

NS.classId = {
    Warrior = 1,
    Paladin = 2,
    Priest = 5,
    DK = 6,
    Mage = 8,
    Warlock = 9,
    Druid = 11,
};
local classId = NS.classId;

NS.raceID = {
    Human = 1,
    Undead = 5,
};
local raceID = NS.raceID;

NS.diminishingReturnCategory = {
    DR_DISORIENT = "disorient",
    DR_INCAPACITATE = "incapacitate",
    DR_SILENCE = "silence",
    DR_STUN = "stun",
    DR_ROOT = "root",
    DR_DISARM = "disarm",
    DR_TAUNT = "taunt",
    DR_KNOCKBACK = "knockback",
};
local DR_DISORIENT = NS.diminishingReturnCategory.DR_DISORIENT;
local DR_INCAPACITATE = NS.diminishingReturnCategory.DR_INCAPACITATE;
local DR_SILENCE = NS.diminishingReturnCategory.DR_SILENCE;
local DR_STUN = NS.diminishingReturnCategory.DR_STUN;
local DR_ROOT = NS.diminishingReturnCategory.DR_ROOT;
local DR_DISARM = NS.diminishingReturnCategory.DR_DISARM;
local DR_TAUNT = NS.diminishingReturnCategory.DR_TAUNT;
local DR_KNOCKBACK = NS.diminishingReturnCategory.DR_KNOCKBACK;

-- Events (and units) to track
-- Avoid tracking aura for CC spells, that way it's hard to see when player avoided a CC spell (shadowmeld, fleshcraft, etc.)
NS.trackType = {
    -- For pet kicks
    TRACK_PET = 1, -- SPELL_CAST_SUCCESS & pet GUID
    TRACK_PET_AURA = 2, -- SPELL_AURA_APPLIED & pet GUID

    TRACK_AURA = 3,
    TRACK_AURA_FADE = 4, -- SPELL_AURA_REMOVED, e.g., prot pally silence
    TRACK_UNIT = 5, -- UNIT_SPELLCAST_SUCCEEDED, e.g., meta (combat log triggered by auto proc meta)
};

local TRACK_PET = NS.trackType.TRACK_PET;
local TRACK_PET_AURA = NS.trackType.TRACK_PET_AURA;
local TRACK_AURA = NS.trackType.TRACK_AURA;
local TRACK_AURA_FADE = NS.trackType.TRACK_AURA_FADE;
local TRACK_UNIT = NS.trackType.TRACK_UNIT;

NS.defaultIndex = 100;

-- dispellable: buff can be dispelled, clear on early SPELL_AURA_REMOVED
-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

-- TODO: implement spec override, e.g., make outlaw rogue 90s blind baseline

-- Offensive spells are further divided to 3 sub categories:
-- OFFENSIVE: glow when it's active, show cooldown timer otherwise
-- OFFENSIVE_AURA: glow when it's active
-- OFFENSIVE_CD: show cooldown timer
NS.spellData = {
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
    -- Death Grip (icon is very close to Asphyxiate, so do not track that one...)
    [49576] = {
        category = CC,
        cooldown = 25,
        opt_charges = true,
    },
    -- Abomination Limb
    [315443] = {
        category = OFFENSIVE,
        cooldown = 120,
        duration = 12,
        index = 1,
    },
    -- Offensive (Unholy)
    -- Unholy Assult
    [207289] = {
        category = OFFENSIVE_AURA,
        duration = 12,
    },
    -- Raise Abomination
    [288853] = {
        category = OFFENSIVE_AURA,
        duration = 25,
    },
    -- Dark Transformation
    [63560] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Offensive (Frost)
    -- Pillar of Frost
    [51271] = {
        category = OFFENSIVE_AURA,
        duration = 12,
    },
    -- Empower Rune Weapon
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
    -- Mind Freeze
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
    -- Metamorphosis
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
    -- Disrupt
    [183752] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
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
    -- Incapacitating Roar
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
    -- Incarnation: King of the Jungle
    [102543] = {
        category = OFFENSIVE_AURA,
        duration = 30,
    },
    -- Celestial Alignment
    [194223] = {
        category = OFFENSIVE_AURA,
        duration = 30,
    },
    -- Incarnation: Chosen of Elune
    [102560] = {
        category = OFFENSIVE_AURA,
        duration = 40,
    },
    -- Kindred Spirits
    [338142] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Convoke the Spirits
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
    [5384] = {
        category = INTERRUPT,
        cooldown = 25,
        trackType = TRACK_UNIT, -- Not triggered by combat log event
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
    -- Aspect of the Turtle
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
    -- Deathborne (Necrolord)
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
    -- Counterspell
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
    -- Ring of Peace
    [116844] = {
        category = CC,
        cooldown = 45,
    },
    -- Offensive
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        category = OFFENSIVE_SPECIAL,
        duration = 15,
        cooldown = 90,
        charges = true,
        extend_power_type = Enum.PowerType.Chi,
        extend_amount = 0.4,
        reduce_power_type = Enum.PowerType.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
    },
    -- Serenity
    [152173] = {
        category = OFFENSIVE_SPECIAL,
        duration = 12,
        cooldown = 90,
        extend_power_type = Enum.PowerType.Chi,
        extend_type = "fixed",
        extend_amount = 0.3,
        reduce_power_type = Enum.PowerType.Chi,
        reduce_amount = 0.15, -- Every 2 Chi spent reduces the cooldown by 0.3 sec.
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        category = OFFENSIVE_AURA,
        duration = 24,
    },
    -- Bonedust Brew
    [325216] = {
        category = OFFENSIVE_AURA,
        duration = 10,
        spec = { specID.WW },
    },
    -- Interrupt
    -- Spear Hand Strike
    [116705] = {
        category = INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
    -- Touch of Karma
    [122470] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 90,
    },
    -- Life Cocoon
    [116849] = {
        category = DEFENSIVE,
        trackType = TRACK_UNIT,
        cooldown = 75, -- PVP talent Chrysalis
    },
    -- Dispel
    -- Detox
    [115450] = {
        category = DISPEL,
        cooldown = 8,
    },

    -- Paladin
    -- CC
    -- Shield of Virtue
    [215652] = {
        category = CC,
        cooldown = 45,
        trackType = TRACK_AURA_FADE,
    },
    -- Blinding Light
    [115750] = {
        category = CC,
        cooldown = 90,
    };
    -- HOJ has special calculation based on holy power spent and is made into a seperate table
    -- Offensive
    -- Avenging Wrath
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
    -- Blessing of Sanctuary
    [210256] = {
        category = DISPEL,
        cooldown = 45,
    },

    -- Priest
    -- CC
    -- Holy Word: Chastise
    [88625] = {
        category = CC,
        cooldown = 30,
    },
    -- Psychic Scream
    [8122] = {
        category = CC,
        cooldown = 60,
        opt_lower_cooldown = 30,
    },
    -- Psychic Horror
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
    -- Psyfiend
    [101398] = {
        category = OFFENSIVE_PET,
        spellID = 211522,
        duration = 12,
    },
    -- Boon of the Ascended
    [325013] = {
        category = OFFENSIVE,
        duration = 10,
        cooldown = 180,
    },
    -- Dispel
    -- Mass Dispel
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
    -- Pain Suppression
    [33206] = {
        category = DEFENSIVE,
        cooldown = 180,
    },
    -- Guardian Spirit
    [47788] = {
        category = DEFENSIVE,
        cooldown = 60, -- Assume it didn't proc
    },
    -- Dispersion
    [47585] = {
        category = DEFENSIVE,
        cooldown = 90, -- Assume playing short dispersion
    },
    -- Interrupt
    -- Holy Ward
    [213610] = {
        category = INTERRUPT,
        cooldown = 45,
    },
    -- Greater Fade
    [213602] = {
        category = INTERRUPT,
        cooldown = 45,
    },

    -- Rogue
    -- CC
    -- Blind
    [2094] = {
        category = CC,
        cooldown = 120,
        opt_lower_cooldown = 90,
    },
    -- Kidney Shot
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
    -- Echoing Reprimand
    [323547] = {
        category = OFFENSIVE_AURA,
        duration = 15,
    },
    -- Adrenaline Rush
    [13750] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Flagellation
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
    -- Shadowstep
    [36554] = {
        category = INTERRUPT,
        cooldown = 30,
        opt_charges = true,
    },
    -- Defensive
    -- Evasion
    [5277] = {
        category = DEFENSIVE,
        cooldown = 120,
    },
    -- Cloak of Shadows
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
    -- Ascendance (Enhancement)
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
    -- Vesper Totem
    [166523] = {
        category = OFFENSIVE_PET,
        spellID = 324386,
        duration = 30,
        sound = true,
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
    -- Axe Toss
    [89766] = { -- Find spellID by "if (unitTarget == "player") or (unitTarget == "pet") then print(spellID) end"
        category = CC,
        cooldown = 30,
        trackType = TRACK_PET,
    },
    -- Axe Toss (by player)
    [119914] = {
        category = CC,
        cooldown = 30,
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
    -- Spell Lock (cast by pet)
    [19647] = { -- Found by "if sourceGUID == UnitGUID("pet") or sourceGUID == UnitGUID("player") then print(subEvent, sourceGUID, spellID) end"
        category = INTERRUPT,
        cooldown = 24,
        trackType = TRACK_PET,
    },
    -- Spell Lock (Grimoire of Sacrifice)
    [132409] = {
        category = INTERRUPT,
        cooldown = 24,
    },
    -- Spell Lock (Command Demon) - cast by player
    [119910] = {
        category = INTERRUPT,
        cooldown = 24,
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
    -- Conqueror's Banner
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
    -- Colossus Smash
    [167105] = {
        category = OFFENSIVE_AURA,
        duration = 10,
    },
    -- Avatar
    [107574] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    },
    -- Recklessness
    [1719] = {
        category = OFFENSIVE,
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

NS.classWithFearSpell = function(class)
    return ( class == classId.Warrior ) or ( class == classId.Priest ) or ( class == classId.Warlock );
end

local playerClass = select(3, UnitClass("player"));
if NS.classWithFearSpell(playerClass) then
    -- Tremor Totem
    NS.spellData[8143] = {
        category = INTERRUPT,
        cooldown = 60,
    };
end

NS.RESET_FULL = 0;
local RESET_FULL = NS.RESET_FULL;

NS.spellResets = {
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
        [88625] = RESET_FULL,
    },

    -- Vanish (Memory of Invigorating Shadowdust)
    [1856] = {
        [2094] = 20, -- Blind
        [408] = 20, -- Kidney
        [212182] = 20, -- Smoke Bomb
    },
};

-- Special abilities that need seperate triggers from the generic ones.
NS.spellData_Combust = {
    spellID = 190319,
    duration = 12,
    cooldown = 120,
    index = 1,
    sound = true,
    dispellable = true,

    resets = {
        [133] = 2, -- Pyrokinesis
        [314791] = 12, -- Shifting Power
    },

    -- Reduce cooldown by 1s (Phoenix Flames spellID somehow does not work)
    critResets = { 133, 11366, 108853, "Phoenix Flames" },
};

NS.spellData_HOJ = {
    spellID = 853,
    cooldown = 60,
    powerType = Enum.PowerType.HolyPower,

    -- Spells that disable the cooldown reduction
    track_cast_start = 20066,
    track_cast_success = 115750,
};

if NS.isTestMode then
    -- Test
    -- Regrowth
    NS.spellData[8936] = {
        category = DEFENSIVE,
        duration = 8,
        cooldown = 120,
        sound = true,
        opt_charges = true,
    };
    -- Rejuv
    NS.spellData[774] = {
        category = CC,
        duration = 8,
        cooldown = 30,
        sound = true;
        charges = true,
    };
    -- Efflorescence
    NS.spellData[145205] = {
        category = INTERRUPT,
        cooldown = 15,
    };
    -- Lifebloom
    NS.spellData[33763] = {
        category = OFFENSIVE,
        duration = 8,
        cooldown = 30,
        sound = true,
    };
    -- Wild Growth
    NS.spellData[48438] = {
        category = OFFENSIVE_AURA,
        duration = 20,
    };
    -- Swiftmend
    NS.spellData[18562] = {
        category = OFFENSIVE_CD,
        cooldown = 45,
    };

    -- Test totem with a mob "Grasslands Vombata" outside of Haven in Zereth Mortis
    NS.spellData[178913] = {
        category = OFFENSIVE_PET,
        spellID = 324386,
        duration = 60,
        sound = true,
    };
end

NS.baselineSpells = {
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

if NS.isTestMode then
    -- Rejuvenation
    NS.baselineSpells[774] = {
        class = classId.Druid,
        cooldown = 60,
        opt_charges = true,
        index = 2,
    };
    -- Regrowth
    NS.baselineSpells[8936] = {
        class = classId.Druid,
        cooldown = 60,
        charges = true,
        index = 1,
    }
end

-- https://github.com/wardz/DRList-1.0/blob/master/DRList-1.0/Spells.lua
NS.diminishingReturnSpells = {
    [207167]  = DR_DISORIENT,       -- Blinding Sleet
    [207685]  = DR_DISORIENT,       -- Sigil of Misery
    [33786]   = DR_DISORIENT,       -- Cyclone
    [1513]    = DR_DISORIENT,       -- Scare Beast
    [31661]   = DR_DISORIENT,       -- Dragon's Breath
    [198909]  = DR_DISORIENT,       -- Song of Chi-ji
    [202274]  = DR_DISORIENT,       -- Incendiary Brew
    [105421]  = DR_DISORIENT,       -- Blinding Light
    [10326]   = DR_DISORIENT,       -- Turn Evil
    [605]     = DR_DISORIENT,       -- Mind Control
    [8122]    = DR_DISORIENT,       -- Psychic Scream
    [226943]  = DR_DISORIENT,       -- Mind Bomb
    [2094]    = DR_DISORIENT,       -- Blind
    [118699]  = DR_DISORIENT,       -- Fear
    [5484]    = DR_DISORIENT,       -- Howl of Terror
    [261589]  = DR_DISORIENT,       -- Seduction (Grimoire of Sacrifice)
    [6358]    = DR_DISORIENT,       -- Seduction (Succubus)
    [5246]    = DR_DISORIENT,       -- Intimidating Shout 1
    [316593]  = DR_DISORIENT,       -- Intimidating Shout 2 (TODO: not sure which one is correct in 9.0.1)
    [316595]  = DR_DISORIENT,       -- Intimidating Shout 3
    [331866]  = DR_DISORIENT,       -- Agent of Chaos (Venthyr Covenant)

    [217832]  = DR_INCAPACITATE,    -- Imprison
    [221527]  = DR_INCAPACITATE,    -- Imprison (Honor talent)
    [2637]    = DR_INCAPACITATE,    -- Hibernate
    [99]      = DR_INCAPACITATE,    -- Incapacitating Roar
    [3355]    = DR_INCAPACITATE,    -- Freezing Trap
    [203337]  = DR_INCAPACITATE,    -- Freezing Trap (Honor talent)
    [213691]  = DR_INCAPACITATE,    -- Scatter Shot
    [118]     = DR_INCAPACITATE,    -- Polymorph
    [28271]   = DR_INCAPACITATE,    -- Polymorph (Turtle)
    [28272]   = DR_INCAPACITATE,    -- Polymorph (Pig)
    [61025]   = DR_INCAPACITATE,    -- Polymorph (Snake)
    [61305]   = DR_INCAPACITATE,    -- Polymorph (Black Cat)
    [61780]   = DR_INCAPACITATE,    -- Polymorph (Turkey)
    [61721]   = DR_INCAPACITATE,    -- Polymorph (Rabbit)
    [126819]  = DR_INCAPACITATE,    -- Polymorph (Porcupine)
    [161353]  = DR_INCAPACITATE,    -- Polymorph (Polar Bear Cub)
    [161354]  = DR_INCAPACITATE,    -- Polymorph (Monkey)
    [161355]  = DR_INCAPACITATE,    -- Polymorph (Penguin)
    [161372]  = DR_INCAPACITATE,    -- Polymorph (Peacock)
    [277787]  = DR_INCAPACITATE,    -- Polymorph (Baby Direhorn)
    [277792]  = DR_INCAPACITATE,    -- Polymorph (Bumblebee)
    [82691]   = DR_INCAPACITATE,    -- Ring of Frost
    [115078]  = DR_INCAPACITATE,    -- Paralysis
    [20066]   = DR_INCAPACITATE,    -- Repentance
    [9484]    = DR_INCAPACITATE,    -- Shackle Undead
    [200196]  = DR_INCAPACITATE,    -- Holy Word: Chastise
    [1776]    = DR_INCAPACITATE,    -- Gouge
    [6770]    = DR_INCAPACITATE,    -- Sap
    [51514]   = DR_INCAPACITATE,    -- Hex
    [196942]  = DR_INCAPACITATE,    -- Hex (Voodoo Totem)
    [210873]  = DR_INCAPACITATE,    -- Hex (Raptor)
    [211004]  = DR_INCAPACITATE,    -- Hex (Spider)
    [211010]  = DR_INCAPACITATE,    -- Hex (Snake)
    [211015]  = DR_INCAPACITATE,    -- Hex (Cockroach)
    [269352]  = DR_INCAPACITATE,    -- Hex (Skeletal Hatchling)
    [309328]  = DR_INCAPACITATE,    -- Hex (Living Honey)
    [277778]  = DR_INCAPACITATE,    -- Hex (Zandalari Tendonripper)
    [277784]  = DR_INCAPACITATE,    -- Hex (Wicker Mongrel)
    [197214]  = DR_INCAPACITATE,    -- Sundering
    [710]     = DR_INCAPACITATE,    -- Banish
    [6789]    = DR_INCAPACITATE,    -- Mortal Coil
    [107079]  = DR_INCAPACITATE,    -- Quaking Palm (Pandaren racial)

    [47476]   = DR_SILENCE,         -- Strangulate
    [204490]  = DR_SILENCE,         -- Sigil of Silence
--      [78675]   = DR_SILENCE,         -- Solar Beam (doesn't seem to DR)
    [202933]  = DR_SILENCE,         -- Spider Sting
    [356727]  = DR_SILENCE,         -- Spider Venom
    [217824]  = DR_SILENCE,         -- Shield of Virtue
    [15487]   = DR_SILENCE,         -- Silence
    [1330]    = DR_SILENCE,         -- Garrote
    [196364]  = DR_SILENCE,         -- Unstable Affliction Silence Effect

    [210141]  = DR_STUN,            -- Zombie Explosion
    [334693]  = DR_STUN,            -- Absolute Zero (Breath of Sindragosa)
    [108194]  = DR_STUN,            -- Asphyxiate (Unholy)
    [221562]  = DR_STUN,            -- Asphyxiate (Blood)
    [91800]   = DR_STUN,            -- Gnaw (Ghoul)
    [91797]   = DR_STUN,            -- Monstrous Blow (Mutated Ghoul)
    [287254]  = DR_STUN,            -- Dead of Winter
    [179057]  = DR_STUN,            -- Chaos Nova
    [205630]  = DR_STUN,            -- Illidan's Grasp (Primary effect)
    [208618]  = DR_STUN,            -- Illidan's Grasp (Secondary effect)
    [211881]  = DR_STUN,            -- Fel Eruption
    [200166]  = DR_STUN,            -- Metamorphosis (PvE stun effect)
    [203123]  = DR_STUN,            -- Maim
    [163505]  = DR_STUN,            -- Rake (Prowl)
    [5211]    = DR_STUN,            -- Mighty Bash
    [202244]  = DR_STUN,            -- Overrun
    [325321]  = DR_STUN,            -- Wild Hunt's Charge
    [357021]  = DR_STUN,            -- Consecutive Concussion
    [24394]   = DR_STUN,            -- Intimidation
    [119381]  = DR_STUN,            -- Leg Sweep
    [202346]  = DR_STUN,            -- Double Barrel
    [853]     = DR_STUN,            -- Hammer of Justice
    [255941]  = DR_STUN,            -- Wake of Ashes
    [64044]   = DR_STUN,            -- Psychic Horror
    [200200]  = DR_STUN,            -- Holy Word: Chastise Censure
    [1833]    = DR_STUN,            -- Cheap Shot
    [408]     = DR_STUN,            -- Kidney Shot
    [118905]  = DR_STUN,            -- Static Charge (Capacitor Totem)
    [118345]  = DR_STUN,            -- Pulverize (Primal Earth Elemental)
    [305485]  = DR_STUN,            -- Lightning Lasso
    [89766]   = DR_STUN,            -- Axe Toss
    [171017]  = DR_STUN,            -- Meteor Strike (Infernal)
    [171018]  = DR_STUN,            -- Meteor Strike (Abyssal)
    [30283]   = DR_STUN,            -- Shadowfury
    [46968]   = DR_STUN,            -- Shockwave
    [132168]  = DR_STUN,            -- Shockwave (Protection)
    [145047]  = DR_STUN,            -- Shockwave (Proving Grounds PvE)
    [132169]  = DR_STUN,            -- Storm Bolt
    [199085]  = DR_STUN,            -- Warpath
    [20549]   = DR_STUN,            -- War Stomp (Tauren)
    [255723]  = DR_STUN,            -- Bull Rush (Highmountain Tauren)
    [287712]  = DR_STUN,            -- Haymaker (Kul Tiran)

    [204085]  = DR_ROOT,            -- Deathchill (Chains of Ice)
    [233395]  = DR_ROOT,            -- Deathchill (Remorseless Winter)
    [339]     = DR_ROOT,            -- Entangling Roots
    [170855]  = DR_ROOT,            -- Entangling Roots (Nature's Grasp)
    [102359]  = DR_ROOT,            -- Mass Entanglement
    [117526]  = DR_ROOT,            -- Binding Shot
    [162480]  = DR_ROOT,            -- Steel Trap
    [273909]  = DR_ROOT,            -- Steelclaw Trap
--      [190927]  = "root_harpoon",    -- Harpoon (TODO: confirm)
    [212638]  = DR_ROOT,            -- Tracker's Net
    [201158]  = DR_ROOT,            -- Super Sticky Tar
    [122]     = DR_ROOT,            -- Frost Nova
    [33395]   = DR_ROOT,            -- Freeze
    [198121]  = DR_ROOT,            -- Frostbite
    [342375]  = DR_ROOT,            -- Tormenting Backlash (Torghast PvE)
    [233582]  = DR_ROOT,            -- Entrenched in Flame
    [116706]  = DR_ROOT,            -- Disable
    [324382]  = DR_ROOT,            -- Clash
    [64695]   = DR_ROOT,            -- Earthgrab (Totem effect)
    [285515]  = DR_ROOT,            -- Surge of Power
    [39965]   = DR_ROOT,            -- Frost Grenade (Item)
    [75148]   = DR_ROOT,            -- Embersilk Net (Item)
    [55536]   = DR_ROOT,            -- Frostweave Net (Item)
    [268966]  = DR_ROOT,            -- Hooked Deep Sea Net (Item)

    [209749]  = DR_DISARM,          -- Faerie Swarm (Balance Honor Talent)
    [207777]  = DR_DISARM,          -- Dismantle
    [233759]  = DR_DISARM,          -- Grapple Weapon
    [236077]  = DR_DISARM,          -- Disarm

    [56222]   = DR_TAUNT,           -- Dark Command
    [51399]   = DR_TAUNT,           -- Death Grip
    [185245]  = DR_TAUNT,           -- Torment
    [6795]    = DR_TAUNT,           -- Growl (Druid)
    [2649]    = DR_TAUNT,           -- Growl (Hunter Pet) (TODO: confirm)
    [20736]   = DR_TAUNT,           -- Distracting Shot
    [116189]  = DR_TAUNT,           -- Provoke
    [118635]  = DR_TAUNT,           -- Provoke (Black Ox Statue)
    [196727]  = DR_TAUNT,           -- Provoke (Niuzao)
    [204079]  = DR_TAUNT,           -- Final Stand
    [62124]   = DR_TAUNT,           -- Hand of Reckoning
    [17735]   = DR_TAUNT,           -- Suffering (Voidwalker) (TODO: confirm)
    [355]     = DR_TAUNT,           -- Taunt

    -- Experimental
    [108199]  = DR_KNOCKBACK,        -- Gorefiend's Grasp
    [202249]  = DR_KNOCKBACK,        -- Overrun
    [61391]   = DR_KNOCKBACK,        -- Typhoon
    [102793]  = DR_KNOCKBACK,        -- Ursol's Vortex
    [186387]  = DR_KNOCKBACK,        -- Bursting Shot
    [236777]  = DR_KNOCKBACK,        -- Hi-Explosive Trap
    [157981]  = DR_KNOCKBACK,        -- Blast Wave
    [237371]  = DR_KNOCKBACK,        -- Ring of Peace
    [204263]  = DR_KNOCKBACK,        -- Shining Force
    [51490]   = DR_KNOCKBACK,        -- Thunderstorm
--      [287712]  = DR_KNOCKBACK,        -- Haywire (Kul'Tiran Racial)
};

if NS.isTestMode then
    NS.diminishingReturnSpells[33763] = NS.diminishingReturnCategory.DR_DISORIENT; -- Lifebloom
    NS.diminishingReturnSpells[8936] = NS.diminishingReturnCategory.DR_STUN; -- Regrowth
    NS.diminishingReturnSpells[774] = NS.diminishingReturnCategory.DR_INCAPACITATE; -- Rejuvenation
end
