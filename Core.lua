local addonName, addon = ...;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");
local SweepyBoopLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {  
	type = "data source",
	text = "SweepyBoop",
	icon = addon.INTERFACE_SWEEPY .. "Art/Logo",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(addon.addonTitle, 1, 1, 1);
        tooltip:AddLine("Click to open options");
    end,
	OnClick = function()
        LibStub("AceConfigDialog-3.0"):Open(addonName);
    end,
})  
local icon = LibStub("LibDBIcon-1.0");

local pvpCursor = "interface/cursor/pvp";

local options = {
    name = addon.addonTitle,
    type = "group",
    args = {
        description = {
            order = 1,
            type = "description",
            fontSize = "large",
            image = addon.INTERFACE_SWEEPY .. "Art/Logo",
            imageWidth = 36,
            imageHeight = 36,
            name = "A lightweight addon to enhance your arena & battleground experience :)"
        },
    },
};

options.args.nameplatesFriendly = {
    order = 3,
    type = "group",
    name = "Friendly class icons",
    get = function(info) return SweepyBoop.db.profile.nameplatesFriendly[info[#info]] end,
    set = function(info, val)
        SweepyBoop.db.profile.nameplatesFriendly[info[#info]] = val;
        SweepyBoop.db.profile.nameplatesFriendly.lastModified = GetTime();
        SweepyBoop:RefreshAllNamePlates();
    end,
    args = {
        classIconsEnabled = {
            order = 1,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid") .. " Enabled",
            desc = "Show class/pet icons on friendly players/pets",
            set = function(info, val)
                SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled = val;
                SweepyBoop.db.profile.nameplatesFriendly.lastModified = GetTime();
                SweepyBoop:RefreshAllNamePlates(true);
            end
        },
        description1 = {
            order = 2,
            width = "full",
            type = "description",
            name = "|cFFFF0000" .. addon.EXCLAMATION .. " Enable \"Friendly Player Nameplates\" in Interface - Nameplates for class icons|r",
            hidden = function ()
                return ( C_CVar.GetCVar("nameplateShowFriends") == "1" );
            end
        },
        description2 = {
            order = 3,
            width = "full",
            type = "description",
            name = addon.EXCLAMATION .. " Enable \"Minions\" in Interface - Nameplates for pet icons",
            hidden = function ()
                return ( C_CVar.GetCVar("nameplateShowFriendlyPets") == "1" );
            end
        },
        classIconStyle = {
            order = 4,
            type = "select",
            values = {
                [addon.CLASS_ICON_STYLE.ICON] = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid") .. " WoW class icons",
                [addon.CLASS_ICON_STYLE.ARROW] = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/ClassArrow") .. " Class color arrows",
                [addon.CLASS_ICON_STYLE.ICON_AND_ARROW] =
                    addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/ClassArrow")
                    .. addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid")
                    .. " Icon + arrow",
            },
            name = "Icon style",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( not addon.PROJECT_MAINLINE );
            end
        },
        newline1 = {
            order = 5,
            type = "description",
            name = "",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        showSpecIcons = {
            order = 6,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_OTHERS_LOGO) .. " Show spec icons instead of class icons in PvP instances",
            hidden = function()
                return ( not addon.PROJECT_MAINLINE ) or
                    ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( SweepyBoop.db.profile.nameplatesFriendly.classIconStyle == addon.CLASS_ICON_STYLE.ARROW );
            end
        },
        hideOutsidePvP = {
            order = 7,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(pvpCursor) .. " Hide class icons outside arenas & battlegrounds",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        breaker1 = {
            order = 8,
            type = "header",
            name = "",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        useHealerIcon = {
            order = 9,
            width = "full",
            type = "toggle",
            name = addon.HELAER_LOGO .. " Show healer icon instead of class icon for healers",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        showHealerOnly = {
            order = 10,
            width = "full",
            type = "toggle",
            name = addon.HELAER_LOGO .. " Show healers only",
            desc = "Hide class icons of non-healer players\nFlag carrier icons will still show if the option is enabled",
            hidden = function ()
                local config = SweepyBoop.db.profile.nameplatesFriendly;
                local dependencyEnabled = config.classIconsEnabled and config.useHealerIcon;
                return ( not dependencyEnabled );
            end
        },
        showMyPetOnly = {
            order = 11,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.ICON_ID_PET) .. " Show my pet only",
            desc = "Hide class icons of other players' pets\nThis option is not available in arenas",
            hidden = function ()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        useFlagCarrierIcon = {
            order = 12,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.FLAG_CARRIER_ALLIANCE_LOGO) .. " Show flag carrier icons in battlegrounds",
            desc = "Use special icons for friendly flag carriers\nThis overwrites the healer icon",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) or ( not addon.PROJECT_MAINLINE );
            end
        },
        targetHighlight = {
            order = 13,
            type = "toggle",
            width = "full",
            name = addon.FORMAT_ATLAS("charactercreate-ring-select") .. " Show target highlight",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        classIconSize = {
            order = 14,
            type = "range",
            isPercent = true,
            min = 0.5,
            max = 2,
            step = 0.01,
            name = "Class icon size",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        petIconSize = {
            order = 15,
            type = "range",
            isPercent = true,
            min = 0.5,
            max = 2,
            step = 0.01,
            name = "Pet icon size",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        newline2 = {
            order = 16,
            type = "description",
            name = "",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        classIconOffset = {
            order = 17,
            type = "range",
            min = 0,
            max = 150,
            step = 1,
            name = "Icon offset",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },

        breaker2 = {
            order = 18,
            type = "header",
            name = "",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },

        classColorBorder = {
            order = 19,
            type = "toggle",
            width = "full",
            name = addon.FORMAT_ATLAS("charactercreate-ring-select") .. " Class-colored borders",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },

        showPlayerName = {
            order = 20,
            type = "toggle",
            width = "full",
            name = addon.FORMAT_ATLAS("tokens-changeName-regular") .. " Show class-colored names under class icons",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        }
    }
};

local beastMasteryHunterIcon = ( addon.PROJECT_MAINLINE and C_Spell.GetSpellTexture(267116) ) or C_Spell.GetSpellTexture(19574);
options.args.nameplatesEnemy = {
    order = 4,
    type = "group",
    childGroups = "tab",
    name = "Enemy nameplates",
    get = function(info) return SweepyBoop.db.profile.nameplatesEnemy[info[#info]] end,
    set = function(info, val)
        SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
        SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
        SweepyBoop:RefreshAllNamePlates();
    end,
    args = {
        general = {
            order = 1,
            type = "group",
            name = "General",
            args = {
                arenaNumbersEnabled = {
                    order = 1,
                    width = "full",
                    type = "toggle",
                    name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_misc_number_1")) .. " Arena enemy player nameplate numbers",
                    desc = "Places arena numbers over enemy players' nameplates, e.g., 1 for arena1, and so on",
                },

                breaker2 = {
                    order = 2,
                    type = "header",
                    name = "Arena & battleground enemy spec icons",
                    hidden = function ()
                        return ( not addon.PROJECT_MAINLINE );
                    end
                },
                arenaSpecIconHealer = {
                    order = 3,
                    width = "full",
                    type = "toggle",
                    name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_HEALER_LOGO) ..  " Show spec icon for healers",
                    desc = "Show spec icons on top of the nameplates of enemy healers",
                    hidden = function ()
                        return ( not addon.PROJECT_MAINLINE );
                    end
                },
                arenaSpecIconHealerIcon = {
                    order = 4,
                    width = "full",
                    type = "toggle",
                    name = addon.FORMAT_ATLAS(addon.ICON_ID_HEALER_ENEMY) .. " Show healer icon instead of spec icon for healers",
                    hidden = function ()
                        return ( not addon.PROJECT_MAINLINE ) or ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer );
                    end
                },
                arenaSpecIconOthers = {
                    order = 5,
                    width = "full",
                    type = "toggle",
                    name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_OTHERS_LOGO) .. " Show spec icon for non-healers",
                    desc = "Show a spec icon on top of the nameplate for enemy players that are not healers inside arenas",
                    hidden = function ()
                        return ( not addon.PROJECT_MAINLINE );
                    end
                },
                arenaSpecIconAlignment = {
                    order = 6,
                    type = "select",
                    width = 0.75,
                    name = "Alignment",
                    values = {
                        [addon.SPEC_ICON_ALIGNMENT.TOP] = "Top",
                        [addon.SPEC_ICON_ALIGNMENT.LEFT] = "Left",
                        [addon.SPEC_ICON_ALIGNMENT.RIGHT] = "Right",
                    },
                    hidden = function ()
                        if ( not addon.PROJECT_MAINLINE ) then return true end
                        return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer ) and ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers );
                    end
                },
                arenaSpecIconVerticalOffset = {
                    order = 7,
                    min = -150,
                    max = 150,
                    step = 1,
                    type = "range",
                    width = 0.85,
                    name = "Vertical offset",
                    hidden = function ()
                        if ( not addon.PROJECT_MAINLINE ) then return true end
                        if ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer ) and ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers ) then return true end
                        return ( SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment ~= addon.SPEC_ICON_ALIGNMENT.TOP );
                    end
                },
                arenaSpecIconScale = {
                    order = 8,
                    min = 50,
                    max = 300,
                    step = 1,
                    type = "range",
                    width = 0.75,
                    name = "Scale (%)",
                    hidden = function ()
                        if ( not addon.PROJECT_MAINLINE ) then return true end
                        return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer ) and ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers );
                    end
                },

                breaker3 = {
                    order = 9,
                    type = "header",
                    name = "Nameplate Filters & Highlights",
                },

                hideHunterSecondaryPet = {
                    order = 10,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(beastMasteryHunterIcon) .. " Hide beast mastery hunter secondary pets in arena",
                    desc = "Hide the extra pet from talents\nThis feature is not available in battlegrounds due to WoW API limitations",
                },
                filterEnabled = {
                    order = 11,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(pvpCursor) .. " Customize enemy units to hide / show / highlight",
                    desc = "Each unit's nameplate can be hidden, shown, or shown with a pulsing icon on top\nThis works in arenas and battlegrounds",
                },
                showCritterIcons = {
                    order = 12,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_ATLAS(addon.ICON_CRITTER) .. " Show critter icons for hidden pet nameplates",
                    desc = "Show a critter icon in place of pet nameplates hidden by the addon\nThis helps with situations such as casting Ring of the Frost on hunter pets, without actually showing all those nameplates to clutter the screen",
                    hidden = function ()
                        return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) and ( not SweepyBoop.db.profile.nameplatesEnemy.hideHunterSecondaryPet );
                    end
                },
                highlightScale = {
                    order = 13,
                    type = "range",
                    name = "Nameplate highlight icon scale (%)",
                    width = 1.5,
                    min = 50,
                    max = 300,
                    step = 1,
                    hidden = function()
                        return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
                    end,
                },

                auraFilterEnabled = {
                    order = 14,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_shadow_shadowwordpain")) .. " Filter debuffs applied by myself",
                    desc = "Show whitelisted debuffs applied by myself"
                        .. "\n\nCrowd control debuffs are never filtered as they are critical for PvP",
                    set = function (info, val)
                        SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
                        SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                        SweepyBoop:RefreshAurasForAllNamePlates();
                    end
                },

                showBuffsOnEnemy = {
                    order = 15,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_holy_divineshield")) .. " Show whitelisted buffs on enemy nameplates",
                    desc = "Show whitelisted buffs on enemy nameplates from all sources",
                    hidden = function ()
                        return ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled );
                    end,
                    set = function (info, val)
                        SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
                        SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                        SweepyBoop:RefreshAurasForAllNamePlates();
                    end
                },
            },
        },

        filterList = {
            order = 2,
            type = "group",
            name = "Unit whitelist",
            get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.filterList[info[#info]] end,
            set = function(info, val)
                SweepyBoop.db.profile.nameplatesEnemy.filterList[info[#info]] = val;
                SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                SweepyBoop:RefreshAllNamePlates();
            end,
            args = {},
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
            end
        },

        debuffWhiteList = {
            order = 3,
            type = "group",
            name = "Debuff whitelist",
            get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.debuffWhiteList[info[#info]] end,
            set = function(info, val)
                SweepyBoop.db.profile.nameplatesEnemy.debuffWhiteList[info[#info]] = val;
                SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                -- No need to refresh nameplates, just apply it on next UNIT_AURA
            end,
            args = {},
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled );
            end
        },

        buffWhiteList = {
            order = 4,
            type = "group",
            name = "Buff whitelist",
            get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.buffWhiteList[info[#info]] end,
            set = function(info, val)
                SweepyBoop.db.profile.nameplatesEnemy.buffWhiteList[info[#info]] = val;
                SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
                -- No need to refresh nameplates, just apply it on next UNIT_AURA
            end,
            args = {},
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled ) or ( not SweepyBoop.db.profile.nameplatesEnemy.showBuffsOnEnemy );
            end
        },
    },
};

addon.AppendNpcOptionsToGroup(options.args.nameplatesEnemy.args.filterList);
addon.AppendAuraOptionsToGroup(options.args.nameplatesEnemy.args.debuffWhiteList, addon.DebuffList, "debuffWhiteList");
addon.AppendAuraOptionsToGroup(options.args.nameplatesEnemy.args.buffWhiteList, addon.BuffList, "buffWhiteList");

if addon.PROJECT_MAINLINE then
    options.args.arenaFrames = {
        order = 5,
        type = "group",
        childGroups = "tab",
        name = "Arena Frames",
        handler = SweepyBoop, -- for running SweepyBoop:TestArena()
        get = function(info) return SweepyBoop.db.profile.arenaFrames[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
            SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
        end,
        args = {
            general = {
                order = 1,
                type = "group",
                name = "General",
                args = {
                    healerIndicator = {
                        order = 1,
                        type = "toggle",
                        name = addon.FORMAT_ATLAS("Icon-Healer") .. " Show healer indicator on arena frames",
                        desc = "To make it easier to identify the healer in case of class stacking",
                        width = "full",
                        hidden = function ()
                            return ( not ( Gladius or sArena ) );
                        end
                    },

                    header1 = {
                        order = 2,
                        type = "header",
                        name = "Arena opponent cooldowns",
                    },

                    testmode = {
                        order = 3,
                        type = "execute",
                        name = "Test",
                        func = "TestArena",
                        width = "half",
                    },
                    hidetest = {
                        order = 4,
                        type = "execute",
                        name = "Hide",
                        func = "HideTestArenaCooldownTracker",
                        width = "half",
                    },
                    tooltipForExtraCharge = {
                        order = 5,
                        type = "description",
                        fontSize = "medium",
                        width = "full",
                        name = addon.FORMAT_ATLAS(addon.CHARGE_TEXTURE, 16) .. " on cooldown icon means there is another charge available",
                    },

                    arenaCooldownTrackerEnabled = {
                        order = 6,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Spell_holy_powerinfusion")) .. " Enabled",
                    },
                    arenaCooldownSeparateRowForDefensive = {
                        order = 7,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Spell_holy_painsupression")) .. " Separate row for defensives",
                    },

                    hideCountDownNumbers = {
                        order = 8,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " Hide countdown numbers",
                        desc = "Hide countdown numbers but show a more visible swiping edge",
                    },

                    arenaCooldownGrowDirection = {
                        order = 9,
                        type = "select",
                        width = 0.75,
                        name = "Grow direction",
                        values = {
                            [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN] = "Right down",
                            [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_UP] = "Right up",
                            [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_DOWN] = "Left down",
                            [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_UP] = "Left up",
                        },
                    },

                    arenaCooldownTrackerIconSize = {
                        order = 10,
                        type = "range",
                        width = 0.75,
                        min = 16,
                        max = 64,
                        step = 1,
                        name = "Icon size",
                        desc = "Size of arena defensive cooldown icons",
                    },

                    newline = {
                        order = 11,
                        type = "description",
                        name = "",
                    },

                    arenaCooldownOffsetX = {
                        order = 12,
                        type = "range",
                        min = -300,
                        max = 300,
                        step = 1,
                        name = "X offset",
                        desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
                        set = function (info, val)
                            SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                            SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                            SweepyBoop:RepositionTestGroup();
                        end
                    },
                    arenaCooldownOffsetY = {
                        order = 13,
                        type = "range",
                        min = -150,
                        max = 150,
                        step = 1,
                        name = "Y offset",
                        desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
                        set = function (info, val)
                            SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                            SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                            SweepyBoop:RepositionTestGroup();
                        end
                    },
                },
            },

            spellList = {
                order = 2,
                type = "group",
                name = "Spells",
                desc = "Select which abilities to track cooldown inside arenas",
                get = function(info) return SweepyBoop.db.profile.arenaFrames.spellList[info[#info]] end,
                set = function(info, val) SweepyBoop.db.profile.arenaFrames.spellList[info[#info]] = val end,
                args = {
                    restoreDefaults = {
                        order = 1,
                        type = "execute",
                        name = "Restore default",
                        func = function ()
                            SweepyBoop:CheckDefaultArenaAbilities();
                        end
                    },
                },
            }
        },
    };

    local indexInClassGroup = {};
    local groupIndex = 3;
    -- Ensure one group for each class, in order
    for _, classID in ipairs(addon.CLASSORDER) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        options.args.arenaFrames.args.spellList.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };

        indexInClassGroup[classInfo.classFile] = 1;
        groupIndex = groupIndex + 1;
    end
    local function AppendSpellOptions(group, spellList)
        for spellID, spellInfo in pairs(spellList) do
            local category = spellInfo.category;
            if ( category ~= addon.SPELLCATEGORY.INTERRUPT ) and ( not spellInfo.parent ) then
                local classFile = spellInfo.class;
                local classGroup = group.args[classFile];
                local icon, name = C_Spell.GetSpellTexture(spellID), C_Spell.GetSpellName(spellID);
                -- https://warcraft.wiki.gg/wiki/SpellMixin
                local spell = Spell:CreateFromSpellID(spellID);
                spell:ContinueOnSpellLoad(function()
                    addon.SPELL_DESCRIPTION[spellID] = spell:GetSpellDescription();
                end)
                classGroup.args[tostring(spellID)] = {
                    order = indexInClassGroup[classFile],
                    type = "toggle",
                    width = "full", -- otherwise the icon might look strange vertically
                    name = addon.FORMAT_TEXTURE(icon) .. " " .. name,
                    desc = function ()
                        return addon.SPELL_DESCRIPTION[spellID] or "";
                    end
                };

                indexInClassGroup[classFile] = indexInClassGroup[classFile] + 1;
            end
        end
    end

    AppendSpellOptions(options.args.arenaFrames.args.spellList, addon.SpellData);

    options.args.raidFrames = {
        order = 6,
        type = "group",
        name = "Raid Frames",
        get = function(info) return SweepyBoop.db.profile.raidFrames[info[#info]] end,
        set = function(info, val) SweepyBoop.db.profile.raidFrames[info[#info]] = val end,
        args = {
            header1 = {
                order = 1,
                type = "header",
                name = "PvP aggro highlight",
            },

            raidFrameAggroHighlightEnabled = {
                order = 2,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_ATLAS("pvptalents-warmode-swords") .. " Enabled",
                desc = "Show an animating dotted line border when a teammate is targeted by enemy players\n\n"
                    .. "The color of the border changes based on the number of enemies targeting the teammate",
            },

            raidFrameAggroHighlightThickness = {
                order = 3,
                type = "range",
                min = 1,
                max = 5,
                step = 1,
                name = "Border thickness",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            raidFrameAggroHighlightAlpha = {
                order = 4,
                type = "range",
                isPercent = true,
                min = 0.5,
                max = 1,
                step = 0.01,
                name = "Border alpha",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            raidFrameAggroHighlightAnimationSpeed = {
                order = 5,
                type = "range",
                width = 1.5,
                min = 0,
                max = 25,
                step = 1,
                name = "Animation speed (0 for no animation)",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            header2 = {
                order = 6,
                type = "header",
                name = "",
            },

            druidHoTHelper = {
                order = 7,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_healingtouch")) .. "Druid HoT helper",
                desc = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_misc_herb_felblossom")) .. " Glow Lifebloom during pandemic window\n\n"
                    .. addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_druid_naturalperfection")) .. " Fade out Cenarion Ward before the healing procs",
            }
        },
    };

    options.args.misc = {
        order = 7,
        type = "group",
        name = "Misc",
        get = function(info) return SweepyBoop.db.profile.misc[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.misc[info[#info]] = val;
            SweepyBoop.db.profile.misc.lastModified = GetTime();
        end,
        handler = SweepyBoop,
        args = {
            header1 = {
                order = 1,
                type = "header",
                name = "Healer in crowd control reminder in arena",
            },
            healerInCrowdControl = {
                order = 2,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_polymorph")) .. " Enabled",
            },
            healerInCrowdControlTest = {
                order = 3,
                type = "execute",
                width = "half",
                name = "Test",
                func = "TestHealerInCrowdControl",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                end
            },
            healerInCrowdControlHide = {
                order = 4,
                type = "execute",
                width = "half",
                name = "Hide",
                func = "HideTestHealerInCrowdControl",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                end
            },
            newline = {
                order = 5,
                type = "description",
                width = "full",
                name = "",
                hidden = function ()
                    return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                end
            },
            healerInCrowdControlSize = {
                order = 6,
                type = "range",
                min = 30,
                max = 200,
                step = 1,
                name = "Icon size",
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:UpdateHealerInCrowdControl();
                end,
                hidden = function ()
                    return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                end
            },
            healerInCrowdControlOffsetX = {
                order = 7,
                type = "range",
                min = -500,
                max = 500,
                step = 1,
                name = "Horizontal offset",
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:UpdateHealerInCrowdControl();
                end,
                hidden = function ()
                    return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                end
            },
            healerInCrowdControlOffsetY = {
                order = 8,
                type = "range",
                min = -500,
                max = 500,
                step = 1,
                name = "Vertical offset",
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:UpdateHealerInCrowdControl();
                end,
                hidden = function ()
                    return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                end
            },

            header2 = {
                order = 10,
                type = "header",
                name = "",
            },
            queueReminder = {
                order = 11,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " PvP Queue Timer",
                desc = "Shows a timer on arena / battlefield queue pop, and plays an alert when it's about to expire",
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop:SetupQueueReminder();
                end
            },

            header3 = {
                order = 12,
                type = "header",
                name = "",
            },
            combatIndicator = {
                order = 13,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_ATLAS("countdown-swords") .. " Show combat indicator on unit frames",
                desc = "Show combat indicator icons on Player / Target / Focus frames",
                set = function(info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:SetupCombatIndicator();
                end,
            },

            header4 = {
                order = 14,
                type = "header",
                name = "Type /afk to surrender arena",
            },
            arenaSurrenderEnabled = {
                order = 15,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_pet_exitbattle")) .. " Enabled",
                desc = "If unable to surrender, by default a confirmation dialog will pop up to confirm leaving arena",
            },
            skipLeaveArenaConfirmation = {
                order = 16,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_druid_cower")) .. " Leave arena directly if unable to surrender (skip confirmation dialog)",
                desc = addon.EXCLAMATION .. " Leaving arena before entering combat might result in deserter status",
                descStyle = "inline",
                hidden = function()
                    return ( not SweepyBoop.db.profile.misc.arenaSurrenderEnabled );
                end,
            },

            header5 = {
                order = 17,
                type = "header",
                name = "",
            },
            showDampenPercentage = {
                order = 18,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_bg_winsoa_underxminutes")) .. " Show dampen percentage on the arena widget",
            },
        },
    };

end

options.args.support = {
    order = 8,
    type = "group",
    name = "Support",
    args = {
        discordLink = {
            order = 1,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("UI-ChatIcon-ODIN") .. " Join Discord for PvP UI support",
            desc = "Press Ctrl+C to copy URL",
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://discord.gg/SMRxeZzVwc";
            end
        },

        donate = {
            order = 2,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("GarrisonTroops-Health") .. " If feeling generous",
            desc = "Press Ctrl+C to copy URL",
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://www.paypal.me/sweepyboop";
            end
        },
    },
}

local defaults = {
    profile = {
        nameplatesFriendly = {
            classIconsEnabled = true,
            classIconStyle = addon.CLASS_ICON_STYLE.ICON,
            showSpecIcons = true,
            hideOutsidePvP = false,
            classIconSize = 1,
            petIconSize = 0.8,
            classIconOffset = 0,
            useHealerIcon = true,
            showHealerOnly = false,
            useFlagCarrierIcon = true,
            targetHighlight = true,
            classColorBorder = true,
            showPlayerName = false,
        },
        nameplatesEnemy = {
            arenaNumbersEnabled = true,
            arenaSpecIconHealer = true,
            arenaSpecIconHealerIcon = true,
            arenaSpecIconOthers = false,
            arenaSpecIconScale = 100,
            arenaSpecIconAlignment = addon.SPEC_ICON_ALIGNMENT.TOP,
            arenaSpecIconVerticalOffset = 0,
            filterEnabled = true,
            showCritterIcons = true,
            auraFilterEnabled = false,
            showBuffsOnEnemy = false,
            highlightScale = 100,
            hideHunterSecondaryPet = true,
            filterList = {},
            debuffWhiteList = {},
            buffWhiteList = {},
        },
        arenaFrames = {
            healerIndicator = true,
            arenaCooldownTrackerEnabled = true,
            arenaCooldownSeparateRowForDefensive = true,
            arenaCooldownGrowDirection = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN,
            arenaCooldownOffsetX = 0,
            arenaCooldownOffsetY = 0,
            arenaCooldownTrackerIconSize = 32,
            hideCountDownNumbers = false,
            spellList = {},
        },
        raidFrames = {
            arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.DISABLED,
            raidFrameAggroHighlightEnabled = true,
            raidFrameAggroHighlightThickness = 2,
            raidFrameAggroHighlightAlpha = 0.5,
            raidFrameAggroHighlightAnimationSpeed = 0,
            druidHoTHelper = true,
        },
        misc = {
            healerInCrowdControl = false,
            healerInCrowdControlSize = 48,
            healerInCrowdControlOffsetX = 0,
            healerInCrowdControlOffsetY = 250,
            queueReminder = true,
            combatIndicator = true,
            arenaSurrenderEnabled = true,
            skipLeaveArenaConfirmation = false,
            showDampenPercentage = true,
        },
        minimap = {
            hide = false,
        },
    }
};

if addon.internal then -- Set default for internal version
    defaults.profile.nameplatesFriendly.classIconStyle = addon.CLASS_ICON_STYLE.ICON_AND_ARROW;
    defaults.profile.nameplatesFriendly.classIconSize = 1.25;
    defaults.profile.nameplatesEnemy.auraFilterEnabled = true;
    defaults.profile.nameplatesEnemy.showBuffsOnEnemy = true;
    defaults.profile.raidFrames.arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.PLAYER_MID;
    defaults.profile.raidFrames.raidFrameAggroHighlightAnimationSpeed = 5;
    defaults.profile.arenaFrames.arenaCooldownOffsetX = 40;
    defaults.profile.arenaFrames.arenaCooldownOffsetY = 8;
    defaults.profile.arenaFrames.hideCountDownNumbers = true;
    defaults.profile.misc.skipLeaveArenaConfirmation = true;
    defaults.profile.misc.healerInCrowdControl = true;
end

addon.FillDefaultToNpcOptions(defaults.profile.nameplatesEnemy.filterList);
addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.debuffWhiteList, addon.DebuffList);
addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.buffWhiteList, addon.BuffList);

local function SetupAllSpells(profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        local category = spellEntry.category;
        -- By default only check burst and defensives
        if ( category == addon.SPELLCATEGORY.BURST ) or ( category == addon.SPELLCATEGORY.DEFENSIVE ) or ( category == addon.SPELLCATEGORY.DISPEL ) then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

if addon.PROJECT_MAINLINE then
    SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.SpellData);
end

function SweepyBoop:OnInitialize()
    local currentTime = GetTime();
    for _, category in pairs(defaults) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    local appName = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 750, 640);
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?

    icon:Register(addonName, SweepyBoopLDB, self.db.profile.minimap);

    -- Print message on first 3 logins with the addon enabled
    if SweepyBoopDB then
        SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 1;
        if ( SweepyBoopDB.slashCommandInvoked <= 3 ) then
            addon.PRINT("Thank you for supporting my addon! Type /sb to bring up the options panel. Have a wonderful PvP journey :)");
        end
    end

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Nameplate module needs optimization to eat less CPU
    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Only nameplate modules for Classic currently
    if ( not addon.PROJECT_MAINLINE ) then return end

    self:SetupArenaCooldownTracker();

    self:SetupHealerIndicator();

    -- Setup raid frame modules
    self:SetupRaidFrameAggroHighlight();
    self:SetupRaidFrameAuraModule();

    self:SetupQueueReminder();

    self:SetupCombatIndicator();
end

function SweepyBoop:TestArena()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    if GladiusEx then
        local frame = _G["GladiusExButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            GladiusEx:SetTesting(3);
        end
    elseif Gladius then
        local frame = _G["GladiusButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            if SlashCmdList["GLADIUS"] then
                SlashCmdList["GLADIUS"]("test 3")
            end
        end
    elseif sArena then
        local frame = _G["sArenaEnemyFrame1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            sArena:Test();
        end
    else
        -- Use Blizzard arena frames
        if ( not CompactArenaFrame:IsShown() ) then
            CompactArenaFrame:Show();
            for i = 1, addon.MAX_ARENA_SIZE do
                _G["CompactArenaFrameMember" .. i]:Show();
            end
        end
    end

    self:TestArenaCooldownTracker();
end

function SweepyBoop:RefreshConfig()
    if addon.PROJECT_MAINLINE then
        self:HideTestArenaCooldownTracker();

        self:SetupCombatIndicator();
    end

    local currentTime = GetTime();
    for _, category in pairs(self.db.profile) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self:RefreshAllNamePlates(true);
end

function SweepyBoop:CheckDefaultArenaAbilities()
    SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.SpellData);
end

SLASH_SweepyBoop1 = "/sb"
SlashCmdList.SweepyBoop = function(msg)
    -- This opens the in-game options panel that is not moveable or resizable
    -- if Settings and Settings.OpenToCategory then
    --     Settings.OpenToCategory(SweepyBoop.categoryID);
    -- end
    LibStub("AceConfigDialog-3.0"):Open(addonName);
    if SweepyBoopDB then
        SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 0;
        if ( SweepyBoopDB.slashCommandInvoked <= 3 ) then
            SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked + 1;
        end
    end
end
