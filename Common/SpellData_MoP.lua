local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

-- charges: baseline 2 charges
-- opt_charges: optionally 2 charges
-- opt_lower_cooldown: this spell has a optionally lower cd, e.g., outlaw rogue blind, priest fear

addon.SpellData = {
    -- Death Knight

    -- Anti-Magic Shell
    [48707] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 45,
        baseline = true,
    },
    -- Dark Simulacrum
    [77606] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Death Grip
    [49576] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 25,
        baseline = true,
    },
    -- Empower Rune Weapon
    [47568] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 300,
        baseline = true,
    },
    -- Icebound Fortitude
    [48792] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Mind Freeze
    [47528] = {
        class = addon.DEATHKNIGHT,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Strangulate
    [47476] = {
        class = addon.DEATHKNIGHT,
        category = category.SILENCE,
        cooldown = 60,
        baseline = true,
    },
    -- Unholy Blight
    [115989] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 90,
        duration = 10,
    },
    -- Lichborne
    [49039] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Anti-Magic Zone
    [51052] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Asphyxiate
    [108194] = {
        class = addon.DEATHKNIGHT,
        category = category.STUN,
        cooldown = 30,
    },
    -- Death Pact
    [48743] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },
    -- Gorefiend's Grasp
    [108199] = {
        class = addon.DEATHKNIGHT,
        category = category.OTHERS,
        cooldown = 60,
    },
    -- Remorseless Winter
    [108200] = {
        class = addon.DEATHKNIGHT,
        category = category.BURST,
        cooldown = 60,
        duration = 8,
    },
    -- Desecrated Ground
    [108201] = {
        class = addon.DEATHKNIGHT,
        category = category.DEFENSIVE,
        cooldown = 120,
    },

    -- Unholy
    -- Summon Gargoyle
    [49206] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
        baseline = true,
    },
    -- Unholy Frenzy
    [49016] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.UNHOLY },
        category = category.BURST,
        cooldown = 180,
        duration = 30,
        baseline = true,
    },
    -- Frost
    -- Pillar of Frost
    [51271] = {
        class = addon.DEATHKNIGHT,
        spec = { specID.FROST },
        category = category.BURST,
        cooldown = 60,
        duration = 20,
        baseline = true,
    },

    -- Druid
    -- Barkskin
    [22812] = {
        class = addon.DRUID,
        category = category.DEFENSIVE,
        cooldown = 45,
        baseline = true,
    },
    -- Innervate
    [29166] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 180,
        baseline = true,
    },
    -- Maim
    [22570] = {
        class = addon.DRUID,
        category = category.STUN,
        cooldown = 10,
        baseline = true,
    },
    -- Might of Ursoc
    [106922] = {
        class = addon.DRUID,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Nature's Grasp
    [16689] = {
        class = addon.DRUID,
        category = category.CROWDCONTROL,
        cooldown = 60,
        baseline = true,
    },
    -- Nature's Swiftness
    [132158] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION, specID.BALANCE, specID.FERAL },
        category = category.OTHERS,
        cooldown = 60,
        baseline = true,
    },
    -- Stampeding Roar
    [106898] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 120,
        baseline = true,
    },
    -- Tranquility
    [740] = {
        class = addon.DRUID,
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
    },
    -- Berserk
    [106951] = {
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN },
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Survival Instincts
    [61336] = {
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN },
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Displacer Beast
    [102280] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 30,
    },
    -- Renewal
    [108238] = {
        class = addon.DRUID,
        category = category.HEAL,
        cooldown = 120,
    },
    -- Typhoon
    [132469] = {
        class = addon.DRUID,
        category = category.KNOCKBACK,
        cooldown = 30,
    },
    -- Incarnation
    [106731] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 180,
        duration = 30,
    },
    -- Disorienting Roar
    [99] = {
        class = addon.DRUID,
        category = category.CROWDCONTROL,
        cooldown = 30,
    },
    -- Ursol's Vortex
    [102793] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 60,
    },
    -- Mighty Bash
    [5211] = {
        class = addon.DRUID,
        category = category.STUN,
        cooldown = 50,
    },
    -- Heart of the Wild
    [108288] = {
        class = addon.DRUID,
        category = category.BURST,
        cooldown = 360,
        duration = 45,
    },
    -- Nature's Vigil
    [124974] = {
        class = addon.DRUID,
        category = category.OTHERS,
        cooldown = 90,
    },
    -- Skull Bash
    [106839] = {
        class = addon.DRUID,
        spec = { specID.FERAL, specID.GUARDIAN },
        category = category.INTERRUPT,
        cooldown = 15,
    },

    -- Restoration
    -- Ironbark
    [102342] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION },
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Nature's Cure
    [88423] = {
        class = addon.DRUID,
        spec = { specID.RESTORATION },
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
    },
    -- Feral
    -- Tiger's Fury
    [5217] = {
        class = addon.DRUID,
        spec = { specID.FERAL },
        category = category.BURST,
        cooldown = 30,
        duration = 6,
        baseline = true,
    },

    -- Hunter
    -- Camouflage
    [51753] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Counter Shot
    [147362] = {
        class = addon.HUNTER,
        spec = { specID.BEASTMASTERY, specID.SURVIVAL },
        category = category.INTERRUPT,
        cooldown = 24,
        baseline = true,
    },
    -- Deterrence
    [19263] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Feign Death
    [5384] = {
        class = addon.HUNTER,
        category = category.DEFENSIVE,
        cooldown = 30,
        baseline = true,
    },
    -- Master's Call
    [53271] = {
        class = addon.HUNTER,
        category = category.OTHERS,
        cooldown = 45,
        baseline = true,
    },
    -- Rapid Fire
    [3045] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 180,
        duration = 15,
        baseline = true,
    },
    -- Scatter Shot
    [19503] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 30,
        baseline = true,
    },
    -- Stampede
    [121818] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 300,
        duration = 20,
        baseline = true,
    },
    -- Explosive Trap
    [13813] = {
        class = addon.HUNTER,
        category = category.KNOCKBACK,
        cooldown = 30,
        baseline = true,
    },
    -- Freezing Trap
    [1499] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 30,
        baseline = true,
    },
    -- Bining Shot
    [109248] = {
        class = addon.HUNTER,
        category = category.STUN,
        cooldown = 45,
    },
    -- Wyvern Sting
    [19386] = {
        class = addon.HUNTER,
        category = category.CROWDCONTROL,
        cooldown = 45,
    },
    -- Intimidation
    [19577] = {
        class = addon.HUNTER,
        category = category.STUN,
        cooldown = 60,
    },
    -- Exhilaration
    [109304] = {
        class = addon.HUNTER,
        category = category.HEAL,
        cooldown = 120,
    },
    -- A Murder of Crows
    [131894] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 120,
        duration = 30,
    },
    -- Lynx Rush
    [120697] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 90,
        duration = 4,
    },
    -- Powershot
    [109259] = {
        class = addon.HUNTER,
        category = category.BURST,
        cooldown = 45,
    },

    -- Marksmanship
    -- Silencing Shot
    [34490] = {
        class = addon.HUNTER,
        spec = { specID.MARKSMANSHIP },
        category = category.INTERRUPT,
        cooldown = 24,
        baseline = true,
    },

    -- Mage
    -- Alter Time
    [108978] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Blink
    [1953] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 15,
        baseline = true,
    },
    -- Counterspell
    [2139] = {
        class = addon.MAGE,
        category = category.INTERRUPT,
        cooldown = 24,
        baseline = true,
    },
    -- Deep Freeze
    [44572] = {
        class = addon.MAGE,
        category = category.STUN,
        cooldown = 30,
        baseline = true,
    },
    -- Evocation
    [12051] = {
        class = addon.MAGE,
        category = category.OTHERS,
        cooldown = 120,
        baseline = true,
    },
    -- Ice Block
    [45438] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 300,
        baseline = true,
    },
    -- Remove Curse
    [475] = {
        class = addon.MAGE,
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
    },
    -- Presence of Mind
    [12043] = {
        class = addon.MAGE,
        category = category.BURST,
        cooldown = 90,
        trackEvent = addon.SPELL_AURA_REMOVED,
    },
    -- Temporal Shield
    [115610] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 25,
    },
    -- Ice Barrier
    [11426] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 25,
    },
    -- Ring of Frost
    [113724] = {
        class = addon.MAGE,
        category = category.CROWDCONTROL,
        cooldown = 45,
    },
    -- Frostjaw
    [102051] = {
        class = addon.MAGE,
        category = category.SILENCE,
        cooldown = 20,
    },
    -- Cauterize
    [87024] = {
        class = addon.MAGE,
        category = category.DEFENSIVE,
        cooldown = 120,
        trackEvent = addon.SPELL_AURA_APPLIED,
    },

    -- Fire
    -- Combustion
    [11129] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.BURST,
        cooldown = 45,
        duration = 3,
        baseline = true,
    },
    -- Dragon's Breath
    [31661] = {
        class = addon.MAGE,
        spec = { specID.FIRE },
        category = category.CROWDCONTROL,
        cooldown = 20,
        baseline = true,
    },
    -- Arcane
    -- Arcane Power
    [12042] = {
        class = addon.MAGE,
        spec = { specID.ARCANE },
        category = category.BURST,
        cooldown = 90,
        duration = 15,
        baseline = true,
    },
    -- Icy Veins
    [12472] = {
        class = addon.MAGE,
        spec = { specID.FROST },
        category = category.BURST,
        cooldown = 180,
        duration = 20,
        baseline = true,
    },

    -- Monk
    -- Detox
    [115450] = {
        class = addon.MONK,
        category = category.DISPEL,
        cooldown = 8,
        baseline = true,
    },
    -- Fortifying Brew
    [115203] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Grapple Weapon
    [117368] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 60,
        baseline = true,
    },
    -- Nimble Brew
    [137562] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Paralysis
    [115078] = {
        class = addon.MONK,
        category = category.CROWDCONTROL,
        cooldown = 15,
        baseline = true,
    },
    -- Spear Hand Strike
    [116705] = {
        class = addon.MONK,
        category = category.INTERRUPT,
        cooldown = 15,
        baseline = true,
    },
    -- Tiger's Lust
    [116841] = {
        class = addon.MONK,
        category = category.OTHERS,
        cooldown = 30,
        baseline = true,
    },
    -- Touch of Death
    [115080] = {
        class = addon.MONK,
        category = category.BURST,
        cooldown = 90,
        baseline = true,
    },
    -- Transcendence: Transfer
    [119996] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 25,
        baseline = true,
    },
    -- Zen Meditation
    [115176] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 180,
        baseline = true,
    },
    -- Leg Sweep
    [119381] = {
        class = addon.MONK,
        category = category.STUN,
        cooldown = 45,
    },
    -- Ring of Peace
    [116844] = {
        class = addon.MONK,
        category = category.KNOCKBACK,
        cooldown = 45,
    },
    -- Dampen Harm
    [122278] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Diffuse Magic
    [122783] = {
        class = addon.MONK,
        category = category.DEFENSIVE,
        cooldown = 90,
    },
    -- Invoke Xuen, the White Tiger
    [123904] = {
        class = addon.MONK,
        category = category.BURST,
        cooldown = 180,
        duration = 45,
    },

    -- Windwalker
    -- Energizing Brew
    [115288] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.BURST,
        cooldown = 60,
        baseline = true,
    },
    -- Touch of Karma
    [122470] = {
        class = addon.MONK,
        spec = { specID.WINDWALKER },
        category = category.DEFENSIVE,
        cooldown = 90,
        baseline = true,
    },
    -- Mistweaver
    -- Life Cocoon
    [116849] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.DEFENSIVE,
        cooldown = 120,
        baseline = true,
    },
    -- Revival
    [115310] = {
        class = addon.MONK,
        spec = { specID.MISTWEAVER },
        category = category.HEAL,
        cooldown = 180,
        baseline = true,
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

    -- Cold Snap
    [235219] = {
        45438, -- Ice Block
    },

    -- Apotheosis
    [200183] = {
        88625, -- Holy Word: Chastise
        2050, -- Grants one charge of Holy Word: Serenity
    },

    -- Holy Fire
    [14914] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },
    -- Smite
    [585] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },
    -- Holy Nova
    [132157] = {
        { spellID = 88625, amount = 4 }, -- Holy Word: Chastise
    },

    -- Prayer of Mending
    [33076] = {
        { spellID = 2050, amount = 4 }, -- Holy Word: Serenity
    },
    -- Power Word: Life
    [440678] = {
        { spellID = 2050, amount = 4 }, -- Holy Word: Serenity
    },
    -- Heal
    [2060] = {
        { spellID = 2050, amount = 6 }, -- Holy Word: Serenity
    },
    -- Flash Heal
    [2061] = {
        { spellID = 2050, amount = 6 }, -- Holy Word: Serenity
    },

    -- Power Word: Shield
    [17] = {
        { spellID = 33206, amount = 3 }, -- Pain Suppression
    },

    -- Kill Command
    [34026] = {
        { spellID = 19577, amount = 0.5 }, -- Intimidation
        { spellID = 109248, amount = 0.5 }, -- Binding Shot
    }
};

