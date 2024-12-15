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

    -- Death Knight
    -- Abomination Limb
    [383269] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 12,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Unholy
    -- Raise Abomination
    [455395] = {
        class = addon.DEATHKNIGHT,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 25,
        index = addon.SPELLPRIORITY.HIGH,
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
    -- Frost
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
        index = addon.SPELLPRIORITY.HIGH,
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

    -- Demon Hunter
    -- Eye Beam
    [198013] = {
        class = addon.DEMONHUNTER,
        category = OFFENSIVE,
        cooldown = 40,
        index = addon.SPELLPRIORITY.LOW,
        -- Cooldown reduced by Blade dance, Chaos Strike, Glaive Tempest
        -- Cooldown reset by activating Metamorphosis
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
        cooldown = 120,
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
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Balance
    -- Incarnation: Chosen of Elune (spellID has not changed in DF)
    [102560] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 90, -- Whirling Stars
        duration = 20,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Celestial Alignment
    [194223] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 90, -- Whirling Stars
        duration = 15,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
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
    -- Tiger's Fury
    [5217] = {
        class = addon.DRUID,
        category = OFFENSIVE,
        cooldown = 30,
        duration = 20, -- can end early
        index = addon.SPELLPRIORITY.LOW,
    },

    -- Evoker
    -- Devastation
    -- Deep Breath
    [357210] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        cooldown = 120,
    },
    -- Dragon Rage
    [375087] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        duration = 14,
        cooldown = 120,
        extend = true, -- Animosity
    },
    -- Tip the Scales
    [370553] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        spec = { specID.DEVASTATION, specID.AUGMENTATION },
        cooldown = 120,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Augmentation
    -- Breath of Eons
    [403631] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        cooldown = 120,
    },
    -- Upheaval (bug: not triggered)
    [396286] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        cooldown = 40,
    },
    -- Ebon Might
    [395152] = {
        class = addon.EVOKER,
        category = OFFENSIVE,
        cooldown = 30,
        duration = 10,
        extend = true,
        index = addon.SPELLPRIORITY.LOW,
    },

    -- Hunter
    -- Beast Mastery
    -- Bestial Wrath
    [19574] = {
        class = addon.HUNTER,
        category = OFFENSIVE,
        cooldown = 90, -- Reduced by Barbed Shot
        duration = 15,
    },
    -- Call of the Wild
    [359844] = {
        class = addon.HUNTER,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 20,
    },
    -- Survival
    -- Coordinated Assult
    [360952] = {
        class = addon.HUNTER,
        category = OFFENSIVE,
        cooldown = 60, -- Symboitic Adrenaline (almost always picked)
        duration = 20,
    },
    -- Marksmanship
    -- Trueshot
    [288613] = {
        class = addon.HUNTER,
        category = OFFENSIVE,
        cooldown = 120, -- Reduced by spending focus
        duration = 15,
        reduce_power_type = POWERTYPE.Focus,
        reduce_amount = 0.05, -- Every 50 focus reduces cd by 2.5s
    },

    -- Mage
    -- Frost
    -- Icy Veins (make sure it's not triggered by Time Anomaly)
    [12472] = {
        class = addon.MAGE,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 25,
        index = addon.SPELLPRIORITY.HIGH,
        extend = true,
    },
    -- Ice Form
    [198144] = {
        class = addon.MAGE,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 12,
        extend = true,
    },
    -- Fire
    -- Combustion
    [190319] = {
        class = addon.MAGE,
        category = OFFENSIVE,
        duration = 12,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,

        -- Reduce cooldown by 1s
        -- Fireball, Pyroblast, Fire Blast, Scorch, Phoenix Flames
        critResets = { 133, 11366, 108853, 2948, 257542 },
        critResetAmount = 1,
    },
    -- Arcane
    -- Arcane Surge
    [365350] = {
        class = addon.MAGE,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 15,
        index = addon.SPELLPRIORITY.HIGH,
    },

    -- Monk
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = addon.MONK,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 15,
        charges = true,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
        extend = true,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Serenity
    [152173] = {
        class = addon.MONK,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 12,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.15, -- Every 2 Chi spent reduces the cooldown by 0.3 sec.
        extend = true,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = addon.MONK,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 24,
    },
    -- Dance of Chi-ji (no cooldown, aura only)
    [325202] = {
        class = addon.MONK,
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },

    -- Paladin
    -- Avenging Wrath
    [31884] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        duration = 23, -- Baseline: 20s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RET },
    },
    -- Crusade
    [231895] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        duration = 30, -- Baseline: 27s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RET },
    },
    -- Wake of Ashes
    [255937] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH, -- the new way of activating wing
    },
    -- Divine Toll
    [375576] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        spec = { specID.RET },
        cooldown = 60,
        opt_lower_cooldown = 45,
    },
    -- Blessing of Summer (cannot reliably track cooldown, assume 45s * 3 = 135s perhaps)
    [388007] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        --trackEvent = addon.SPELL_AURA_APPLIED,
        --trackDest = true,
        cooldown = 135,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Final Reckoning
    [343721] = {
        class = addon.PALADIN,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 12,
    },

    -- Priest
    -- Mindgames
    [375901] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        cooldown = 45,
        duration = 7, -- Confirm early dismiss
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Psyfiend
    [211522] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        spellID = 211522,
        cooldown = 45,
        duration = 12, -- If killed early, UNIT_DIED is triggered
    },
    -- Power Infusion
    [10060] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        --trackDest = true,
        --trackEvent = addon.SPELL_AURA_APPLIED, -- Twins of the Sun Pristess (when casting on allies, the self buff doesn't trigger SPELL_CAST_SUCCESS)
        cooldown = 120,
        duration = 20, -- Dismissed when either aura is gone (Twins of the Sun Priestess)
    },
    -- Shadow
    -- Mindbender (Idol of Y'Shaarj)
    [200174] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = OFFENSIVE,
        cooldown = 60,
        duration = 15, -- UNIT_DIED not triggered when expiring, consider using UNIT_PET to scan the entire npcMap
    },
    -- Dark Ascension
    [391109] = {
        category = OFFENSIVE,
        class = addon.PRIEST,
        cooldown = 60,
        duration = 20,
    },
    -- Void Torrent
    [263165] = {
        category = OFFENSIVE,
        class = addon.PRIEST,
        cooldown = 45,
    },
    -- Voidform
    [194249] = {
        category = OFFENSIVE,
        class = addon.PRIEST,
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 120, -- Reduced by Driven to Madness, cannot track reliably
        duration = addon.DURATION_DYNAMIC,
        extend = true,
    },
    -- Holy
    -- Restitution (treat as offensive spell with highest priority. Buff is hidden aura, so we track debuff spellId)
    -- Currently lacking the detection of early dismiss (if the priest right clicks the spirit buff)
    [211319] = {
        class = addon.PRIEST,
        category = OFFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 600,
        duration = 15,
        index = addon.SPELLPRIORITY.HIGH,
    },

    -- Rogue
    -- Cold Blood
    [382245] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 45,
        --spec = {specID.SUBTLETY},
        index = addon.SPELLPRIORITY.HIGH,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Subtlety
    -- Shadow Blades
    [121471] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 20,
    },
    -- Shadow Dance
    [185313] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 30, -- 2 charges but cannot track cd reliably, just divide cd by 2
        duration = 8,
        --spec = {specID.SUBTLETY},
    },
    -- Outlaw
    -- Adrenaline Rush
    [13750] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 180,
        duration = 20,
    },
    -- Between the Eyes
    [315341] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        cooldown = 45,
        duration = 21, -- Max duration, can dismiss early
    },
    -- Assassination
    -- Death Mark
    [360194] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 16, -- confirm early dismiss
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Kingsbane
    [385627] = {
        class = addon.ROGUE,
        category = OFFENSIVE,
        duration = 14,
        index = addon.SPELLPRIORITY.HIGH,
    },

    -- Shaman
    -- Totem of Wrath (cannot track cooldown reliably)
    -- [208963] = {
    --     class = addon.SHAMAN,
    --     cooldown = 45,
    --     duration = 15,
    --     category = OFFENSIVE,
    --     trackEvent = addon.SPELL_AURA_APPLIED,
    --     --trackDest = true,
    -- },
    -- Enhancement
    -- Ascendance (Enhancement)
    [114051] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        cooldown = 180,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 8,
        cooldown = 60,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Feral Spirit
    [51533] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 15,
    },
    -- Bloodlust (Shamanism)
    [204361] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Heroism (Shamanism)
    [204362] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        --trackDest = true,
    },
    -- Elemental
    -- Stormkeeper
    [191634] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        cooldown = 60, -- reduced by Lighting Bolt and Chain Lightning
        duration = 15,
    },
    -- Fire Elemental
    [198067] = {
        class = addon.SHAMAN,
        category = OFFENSIVE,
        cooldown = 150,
        duration = 24,
        index = addon.SPELLPRIORITY.HIGH,
    },

    -- Warlock
    -- Call Observer
    [201996] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 20, -- confirm early dismiss if killed
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Affliction
    -- Soul Rot
    [386997] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        cooldown = 60,
    },
    -- Summon Darkglare
    [205180] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        duration = 20, -- confirm early dismiss if killed
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 30,
    },
    -- Demonology
    -- Summon Demonic Tyrant
    [265187] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        cooldown = 60,
        duration = 15,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        cooldown = 120,
        duration = 17,
    },
    -- Demonic Strength
    [267171] = {
        class = addon.WARLOCK,
        category = OFFENSIVE,
        cooldown = 60,
    },

    -- Warrior
    -- Champion's Spear
    [376079] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 6,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Avatar
    [107574] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 20,
    },
    -- Arms
    -- Warbreaker
    [262161] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Colossus Smash
    [167105] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Fury
    -- Recklessness
    [1719] = {
        class = addon.WARRIOR,
        category = OFFENSIVE,
        cooldown = 90,
        duration = 16,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05, -- Every 20 rage spent reduces the cooldown by 1 sec.
        index = addon.SPELLPRIORITY.HIGH,
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
    -- Pyrokinesis removed

    -- Eye Beam
    -- Metamorphosis
    [191427] = {
        198013, -- Full reset
    },
    -- Blade Dance
    [188499] = {
        [198013] = 1,
    },
    -- Chaos Strike
    [162794] = {
        [198013] = 1,
    },
    -- Glaive Tempest
    [342817] = {
        [198013] = 1,
    },

    -- Bestial Wrath
    -- Barbed Shot
    [217200] = {
        [19574] = 12,
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
        index = addon.SPELLPRIORITY.HIGH,
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
        index = addon.SPELLPRIORITY.HIGH,

        resets = {
            [133] = 2, -- Pyrokinesis
            [314791] = 12, -- Shifting Power
        },

        -- Reduce cooldown by 1s (Phoenix Flames spellID somehow does not work)
        critResets = { 133, 11366, 108853, "Phoenix Flames" },
        critResetAmount = 1,
    };
end
