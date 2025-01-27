local _, addon = ...;

addon.AuraList = { -- Use table with consecutive indexes to preserve the order
    {
        classID = addon.CLASSID.DEATHKNIGHT,
        auras = {
            { spellId = 45524, default = true }, -- Chains of Ice
            -- Unholy
            { spellId = 191587, default = true }, -- Virulent Plague
            { spellId = 194310, default = true }, -- Festering Wound
            -- Frost
            { spellId = 55095, default = true }, -- Frost Fever
            -- Blood
            { spellId = 55078, default = true }, -- Blood Plague
        }
    },
    {
        classID = addon.CLASSID.DEMONHUNTER,
        auras = {
            { spellId = 390155, default = true }, -- Serrated Glaive
            { spellId = 391191, default = true }, -- Burning Wound
            { spellId = 390181 }, -- Soulscar
            { spellId = 213405 }, -- Master of the Glaive
        }
    },
    {
        classID = addon.CLASSID.DRUID,
        auras = {
            { spellId = 164812, default = true }, -- Moonfire
            { spellId = 164815, default = true }, -- Sunfire
            { spellId = 155722, default = true }, -- Rake
            { spellId = 1079, default = true }, -- Rip
            { spellId = 391889, default = true }, -- Adaptive Swarm
            { spellId = 405233, default = true}, -- Thrash
            { spellId = 236021 }, -- Ferocious Wound
            { spellId = 274838 }, -- Feral Frenzy
            { spellId = 439531 }, -- Bloodseeker Vines
        }
    },
    {
        classID = addon.CLASSID.EVOKER,
        auras = {
            { spellId = 357209, default = true }, -- Fire Breath
        }
    },
    {
        classID = addon.CLASSID.HUNTER,
        auras = {
            { spellId = 212431, default = true }, -- Explosive Shot
            { spellId = 271788, default = true }, -- Serpent Sting
            { spellId = 5116, default = true }, -- Concussive Shot
            { spellId = 217200 }, -- Barbed Shot
        }
    },
    {
        classID = addon.CLASSID.MAGE,
        auras = {
            { spellId = 210824, default = true }, -- Touch of the Magi
            { spellId = 31589, default = true }, -- Slow
            { spellId = 12654 }, -- Ignite
            { spellId = 217694 }, -- Living Bomb
            { spellId = 244813 }, -- Living Bomb
        }
    },
    -- {
    --     classID = addon.CLASSID.MONK,
    --     auras = {
    --         { spellId = 115078, default = true }, -- Paralysis
    --         { spellId = 123725, default = true }, -- Breath of Fire
    --         { spellId = 115804, default = true }, -- Mortal Wounds
    --         { spellId = 116189, default = true }, -- Provoke
    --     }
    -- },
    -- {
    --     classID = addon.CLASSID.PALADIN,
    --     auras = {
    --         { spellId = 853, default = true }, -- Hammer of Justice
    --         { spellId = 183218, default = true }, -- Hand of Hindrance
    --         { spellId = 197277, default = true }, -- Judgment of Light
    --         { spellId = 204242, default = true }, -- Consecration
    --     }
    -- },
    -- {
    --     classID = addon.CLASSID.PRIEST,
    --     auras = {
    --         { spellId = 589, default = true }, -- Shadow Word: Pain
    --         { spellId = 34914, default = true }, -- Vampiric Touch
    --         { spellId = 204213, default = true }, -- Purge the Wicked
    --         { spellId = 335467, default = true }, -- Devouring Plague
    --     }
    -- },
    -- {
    --     classID = addon.CLASSID.ROGUE,
    --     auras = {
    --         { spellId = 703, default = true }, -- Garrote
    --         { spellId = 1943, default = true }, -- Rupture
    --         { spellId = 2818, default = true }, -- Deadly Poison
    --         { spellId = 3409, default = true }, -- Crippling Poison
    --     }
    -- },
    -- {
    --     classID = addon.CLASSID.SHAMAN,
    --     auras = {
    --         { spellId = 188389, default = true }, -- Flame Shock
    --         { spellId = 196840, default = true }, -- Frost Shock
    --         { spellId = 197209, default = true }, -- Lightning Rod
    --         { spellId = 64695, default = true }, -- Earthgrab
    --     }
    -- },
    -- {
    --     classID = addon.CLASSID.WARLOCK,
    --     auras = {
    --         { spellId = 980, default = true }, -- Agony
    --         { spellId = 172, default = true }, -- Corruption
    --         { spellId = 348, default = true }, -- Immolate
    --         { spellId = 30108, default = true }, -- Unstable Affliction
    --     }
    -- },
    -- {
    --     classID = addon.CLASSID.WARRIOR,
    --     auras = {
    --         { spellId = 115767, default = true }, -- Deep Wounds
    --         { spellId = 1160, default = true }, -- Demoralizing Shout
    --         { spellId = 208086, default = true }, -- Colossus Smash
    --         { spellId = 1715, default = true }, -- Hamstring
    --     }
    -- },
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
        name = "Reset to default",
        func = function()
            addon.FillDefaultToAuraOptions(SweepyBoop.db.profile.nameplatesEnemy.auraWhiteList);
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
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(texture) .. " " .. C_Spell.GetSpellName(auraEntry.spellId),
                desc = description,
            };
            auraIdx = auraIdx + 1;
        end

        group.args[tostring(classEntry.classID)] = classGroup;
        index = index + 1;
    end
end
