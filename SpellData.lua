local _, NS = ...;

local UnitAura = UnitAura;
local strsplit = strsplit;

NS.isTestMode = false;

NS.Util_GetUnitAura = function(unit, spell, filter)
    if filter and not filter:upper():find("FUL") then
        filter = filter.."|HELPFUL"
    end
    for i = 1, 255 do
      local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
      if not name then return end
      if spell == spellId or spell == name then
        return UnitAura(unit, i, filter)
      end
    end
end

NS.Util_GetUnitBuff = function(unit, spell, filter)
    filter = filter and filter.."|HELPFUL" or "HELPFUL"
    return NS.Util_GetUnitAura(unit, spell, filter)
end

NS.GetNpcIdFromGuid = function (guid)
    local NpcId = select ( 6, strsplit ( "-", guid ) )
    if (NpcId) then
        return tonumber ( NpcId )
    end

    return 0
end

NS.spellCategory = {
    OFFENSIVE = 1,
    OFFENSIVE_DURATION = 2, -- Exclude spells that have dynamic duration, e.g., icy veins can extend the duration from hitting frozen targets with ice lance.
    OFFENSIVE_PET = 3, -- e.g., Psyfiend, Vesper Totem (match with NPC ID instead of spellID).
    OFFENSIVE_SPECIAL = 4,
}

-- trackEvent: event or combat log subEvent to track
-- trackDest: track destGUID instead of sourceGUID, otherwise we assume destGUID == sourceGUID (this cannot be set to spells that can only self cast)

local OFFENSIVE = NS.spellCategory.OFFENSIVE
local OFFENSIVE_DURATION = NS.spellCategory.OFFENSIVE_DURATION
local OFFENSIVE_PET = NS.spellCategory.OFFENSIVE_PET
local OFFENSIVE_SPECIAL = NS.spellCategory.OFFENSIVE_SPECIAL

-- Event name constants
NS.PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD"
NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS"
NS.PLAYER_SPECIALIZATION_CHANGED = "PLAYER_SPECIALIZATION_CHANGED"
NS.UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED"
NS.UNIT_AURA = "UNIT_AURA"
NS.COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED"
NS.GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE"
NS.NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED"
NS.NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED"
-- Sub event name constants
NS.SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS"
NS.SPELL_AURA_APPLIED = "SPELL_AURA_APPLIED"
NS.SPELL_AURA_REMOVED = "SPELL_AURA_REMOVED"
NS.SPELL_DAMAGE = "SPELL_DAMAGE"
NS.SPELL_CAST_START = "SPELL_CAST_START"
NS.SPELL_SUMMON = "SPELL_SUMMON"
NS.UNIT_DIED = "UNIT_DIED"

NS.specID = {
    BALANCE = 102,
    FERAL = 103,
    RET = 70,
    BM = 253,
    WW = 269,
    DEVASTATION = 1467,
}
local specID = NS.specID

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

-- TODO: implement spec override, e.g., make outlaw rogue 90s blind baseline

