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
