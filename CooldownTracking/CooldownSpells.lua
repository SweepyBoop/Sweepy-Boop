local _, NS = ...;

local SPELLCATEGORY = NS.SPELLCATEGORY;
local POWERTYPE = Enum.PowerType;
local UnitClass = UnitClass;

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
        trackPet = true,
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

    -- Demon Hunter
    -- Interrupt
    -- Disrupt
    [183752] = {
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.INTERRUPT,
        cooldown = 15,
    },
    -- Defensive
    -- Netherwalk
    [196555] = {
        cooldown = 180,
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.DEFENSIVE
    },
    -- Crowd Control
    -- Imprison
    [217832] = {
        cooldown = 45,
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Imprison (Detainment)
    [221527] = {
        cooldown = 45,
        class = "DEMONHUNTER",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    [211881] = {cooldown = 30, class = "DEMONHUNTER", category = SPELLCATEGORY.CROWDCONTROL}, -- Fel Eruption

    -- Priest
    -- Dispel
    -- Mass Dispel
    [32375] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.DISPEL,
        opt_lower_cooldown = 25,
    },
    -- Purify
    [527] = {
        cooldown = 8,
        class = "PRIEST",
        category = SPELLCATEGORY.DISPEL,
        trackEvent = "SPELL_DISPEL",
        opt_charges = true,
    },
    -- Crowd Control
    -- Psychic Scream
    [8122] = {
        cooldown = 30,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Holy Word: Chastise
    [88625] = {
        cooldown = 60,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Silence
    [15487] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
        opt_lower_cooldown = 30,
    },
    -- Psychic Horror
    [64044] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Defensive
    -- Void Shift
    [108968] = {
        cooldown = 300,
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Pain Suppression
    [33206] = {
        cooldown = 180,
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Guardian Spirit
    [47788] = {
        cooldown = 60, -- Assume it didn't proc
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Dispersion
    [47585] = {
        cooldown = 90,
        class = "PRIEST",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Disrupt
    -- Holy Ward
    [213610] = {
        cooldown = 45,
        class = "PRIEST",
        category = SPELLCATEGORY.DISRUPT,
    },

    -- Paladin
    -- Defensive
    -- Divine Shield
    [642] = {
        cooldown = 210,
        class = "PALADIN",
        category = SPELLCATEGORY.DEFENSIVE,
    },
    -- Blessing of Protection
    [1022] = {
        cooldown = 240,
        class = "PALADIN",
        category = SPELLCATEGORY.DEFENSIVE,
        opt_charges = true,
    },
    -- Crowd Control
    -- Hammer of Justice
    [853] = {
        cooldown = 60,
        class = "PALADIN",
        category = SPELLCATEGORY.CROWDCONTROL,
        reduce_power_type = POWERTYPE.HolyPower;
        reduce_amount = 2, -- Each holy power spent reduces the cooldown by 2 sec.
    },
    -- Blinding Light
    [115750] = {
        cooldown = 90,
        class = "PALADIN",
        category = SPELLCATEGORY.CROWDCONTROL,
    },
    -- Shield of Virtue
    [215652] = {
        cooldown = 45,
        class = "PALADIN",
        category = SPELLCATEGORY.CROWDCONTROL,
        trackEvent = "SPELL_AURA_REMOVED",
    },
    -- Interrupt
    -- Rebuke
    [96231] = {
        cooldown = 15,
        class = "PALADIN",
        category = SPELLCATEGORY.INTERRUPT,
    },
    -- Dispel
    [4987] = {cooldown = 8, class = "PALADIN", category = SPELLCATEGORY.DISPEL, trackEvent = "SPELL_DISPEL"}, -- Cleanse
    [210256] = {cooldown = 45, class = "PALADIN", category = SPELLCATEGORY.DISPEL}, -- Blessing of Sanctuary

    -- Druid
    -- Crowd Control
    [5211] = {cooldown = 60, class = "DRUID", category = SPELLCATEGORY.CROWDCONTROL}, -- Mighty Bash
    [22570] = {cooldown = 20, class = "DRUID", category = SPELLCATEGORY.CROWDCONTROL}, -- Maim
    [99] = {cooldown = 30, class = "DRUID", category = SPELLCATEGORY.CROWDCONTROL}, -- Incapacitating Roar
    [78675] = {cooldown = 60, class = "DRUID", reduce_on_interrupt = 15, category = SPELLCATEGORY.CROWDCONTROL}, -- Solar Beam
    -- Interrupt
    [106839] = {cooldown = 15, class = "DRUID", category = SPELLCATEGORY.INTERRUPT}, -- Skull Bash
    -- Defensive
    [61336] = {cooldown = {default = 180, [104] = 120}, class = "DRUID", charges = {[104] = true}, category = SPELLCATEGORY.DEFENSIVE}, -- Survival Instincts
    [102342] = {cooldown = 90, class = "DRUID", opt_lower_cd = 70, category = SPELLCATEGORY.DEFENSIVE}, -- Ironbark

    -- Warrior
    -- Disrupt
    [100] = {cooldown = 17, class = "WARRIOR", charges = true, category = SPELLCATEGORY.DISRUPT}, -- Charge
    [23920] = {cooldown = 25, class = "WARRIOR", category = SPELLCATEGORY.DISRUPT}, -- Spell Reflection
    [6544] = {cooldown = 30, class = "WARRIOR", category = SPELLCATEGORY.DISRUPT}, -- Heroic Leap
    -- Interrupt
    [6552] = {cooldown = 14, class = "WARRIOR", category = SPELLCATEGORY.INTERRUPT}, -- Pummel
    -- Crowd Control
    [107570] = {cooldown = 30, class = "WARRIOR", category = SPELLCATEGORY.CROWDCONTROL}, -- Storm Bolt
    [5246] = {cooldown = 90, class = "WARRIOR", category = SPELLCATEGORY.CROWDCONTROL}, -- Intimidating Shout
    -- Defensive
    [118038] = {cooldown = 90, class = "WARRIOR", category = SPELLCATEGORY.DEFENSIVE}, -- Die by the Sword
    [184364] = {cooldown = 120, class = "WARRIOR", category = SPELLCATEGORY.DEFENSIVE}, -- Enraged Regeneration
    -- Dispel
    [88423] = {cooldown = 8, class = "DRUID", category = SPELLCATEGORY.DISPEL, trackEvent = "SPELL_DISPEL"}, -- Nature's Cure

    -- Warlock
    -- Crowd Control
    [6789] = {cooldown = 45, class = "WARLOCK", category = SPELLCATEGORY.CROWDCONTROL}, -- Mortal Coil
    [5484] = {cooldown = 40, class = "WARLOCK", category = SPELLCATEGORY.CROWDCONTROL}, -- Howl of Terror
    [89766] = {cooldown = 30, class = "WARLOCK", trackPet = true, category = SPELLCATEGORY.CROWDCONTROL}, -- Axe Toss
    -- Defensive
    [104773] = {cooldown = 180, class = "WARLOCK", opt_lower_cd = 135, category = SPELLCATEGORY.DEFENSIVE}, -- Unending Resolve
    -- Interrupt
    [119910] = {cooldown = 24, class = "WARLOCK", trackPet = true, category = SPELLCATEGORY.INTERRUPT}, -- Spell Lock (Command Demon)
        [19647] = {parent = 119910}, -- Spell Lock (Felhunter)
		[119911] = {parent = 119910}, -- Optical Blast (Command Demon)
		[115781] = {parent = 119910}, -- Optical Blast (Observer)
		[132409] = {parent = 119910}, -- Spell Lock (Grimoire of Sacrifice)
		[171138] = {parent = 119910}, -- Shadow Lock (Doomguard)
		[171139] = {parent = 119910}, -- Shadow Lock (Grimoire of Sacrifice)
		[171140] = {parent = 119910}, -- Shadow Lock (Command Demon)
    [212619] = {cooldown = 60, class = "WARLOCK", category = SPELLCATEGORY.INTERRUPT}, -- Call Felhunter
    -- Disrupt
    [212295] = {cooldown = 45, class = "WARLOCK", category = SPELLCATEGORY.DISRUPT}, -- Nether Ward

    -- Shaman
    -- Interrupt
    [57994] = {cooldown = 12, class = "SHAMAN", category = SPELLCATEGORY.INTERRUPT}, -- Wind Shear
    -- Defensive
    [108271] = {cooldown = 90, class = "SHAMAN", category = SPELLCATEGORY.DEFENSIVE}, -- Astral Shift
    [210918] = {cooldown = 60, class = "SHAMAN", category = SPELLCATEGORY.DEFENSIVE}, -- Ethereal Form
    [98008] = {cooldown = 180, class = "SHAMAN", category = SPELLCATEGORY.DEFENSIVE}, -- Spirit Link Totem
    -- Disrupt
    [204336] = {cooldown = 30, class = "SHAMAN", category = SPELLCATEGORY.DISRUPT}, -- Grounding Totem
    -- Dispel
    [77130] = {cooldown = 8, class = "SHAMAN", category = SPELLCATEGORY.DISPEL, trackEvent = "SPELL_DISPEL"}, -- Purify Spirit

    -- Hunter
    -- Disrupt
    [5384] = {cooldown = 30, class = "HUNTER", category = SPELLCATEGORY.DISRUPT}, -- Feign Death
    -- Crowd Control
    [19577] = {cooldown = 60, class = "HUNTER", category = SPELLCATEGORY.CROWDCONTROL}, -- Intimidation
    [187650] = {cooldown = 25, class = "HUNTER", category = SPELLCATEGORY.CROWDCONTROL}, -- Freezing Trap
    -- Defensive
    [186265] = {cooldown = 180, class = "HUNTER", category = SPELLCATEGORY.DEFENSIVE}, -- Aspect of the Turtle
    -- Interrupt
    [147362] = {cooldown = 24, class = "HUNTER", category = SPELLCATEGORY.INTERRUPT}, -- Counter Shot
    [187707] = {cooldown = 15, class = "HUNTER", category = SPELLCATEGORY.INTERRUPT}, -- Muzzle

    -- Mage
    -- Interrupt
    [2139] = {cooldown = 24, class = "MAGE", reduce_on_interrupt = 4, category = SPELLCATEGORY.INTERRUPT}, -- Counterspell
    -- Defensive
    [45438] = {cooldown = 200, class = "MAGE", category = SPELLCATEGORY.DEFENSIVE}, -- Ice Block
    [87024] = {cooldown = 300, class = "MAGE", category = SPELLCATEGORY.CROWDCONTROL, trackEvent = "SPELL_AURA_APPLIED"}, -- Cauterize
    -- Crowd Control
    [113724] = {cooldown = 45, class = "MAGE", category = SPELLCATEGORY.CROWDCONTROL}, -- Ring of Frost
    [31661] = {cooldown = 45, class = "MAGE", category = SPELLCATEGORY.CROWDCONTROL}, -- Dragon's Breath
    -- Disrupt
    [30449] = {cooldown = 30, class = "MAGE", spec = {62}, category = SPELLCATEGORY.DISRUPT}, -- Spellsteal (Kleptomania)

    -- Rogue
    -- Interrupt
    [1766] = {cooldown = 15, class = "ROGUE", category = SPELLCATEGORY.INTERRUPT}, -- Kick
    -- Defensive
    [1856] = {cooldown = {default = 120, [260] = 75}, class = "ROGUE", charges = {[261] = true}, category = SPELLCATEGORY.DEFENSIVE}, -- Vanish
    [31224] = {cooldown = 120, class = "ROGUE", category = SPELLCATEGORY.DEFENSIVE}, -- Cloak of Shadows
    [5277] = {cooldown = 120, class = "ROGUE", category = SPELLCATEGORY.DEFENSIVE}, -- Evasion
    -- Crowd Control
    [408] = {cooldown = 20, class = "ROGUE", category = SPELLCATEGORY.CROWDCONTROL}, -- Kidney Shot
    [2094] = {cooldown = {default = 120, [260] = 90}, class = "ROGUE", category = SPELLCATEGORY.CROWDCONTROL}, -- Blind
    [212182] = {cooldown = 180, class = "ROGUE", category = SPELLCATEGORY.CROWDCONTROL}, -- Smoke Bomb
    [359053] = {cooldown = 120, class = "ROGUE", category = SPELLCATEGORY.CROWDCONTROL}, -- Smoke Bomb (Subtlety)
    -- Disrupt
    [36554] = {cooldown = 30, class = "ROGUE", charges = {[259] = true, [261] = true}, category = SPELLCATEGORY.DISRUPT}, -- Shadowstep
    [195457] = {cooldown = 30, class = "ROGUE", category = SPELLCATEGORY.DISRUPT}, -- Grappling Hook

    -- Monk
    -- Crowd Control
    [115078] = {cooldown = 30, class = "MONK", category = SPELLCATEGORY.CROWDCONTROL}, -- Paralysis
    [119381] = {cooldown = 50, class = "MONK", category = SPELLCATEGORY.CROWDCONTROL}, -- Leg Sweep
    -- Disrupt
    [116844] = {cooldown = 45, class = "MONK", category = SPELLCATEGORY.DISRUPT}, -- Ring of Peace
    -- Interrupt
    [116705] = {cooldown = 15, class = "MONK", category = SPELLCATEGORY.DISRUPT}, -- Spear Hand Strike
    -- Defensive
    [122470] = {cooldown = 90, class = "MONK", category = SPELLCATEGORY.DEFENSIVE}, -- Touch of Karma
    [116849] = {cooldown = 75, class = "MONK", category = SPELLCATEGORY.DEFENSIVE}, -- Life Cocoon
    -- Dispel
    [115450] = {cooldown = 8, class = "MONK", category = SPELLCATEGORY.DISPEL, trackEvent = "SPELL_DISPEL"}, -- Detox

    -- Evoker
    -- Defensive
    [363916] = {cooldown = 90, class = "EVOKER", charges = true, category = SPELLCATEGORY.DEFENSIVE}, -- Obsidian Scales
    [370960] = {cooldown = 180, class = "EVOKER", category = SPELLCATEGORY.DEFENSIVE}, -- Emerald Communion
    -- Interrupt
    [351338] = {cooldown = {default = 40, [1467] = 20}, class = "EVOKER", category = SPELLCATEGORY.INTERRUPT}, -- Quell
    -- Crowd Control
    [357210] = {cooldown = {default = 120, [1467] = 60}, class = "EVOKER", category = SPELLCATEGORY.CROWDCONTROL}, -- Deep Breath
    -- Dispel
    [360823] = {cooldown = 8, class = "EVOKER", category = SPELLCATEGORY.DISPEL, trackEvent = "SPELL_DISPEL"} -- Naturalize
};

local class = select(2, UnitClass("player"));
if ( class == "PRIEST" ) or ( class == "WARLOCK" ) or ( class == "WARRIOR" ) then
    -- Lichborne
    NS.cooldownSpells[49039] = {
        class = "DEATHKNIGHT",
        category = SPELLCATEGORY.DEFENSIVE,
        cooldown = 120,
        index = 2,
    };
    -- Tremor Totem
    NS.cooldownSpells[8143] = {
        duration = 60,
        class = "SHAMAN",
        category = SPELLCATEGORY.DISRUPT,
    };
end

for spellID, spell in pairs(NS.cooldownSpells) do
    -- Fill options from parent
    if spell.parent then
        local parent = NS.cooldownSpells[spell.parent];

        spell.cooldown = spell.cooldown or parent.cooldowns;
        spell.class = spell.class or parent.class;
        spell.category = spell.category or parent.category;
        spell.trackPet = parent.trackPet or parent.category;
    end
end

if NS.isTestMode then
    local testCategory = SPELLCATEGORY.DEFENSIVE;
    -- Test
    -- Mark of the Wild
    NS.cooldownSpells[1126] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 60,
        sound = true,
    };
    -- Regrowth
    NS.cooldownSpells[8936] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 60,
    };
    -- Rejuv
    NS.cooldownSpells[774] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 60,
    };
    -- Wild Growth
    NS.cooldownSpells[48438] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 60,
    };
    -- Nourish
    NS.cooldownSpells[50464] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 60,
    };
    -- Efflorescence
    NS.cooldownSpells[145205] = {
        class = "DRUID",
        category = testCategory,
        cooldown = 60,
    };
