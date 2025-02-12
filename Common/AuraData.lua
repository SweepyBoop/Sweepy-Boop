local _, addon = ...;

addon.DebuffList = { -- Use table with consecutive indexes to preserve the order
    {
        classID = addon.CLASSID.DEATHKNIGHT,
        auras = {
            { spellId = 191587, default = true }, -- Virulent Plague
            { spellId = 194310, default = true }, -- Festering Wound
            { spellId = 55095, default = true }, -- Frost Fever
            { spellId = 55078, default = true }, -- Blood Plague

            { spellId = 45524, default = true }, -- Chains of Ice
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

            { spellId = 205708 }, -- Chilled
            { spellId = 228358 }, -- Winter's Chill

            { spellId = 12654 }, -- Ignite
            { spellId = 217694 }, -- Living Bomb
            { spellId = 244813 }, -- Living Bomb
        }
    },
    {
        classID = addon.CLASSID.MONK,
        auras = {
            { spellId = 116095, default = true }, -- Disable

            { spellId = 228287 }, -- Mark of the Crane
            { spellId = 451433}, -- Acclamation
            { spellId = 392983 }, -- Strike of the Windlord
            { spellId = 122470 }, -- Touch of Karma
            { spellId = 115804 }, -- Mortal Wounds
        }
    },
    {
        classID = addon.CLASSID.PALADIN,
        auras = {
            { spellId = 343721, default = true }, -- Final Reckoning
            { spellId = 197277, default = true }, -- Judgment
            { spellId = 403695, default = true }, -- Truth's Wake
            { spellId = 383346, default = true }, -- Expurgation

            { spellId = 408383 }, -- Judgment of Justice
        }
    },
    {
        classID = addon.CLASSID.PRIEST,
        auras = {
            { spellId = 589, default = true }, -- Shadow Word: Pain
            { spellId = 204213, default = true }, -- Purge the Wicked
            { spellId = 34914, default = true }, -- Vampiric Touch
            { spellId = 335467, default = true }, -- Devouring Plague
            { spellId = 214621, default = true }, -- Schism
            { spellId = 375901, default = true }, -- Mindgames
            { spellId = 323716, default = true }, -- Thoughtsteal

            -- { spellId = 199845 }, -- Psyflay (Psyfiend)
        }
    },
    {
        classID = addon.CLASSID.ROGUE,
        auras = {
            { spellId = 703, default = true }, -- Garrote
            { spellId = 1943, default = true }, -- Rupture
            { spellId = 360194, default = true }, -- Deathmark
            { spellId = 121411, default = true }, -- Crimson Tempest
            { spellId = 394036, default = true }, -- Serrated Bone Spike

            { spellId = 381628 }, -- Internal Bleeding
            { spellId = 385627 }, -- Kingsbane
            { spellId = 5760 }, -- Numbing Poison
            { spellId = 3409 }, -- Crippling Poison
            { spellId = 383414 }, -- Amplifying Poison
            { spellId = 2818 }, -- Deadly Poison
            { spellId = 8680 }, -- Wound Poison
        }
    },
    {
        classID = addon.CLASSID.SHAMAN,
        auras = {
            { spellId = 188389, default = true }, -- Flame Shock
            { spellId = 196840, default = true }, -- Frost Shock
            { spellId = 197209, default = true }, -- Lightning Rod

            { spellId = 3600 }, -- Earthbind
        }
    },
    {
        classID = addon.CLASSID.WARLOCK,
        auras = {
            { spellId = 316099, default = true }, -- Unstable Affliction
            { spellId = 980, default = true }, -- Agony
            { spellId = 146739, default = true }, -- Corruption
            { spellId = 27243, default = true }, -- Seed of Corruption
            { spellId = 48181, default = true }, -- Haunt
            { spellId = 205179, default = true }, -- Phantom Singularity
            { spellId = 702, default = true }, -- Curse of Weakness
            { spellId = 1714, default = true}, -- Curse of Tongues

            { spellId = 157736 }, -- Immolate
            { spellId = 386997 }, -- Soul Rot

            { spellId = 334275 }, -- Curse of Exhaustion
            { spellId = 410598 }, -- Soul Rip
        }
    },
    {
        classID = addon.CLASSID.WARRIOR,
        auras = {
            { spellId = 1715, default = true }, -- Hamstring
            { spellId = 376080, default = true }, -- Champion's Spear
            { spellId = 208086, default = true }, -- Colossus Smash (Warbreaker)
            { spellId = 354788, default = true }, -- Slaughterhouse

            { spellId = 388539 }, -- Rend
        }
    },
};

