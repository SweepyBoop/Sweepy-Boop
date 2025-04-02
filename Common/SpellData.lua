local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

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
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 90,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Unholy Assult
    [207289] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 90,
        duration = 20,
    },
    -- Dark Transformation
    [63560] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 45,
        duration = 15, -- extended by Eternal Agony (need to track buff on pet, is it feasible)
    },
    -- Apocalypse
    [275699] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 45,
        duration = 20,
    },
    -- Summon Gargoyle
    [49206] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 25,
    },
    -- Frost
    -- Remorseless Winter
    [196770] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 20,
        duration = 8,
        extend = true, -- Gathering Storm
        baseline = true,
    },
    -- Pillar of Frost
    [51271] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 60,
        duration = 12,
    },
    -- Absolute zero (Frostwyrm's Fury)
    [279302] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 90,
        duration = 10,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Chill Streak
    [305392] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST_DK },
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
        baseline = true,
    },
    -- Shambling Rush
    [91807] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
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
        charges = true, -- Death's Echo is almost always picked
        baseline = true,
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
        baseline = true,
    },
    -- Anti-Magic Shell
    [48707] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 40, -- Anti-Magic Barrier almost always picked
        -- Not set as baseline, since it can be replaced by Spellwarden
    },
        -- Anti-Magic Shell (Spellwarden)
        [410358] = {
            parent = 48707,
            cooldown = 30,
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
        spec = { specID.HAVOC },
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
        baseline = true,
    },
    -- Essence Break
    [258860] = {
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
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
        baseline = true,
    },
    -- Defensive
    -- Blur
    [198589] = {
        cooldown = 60,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Netherwalk
    [196555] = {
        cooldown = 180,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.DEFENSIVE
    },
    -- Darkness
    [196718] = {
        cooldown = 180,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE
    },
    -- Reverse Magic
    [205604] = {
        cooldown = 60,
        class = addon.DEMONHUNTER,
        category = category.DEFENSIVE,
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
        parent = 217832,
    },
    -- Fel Eruption
    [211881] = {
        cooldown = 30,
        class = addon.DEMONHUNTER,
        spec = { specID.HAVOC },
        category = category.CROWDCONTROL,
        baseline = true,
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
    -- Incarnation: Chosen of Elune
    [102560] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 90, -- Whirling Stars
        duration = 20,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
    },
        -- Incarnation: Chosen of Elune (Orbital Strike)
        [390414] = {
            parent = 102560,
            cooldown = 120,
        },
    -- Celestial Alignment
    [194223] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 90, -- Whirling Stars
        duration = 15,
        charges = true, -- Whirling Stars
        index = addon.SPELLPRIORITY.HIGH,
    },
        -- Celestial Alignment (Orbital Strike)
        [383410] = {
            parent = 194223,
            cooldown = 120,
        },
    -- Force of Nature
    [205636] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 60,
        duration = 10,
    },
    -- Fury of Elune
    [202770] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.BURST,
        cooldown = 60,
        duration = 8,
    },
    -- Feral
    -- Berserk
    [106951] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Incarnation: Avatar of Ashamane
    [102543] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
    },
    -- Feral Frenzy
    [274837] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 45,
    },
    -- Tiger's Fury
    [5217] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
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
        spec = { specID.BALANCE },
        reduce_on_interrupt = 15,
        category = category.CROWDCONTROL
    },
    -- Disrupt
    -- Faerie Swarm
    [209749] = {
        class = addon.DRUID,
        spec = { specID.BALANCE },
        category = category.DISRUPT,
        cooldown = 30,
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
        spec = { specID.GUARDIAN, specID.FERAL },
        charges = {[specID.GUARDIAN] = true},
        category = category.DEFENSIVE
    },
    -- Ironbark
    [102342] = {
        cooldown = 90,
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        opt_lower_cooldown = 70,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Barkskin
    [22812] = {
        cooldown = 60,
        class = addon.DRUID,
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Renewal
    [108238] = {
        cooldown = 90,
        class = addon.DRUID,
        category = category.DEFENSIVE
    },
    -- Ancient of Lore
    [473909] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Dispel
    -- Nature's Cure
    [88423] = {
        cooldown = 8,
        class = addon.DRUID,
        spec = { specID.RESTORATION_DRUID },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },

    -- Evoker
    -- Devastation
    -- Deep Breath
    [357210] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 120,
        baseline = true,
    },
    -- Dragon Rage
    [375087] = {
        class = addon.EVOKER,
        spec = { specID.DEVASTATION },
        category = category.BURST,
        duration = 14,
        cooldown = 120,
        extend = true, -- Animosity
    },
    -- Tip the Scales
    [370553] = {
        class = addon.EVOKER,
        category = category.BURST,
        cooldown = 120,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Augmentation
    -- Breath of Eons
    [403631] = {
        class = addon.EVOKER,
        spec = { specID.AUGMENTATION },
        category = category.BURST,
        cooldown = 120,
    },
    -- Upheaval
    [396286] = {
        class = addon.EVOKER,
        spec = { specID.AUGMENTATION },
        category = category.BURST,
        cooldown = 40,
        trackEvent = addon.SPELL_EMPOWER_END,
    },
    -- Ebon Might
    [395152] = {
        class = addon.EVOKER,
        spec = { specID.AUGMENTATION },
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
        baseline = true, -- technically a talent, but always picked
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
        spec = { specID.PRESERVATION },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true, -- technically a talent, but always picked
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
        cooldown = { default = 40, [specID.DEVASTATION] = 20, [specID.AUGMENTATION] = 20 },
        class = addon.EVOKER,
        category = category.INTERRUPT,
        baeline = true, -- technically a talent, but always picked
    },
    -- Crowd Control
    -- Dispel
    -- Naturalize
    [360823] = {
        cooldown = 8,
        class = addon.EVOKER,
        spec = { specID.PRESERVATION },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Disrupt
    -- Fire Breath (Scouring Flame which purges 1 buff per empower level)
    [382266] = {
        cooldown = 30,
        class = addon.EVOKER,
        category = category.DISRUPT,
        trackEvent = addon.SPELL_EMPOWER_END,
        baseline = true,
    },

    -- Hunter
    -- Beast Mastery
    -- Bestial Wrath
    [19574] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY },
        category = category.BURST,
        cooldown = 90, -- Reduced by Barbed Shot
        duration = 15,
        baseline = true, -- technically a talent, but always picked
    },
    -- Call of the Wild
    [359844] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY },
        category = category.BURST,
        cooldown = 120,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
    },
    -- Survival
    -- Coordinated Assult
    [360952] = {
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.BURST,
        cooldown = 60, -- Symboitic Adrenaline (almost always picked)
        duration = 20,
        baseline = true, -- technically a talent, but always picked
    },
    -- Marksmanship
    -- Trueshot
    [288613] = {
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP },
        category = category.BURST,
        cooldown = 120, -- Reduced by spending focus
        duration = 15,
        reduce_power_type = POWERTYPE.Focus,
        reduce_amount = 0.05, -- Every 50 focus reduces cd by 2.5s
        baseline = true, -- technically a talent, but always picked
    },
    -- Volley
    [260243] = {
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP },
        category = category.BURST,
        cooldown = 45,
        duration = 6,
    },
    -- Disrupt
    -- Feign Death
    [5384] = {
        class = addon.HUNTER,
        category = category.DISRUPT,
        cooldown = 30,
        baseline = true,
    },
    -- Mending Bandage
    [212640] = {
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.DISRUPT,
        cooldown = 25,
    },
    -- Crowd Control
    -- Intimidation
    [19577] = {
        cooldown = 50,
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
    },
    -- Freezing Trap
    [187650] = {
        cooldown = 25,
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Defensive
    -- Survival of the Fittest
    [264735] = {
        cooldown = 90,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        charges = true,
        baseline = true, -- technically a talent, but always picked
    },
    -- Aspect of the Turtle
    [186265] = {
        cooldown = 144,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    },
    -- Roar of Sacrifice
    [53480] = {
        cooldown = 60,
        class = addon.HUNTER,
        category = category.DEFENSIVE
    },
    -- Exhilaration
    [109304] = {
        cooldown = 120,
        class = addon.HUNTER,
        category = category.DEFENSIVE,
    },
    -- Interrupt
    -- Counter Shot
    [147362] = {
        cooldown = 22,
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP, specID.BEASTMASTERY },
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Muzzle
    [187707] = {
        cooldown = 13,
        class = addon.HUNTER,
        spec = { specID.SURVIVAL },
        category = category.INTERRUPT,
        baseline = true,
    },

    -- Mage
    -- Frost
    -- Icy Veins (make sure it's not triggered by Time Anomaly)
    [12472] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.BURST,
        cooldown = 120,
        duration = 30,
        index = addon.SPELLPRIORITY.HIGH,
        extend = true,
        baseline = true, -- technically a talent, but always picked
    },
    -- Ice Form
    [198144] = {
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.BURST,
        cooldown = 60,
        duration = 12,
        extend = true,
    },
    -- Fire
    -- Combustion
    [190319] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.BURST,
        duration = 12,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,

        -- Reduce cooldown by 1s
        -- Fireball, Pyroblast, Fire Blast, Scorch, Phoenix Flames
        critResets = { 133, 11366, 108853, 2948, 257542 },
        critResetAmount = 1,

        baseline = true, -- technically a talent, but always picked
    },
    -- Arcane
    -- Arcane Surge
    [365350] = {
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Interrupt
    -- Counterspell
    [2139] = {
        cooldown = 24,
        class = addon.MAGE,
        reduce_on_interrupt = 4,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Defensive
    -- Ice Block
    [45438] = {
        cooldown = 180,
        class = addon.MAGE,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    },
    -- Cauterize
    [87024] = {
        cooldown = 300,
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    },
    -- Cold Snap (resets ice block)
    [235219] = {
        cooldown = 300,
        class = addon.MAGE,
        spec = { specID.FROST_MAGE },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Alter Time (Arcane)
    [342246] = {
        cooldown = 50,
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.DEFENSIVE,
        trackEvent = addon.SPELL_AURA_APPLIED,
        baseline = true, -- technically a talent, but always picked
    },
    -- Alter Time (Fire/Frost)
    [110909] = {
        parent = 342246,
        spec = { specID.FIRE, specID.FROST_MAGE },
    },
    -- Crowd Control
    -- Ring of Frost
    [113724] = {
        cooldown = 45,
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Dragon's Breath
    [31661] = {
        cooldown = 45,
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Disrupt
    -- Kleptomania (now a channel with a different spellID)
    [198100] = {
        cooldown = 20,
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.DISRUPT,
    },
    -- Greater Invisibility
    [110959] = {
        cooldown = 120,
        class = addon.MAGE,
        category = category.DISRUPT,
    },
    -- Blink
    [1953] = {
        cooldown = 11, -- 15s - 4s from Flow of Time
        class = addon.MAGE,
        category = category.DISRUPT,
        -- Not baseline since it can be replaced by Shimmer
    },

    -- Monk
    -- Celestial Conduit
    [443028] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER, specID.WINDWALKER },
        category = category.BURST,
        cooldown = 90,
        duration = 4,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Storm, Earth, and Fire (icon is strange when testing with a monk probably because the icon changes after spell is cast...)
    [137639] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        charges = true,
        reduce_power_type = POWERTYPE.Chi,
        reduce_amount = 0.5, -- Every 2 Chi spent reduces the cooldown by 1 sec.
        extend = true,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 120,
        duration = 24,
        baseline = true, -- technically a talent, but always picked
    },
    -- -- Dance of Chi-ji (no cooldown, aura only)
    -- [325202] = {
    --     class = addon.MONK,
    --     category = category.BURST,
    --     trackEvent = addon.SPELL_AURA_APPLIED,
    -- },
    -- Crowd Control
    -- Paralysis
    [115078] = {
        cooldown = 30,
        class = addon.MONK,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Leg Sweep
    [119381] = {
        cooldown = 50,
        class = addon.MONK,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Breath of Fire (Incendiary Breath)
    -- [115181] = {
    --     cooldown = 30,
    --     class = addon.MONK,
    --     category = category.CROWDCONTROL,
    -- },
    -- Ring of Peace
    [116844] = {
        cooldown = 45,
        class = addon.MONK,
        category = category.DISRUPT,
        -- not baseline, it's on the same node as Song of Chi-Ji
    },
    -- Spear Hand Strike
    [116705] = {
        cooldown = 15,
        class = addon.MONK,
        category = category.INTERRUPT,
        baseline = true, -- technically a talent, but always picked
    },
    -- Touch of Karma
    [122470] = {
        cooldown = 90,
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    },
    -- Life Cocoon (120 baseline - 45s from Chrysalis)
    [116849] = {
        cooldown = 75,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Diffuse Magic
    [122783] = {
        cooldown = 90,
        class = addon.MONK,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Revival
    [115310] = {
        cooldown = 150,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
        -- Restoral (once detected, reuse Revival icon but change texture to Restoral)
        [388615] = {
            parent = 115310,
            use_parent_icon = true,
        },
    -- Fortifying Brew
    [115203] = {
        cooldown = 90,
        class = addon.MONK,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.LOW,
    },
    -- Transcendence: Transfer
    [119996] = {
        cooldown = 45,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Disrupt
    -- Grapple Weapon
    [233759] = {
        class = addon.MONK,
        category = category.DISRUPT,
        cooldown = 45,
    },
    -- Dispel
    -- Detox
    [115450] = {
        cooldown = 8,
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },

    -- Paladin
    -- Avenging Wrath
    [31884] = {
        class = addon.PALADIN,
        category = category.BURST,
        duration = 23, -- Baseline: 20s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RETRIBUTION },
    },
    -- Crusade
    [231895] = {
        class = addon.PALADIN,
        category = category.BURST,
        duration = 30, -- Baseline: 27s, Divine Wrath: 3s
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,
        spec = { specID.RETRIBUTION },
    },
    -- Wake of Ashes
    [255937] = {
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.BURST,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH, -- the new way of activating wing
    },
    -- Divine Toll
    [375576] = {
        class = addon.PALADIN,
        category = category.BURST,
        spec = { specID.RETRIBUTION },
        cooldown = 60,
        opt_lower_cooldown = 45,
    },
    -- Blessing of Summer (cannot reliably track cooldown, assume 45s * 3 = 135s perhaps)
    [388007] = {
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
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
        spec = { specID.RETRIBUTION },
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
        baseline = true,
    },
    -- Blessing of Protection
    [1022] = {
        cooldown = 240,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
        -- Blessing of SpellWarding
        [204018] = {
            spec = { specID.HOLY_PALADIN },
            baseline = false, -- to avoid inheriting parent baseline property
            parent = 1022,
            use_parent_icon = true, -- different abilities but sharing cooldown
        },
    -- Lay on Hands
    [633] = {
        cooldown = 420,
        class = addon.PALADIN,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    },
    -- Divine Protection
    [498] = {
        cooldown = 42, -- 60 * 0.7 (Unbreakable Spirit)
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN, specID.RETRIBUTION },
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Shield of Vengeance
    [184662] = {
        cooldown = 63,
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.DEFENSIVE,
    },
    -- Crowd Control
    -- Hammer of Justice
    [853] = {
        cooldown = 45,
        class = addon.PALADIN,
        category = category.CROWDCONTROL,
        baseline = true,
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
        spec = { specID.PROTECTION_PALADIN },
        category = category.CROWDCONTROL,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Interrupt
    -- Rebuke
    [96231] = {
        cooldown = 15,
        class = addon.PALADIN,
        category = category.INTERRUPT,
        baseline = true, -- technically a talent, but always picked
    },
    -- Disrupt
    -- Blessing of Sacrifice
    [6940] = {
        class = addon.PALADIN,
        category = category.DISRUPT,
        cooldown = 105,
        -- Don't make baseline since it can be replaced by Ultimate Sacrifice
    },
        -- Ultimate Sacrifice
        [199448] = {
            parent = 6940,
            cooldown = 105,
        },
    -- Dispel
    -- Cleanse
    [4987] = {
        cooldown = 8,
        class = addon.PALADIN,
        spec = { specID.HOLY_PALADIN },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },
    -- Blessing of Sanctuary
    [210256] = {
        cooldown = 45,
        class = addon.PALADIN,
        spec = { specID.RETRIBUTION },
        category = category.DISPEL,
    },

    -- Priest
    -- Mindgames
    [375901] = {
        class = addon.PRIEST,
        category = category.BURST,
        cooldown = 45,
        duration = 7, -- Confirm early dismiss
    },
    -- Psyfiend (triggers SPELL_AURA_REMOVED when dismissed)
    [211522] = {
        class = addon.PRIEST,
        spec = { specID.SHADOW },
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
        baseline = true, -- technically a talent, but always picked
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
        spec = { specID.SHADOW },
        cooldown = 60,
        duration = 20,
    },
    -- Void Torrent
    [263165] = {
        category = category.BURST,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        cooldown = 45,
    },
    -- Voidform
    [194249] = {
        category = category.BURST,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        trackEvent = addon.SPELL_AURA_APPLIED,
        cooldown = 120, -- Reduced by Driven to Madness, cannot track reliably
        duration = addon.DURATION_DYNAMIC,
        extend = true,
    },
    -- Dispel
    -- Mass Dispel
    [32375] = {
        cooldown = 120,
        class = addon.PRIEST,
        category = category.DISPEL,
    },
    -- Purify
    [527] = {
        cooldown = 8,
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST, specID.DISCIPLINE },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        opt_charges = true,
        baseline = true,
    },
    -- Crowd Control
    -- Psychic Scream
    [8122] = {
        cooldown = 30,
        class = addon.PRIEST,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Holy Word: Chastise
    [88625] = {
        cooldown = 60,
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Silence
    [15487] = {
        cooldown = 45,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.CROWDCONTROL,
        opt_lower_cooldown = 30,
        baseline = true, -- technically a talent, but always picked
    },
    -- Psychic Horror
    [64044] = {
        cooldown = 45,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.CROWDCONTROL,
    },
    -- Defensive
    -- Void Shift
    [108968] = {
        cooldown = 300,
        class = addon.PRIEST,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Pain Suppression
    [33206] = {
        cooldown = 180,
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
        charges = true,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Power Word: Barrier
    [62618] = {
        cooldown = 180,
        class = addon.PRIEST,
        spec = { specID.DISCIPLINE },
        category = category.DEFENSIVE,
    },
    -- Guardian Spirit
    [47788] = {
        cooldown = 60, -- Assume it didn't proc
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Dispersion
    [47585] = {
        cooldown = 90,
        class = addon.PRIEST,
        spec = { specID.SHADOW },
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Restitution
    [211319] = {
        class = addon.PRIEST,
        spec = { specID.HOLY_PRIEST },
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
        spec = { specID.HOLY_PRIEST },
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
    -- Shadow Word: Death
    [32379] = {
        cooldown = 10,
        class = addon.PRIEST,
        category = category.DISRUPT,
        baseline = true,
    },

    -- Rogue
    -- Cold Blood
    [382245] = {
        class = addon.ROGUE,
        category = category.BURST,
        cooldown = 45,
        index = addon.SPELLPRIORITY.HIGH,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Subtlety
    -- Shadow Blades
    [121471] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 90,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
    },
    -- Shadow Dance
    [185313] = {
        class = addon.ROGUE,
        spec = { specID.SUBTLETY },
        category = category.BURST,
        cooldown = 30, -- 2 charges but cannot track cd reliably, just divide cd by 2
        duration = 8,
        baseline = true,
    },
    -- Outlaw
    -- Adrenaline Rush
    [13750] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 180,
        duration = 20,
        baseline = true, -- technically a talent, but always picked
    },
    -- Between the Eyes
    [315341] = {
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        category = category.BURST,
        cooldown = 45,
        duration = 21, -- Max duration, can dismiss early
        baseline = true,
    },
    -- Assassination
    -- Death Mark
    [360194] = {
        class = addon.ROGUE,
        spec = { specID.ASSASSINATION },
        category = category.BURST,
        duration = 16, -- confirm early dismiss
        cooldown = 120,
        index = addon.SPELLPRIORITY.DEADLY,
        baseline = true, -- technically a talent, but always picked
    },
    -- Kingsbane
    [385627] = {
        class = addon.ROGUE,
        spec = { specID.ASSASSINATION },
        category = category.BURST,
        duration = 14,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Interrupt
    -- Kick
    [1766] = {
        cooldown = 15,
        class = addon.ROGUE,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Defensive
    -- Vanish (addition charge in class talent tree)
    [1856] = {
        cooldown = 120,
        class = addon.ROGUE,
        charges = true,
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Cloak of Shadows
    [31224] = {
        cooldown = 120,
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Evasion
    [5277] = {
        cooldown = 120,
        class = addon.ROGUE,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Crowd Control
    -- Kidney Shot
    [408] = {
        cooldown = 20,
        class = addon.ROGUE,
        category = category.CROWDCONTROL,
        baseline = true,
    },
    -- Blind
    [2094] = {
        cooldown = {default = 120, [specID.OUTLAW] = 90},
        class = addon.ROGUE,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Smoke Bomb
    [212182] = {
        cooldown = 180,
        class = addon.ROGUE,
        spec = { specID.SUBTLETY, specID.OUTLAW },
        category = category.CROWDCONTROL,
    },
    -- Smoke Bomb (Subtlety)
    [359053] = {
        parent = 212182,
        cooldown = 120,
        spec = { specID.SUBTLETY },
    },
    -- Disrupt
    -- Shadowstep
    [36554] = {
        cooldown = 30,
        class = addon.ROGUE,
        spec = { specID.SUBTLETY, specID.ASSASSINATION },
        charges = true,
        category = category.DISRUPT,
        baseline = true,
    },
    -- Grappling Hook
    [195457] = {
        cooldown = 30,
        class = addon.ROGUE,
        spec = { specID.OUTLAW },
        charges = true,
        category = category.DISRUPT,
        baseline = true,
    },
    -- Dismantle
    [207777] = {
        cooldown = 45,
        class = addon.ROGUE,
        category = category.DISRUPT
    },

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
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 180,
        duration = 15,
    },
    -- Doom Winds
    [384352] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        duration = 8,
        cooldown = 60,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Feral Spirit
    [51533] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
    },
    -- Bloodlust (Shamanism)
    [204361] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
        category = category.BURST,
        duration = 10,
        trackEvent = addon.SPELL_AURA_APPLIED,
        trackDest = true,
    },
    -- Heroism (Shamanism)
    [204362] = {
        class = addon.SHAMAN,
        spec = { specID.ENHANCEMENT },
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
        spec = { specID.ELEMENTAL },
        category = category.BURST,
        cooldown = 60, -- reduced by Lighting Bolt and Chain Lightning
        duration = 15,
    },
    -- Fire Elemental
    [198067] = {
        class = addon.SHAMAN,
        spec = { specID.ELEMENTAL },
        category = category.BURST,
        cooldown = 150,
        duration = 24,
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Interrupt
    -- Wind Shear
    [57994] = {
        cooldown = 12,
        class = addon.SHAMAN,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Defensive
    -- Astral Shift (120s baseline, -30 Planes Traveler)
    [108271] = {
        cooldown = 90,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        baseline = true,
    },
    -- Spirit Link Totem
    [98008] = {
        cooldown = 174,
        class = addon.SHAMAN,
        category = category.DEFENSIVE,
        spec = { specID.RESTORATION_SHAMAN },
        baseline = true, -- technically a talent, but always picked
    },
    -- Burrow
    [409293] = {
        cooldown = 120,
        class = addon.SHAMAN,
        category = category.DEFENSIVE
    },
    -- Stone Bulwark Totem (can be reset by Totemic Recall)
    [108270] = {
        cooldown = 174,
        class = addon.SHAMAN,
        category = category.DEFENSIVE
    },
    -- Disrupt
    -- Grounding Totem
    [204336] = {
        cooldown = 24,
        class = addon.SHAMAN,
        category = category.DISRUPT
    },
    -- Tremor Totem
    [8143] = {
        cooldown = 54,
        class = addon.SHAMAN,
        category = category.DISRUPT
    },
    -- Dispel
    -- Purify Spirit
    [77130] = {
        cooldown = 8,
        class = addon.SHAMAN,
        spec = { specID.RESTORATION_SHAMAN },
        category = category.DISPEL,
        trackEvent = addon.SPELL_DISPEL,
        baseline = true,
    },

    -- Warlock
    -- Affliction
    -- Soul Rot
    [386997] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION },
        category = category.BURST,
        cooldown = 60,
    },
    -- Summon Darkglare
    [205180] = {
        class = addon.WARLOCK,
        spec = { specID.AFFLICTION },
        category = category.BURST,
        duration = 20, -- confirm early dismiss if killed
        index = addon.SPELLPRIORITY.HIGH,
    },
    -- Destruction
    -- Summon Infernal
    [1122] = {
        class = addon.WARLOCK,
        spec = { specID.DESTRUCTION },
        category = category.BURST,
        cooldown = 120,
        duration = 30,
    },
    -- Demonology
    -- Summon Demonic Tyrant
    [265187] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        category = category.BURST,
        cooldown = 60,
        duration = 15,
    },
    -- Grimoire: Felguard
    [111898] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
        category = category.BURST,
        cooldown = 120,
        duration = 17,
    },
    -- Demonic Strength
    [267171] = {
        class = addon.WARLOCK,
        spec = { specID.DEMONOLOGY },
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
        spec = { specID.DEMONOLOGY },
        trackPet = true,
        category = category.CROWDCONTROL,
    },
        -- Axe Toss (Command Demon Ability) (only shows up once no matter which version is cast)
        [119914] = {
            parent = 89766,
        },
    -- Defensive
    -- Unending Resolve
    [104773] = {
        cooldown = 180,
        class = addon.WARLOCK,
        opt_lower_cooldown = 135,
        category = category.DEFENSIVE,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
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
        baseline = true, -- technically a talent, but always picked
    },
    -- Demonic Circle: Teleport
    [48020] = {
        cooldown = 30,
        class = addon.WARLOCK,
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Interrupt
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

    -- Warrior
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
        baseline = true, -- technically a talent, but always picked
    },
    -- Warbreaker
    [262161] = {
        class = addon.WARRIOR,
        spec = { specID.ARMS },
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
        spec = { specID.ARMS },
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
        spec = { specID.FURY },
        category = category.BURST,
        cooldown = 90,
        duration = 16,
        reduce_power_type = POWERTYPE.Rage,
        reduce_amount = 0.05,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true, -- technically a talent, but always picked
    },
    -- Charge
    [100] = {
        cooldown = 17,
        class = addon.WARRIOR,
        charges = true,
        category = category.DISRUPT,
        baseline = true,
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
        baseline = true, -- technically a talent, but always picked
    },
    -- Disarm
    [236077] = {
        cooldown = 45,
        class = addon.WARRIOR,
        category = category.DISRUPT,
    },
    -- Pummel
    [6552] = {
        cooldown = 13, -- with both cd reduction talents
        class = addon.WARRIOR,
        category = category.INTERRUPT,
        baseline = true,
    },
    -- Storm Bolt
    [107570] = {
        cooldown = 28.5,
        class = addon.WARRIOR,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Intimidating Shout
    [5246] = {
        cooldown = 90,
        class = addon.WARRIOR,
        category = category.CROWDCONTROL,
        baseline = true, -- technically a talent, but always picked
    },
    -- Die by the Sword
    [118038] = {
        cooldown = 85.5,
        class = addon.WARRIOR,
        spec = { specID.ARMS },
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Enraged Regeneration
    [184364] = {
        cooldown = 114,
        class = addon.WARRIOR,
        spec = { specID.FURY },
        category = category.DEFENSIVE,
        baseline = true, -- technically a talent, but always picked
    },
    -- Rallying Cry
    [97462] = {
        cooldown = 180,
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
        { spellID = 12472, amount = 12 }, -- Icy Veins
        { spellID = 365350, amount = 12 }, -- Arcane Surge
    },
    -- Cold Snap
    [235219] = {
        45438, -- Ice Block
    },

    -- Apotheosis
    [200183] = {
        88625, -- Holy Word: Chastise
    },
    -- Prayer of Mending
    [33076] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },
    -- Holy Fire
    [14914] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },
    -- Power Word: Life
    [194384] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },

    -- Power Word: Shield
    [17] = {
        { spellID = 33206, amount = 3 }, -- Pain Suppression
    },
};

if addon.TEST_MODE then
    -- Test
    -- Mark of the Wild
    addon.SpellData[1126] = {
        class = addon.DRUID,
        category = category.BURST,
        duration = 8,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH,
    };
    -- Regrowth
    addon.SpellData[8936] = {
        class = addon.DRUID,
        category = category.BURST,
        duration = 5,
        cooldown = 10,
    };
    -- Rejuv
    addon.SpellData[774] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 45,
    };
    -- Wild Growth
    addon.SpellData[48438] = {
        class = addon.DRUID,
        category = category.BURST,
        duration = 7,
        trackDest = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
    };

    addon.SpellData[1459] = {
        class = addon.MAGE,
        category = category.BURST,
        duration = 12,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,

        resets = {
            [133] = 2, -- Pyrokinesis
            [314791] = 12, -- Shifting Power
        },

        -- Reduce cooldown by 1s
        critResets = { 133, 11366, 108853, 2948, 257542 },
        critResetAmount = 1,
    };
end

for _, spell in pairs(addon.SpellData) do
    -- Fill options from parent
    if spell.parent then
        local parent = addon.SpellData[spell.parent];

        spell.cooldown = spell.cooldown or parent.cooldown;
        spell.class = spell.class or parent.class;
        spell.spec = spell.spec or parent.spec;
        spell.category = spell.category or parent.category;
        spell.trackPet = spell.trackPet or parent.trackPet;
        spell.trackEvent = spell.trackEvent or parent.trackEvent;
        spell.baseline = spell.baseline or parent.baseline;
        spell.index = spell.index or parent.index;
    end
end
