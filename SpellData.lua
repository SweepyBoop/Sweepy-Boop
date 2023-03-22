local _, NS = ...;

local POWERTYPE = Enum.PowerType;

-- trackEvent: event or combat log subEvent to track
-- trackDest: track destGUID instead of sourceGUID, otherwise we assume destGUID == sourceGUID (this cannot be set to spells that can only self cast)

local OFFENSIVE = NS.SPELLCATEGORY.OFFENSIVE

local specID = NS.SPECID

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

NS.spellData = {
    -- General
    -- Offensive

    -- DK
    -- Abomination Limb
    [383269] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 12,
        index = 2,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Offensive (Unholy)
    -- Summon Gargoyle
    [49206] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 180,
        duration = 25,
        index = 1,
    },
    -- Unholy Assult
    [207289] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Raise Abomination
    [288853] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        duration = 25,
    },
    -- Apocalypse
    [275699] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Offensive (Frost)
    -- Pillar of Frost
    [51271] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        duration = 12,
    },
    -- Chill Streak
    [305392] = {
        class = NS.DEATHKNIGHT,
        category = OFFENSIVE,
        duration = 4,
        index = 2,
        sound = true,
    },

    -- DH
    -- Offensive
    -- The Hunt
    [370965] = {
        class = NS.DEMONHUNTER,
        category = OFFENSIVE,
        cooldown = 90,
        index = 1,
    },
    -- Essence Break
    [258860] = {
        class = NS.DEMONHUNTER,
        category = OFFENSIVE,
        duration = 4,
        index = 2,
    },
    -- Metamorphosis (have to track with UNIT_SPELLCAST_SUCCEEDED to exclude auto proc from Eye Beam)
    [191427] = {
        class = NS.DEMONHUNTER,
        category = OFFENSIVE,
        trackEvent = NS.UNIT_SPELLCAST_SUCCEEDED,
        duration = 24,
    },

    -- Druid
    -- Offensive
    -- Berserk
    [106951] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Incarnation: Avatar of Ashamane
    [102543] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        duration = 30,
    },
    -- Celestial Alignment
    [194223] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Incarnation: Chosen of Elune (spellID has not changed in DF)
    [102560] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        duration = 30,
        cooldown = 120,
        index = 2,
    },
    -- Convoke the Spirits
    [391528] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        cooldown = 60,
        spec = { specID.BALANCE, specID.FERAL },
        index = 1,
    },
    -- Feral Frenzy
    [274837] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        cooldown = 45,
    },

    -- Evoker
    -- Tip the Scales
    [370553] = {
        class = NS.EVOKER,
        category = OFFENSIVE,
        spec = { specID.DEVASTATION },
        cooldown = 120,
    },
    -- Dragon Rage
    [375087] = {
        class = NS.EVOKER,
        category = OFFENSIVE,
        duration = 14,
        cooldown = 120,
        extend = true,
        index = 2,
    },

    -- Hunter
    -- Offensive
    -- Bestial Wrath
    [19574] = {
        class = NS.HUNTER,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Coordinated Assult
    [360952] = {
        class = NS.HUNTER,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Trueshot
    [288613] = {
        class = NS.HUNTER,
        category = OFFENSIVE,
        duration = 18,
    },
    -- Call of the Wild
    [359844] = {
        class = NS.HUNTER,
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
        class = NS.MAGE,
        category = OFFENSIVE,
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
        class = NS.MAGE,
        category = OFFENSIVE,
        duration = 25,
        extend = true,
    },
    -- Ice Form
    [198144] = {
        class = NS.MAGE,
        category = OFFENSIVE,
        duration = 12,
        extend = true,
    },
    -- Arcane Surge
    [365350] = {
        class = NS.MAGE,
        category = OFFENSIVE,
        cooldown = 90,
        index = 1,
    },

    -- Monk
    -- Offensive
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = NS.MONK,
        category = OFFENSIVE,
        duration = 15,
        cooldown = 90,
        charges = true,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
        extend = true,
        index = 1,
    },
    -- Serenity
    [152173] = {
        class = NS.MONK,
        category = OFFENSIVE,
        duration = 12,
        cooldown = 90,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.15, -- Every 2 Chi spent reduces the cooldown by 0.3 sec.
        extend = true,
        index = 1,
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = NS.MONK,
        category = OFFENSIVE,
        duration = 24,
    },
    -- Bonedust Brew
    [386276] = {
        class = NS.MONK,
        category = OFFENSIVE,
        duration = 10,
        spec = { specID.WW },
        index = 2,
    },
    -- Dance of Chi-ji
    [325202] = {
        class = NS.MONK,
        category = OFFENSIVE,
        trackEvent = NS.SPELL_AURA_APPLIED,
        index = 2,
    },

    -- Paladin
    -- Offensive
    -- Avenging Wrath
    [31884] = {
        class = NS.PALADIN,
        category = OFFENSIVE,
        duration = 23, -- Baseline: 20s, Divine Wrath: 3s
        cooldown = 60, -- Avenging Wrath: Might
        sound = true,
        index = 1,
        spec = { specID.RET },
    },
    -- Crusade
    [231895] = {
        class = NS.PALADIN,
        category = OFFENSIVE,
        duration = 30, -- Baseline: 27s, Divine Wrath: 3s
        cooldown = 120,
        sound = true,
        index = 1,
        spec = { specID.RET },
    },
    -- Divine Toll
    [375576] = {
        class = NS.PALADIN,
        category = OFFENSIVE,
        spec = { specID.RET },
        cooldown = 60,
    },
    -- Blessing of Summer
    [388007] = {
        category = OFFENSIVE,
        trackEvent = NS.SPELL_AURA_APPLIED,
        trackDest = true,
        index = 2,
    },
    -- Final Reckoning
    [343721] = {
        class = NS.PALADIN,
        category = OFFENSIVE,
        duration = 12,
    },

    -- Priest
    -- Offensive
    -- Mindgames
    [375901] = {
        class = NS.PRIEST,
        category = OFFENSIVE,
        cooldown = 45,
        index = 1,
    },
    -- Mindbender (Idol of Y'Shaarj)
    [200174] = {
        class = NS.PRIEST,
        spec = { specID.SHADOW },
        category = OFFENSIVE,
        duration = 15,
        cooldown = 60,
    },
    -- Psyfiend
    [211522] = {
        class = NS.PRIEST,
        category = OFFENSIVE,
        spellID = 211522,
        duration = 12,
    },
    -- Power Infusion
    [10060] = {
        category = OFFENSIVE,
        trackDest = true,
        trackEvent = NS.SPELL_AURA_APPLIED, -- Twins of the Sun Pristess (when casting on allies, the self buff doesn't trigger SPELL_CAST_SUCCESS)
        duration = 20,
    },
    -- Dark Ascension
    [391109] = {
        category = OFFENSIVE,
        class = NS.PRIEST,
        duration = 20,
    },
    -- Voidform
    [194249] = {
        category = OFFENSIVE,
        class = NS.PRIEST,
        trackEvent = NS.SPELL_AURA_APPLIED,
        duration = NS.DURATION_DYNAMIC,
    },
    -- Restitution (treat as offensive spell with highest priority. Buff is hidden aura, so we track debuff spellId)
    -- Currently lacking the detection of early dismiss (if the priest right clicks the spirit buff)
    [211319] = {
        class = NS.PRIEST,
        category = OFFENSIVE,
        trackEvent = NS.SPELL_AURA_APPLIED,
        duration = 15,
        index = 1,
    },

    -- Rogue
    -- Offensive
    -- Shadow Blades
    [121471] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Adrenaline Rush
    [13750] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Sepsis
    [385408] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        duration = 10,
    },
    -- Death Mark
    [360194] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        duration = 16,
        cooldown = 120,
        index = 1,
        sound = true,
    },
    -- Exsanguinate
    [200806] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        cooldown = 180,
        index = 2,
    },
    -- Kingsbane
    [385627] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        duration = 14,
        index = 2,
    },
    -- Echoing Reprimand
    [323560] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        trackEvent = NS.SPELL_AURA_APPLIED,
    },
    -- Cold Blood
    [382245] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        cooldown = 45,
        spec = {specID.SUBTLETY},
        index = 2,
        trackEvent = NS.SPELL_AURA_REMOVED,
    },
    -- Shadow Dance
    [185313] = {
        class = NS.ROGUE,
        category = OFFENSIVE,
        duration = 8,
        spec = {specID.SUBTLETY},
    },

    -- Shaman
    -- Offensive
    -- Ascendance (Enhancement)
    [114051] = {
        class = NS.SHAMAN,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = NS.SHAMAN,
        category = OFFENSIVE,
        duration = 8,
        cooldown = 90,
        index = 2,
    },
    -- Feral Spirit
    [51533] = {
        class = NS.SHAMAN,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Bloodlust (Shamanism)
    [204361] = {
        category = OFFENSIVE,
        duration = 10,
        trackEvent = NS.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Heroism (Shamanism)
    [204362] = {
        category = OFFENSIVE,
        duration = 10,
        trackEvent = NS.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Stormkeeper
    [191634] = {
        class = NS.SHAMAN,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Skyfury
    [208963] = {
        duration = 15,
        category = OFFENSIVE,
        trackEvent = NS.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Fire Elemental
    [198067] = {
        class = NS.SHAMAN,
        category = OFFENSIVE,
        duration = 30,
        cooldown = 150,
        index = 1,
    },

    -- Warlock
    -- Affliction
    -- Summon Darkglare
    [205180] = {
        class = NS.WARLOCK,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = NS.WARLOCK,
        category = OFFENSIVE,
        duration = 30,
    },
    -- Demonology
    -- Nether Portal
    [267217] = {
        class = NS.WARLOCK,
        category = OFFENSIVE,
        duration = 15, -- Show Pit Lord nameplate
        cooldown = 180,
        index = 1,
    },
    -- Summon Demonic Tyrant
    [265187] = {
        class = NS.WARLOCK,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Fel Obelisk
    [353601] = {
        class = NS.WARLOCK,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = NS.WARLOCK,
        category = OFFENSIVE,
        duration = 17,
    },
    -- Gul'dan's Ambition (Pit Lord)
    [387578] = {
        class = NS.WARLOCK,
        duration = 10,
    },

    -- Warrior
    -- Offensive
    -- Warbreaker
    [262161] = {
        class = NS.WARRIOR,
        category = OFFENSIVE,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 2,
    },
    -- Colossus Smash
    [167105] = {
        class = NS.WARRIOR,
        category = OFFENSIVE,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 2,
    },
    -- Spear of Bastion
    [376079] = {
        class = NS.WARRIOR,
        category = OFFENSIVE,
        duration = 4,
        cooldown = 90,
        index = 2,
    },
    -- Avatar
    [107574] = {
        class = NS.WARRIOR,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Recklessness
    [1719] = {
        class = NS.WARRIOR,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 16,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 1,
    },
}

NS.ClassWithFearSpell = function(class)
    return ( class == NS.WARRIOR ) or ( class == NS.PRIEST ) or ( class == NS.WARLOCK );
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
        class = NS.DRUID,
        category = OFFENSIVE,
        duration = 8,
        cooldown = 30,
        index = 1,
        sound = true,
    }
    -- Regrowth
    NS.spellData[8936] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        duration = 5,
        cooldown = 10,
    }
    -- Rejuv
    NS.spellData[774] = {
        class = NS.DRUID,
        category = OFFENSIVE,
        cooldown = 45,
    }
    -- Wild Growth
    NS.spellData[48438] = {
        category = OFFENSIVE,
        duration = 7,
        trackDest = true,
        trackEvent = NS.SPELL_AURA_APPLIED,
    }

    NS.spellData[1459] = {
        class = NS.MAGE,
        category = OFFENSIVE,
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