addon.BuffList = {
    {
        classID = addon.CLASSID.DEATHKNIGHT,
        auras = {
            { spellId = 48707, default = true }, -- Anti-Magic Shell
            { spellId = 48792, default = true }, -- Icebound Fortitude
            { spellId = 49039, default = true }, -- Lichborne
        }
    },
    {
        classID = addon.CLASSID.DEMONHUNTER,
        auras = {
            { spellId = 196555, default = true }, -- Netherwalk
            { spellId = 212800, default = true }, -- Blur
            { spellId = 209426 }, -- Darkness
        }
    },
    {
        classID = addon.CLASSID.DRUID,
        auras = {
            { spellId = 61336, default = true }, -- Survival Instincts
            { spellId = 102342, default = true }, -- Ironbark
            { spellId = 22812, default = true }, -- Barkskin

            { spellId = 102352 }, -- Cenarion Ward
            { spellId = 33763 }, -- Lifebloom
            { spellId = 188550 }, -- Lifebloom (Undergrowth)
        }
    },
    {
        classID = addon.CLASSID.EVOKER,
        auras = {
            { spellId = 378464, default = true }, -- Nullifying Shroud
            { spellId = 363916, default = true }, -- Obsidian Scales
        }
    },
    {
        classID = addon.CLASSID.HUNTER,
        auras = {
            { spellId = 186265, default = true }, -- Aspect of the Turtle
            { spellId = 264735, default = true }, -- Survival of the Fittest
        }
    },
    {
        classID = addon.CLASSID.MAGE,
        auras = {
            { spellId = 45438, default = true }, -- Ice Block
            { spellId = 110909, default = true }, -- Alter Time
            { spellId = 342246, default = true }, -- Alter Time

            --{ spellId = 12544, default = true }, -- Frost Armor (For testing, mobs near Stone Cairn Lake in Elywnn Forest)
        }
    },
    {
        classID = addon.CLASSID.MONK,
        auras = {
            { spellId = 116849, default = true }, -- Life Cocoon
            { spellId = 125174, default = true }, -- Touch of Karma
            { spellId = 122783, default = true }, -- Diffuse Magic
        }
    },
    {
        classID = addon.CLASSID.PALADIN,
        auras = {
            { spellId = 642, default = true }, -- Divine Shield
            { spellId = 1022, default = true }, -- Blessing of Protection
            { spellId = 204018, default = true }, -- Blessing of Spellwarding
            { spellId = 6940, default = true }, -- Blessing of Sacrifice
            { spellId = 86659, default = true }, -- Guardian of Ancient Kings
            { spellId = 184662 }, -- Shield of Vengeance
            { spellId = 498 }, -- Divine Protection
        }
    },
    {
        classID = addon.CLASSID.PRIEST,
        auras = {
            { spellId = 33206, default = true }, -- Pain Suppression
            { spellId = 47788, default = true }, -- Guardian Spirit
            { spellId = 47585, default = true }, -- Dispersion
        }
    },
    {
        classID = addon.CLASSID.ROGUE,
        auras = {
            { spellId = 31224, default = true }, -- Cloak of Shadows
            { spellId = 5277, default = true }, -- Evasion
        }
    },
    {
        classID = addon.CLASSID.SHAMAN,
        auras = {
            { spellId = 108271, default = true }, -- Astral Shift
        }
    },
    {
        classID = addon.CLASSID.WARLOCK,
        auras = {
            { spellId = 104773, default = true }, -- Unending Resolve
        }
    },
    {
        classID = addon.CLASSID.WARRIOR,
        auras = {
            { spellId = 118038, default = true }, -- Die by the Sword
            { spellId = 184364, default = true }, -- Enraged Regeneration
        }
    }
};

addon.FillDefaultToAuraOptions = function(profile, auraList)
    for _, classEntry in ipairs(auraList) do
        for _, auraEntry in ipairs(classEntry.auras) do
            profile[tostring(auraEntry.spellId)] = auraEntry.default;
        end
    end
end

addon.AppendAuraOptionsToGroup = function(group, auraList, profileName)
    group.args = {};

    group.args.reset = {
        order = 1,
        type = "execute",
        name = "Reset to default",
        func = function()
            local profile = SweepyBoop.db.profile.nameplatesEnemy[profileName];
            addon.FillDefaultToAuraOptions(profile, auraList);
        end,
    };

    local index = 2;
    for _, classEntry in ipairs(auraList) do
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
            local spell = Spell:CreateFromSpellID(auraEntry.spellId);
            spell:ContinueOnSpellLoad(function()
                addon.SPELL_DESCRIPTION[auraEntry.spellId] = spell:GetSpellDescription();
            end)

            local texture = C_Spell.GetSpellTexture(auraEntry.spellId);
            classGroup.args[tostring(auraEntry.spellId)] = {
                order = auraIdx,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(texture) .. " " .. C_Spell.GetSpellName(auraEntry.spellId),
                desc = function ()
                    return addon.SPELL_DESCRIPTION[auraEntry.spellId] or "";
                end
            };
            auraIdx = auraIdx + 1;
        end

        group.args[tostring(classEntry.classID)] = classGroup;
        index = index + 1;
    end
end
