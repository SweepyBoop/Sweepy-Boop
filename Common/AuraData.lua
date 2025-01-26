local _, addon = ...;

addon.AuraList = { -- Use table with consecutive indexes to preserve the order
    {
        classID = addon.CLASSID.DEATHKNIGHT,
        auras = {
            { spellId = 45524, default = true }, -- Chains of Ice
            -- Unholy
            { spellId = 77575, default = true }, -- Virulent Plague
            { spellId = 197147, default = true }, -- Festering Wound
            { spellId = 194310, default = true }, -- Festering Wound (new)
            -- Frost
            { spellId = 55095, default = true }, -- Frost Fever
            -- Blood
            { spellId = 55078, default = true }, -- Blood Plague
            { spellId = 206930, default = true }, -- Heart Strike
            { spellId = 206931, default = true }, -- Blooddrinker
        }
    },
    {
        classID = addon.CLASSID.DEMONHUNTER,
        auras = {
            { spellId = 207690, default = true }, -- Bloodlet
            { spellId = 204490, default = true }, -- Sigil of Silence
            { spellId = 204598, default = true }, -- Sigil of Flame
            { spellId = 207744, default = true }, -- Fiery Brand
            { spellId = 204021, default = true }, -- Fiery Demise
            { spellId = 206491, default = true }, -- Nemesis
            { spellId = 213405, default = true }, -- Master of the Glaive
        }
    },
    {
        classID = addon.CLASSID.DRUID,
        auras = {
            { spellId = 164812, default = true }, -- Moonfire
            { spellId = 164815, default = true }, -- Sunfire
            { spellId = 155722, default = true }, -- Rake
            { spellId = 1079, default = true }, -- Rip
            { spellId = 33763, default = true }, -- Lifebloom
            { spellId = 188550, default = true }, -- Lifebloom (new)
            { spellId = 102359, default = true }, -- Mass Entanglement
        }
    },
    {
        classID = addon.CLASSID.EVOKER,
        auras = {
            { spellId = 370898, default = true }, -- Fire Breath
            { spellId = 355689, default = true }, -- Dream Breath
        }
    },
    {
        classID = addon.CLASSID.HUNTER,
        auras = {
            { spellId = 217200, default = true }, -- Barbed Shot
            { spellId = 259491, default = true }, -- Serpent Sting
            { spellId = 135299, default = true }, -- Tar Trap
            { spellId = 162487, default = true }, -- Steel Trap
        }
    },
    {
        classID = addon.CLASSID.MAGE,
        auras = {
            { spellId = 12654, default = true }, -- Ignite
            { spellId = 31589, default = true }, -- Slow
            { spellId = 122, default = true }, -- Frost Nova
            { spellId = 44457, default = true }, -- Living Bomb
        }
    },
    {
        classID = addon.CLASSID.MONK,
        auras = {
            { spellId = 115078, default = true }, -- Paralysis
            { spellId = 123725, default = true }, -- Breath of Fire
            { spellId = 115804, default = true }, -- Mortal Wounds
            { spellId = 116189, default = true }, -- Provoke
        }
    },
    {
        classID = addon.CLASSID.PALADIN,
        auras = {
            { spellId = 853, default = true }, -- Hammer of Justice
            { spellId = 183218, default = true }, -- Hand of Hindrance
            { spellId = 197277, default = true }, -- Judgment of Light
            { spellId = 204242, default = true }, -- Consecration
        }
    },
    {
        classID = addon.CLASSID.PRIEST,
        auras = {
            { spellId = 589, default = true }, -- Shadow Word: Pain
            { spellId = 34914, default = true }, -- Vampiric Touch
            { spellId = 204213, default = true }, -- Purge the Wicked
            { spellId = 335467, default = true }, -- Devouring Plague
        }
    },
    {
        classID = addon.CLASSID.ROGUE,
        auras = {
            { spellId = 703, default = true }, -- Garrote
            { spellId = 1943, default = true }, -- Rupture
            { spellId = 2818, default = true }, -- Deadly Poison
            { spellId = 3409, default = true }, -- Crippling Poison
        }
    },
    {
        classID = addon.CLASSID.SHAMAN,
        auras = {
            { spellId = 188389, default = true }, -- Flame Shock
            { spellId = 196840, default = true }, -- Frost Shock
            { spellId = 197209, default = true }, -- Lightning Rod
            { spellId = 64695, default = true }, -- Earthgrab
        }
    },
    {
        classID = addon.CLASSID.WARLOCK,
        auras = {
            { spellId = 980, default = true }, -- Agony
            { spellId = 172, default = true }, -- Corruption
            { spellId = 348, default = true }, -- Immolate
            { spellId = 30108, default = true }, -- Unstable Affliction
        }
    },
    {
        classID = addon.CLASSID.WARRIOR,
        auras = {
            { spellId = 115767, default = true }, -- Deep Wounds
            { spellId = 1160, default = true }, -- Demoralizing Shout
            { spellId = 208086, default = true }, -- Colossus Smash
            { spellId = 1715, default = true }, -- Hamstring
        }
    },
};

addon.FillDefaultToAuraOptions = function(profile)
    for _, classEntry in ipairs(addon.AuraList) do
        for _, auraEntry in ipairs(classEntry.auras) do
            profile[tostring(auraEntry.spellId)] = auraEntry.default;
        end
    end
end

addon.AppendAuraOptionsToGroup = function(group)
    group.args = {};

    group.args.reset = {
        order = 1,
        type = "execute",
        name = "Reset filter whitelist",
        func = function()
            addon.FillDefaultToAuraOptions(SweepyBoop.db.profile.nameplatesEnemy.filterList);
        end,
    };

    local index = 2;
    for _, classEntry in ipairs(addon.AuraList) do
        local classInfo = C_CreatureInfo.GetClassInfo(classEntry.classID);
        local classGroup = {
            order = index,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };

        local auraIdx = 1;
        for _, auraEntry in ipairs(classEntry.auras) do
            -- https://warcraft.wiki.gg/wiki/SpellMixin
            local description;
            local spell = Spell:CreateFromSpellID(auraEntry.spellId);
            spell:ContinueOnSpellLoad(function()
                description = spell:GetSpellDescription();
            end)
            
            local texture = C_Spell.GetSpellTexture(auraEntry.spellId);
            classGroup.args[tostring(auraEntry.spellId)] = {
                order = auraIdx,
                type = "select",
                width = "full",
                values = {
                    [addon.AuraOption.Hide] = "Hide",
                    [addon.AuraOption.Show] = "Show",
                    [addon.AuraOption.Highlight] = "Highlight",
                },
                name = addon.FORMAT_TEXTURE(texture) .. " " .. GetSpellInfo(auraEntry.spellId),
                desc = description,
            };
            auraIdx = auraIdx + 1;
        end

        group.args[tostring(classEntry.classID)] = classGroup;
        index = index + 1;
    end
end
