local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.category;

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

addon.SpellData = {
    -- General

    -- Death Knight
    -- Abomination Limb
    [383269] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 120,
        duration = 12,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Unholy
    -- Raise Abomination
    [455395] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 90,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Unholy Assult
    [207289] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 90,
        duration = 20,
    },
    -- Dark Transformation
    [63560] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 45,
        duration = 15, -- extended by Eternal Agony (need to track buff on pet, is it feasible)
    },
    -- Apocalypse
    [275699] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 45,
        duration = 20,
    },
    -- Summon Gargoyle
    [49206] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 180,
        duration = 25,
    },
    -- Frost
    -- Remorseless Winter
    [196770] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 20,
        duration = 8,
        extend = true, -- Gathering Storm
    },
    -- Pillar of Frost
    [51271] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 60,
        duration = 12,
    },
    -- Absolute zero (Frostwyrm's Fury)
    [279302] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 90,
        duration = 10,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Chill Streak
    [305392] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 45,
        duration = 4,
    },
    -- Interrupt
    -- Mind Freeze
    [47528] = {
        class = addon.DEATHKNIGHT,
        category = category.INTERRUPT,
        cooldown = 15,
    },
    -- Shambling Rush
    [91807] = {
        class = addon.DEATHKNIGHT,
        category = category.INTERRUPT,
        cooldown = 30,
        trackPet = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },
    -- Disrupt
    -- Death Grip
    [49576] = {
        class = addon.DEATHKNIGHT,
        category = category.DISRUPT,
        cooldown = 25,
        --opt_charges = true,
        charges = true, -- Death's Echo is almost always picked
    },
    -- Crowd Control
    -- Strangulate
    [47476] = {
        class = addon.DEATHKNIGHT,
        category = category.CROWDCONTROL,
        cooldown = 60,
    },
    -- Blinding Sleet
    [207167] = {
        class = addon.DEATHKNIGHT,
        category = category.CROWDCONTROL,
        cooldown = 60,
    },
    -- Asphyxiate
    [221562] = {
        class = addon.DEATHKNIGHT,
        category = category.CROWDCONTROL,
        cooldown = 45,
    },
    -- Defensive
    -- Icebound Fortitude
    [48792] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Anti-Magic Shell
    [48707] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 40, -- Anti-Magic Barrier almost always picked
    },
    -- Anti-Magic Zone
    [51052] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
        opt_lower_cooldown = 90, -- Assimilation
    },

    -- Demon Hunter
    -- Eye Beam
    [198013] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        cooldown = 40,
        index = addon.SPELLPRIORITY.LOW,
        -- Cooldown reduced by Blade dance, Chaos Strike, Glaive Tempest
        -- Cooldown reset by activating Metamorphosis
    },
    -- The Hunt
    [370965] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        cooldown = 90,
    },
    -- Metamorphosis (have to track with UNIT_SPELLCAST_SUCCEEDED to exclude auto proc from Eye Beam)
    [191427] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        trackEvent = addon.UNIT_SPELLCAST_SUCCEEDED,
        cooldown = 120,
        duration = 24,
    },
    -- Essence Break
    [258860] = {
        class = addon.DEMONHUNTER,
        category = category.BURST,
        cooldown = 40,
        duration = 4,
    },
    -- Interrupt
    -- Disrupt
    [183752] = {
        class = addon.DEMONHUNTER,
        category = category.INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
    -- Blur
    [198589] = {
        cooldown = 60,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE
    },
    -- Netherwalk
    [196555] = {
        cooldown = 180,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE
    },
    -- Darkness
    [196718] = {
        cooldown = 180,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE
    },
    -- Crowd Control
    -- Imprison
    [217832] = {
        cooldown = 45,
        class = addon.DEMONHUNTER,
        category = category.CROWDCONTROL,
    },
    -- Imprison (Detainment)
    [221527] = {
        cooldown = 45,
        class = addon.DEMONHUNTER,
        category = category.CROWDCONTROL,
    },
    -- Fel Eruption
    [211881] = {
        cooldown = 30,
        class = addon.DEMONHUNTER,
        category = category.CROWDCONTROL,
    },

    -- Druid
    -- Convoke the Spirits
    [391528] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 60,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Balance
    -- Incarnation: Chosen of Elune (spellID has not changed in DF)
    [102560] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 90, -- Whirling Stars
        duration = 20,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Celestial Alignment
    [194223] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 90, -- Whirling Stars
        duration = 15,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Force of Nature
    [205636] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 60,
        duration = 10,
    },
    -- Fury of Elune
    [202770] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 60,
        duration = 8,
    },
    -- Feral
    -- Berserk
    [106951] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Incarnation: Avatar of Ashamane
    [102543] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Feral Frenzy
    [274837] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 45,
    },
    -- Tiger's Fury
    [5217] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 30,
        duration = 20, -- can end early
        index = addon.SPELLPRIORITY.LOW,
    },
    -- Crowd Control
    -- Mighty Bash
    [5211] = {
        cooldown = 60,
        class = addon.DRUID,
        category = category.CROWDCONTROL
    },
    -- Maim
    [22570] = {
        cooldown = 20,
        class = addon.DRUID,
        category = category.CROWDCONTROL
    },
    -- Incapacitating Roar
    [99] = {
        cooldown = 30,
        class = addon.DRUID,
        category = category.CROWDCONTROL
    },
    -- Solar Beam
    [78675] = {
        cooldown = 60,
        class = addon.DRUID,
        reduce_on_interrupt = 15,
        category = category.CROWDCONTROL
    },
    -- Interrupt
    -- Skull Bash
    [106839] = {
        cooldown = 15,
        class = addon.DRUID,
        category = category.INTERRUPT
    },
    -- Defensive
    -- Survival Instincts
    [61336] = {
        cooldown = {default = 180, [specID.GUARDIAN] = 120},
        class = addon.DRUID,
        charges = {[specID.GUARDIAN] = true},
        category = category.DEFENSIVE
    },
    -- Ironbark
    [102342] = {
        cooldown = 90,
        class = addon.DRUID,
        opt_lower_cooldown = 70,
        category = category.DEFENSIVE
    },
    -- Barkskin
    [22812] = {
        cooldown = 60,
        class = addon.DRUID,
        category = category.DEFENSIVE
    },
    -- Dispel
    -- Nature's Cure
    [88423] = {
        cooldown = 8,
        class = addon.DRUID,
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL
    },

    -- Evoker
    -- Devastation
    -- Deep Breath
    [357210] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 120,
    },
    -- Dragon Rage
    [375087] = {
        class = addon.EVOKER,
        category = category.BURST,
        duration = 14,
        cooldown = 120,
        extend = true, -- Animosity
    },
    -- Tip the Scales
    [370553] = {
        class = addon.EVOKER,
        category = category.BURST,
        spec = { specID.DEVASTATION, specID.AUGMENTATION },
        cooldown = 120,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Augmentation
    -- Breath of Eons
    [403631] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 120,
    },
    -- Upheaval (bug: not triggered)
    [396286] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 40,
    },
    -- Ebon Might
    [395152] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 30,
        duration = 10,
        extend = true,
        index = addon.SPELLPRIORITY.LOW,
    },
    -- Defensive
    -- Obsidian Scales
    [363916] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 90,
        charges = true,
    },
    -- Renewing Blaze
    [374348] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Emerald Communion
    [370960] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 180,
    },
    -- Cauterizing Flame
    [374251] = {
        class = addon.EVOKER,
        category = category.DEFENSIVE,
        cooldown = 60,
    },
    -- Interrupt
    -- Quell
    [351338] = {
        cooldown = {default = 40, [specID.DEVASTATION] = 20},
        class = addon.EVOKER,
        category = category.INTERRUPT,
    },
    -- Crowd Control
    -- Dispel
    -- Naturalize
    [360823] = {
        cooldown = 8,
        class = addon.EVOKER,
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },
    -- Disrupt
    -- Fire Breath (Scouring Flame which purges 1 buff per empower level)
    [382266] = {
        cooldown = 30,
        class = addon.EVOKER,
        category = category.DISRUPT,
        trackEvent = addon.SPELL_EMPOWER_END,
    },

    -- Hunter
    -- Beast Mastery
    -- Bestial Wrath
    [19574] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 90, -- Reduced by Barbed Shot
        duration = 15,
    },
    -- Call of the Wild
    [359844] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Survival
    -- Coordinated Assult
    [360952] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 60, -- Symboitic Adrenaline (almost always picked)
        duration = 20,
    },
    -- Marksmanship
    -- Trueshot
    [288613] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 120, -- Reduced by spending focus
        duration = 15,
        reduce_power_type = POWERTYPE.Focus,
        reduce_amount = 0.05, -- Every 50 focus reduces cd by 2.5s
    },
    -- Disrupt
    -- Feign Death
    [5384] = {
        class = addon.HUNTER,
        category = category.DISRUPT,
        cooldown = 30,
    },
    -- Crowd Control
    -- Intimidation
    [19577] = {
        cooldown = 60,
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
    },
    -- Freezing Trap
    [187650] = {
        cooldown = 25,
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
    },
    -- Defensive
    -- Survival of the Fittest
    [264735] = {
        cooldown = 90,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        charges = true
    },
    -- Aspect of the Turtle
    [186265] = {
        cooldown = 144,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH
    },
    -- Roar of Sacrifice (need to confirm)
    [53480] = {
        cooldown = 60,
        class = addon.HUNTER,
        category = category.DEFENSIVE
    },
    -- Interrupt
    -- Counter Shot
    [147362] = {
        cooldown = 24,
        class = addon.HUNTER,
        category = category.INTERRUPT
    },
    -- Muzzle
    [187707] = {
        cooldown = 15,
        class = addon.HUNTER,
        category = category.INTERRUPT
    },

    -- Mage
    -- Frost
    -- Icy Veins (make sure it's not triggered by Time Anomaly)
    [12472] = {
        class = addon.MAGE,
        category = category.BURST,
        cooldown = 120,
        duration = 25,
        index = addon.SPELLPRIORITY.HIGH,
        extend = true,
    },
    -- Ice Form
    [198144] = {
        class = addon.MAGE,
        category = category.BURST,
        cooldown = 60,
        duration = 12,
        extend = true,
    },
    -- Fire
    -- Combustion
    [190319] = {
        class = addon.MAGE,
        category = category.BURST,
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
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Interrupt
    -- Counterspell
    [2139] = {
        cooldown = 24,
        class = addon.MAGE,
        reduce_on_interrupt = 4,
        category = category.INTERRUPT,
    },
    -- Defensive
    -- Ice Block
    [45438] = {
        cooldown = 180,
        class = addon.MAGE,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Cauterize
    [87024] = {
        cooldown = 300,
        class = addon.MAGE,
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Temporal Shield
    [198111] = {
        cooldown = 45,
        class = addon.MAGE,
        category = category.DEFENSIVE,
    },
    -- Cold Snap (resets ice block)
    [235219] = {
        cooldown = 300,
        class = addon.MAGE,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Crowd Control
    -- Ring of Frost
    [113724] = {
        cooldown = 45,
        class = addon.MAGE,
        category = category.CROWDCONTROL,
    },
    -- Dragon's Breath
    [31661] = {
        cooldown = 45,
        class = addon.MAGE,
        category = category.CROWDCONTROL,
    },
    -- Disrupt
    -- Kleptomania (now a channel with a different spellID)
    [198100] = {
        cooldown = 20,
        class = addon.MAGE,
        category = category.DISRUPT,
    },

    -- Monk
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = addon.MONK,
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        charges = true,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
        extend = true,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = addon.MONK,
        category = category.BURST,
        cooldown = 120,
        duration = 24,
    },
    -- Dance of Chi-ji (no cooldown, aura only)
    [325202] = {
        class = addon.MONK,
        category = category.BURST,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },
    -- Crowd Control
    -- Paralysis
    [115078] = {
        cooldown = 30,
        class = addon.MONK,
        category = category.CROWDCONTROL,
    },
    -- Leg Sweep
    [119381] = {
        cooldown = 50,
        class = addon.MONK,
        category = category.CROWDCONTROL,
    },
    -- Breath of Fire (Incendiary Breath)
    [115181] = {
        cooldown = 30,
        class = addon.MONK,
        category = category.CROWDCONTROL,
    },
    -- Ring of Peace
    [116844] = {
        cooldown = 45,
        class = addon.MONK,
        category = category.DISRUPT,
    },
    -- Spear Hand Strike
    [116705] = {
        cooldown = 15,
        class = addon.MONK,
        category = category.DISRUPT,
    },
    -- Touch of Karma
    [122470] = {
        cooldown = 90,
        class = addon.MONK,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Life Cocoon (120 baseline - 45s from Chrysalis)
    [116849] = {
        cooldown = 75,
        class = addon.MONK,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Diffuse Magic
    [122783] = {
        cooldown = 90,
        class = addon.MONK,
        category = category.DEFENSIVE,
    },
    -- Detox
    [115450] = {
        cooldown = 8,
        class = addon.MONK,
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
    },

    -- Paladin
    -- Avenging Wrath
    [31884] = {
        class = addon.PALADIN,
        category = category.BURST,
        duration = 23, -- Baseline: 20s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RET },
    },
    -- Crusade
    [231895] = {
        class = addon.PALADIN,
        category = category.BURST,
        duration = 30, -- Baseline: 27s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RET },
    },
    -- Wake of Ashes
    [255937] = {
        class = addon.PALADIN,
        category = category.BURST,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH, -- the new way of activating wing
    },
    -- Divine Toll
    [375576] = {
        class = addon.PALADIN,
        category = category.BURST,
        spec = { specID.RET },
        cooldown = 60,
        opt_lower_cooldown = 45,
    },
    -- Blessing of Summer (cannot reliably track cooldown, assume 45s * 3 = 135s perhaps)
    [388007] = {
        class = addon.PALADIN,
        category = category.BURST,
        --trackEvent = addon.SPELL_AURA_APPLIED,
        --trackDest = true,
        cooldown = 135,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Final Reckoning
    [343721] = {
        class = addon.PALADIN,
        category = category.BURST,
        cooldown = 60,
        duration = 12,
    },
    -- Defensive
    -- Divine Shield
    [642] = {
        cooldown = 210,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Blessing of Protection
    [1022] = {
        cooldown = 240,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        opt_charges = true,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Blessing of SpellWarding
    [204018] = {
        cooldown = 240,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Lay on Hands
    [633] = {
        cooldown = 420,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Divine Protection
    [498] = {
        cooldown = 60,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
    },
    -- Shield of Vengeance
    [184662] = {
        cooldown = 90,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
    },
    -- Crowd Control
    -- Hammer of Justice
    [853] = {
        cooldown = 45,
        class = addon.PALADIN,
        category = category.CROWDCONTROL,
    },
    -- Blinding Light
    [115750] = {
        cooldown = 90,
        class = addon.PALADIN,
        category = category.CROWDCONTROL,
    },
    -- Shield of Virtue
    [215652] = {
        cooldown = 45,
        class = addon.PALADIN,
        category = category.CROWDCONTROL,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Interrupt
    -- Rebuke
    [96231] = {
        cooldown = 15,
        class = addon.PALADIN,
        category = category.INTERRUPT,
    },
    -- Dispel
    [4987] = {cooldown = 8, class = addon.PALADIN, category = category.DISPEL, trackEvent = addon.SPELL_DISPEL}, -- Cleanse
    [210256] = {cooldown = 45, class = addon.PALADIN, category = category.DISPEL}, -- Blessing of Sanctuary

    -- Priest
    -- Mindgames
    [375901] = {
        class = addon.PRIEST,
        category = category.BURST,
        cooldown = 45,
        duration = 7, -- Confirm early dismiss
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Psyfiend
    [211522] = {
        class = addon.PRIEST,
        category = category.BURST,
        spellID = 211522,
        cooldown = 45,
        duration = 12, -- If killed early, UNIT_DIED is triggered
    },
    -- Power Infusion
    [10060] = {
        class = addon.PRIEST,
        category = category.BURST,
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
        category = category.BURST,
        cooldown = 60,
        duration = 15, -- UNIT_DIED not triggered when expiring, consider using UNIT_PET to scan the entire npcMap
    },
    -- Dark Ascension
    [391109] = {
        category = category.BURST,
        class = addon.PRIEST,
        cooldown = 60,
        duration = 20,
    },
    -- Void Torrent
    [263165] = {
        category = category.BURST,
        class = addon.PRIEST,
        cooldown = 45,
    },
    -- Voidform
    [194249] = {
        category = category.BURST,
        class = addon.PRIEST,
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 120, -- Reduced by Driven to Madness, cannot track reliably
        duration = addon.DURATION_DYNAMIC,
        extend = true,
    },
    -- Dispel
    -- Mass Dispel
    [32375] = {
        cooldown = 45,
        class = addon.PRIEST,
        category = category.DISPEL,
        opt_lower_cooldown = 25,
    },
    -- Purify
    [527] = {
        cooldown = 8,
        class = addon.PRIEST,
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        opt_charges = true,
    },
    -- Crowd Control
    -- Psychic Scream
    [8122] = {
        cooldown = 30,
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
    },
    -- Holy Word: Chastise
    [88625] = {
        cooldown = 60,
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
    },
    -- Silence
    [15487] = {
        cooldown = 45,
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
        opt_lower_cooldown = 30,
    },
    -- Psychic Horror
    [64044] = {
        cooldown = 45,
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
    },
    -- Defensive
    -- Void Shift
    [108968] = {
        cooldown = 300,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Pain Suppression
    [33206] = {
        cooldown = 180,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        charges = true,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Rapture
    [47536] = {
        cooldown = 90,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
    },
    -- Guardian Spirit
    [47788] = {
        cooldown = 60, -- Assume it didn't proc
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Dispersion
    [47585] = {
        cooldown = 90,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Restitution
    [211319] = {
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 600,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Disrupt
    -- Holy Ward
    [213610] = {
        cooldown = 45,
        class = addon.PRIEST,
        category = category.DISRUPT,
    },
    -- Fade (Phase Shift)
    [408558] = {
        cooldown = 30,
        opt_lower_cooldown = 20,
        class = addon.PRIEST,
        category = category.DISRUPT,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },

    -- Rogue
    -- Cold Blood
    [382245] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 45,
        --spec = {specID.SUBTLETY},
        index = addon.SPELLPRIORITY.HIGH,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Subtlety
    -- Shadow Blades
    [121471] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 90,
        duration = 20,
    },
    -- Shadow Dance
    [185313] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 30, -- 2 charges but cannot track cd reliably, just divide cd by 2
        duration = 8,
        --spec = {specID.SUBTLETY},
    },
    -- Outlaw
    -- Adrenaline Rush
    [13750] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 180,
        duration = 20,
    },
    -- Between the Eyes
    [315341] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 45,
        duration = 21, -- Max duration, can dismiss early
    },
    -- Assassination
    -- Death Mark
    [360194] = {
        class = addon.ROGUE,
        category = category.BURST,
        duration = 16, -- confirm early dismiss
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Kingsbane
    [385627] = {
        class = addon.ROGUE,
        category = category.BURST,
        duration = 14,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Interrupt
    [1766] = {cooldown = 15, class = addon.ROGUE, category = category.INTERRUPT}, -- Kick
    -- Defensive
    [1856] = {cooldown = 120, class = addon.ROGUE, charges = true, category = category.DEFENSIVE}, -- Vanish (addition charge in class talent tree)
    [31224] = {cooldown = 120, class = addon.ROGUE, category = category.DEFENSIVE}, -- Cloak of Shadows
    [5277] = {cooldown = 120, class = addon.ROGUE, category = category.DEFENSIVE}, -- Evasion
    -- Crowd Control
    [408] = {cooldown = 20, class = addon.ROGUE, category = category.CROWDCONTROL}, -- Kidney Shot
    [2094] = {cooldown = {default = 120, [specID.OUTLAW] = 90}, class = addon.ROGUE, category = category.CROWDCONTROL}, -- Blind
    [212182] = {cooldown = 180, class = addon.ROGUE, category = category.CROWDCONTROL}, -- Smoke Bomb
    [359053] = {cooldown = 120, class = addon.ROGUE, category = category.CROWDCONTROL}, -- Smoke Bomb (Subtlety)
    -- Disrupt
    [36554] = {cooldown = 30, class = addon.ROGUE, charges = {[specID.ASSASSIN] = true, [specID.SUBTLETY] = true}, category = category.DISRUPT}, -- Shadowstep
    [195457] = {cooldown = 30, class = addon.ROGUE, category = category.DISRUPT}, -- Grappling Hook

    -- Shaman
    -- Totem of Wrath (cannot track cooldown reliably)
    -- [208963] = {
    --     class = addon.SHAMAN,
    --     cooldown = 45,
    --     duration = 15,
    --     category = category.BURST,
    --     trackEvent = addon.SPELL_AURA_APPLIED,
    --     --trackDest = true,
    -- },
    -- Enhancement
    -- Ascendance (Enhancement)
    [114051] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 180,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = addon.SHAMAN,
        category = category.BURST,
        duration = 8,
        cooldown = 60,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Feral Spirit
    [51533] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 90,
        duration = 15,
    },
    -- Bloodlust (Shamanism)
    [204361] = {
        class = addon.SHAMAN,
        category = category.BURST,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Heroism (Shamanism)
    [204362] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 60,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        --trackDest = true,
    },
    -- Elemental
    -- Stormkeeper
    [191634] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 60, -- reduced by Lighting Bolt and Chain Lightning
        duration = 15,
    },
    -- Fire Elemental
    [198067] = {
        class = addon.SHAMAN,
        category = category.BURST,
        cooldown = 150,
        duration = 24,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Interrupt
    [57994] = {cooldown = 12, class = addon.SHAMAN, category = category.INTERRUPT}, -- Wind Shear
    -- Defensive
    [108271] = {cooldown = 90, class = addon.SHAMAN, category = category.DEFENSIVE}, -- Astral Shift (120s baseline, -30 Planes Traveler)
    [98008] = {cooldown = 180, class = addon.SHAMAN, category = category.DEFENSIVE}, -- Spirit Link Totem
    [409293] = {cooldown = 120, class = addon.SHAMAN, category = category.DEFENSIVE}, -- Burrow
    [108270] = {cooldown = 180, class = addon.SHAMAN, category = category.DEFENSIVE}, -- Stone Bulwark Totem (can be reset by Totemic Recall)
    -- Disrupt
    [204336] = {cooldown = 30, class = addon.SHAMAN, category = category.DISRUPT}, -- Grounding Totem
    -- Dispel
    [77130] = {cooldown = 8, class = addon.SHAMAN, category = category.DISPEL, trackEvent = addon.SPELL_DISPEL}, -- Purify Spirit

    -- Warlock
    -- Call Observer
    [201996] = {
        class = addon.WARLOCK,
        category = category.BURST,
        cooldown = 60,
        duration = 20, -- confirm early dismiss if killed
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Affliction
    -- Soul Rot
    [386997] = {
        class = addon.WARLOCK,
        category = category.BURST,
        cooldown = 60,
    },
    -- Summon Darkglare
    [205180] = {
        class = addon.WARLOCK,
        category = category.BURST,
        duration = 20, -- confirm early dismiss if killed
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = addon.WARLOCK,
        category = category.BURST,
        cooldown = 120,
        duration = 30,
    },
    -- Demonology
    -- Summon Demonic Tyrant
    [265187] = {
        class = addon.WARLOCK,
        category = category.BURST,
        cooldown = 60,
        duration = 15,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = addon.WARLOCK,
        category = category.BURST,
        cooldown = 120,
        duration = 17,
    },
    -- Demonic Strength
    [267171] = {
        class = addon.WARLOCK,
        category = category.BURST,
        cooldown = 60,
    },
    -- Crowd Control
    -- Mortal Coil
    [6789] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.CROWDCONTROL,
    },
    -- Howl of Terror
    [5484] = {
        cooldown = 40,
        class = addon.WARLOCK,
        category = category.CROWDCONTROL,
    },
    -- Axe Toss
    [89766] = {
        cooldown = 30,
        class = addon.WARLOCK,
        trackPet = true,
        category = category.CROWDCONTROL,
    },
    -- Axe Toss (Command Demon Ability) (only shows up once no matter which version is cast)
    [119914] = {
        parent = 89766,
    },
    -- Unending Resolve
    [104773] = {
        cooldown = 180,
        class = addon.WARLOCK,
        opt_lower_cooldown = 135,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Soul Rip
    [410598] = {
        cooldown = 60,
        class = addon.WARLOCK,
        opt_lower_cooldown = 135,
        category = category.DEFENSIVE,
    },
    -- Dark Pact
    [108416] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
    },
    -- Spell Lock (Command Demon Ability)
    [19647] = {
        cooldown = 24,
        class = addon.WARLOCK,
        trackPet = true,
        category = category.INTERRUPT,
    },
    -- Spell Lock (Grimoire of Sacrifice)
    [132409] = {
        parent = 19647,
    },
    -- Optical Blast (Command Demon)
    [119911] = {
        parent = 19647,
    },
    -- Optical Blast (Observer)
    [115781] = {
        parent = 19647,
    },
    -- Shadow Lock (Doomguard)
    [171138] = {
        parent = 19647,
    },
    -- Shadow Lock (Grimoire of Sacrifice)
    [171139] = {
        parent = 19647,
    },
    -- Shadow Lock (Command Demon)
    [171140] = {
        parent = 19647,
    },
    -- Call Felhunter
    [212619] = {
        cooldown = 60,
        class = addon.WARLOCK,
        category = category.INTERRUPT,
    },
    -- Nether Ward
    [212295] = {
        cooldown = 45,
        class = addon.WARLOCK,
        category = category.DISRUPT,
    },
    -- Champion's Spear
    [376079] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 90,
        duration = 6,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Avatar
    [107574] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 90,
        duration = 20,
    },
    -- Warbreaker
    [262161] = {
        class = addon.WARRIOR,
        category = category.BURST,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Colossus Smash
    [167105] = {
        class = addon.WARRIOR,
        category = category.BURST,
        duration = 10,
        cooldown = 45,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Recklessness
    [1719] = {
        class = addon.WARRIOR,
        category = category.BURST,
        cooldown = 90,
        duration = 16,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Charge
    [100] = {
        cooldown = 17,
        class = addon.WARRIOR,
        charges = true,
        category = category.DISRUPT,
    },
    -- Spell Reflection
    [23920] = {
        cooldown = 23.75,
        class = addon.WARRIOR,
        category = category.DISRUPT,
    },
    -- Heroic Leap
    [6544] = {
        cooldown = 30,
        class = addon.WARRIOR,
        category = category.DISRUPT,
    },
    -- Pummel
    [6552] = {
        cooldown = 14.25,
        class = addon.WARRIOR,
        category = category.INTERRUPT,
    },
    -- Storm Bolt
    [107570] = {
        cooldown = 28.5,
        class = addon.WARRIOR,
        category = category.CROWDCONTROL,
    },
    -- Intimidating Shout
    [5246] = {
        cooldown = 90,
        class = addon.WARRIOR,
        category = category.CROWDCONTROL,
    },
    -- Die by the Sword
    [118038] = {
        cooldown = 85.5,
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
    },
    -- Enraged Regeneration
    [184364] = {
        cooldown = 114,
        class = addon.WARRIOR,
        category = category.DEFENSIVE,
    },
};

addon.SpellResets = {
    -- Metamorphosis
    [191427] = {
        198013, -- Eye Beam
    },
    -- Blade Dance
    [188499] = {
        { spellID = 198013, amount = 1 }, -- Eye Beam
    },
    -- Chaos Strike
    [162794] = {
        { spellID = 198013, amount = 1 }, -- Eye Beam
    },
    -- Glaive Tempest
    [342817] = {
        { spellID = 198013, amount = 1 }, -- Eye Beam
    },

    -- Bestial Wrath
    -- Barbed Shot
    [217200] = {
        { spellID = 19574, amount = 12 }, -- Bestial Wrath
    },

    -- Shifting Power
    [382440] = {
        { spellID = 31661, amount = 12 }, -- Dragon's Breath
        { spellID = 113724, amount = 12 }, -- Ring of Frost
        { spellID = 2139, amount = 12 }, -- Counterspell
        { spellID = 45438, amount = 12 }, -- Ice Block
        { spellID = 190319, amount = 12 }, -- Combustion
    },
    -- Cold Snap
    [235219] = {
        45438, -- Ice Block
    },

    -- Apotheosis
    [200183] = {
        88625, -- Holy Word: Chastise
    },
    -- Smite
    [585] = {
        { spellID = 88625, amount = 4 }, -- -- Holy Word: Chastise
    },
    -- Holy Fire
    [14914] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },

    -- Vanish (Memory of Invigorating Shadowdust, Subtlety Rogue)
    [1856] = {
        { spellID = 2094, amount = 15, specID = {specID.SUBTLETY} }, -- Blind
        { spellID = 408, amount = 15, specID = {specID.SUBTLETY} }, -- Kidney Shot
        { spellID = 212182, amount = 15, specID = {specID.SUBTLETY} }, -- Smoke Bomb
        { spellID = 1766, amount = 15, specID = {specID.SUBTLETY} }, -- Kick
        { spellID = 36554, amount = 15, specID = {specID.SUBTLETY} }, -- Shadowstep
    },

    -- Power Word: Shield
    [17] = { { spellID = 33206, amount = 3 } }, -- Pain Suppression
};