addon.SpellResets[382445] = {}; -- Shifting Power each tick
addon.SpellResets[157982] = {}; -- Tranquility each tick
-- Reduce each Mage spell by 3 Sec
-- Fill the entries programatically from addon.Spells
for spellID, spell in pairs(addon.SpellData) do
    if spell.class == addon.MAGE then
        table.insert(addon.SpellResets[382445], { spellID = spellID, amount = 3 });
    elseif ( spell.class == addon.DRUID and spellID ~= 740 ) then
        table.insert(addon.SpellResets[157982], { spellID = spellID, amount = 4 });
    end
end

addon.SpellResetsAffectedByApotheosis = {
    [14914] = 2, -- Holy Fire (nerfed in PvP)
    [585] = 3, -- Smite
    [132157] = 3, -- Holy Nova

    [33076] = 3, -- Prayer of Mending
    [440678] = 3, -- Power Word: Life
    [2060] = 3, -- Heal
    [2061] = 3, -- Flash Heal
};

if addon.TEST_MODE then
    -- Test
    -- Mark of the Wild
    addon.SpellData[1126] = {
        class = addon.DRUID,
        category = category.INTERRUPT,
        duration = 8,
        cooldown = 30,
        index = addon.SPELLPRIORITY.HIGH,
        baseline = true,
    };
    -- Regrowth
    addon.SpellData[8936] = {
        class = addon.DRUID,
        category = category.INTERRUPT,
        duration = 5,
        cooldown = 10,
        baseline = true,
    };
    -- Rejuv
    addon.SpellData[774] = {
        class = addon.DRUID,
        category = category.DEFENSIVE,
        cooldown = 8,
        baseline = true,
        opt_charges = true,
    };
    -- Wild Growth
    addon.SpellData[48438] = {
        class = addon.DRUID,
        category = category.BURST,
        duration = 7,
        cooldown = 30,
        trackDest = true,
        trackEvent = addon.SPELL_AURA_APPLIED,
        baseline = true,
    };

    addon.SpellData[1459] = {
        class = addon.MAGE,
        category = category.BURST,
        duration = 12,
        cooldown = 120,
        index = addon.SPELLPRIORITY.HIGH,

        -- Fireball, Pyroblast, Fire Blast, Scorch, Phoenix Flames
        critResets = {
            [133] = 1,
            [11366] = 1,
            [108853] = 1,
            [2948] = 1,
            [257542] = 1,
        }
    };
end

for _, spell in pairs(addon.SpellData) do
    -- Fill default glow duration for burst abilities
    if spell.category == category.BURST and ( not spell.duration ) then
        spell.duration = 3;
    end
end

for _, spell in pairs(addon.SpellData) do
    -- Fill options from parent
    if spell.parent then
        local parent = addon.SpellData[spell.parent];

        spell.cooldown = spell.cooldown or parent.cooldown;
        spell.duration = spell.duration or parent.duration;
        spell.class = spell.class or parent.class;
        spell.spec = spell.spec or parent.spec;
        spell.category = spell.category or parent.category;
        spell.trackPet = spell.trackPet or parent.trackPet;
        spell.trackEvent = spell.trackEvent or parent.trackEvent;
        spell.baseline = spell.baseline or parent.baseline;
        spell.index = spell.index or parent.index;
        spell.default = spell.default or parent.default;
    end
end
