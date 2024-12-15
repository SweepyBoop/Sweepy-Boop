local _, addon = ...;

local POWERTYPE = Enum.PowerType;

-- trackEvent: event or combat log subEvent to track
-- trackDest: track destGUID instead of sourceGUID, otherwise we assume destGUID == sourceGUID (this cannot be set to spells that can only self cast)

local OFFENSIVE = addon.SPELLCATEGORY.OFFENSIVE

local specID = addon.SPECID

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

addon.spellData = {
    -- General
    -- Offensive

    -- Death Knight
    -- Abomination Limb
    [383269] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 12,
        index = 2,
    },
    -- Offensive (Unholy)
    -- Raise Abomination
    [455395] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 25,
        index = 1,
    },
    -- Unholy Assult
    [207289] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 20,
    },
    -- Dark Transformation
    [63560] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 45,
        duration = 15, -- extended by Eternal Agony (need to track buff on pet, is it feasible)
    },
    -- Apocalypse
    [275699] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 45,
        duration = 20,
    },
    -- Summon Gargoyle
    [49206] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 180,
        duration = 25,
    },
    -- Offensive (Frost)
    -- Remorseless Winter
    [196770] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 20,
        duration = 8,
        extend = true, -- Gathering Storm
    },
    -- Pillar of Frost
    [51271] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 12,
    },
    -- Absolute zero (Frostwyrm's Fury)
    [279302] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 10,
        index = 1,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 20,
    },
    -- Chill Streak
    [305392] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 45,
        duration = 4,
    },
    
    -- DH
    -- Offensive
    -- Eye Beam
    [198013] = {
        class = addon.DEMONHUNTER,
        category = OFFENSIVE,
        cooldown = 40,
        -- Cooldown reduced by Blade dance, Chaos Strike, Glaive Tempest
    },
    -- The Hunt
    [370965] = {
        class = addon.DEMONHUNTER,
        category = OFFENSIVE,
        cooldown = 90,
    },
    -- Metamorphosis (have to track with UNIT_SPELLCAST_SUCCEEDED to exclude auto proc from Eye Beam)
    [191427] = {
        class = addon.DEMONHUNTER,
        category = OFFENSIVE,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
        cooldown = 180,
        duration = 24,
    },
    -- Essence Break
    [258860] = {
        class = addon.DEMONHUNTER,
        category = OFFENSIVE,
        cooldown = 40,
        duration = 4,
    },

    -- Druid
    -- Convoke the Spirits
    [391528] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 60,
        index = 1,
    },
    -- Balance
    -- Incarnation: Chosen of Elune (spellID has not changed in DF)
    [102560] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 90, -- Whirling Stars
        duration = 20,
        charges = true, -- Whirling Stars
        index = 1,
    },
    -- Celestial Alignment
    [194223] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 90, -- Whirling Stars
        duration = 15,
        charges = true, -- Whirling Stars
        index = 1,
    },
    -- Force of Nature
    [205636] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 10,
    },
    -- Fury of Elune
    [202770] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 8,
    },
    -- Feral
    -- Berserk
    [106951] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 20,
    },
    -- Incarnation: Avatar of Ashamane
    [102543] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 20,
    },
    -- Feral Frenzy
    [274837] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 45,
    },
    
    -- Evoker
    -- Tip the Scales
    [370553] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        spec = { specID.DEVASTATION },
        cooldown = 120,
    },
    -- Dragon Rage
    [375087] = {
        class = addon.EVOKER,
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
        class = addon.HUNTER,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Coordinated Assult
    [360952] = {
        class = addon.HUNTER,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Trueshot
    [288613] = {
        class = addon.HUNTER,
        category = OFFENSIVE,
        duration = 18,
    },
    -- Call of the Wild
    [359844] = {
        class = addon.HUNTER,
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
        class = addon.MAGE,
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
        class = addon.MAGE,
        category = OFFENSIVE,
        duration = 25,
        extend = true,
    },
    -- Ice Form
    [198144] = {
        class = addon.MAGE,
        category = OFFENSIVE,
        duration = 12,
        extend = true,
    },
    -- Arcane Surge
    [365350] = {
        class = addon.MAGE,
        category = OFFENSIVE,
        cooldown = 90,
        index = 1,
    },

    -- Monk
    -- Offensive
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = addon.MONK,
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
        class = addon.MONK,
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
        class = addon.MONK,
        category = OFFENSIVE,
        duration = 24,
    },
    -- Bonedust Brew
    [386276] = {
        class = addon.MONK,
        category = OFFENSIVE,
        duration = 10,
        spec = { specID.WW },
        index = 2,
    },
    -- Dance of Chi-ji
    [325202] = {
        class = addon.MONK,
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        index = 2,
    },

    -- Paladin
    -- Offensive
    -- Avenging Wrath
    [31884] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        duration = 23, -- Baseline: 20s, Divine Wrath: 3s
        cooldown = 60, -- Avenging Wrath: Might
        sound = true,
        index = 1,
        spec = { specID.RET },
    },
    -- Crusade
    [231895] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        duration = 30, -- Baseline: 27s, Divine Wrath: 3s
        cooldown = 120,
        sound = true,
        index = 1,
        spec = { specID.RET },
    },
    -- Divine Toll
    [375576] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        spec = { specID.RET },
        cooldown = 60,
        opt_lower_cooldown = 45,
    },
    -- Blessing of Summer
    [388007] = {
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
        index = 2,
    },
    -- Final Reckoning
    [343721] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        duration = 12,
    },

    -- Priest
    -- Offensive
    -- Mindgames
    [375901] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        cooldown = 45,
        index = 1,
    },
    -- Mindbender (Idol of Y'Shaarj)
    [200174] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = OFFENSIVE,
        duration = 15,
        cooldown = 60,
    },
    -- Psyfiend
    [211522] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        spellID = 211522,
        duration = 12,
    },
    -- Power Infusion
    [10060] = {
        category = OFFENSIVE,
        trackDest = true,
        trackEvent = addon.SPELL_AURA_APPLIED, -- Twins of the Sun Pristess (when casting on allies, the self buff doesn't trigger SPELL_CAST_SUCCESS)
        duration = 20,
    },
    -- Dark Ascension
    [391109] = {
        category = OFFENSIVE,
        class = addon.PRIEST,
        duration = 20,
    },
    -- Voidform
    [194249] = {
        category = OFFENSIVE,
        class = addon.PRIEST,
        trackEvent = addon.SPELL_AURA_APPLIED,
        duration = addon.DURATION_DYNAMIC,
    },
    -- Restitution (treat as offensive spell with highest priority. Buff is hidden aura, so we track debuff spellId)
    -- Currently lacking the detection of early dismiss (if the priest right clicks the spirit buff)
    [211319] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        duration = 15,
        index = 1,
    },

    -- Rogue
    -- Offensive
    -- Shadow Blades
    [121471] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Adrenaline Rush
    [13750] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Sepsis
    [385408] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 10,
    },
    -- Death Mark
    [360194] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 16,
        cooldown = 120,
        index = 1,
        sound = true,
    },
    -- Exsanguinate
    [200806] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 180,
        index = 2,
    },
    -- Kingsbane
    [385627] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 14,
        index = 2,
    },
    -- Echoing Reprimand
    [323560] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },
    -- Cold Blood
    [382245] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 45,
        spec = {specID.SUBTLETY},
        index = 2,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Shadow Dance
    [185313] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 8,
        spec = {specID.SUBTLETY},
    },

    -- Shaman
    -- Offensive
    -- Ascendance (Enhancement)
    [114051] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 8,
        cooldown = 90,
        index = 2,
    },
    -- Feral Spirit
    [51533] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Bloodlust (Shamanism)
    [204361] = {
        category = OFFENSIVE,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Heroism (Shamanism)
    [204362] = {
        category = OFFENSIVE,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Stormkeeper
    [191634] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Totem of Wrath
    [208963] = {
        duration = 15,
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Fire Elemental
    [198067] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 30,
        cooldown = 150,
        index = 1,
    },

    -- Warlock
    -- Affliction
    -- Summon Darkglare
    [205180] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 30,
    },
    -- Demonology
    -- Nether Portal
    [267217] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 15, -- Show Pit Lord nameplate
        cooldown = 180,
        index = 1,
    },
    -- Summon Demonic Tyrant
    [265187] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Fel Obelisk
    [353601] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 15,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 17,
    },
    -- Gul'dan's Ambition (Pit Lord)
    [387578] = {
        class = addon.WARLOCK,
        duration = 10,
    },

    -- Warrior
    -- Offensive
    -- Warbreaker
    [262161] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 2,
    },
    -- Colossus Smash
    [167105] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 2,
    },
    -- Spear of Bastion
    [376079] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        duration = 4,
        cooldown = 90,
        index = 2,
    },
    -- Avatar
    [107574] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        duration = 20,
    },
    -- Recklessness
    [1719] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 16,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = 1,
    },
};

addon.spellResets = {
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
};

if addon.isTestMode then
    -- Test
    -- Mark of the Wild
    addon.spellData[1126] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        duration = 8,
        cooldown = 30,
        index = 1,
        sound = true,
    };
    -- Regrowth
    addon.spellData[8936] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        duration = 5,
        cooldown = 10,
    };
    -- Rejuv
    addon.spellData[774] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 45,
    };
    -- Wild Growth
    addon.spellData[48438] = {
        category = OFFENSIVE,
        duration = 7,
        trackDest = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
    };

    addon.spellData[1459] = {
        class = addon.MAGE,
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
    };
end