-- Offensive spells are further divided to 3 sub categories:
-- OFFENSIVE: glow when it's active, show cooldown timer otherwise
-- OFFENSIVE_DURATION: glow when it's active
-- OFFENSIVE: show cooldown timer
NS.spellData = {
    -- General
    -- Offensive

    -- DK
    -- Abomination Limb
    [383269] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE,
        cooldown = 120,
        duration = 12,
        index = 1,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Offensive (Unholy)
    -- Summon Gargoyle
    [49206] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE,
        cooldown = 180,
        duration = 25,
        index = 1,
    },
    -- Unholy Assult
    [207289] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Apocalypse
    [275699] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Offensive (Frost)
    -- Pillar of Frost
    [51271] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE_DURATION,
        duration = 12,
    },
    -- Chill Streak
    [305392] = {
        class = "DEATHKNIGHT",
        category = OFFENSIVE_DURATION,
        duration = 4,
        index = 2,
        sound = true,
    },

    -- DH
    -- Offensive
    -- The Hunt
    [370965] = {
        class = "DEMONHUNTER",
        category = OFFENSIVE,
        cooldown = 90,
        index = 1,
    },
    -- Metamorphosis (have to track with UNIT_SPELLCAST_SUCCEEDED to exclude auto proc from Eye Beam)
    [191427] = {
        class = "DEMONHUNTER",
        category = OFFENSIVE_DURATION,
        trackEvent = NS.UNIT_SPELLCAST_SUCCEEDED,
        duration = 24,
    },

    -- Druid
    -- Offensive
    -- Berserk
    [106951] = {
        class = "DRUID",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Incarnation: Avatar of Ashamane
    [102543] = {
        class = "DRUID",
        category = OFFENSIVE_DURATION,
        duration = 30,
    },
    -- Celestial Alignment
    [194223] = {
        class = "DRUID",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Incarnation: Chosen of Elune (spellID has not changed in DF)
    [102560] = {
        class = "DRUID",
        category = OFFENSIVE,
        duration = 30,
        cooldown = 180,
        index = 2,
    },
    -- Convoke the Spirits
    [391528] = {
        class = "DRUID",
        category = OFFENSIVE,
        cooldown = 60,
        spec = { specID.BALANCE, specID.FERAL },
        index = 1,
    },
    -- Feral Frenzy
    [274837] = {
        class = "DRUID",
        category = OFFENSIVE,
        cooldown = 45,
    },

    -- Evoker
    -- Tip the Scales
    [370553] = {
        class = "EVOKER",
        category = OFFENSIVE,
        spec = { specID.DEVASTATION },
        cooldown = 120,
    },
    -- Dragon Rage
    [375087] = {
        class = "EVOKER",
        category = OFFENSIVE_SPECIAL,
        duration = 14,
        cooldown = 120,
        extend = true,
    },

    -- Hunter
    -- Offensive
    -- Bestial Wrath
    [19574] = {
        class = "HUNTER",
        category = OFFENSIVE_DURATION,
        duration = 15,
    },
    -- Coordinated Assult
    [360952] = {
        class = "HUNTER",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Trueshot
    [288613] = {
        class = "HUNTER",
        category = OFFENSIVE_DURATION,
        duration = 18,
    },
    -- Call of the Wild
    [359844] = {
        class = "HUNTER",
        category = OFFENSIVE,
        duration = 20,
        cooldown = 180,
        index = 1,
    },

    -- Mage
    -- Offensive
    -- Icy Veins (Skipped, duration unstable)
    -- Ice Form (Skipped, duration unstable)
    -- Combustion
    [190319] = {
        class = "MAGE",
        category = OFFENSIVE_SPECIAL,
        duration = 12,
        cooldown = 120,
        index = 1,
        sound = true,

        resets = {
            [133] = 2, -- Pyrokinesis
            [314791] = 12, -- Shifting Power
        },

        -- Reduce cooldown by 1s (Phoenix Flames spellID somehow does not work)
        critResets = { 133, 11366, 108853, "Phoenix Flames" },
        critResetAmount = 75,
    },
    -- Icy Veins
    [12472] = {
        class = "MAGE",
        category = OFFENSIVE_DURATION,
        duration = 25,
        extend = true,
    },
    -- Ice Form
    [198144] = {
        class = "MAGE",
        category = OFFENSIVE_DURATION,
        duration = 12,
        extend = true,
    },
    -- Arcane Surge
    [365350] = {
        class = "MAGE",
        category = OFFENSIVE,
        cooldown = 90,
        index = 1,
    },

    -- Monk
    -- Offensive
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = "MONK",
        category = OFFENSIVE_SPECIAL,
        duration = 15,
        cooldown = 90,
        charges = true,
        reduce_power_type = Enum.PowerType.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
        extend = true,
        index = 1,
    },
    -- Serenity
    [152173] = {
        class = "MONK",
        category = OFFENSIVE_SPECIAL,
        duration = 12,
        cooldown = 90,
        reduce_power_type = Enum.PowerType.Chi,
        reduce_amount = 0.15, -- Every 2 Chi spent reduces the cooldown by 0.3 sec.
        extend = true,
        index = 1,
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = "MONK",
        category = OFFENSIVE_DURATION,
        duration = 24,
    },
    -- Bonedust Brew
    [386276] = {
        class = "MONK",
        category = OFFENSIVE_DURATION,
        duration = 10,
        spec = { specID.WW },
        index = 2,
    },
    -- Dance of Chi-ji
    [325202] = {
        class = "MONK",
        category = OFFENSIVE_DURATION,
        trackEvent = NS.SPELL_AURA_APPLIED,
        index = 2,
    },

    -- Paladin
    -- Offensive
    -- Avenging Wrath
    [31884] = {
        class = "PALADIN",
        category = OFFENSIVE,
        duration = 20,
        cooldown = 120,
        sound = true,
        index = 1,
        spec = { specID.RET },
        extend = true, -- Zelot's Paragon
    },
    -- Crusade
    [231895] = {
        class = "PALADIN",
        category = OFFENSIVE,
        duration = 25,
        cooldown = 120,
        sound = true,
        index = 1,
        spec = { specID.RET },
        extend = true, -- Zelot's Paragon
    },
    -- Divine Toll
    [375576] = {
        class = "PALADIN",
        category = OFFENSIVE,
        spec = { specID.RET },
        cooldown = 60,
    },
    -- Blessing of Summer
    [388007] = {
        category = OFFENSIVE_DURATION,
        trackEvent = NS.SPELL_AURA_APPLIED,
        trackDest = true,
        index = 1,
    },
    -- Seraphim
    [152262] = {
        class = "PALADIN",
        category = OFFENSIVE_DURATION,
        duration = 15,
        spec = { specID.RET },
    },
    -- Final Reckoning
    [343721] = {
        class = "PALADIN",
        category = OFFENSIVE_DURATION,
        duration = 8,
    },

    -- Priest
    -- Offensive
    -- Mindgames
    [375901] = {
        class = "PRIEST",
        category = OFFENSIVE,
        cooldown = 45,
        index = 1,
    },
    -- Mindbender (Idol of Y'Shaarj)
    [200174] = {
        class = "PRIEST",
        category = OFFENSIVE,
        duration = 15,
        cooldown = 60,
    },
    -- Psyfiend
    [211522] = {
        class = "PRIEST",
        category = OFFENSIVE_PET,
        spellID = 211522,
        duration = 12,
    },
    -- Power Infusion
    [10060] = {
        category = OFFENSIVE_DURATION,
        trackDest = true,
        trackEvent = NS.SPELL_AURA_APPLIED, -- Twins of the Sun Pristess (when casting on allies, the self buff doesn't trigger SPELL_CAST_SUCCESS)
        duration = 20,
    },

    -- Rogue
    -- Offensive
    -- Shadow Blades
    [121471] = {
        class = "ROGUE",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Adrenaline Rush
    [13750] = {
        class = "ROGUE",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Sepsis
    [385408] = {
        class = "ROGUE",
        category = OFFENSIVE,
        duration = 10,
        cooldown = 90,
        index = 2,
    },
    -- Death Mark
    [360194] = {
        class = "ROGUE",
        category = OFFENSIVE,
        duration = 16,
        cooldown = 120,
        index = 1,
        sound = true,
    },
    -- Exsanguinate
    [200806] = {
        class = "ROGUE",
        category = OFFENSIVE,
        cooldown = 180,
        index = 2,
    },
    -- Kingsbane
    [385627] = {
        class = "ROGUE",
        category = OFFENSIVE_DURATION,
        duration = 14,
        index = 2,
    },
    -- Echoing Reprimand
    [323560] = {
        class = "ROGUE",
        category = OFFENSIVE_DURATION,
        trackEvent = NS.SPELL_AURA_APPLIED,
    },

    -- Shaman
    -- Offensive
    -- Ascendance (Enhancement)
    [114051] = {
        class = "SHAMAN",
        category = OFFENSIVE_DURATION,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = "SHAMAN",
        category = OFFENSIVE,
        duration = 8,
        cooldown = 60,
        index = 2,
    },
    -- Stormkeeper
    [191634] = {
        class = "SHAMAN",
        category = OFFENSIVE_DURATION,
        duration = 15,
    },
    -- Skyfury
    [208963] = {
        duration = 15,
        category = OFFENSIVE_DURATION,
        trackEvent = NS.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Fire Elemental
    [198067] = {
        class = "SHAMAN",
        category = OFFENSIVE,
        duration = 30,
        cooldown = 150,
        index = 1,
    },

    -- Warlock
    -- Affliction
    -- Summon Darkglare
    [205180] = {
        class = "WARLOCK",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = "WARLOCK",
        category = OFFENSIVE_DURATION,
        duration = 30,
    },
    -- Demonology
    -- Nether Portal
    [267217] = {
        class = "WARLOCK",
        category = OFFENSIVE,
        duration = 15, -- Show Pit Lord nameplate
        cooldown = 180,
        index = 1,
    },
    -- Summon Demonic Tyrant
    [265187] = {
        class = "WARLOCK",
        category = OFFENSIVE_DURATION,
        duration = 15,
    },
    -- Fel Obelisk
    [353601] = {
        class = "WARLOCK",
        category = OFFENSIVE_DURATION,
        duration = 15,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = "WARLOCK",
        category = OFFENSIVE_DURATION,
        duration = 17,
    },
    -- Gul'dan's Ambition (Pit Lord)
    [387578] = {
        class = "WARLOCK",
        duration = 10,
    },

    -- Warrior
    -- Offensive
    -- Warbreaker
    [262161] = {
        class = "WARRIOR",
        category = OFFENSIVE_DURATION,
        duration = 10,
    },
    -- Colossus Smash
    [167105] = {
        class = "WARRIOR",
        category = OFFENSIVE_DURATION,
        duration = 10,
    },
    -- Avatar
    [107574] = {
        class = "WARRIOR",
        category = OFFENSIVE_DURATION,
        duration = 20,
    },
    -- Recklessness
    [1719] = {
        class = "WARRIOR",
        category = OFFENSIVE_SPECIAL,
        cooldown = 90,
        duration = 16,
        reduce_power_type = Enum.PowerType.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 1,
    },
}

NS.ClassWithFearSpell = function(class)
    return ( class == "WARRIOR" ) or ( class == "PRIEST" ) or ( class == "WARLOCK" );
end

NS.RESET_FULL = 0
local RESET_FULL = NS.RESET_FULL

NS.spellResets = {
    -- Mindgames
    -- Mind Blast
    [8092] = {
        [375901] = 1,
    },
    -- Mind Spike
    [73510] = {
        [375901] = 1,
    },
    -- Smite
    [585] = {
        [375901] = 1,
    },
    -- Holy Fire
    [14914] = {
        [375901] = 1,
    },

    -- Shifting Power
    [314791] = {
        [190319] = 12, -- Combustion
    },
    -- Fireball
    [133] = {
        [190319] = 2, -- Combustion
    },
}

if NS.isTestMode then
    -- Test
    -- Mark of the Wild
    NS.spellData[1126] = {
        class = "DRUID",
        category = OFFENSIVE,
        duration = 8,
        cooldown = 30,
        index = 1,
        sound = true,
    }
    -- Regrowth
    NS.spellData[8936] = {
        class = "DRUID",
        category = OFFENSIVE,
        duration = 5,
        cooldown = 10,
    }
    -- Rejuv
    NS.spellData[774] = {
        class = "DRUID",
        category = OFFENSIVE,
        cooldown = 45,
    }
    -- Wild Growth
    NS.spellData[48438] = {
        category = OFFENSIVE,
        duration = 7,
        trackDest = true,
        trackEvent = "SPELL_AURA_APPLIED",
    }

    NS.spellData[1459] = {
        class = "MAGE",
        category = OFFENSIVE_SPECIAL,
        duration = 12,
        cooldown = 120,
        index = 1,
        sound = true,

        resets = {
            [133] = 2, -- Pyrokinesis
            [314791] = 12, -- Shifting Power
        },

        -- Reduce cooldown by 1s (Phoenix Flames spellID somehow does not work)
        critResets = { 133, 11366, 108853, "Phoenix Flames" },
        critResetAmount = 1,
    }
end