end

NS.cooldownResets = {
    -- Shifting Power
    [314791] = {
        { spellID = 31661, amount = 12 }, -- Dragon's Breath
        { spellID = 113724, amount = 12 }, -- Ring of Frost
        { spellID = 2139, amount = 12 }, -- Counterspell
        { spellID = 45438, amount = 12 }, -- Ice Block
    },
    -- Cold Snap
    [235219] = { 45438 },

    -- Holy Word: Chastise
    -- Apotheosis
    [200183] = { 88625 },
    -- Smite
    [585] = { { spellID = 88625, amount = 4 } },
    -- Holy Fire
    [14914] = { { spellID = 88625, amount = 4 } },

    -- Vanish (Memory of Invigorating Shadowdust, Subtlety Rogue)
    [1856] = {
        { spellID = 2094, amount = 20, specID = {261} }, -- Blind
        { spellID = 408, amount = 20, specID = {261} }, -- Kidney Shot
        { spellID = 212182, amount = 20, specID = {261} }, -- Smoke Bomb
        { spellID = 1766, amount = 20, specID = {261} }, -- Kick
        { spellID = 36554, amount = 20, specID = {261} }, -- Shadowstep
    },

    -- Power Word: Shield
    [17] = { { spellID = 33206, amount = 3 } }, -- Pain Suppression
};
