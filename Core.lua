local addonName, addon = ...;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");
local SweepyBoopLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName,
	icon = addon.INTERFACE_SWEEPY .. "Art/Logo",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(addon.addonTitle, 1, 1, 1);
        tooltip:AddLine("Click to open options");
    end,
	OnClick = function()
        LibStub("AceConfigDialog-3.0"):Open(addonName);
        if SweepyBoopDB then
            SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 0;
            if ( SweepyBoopDB.slashCommandInvoked <= 3 ) then
                SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked + 1;
            end
        end
    end,
})
local icon = LibStub("LibDBIcon-1.0");

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

if addon.PROJECT_MAINLINE then
    options.args.arenaFrames = {
        order = 5,
        type = "group",
        childGroups = "tab",
        name = "Arena cooldowns",
        handler = SweepyBoop, -- for running SweepyBoop:TestArena()
        get = function(info) return SweepyBoop.db.profile.arenaFrames[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
            SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
        end,
        args = {
            individual = {
                order = 1,
                type = "group",
                childGroups = "tab",
                name = "Arena frames",
                args = {
                    testmode = {
                        order = 1,
                        type = "execute",
                        name = "Test",
                        func = "TestArena",
                        width = "half",
                    },
                    hidetest = {
                        order = 2,
                        type = "execute",
                        name = "Hide",
                        func = "HideTestArenaCooldownTracker",
                        width = "half",
                    },
                    tooltipForExtraCharge = {
                        order = 3,
                        type = "description",
                        fontSize = "medium",
                        width = "full",
                        name = addon.FORMAT_ATLAS(addon.CHARGE_TEXTURE, 16) .. " on cooldown icon means there is another charge available",
                    },

                    general = {
                        order = 4,
                        type = "group",
                        childGroups = "tab",
                        name = "Settings",
                        args = {
                            arenaCooldownTrackerEnabled = {
                                order = 6,
                                width = "full",
                                type = "toggle",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Spell_holy_powerinfusion")) .. " Enabled",
                            },
                            arenaCooldownSecondaryBar = {
                                order = 7,
                                width = "full",
                                type = "toggle",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Spell_holy_painsupression")) .. " Enable secondary bar",
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownTrackerEnabled );
                                end
                            },

                            hideCountDownNumbers = {
                                order = 8,
                                type = "toggle",
                                width = "full",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " Hide countdown numbers",
                                desc = "Hide countdown numbers but show a more visible swiping edge",
                            },

                            showUnusedIcons = {
                                order = 9,
                                type = "toggle",
                                width = "full",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_deathknight_iceboundfortitude")) .. " Always show icons",
                                desc = "Show icons for abilities that are not on cooldown\nAbilities that are not baseline will only show after they are detected",
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

                            unusedIconAlpha = {
                                order = 11,
                                type = "range",
                                width = 0.8,
                                isPercent = true,
                                min = 0.5,
                                max = 1,
                                step = 0.1,
                                name = "Off-cooldown alpha",
                                hidden = function ()
                                    return ( not SweepyBoop.db.profile.arenaFrames.showUnusedIcons );
                                end
                            },

                            usedIconAlpha = {
                                order = 12,
                                type = "range",
                                width = 0.8,
                                isPercent = true,
                                min = 0.5,
                                max = 1,
                                step = 0.1,
                                name = "On-cooldown alpha",
                                hidden = function ()
                                    return ( not SweepyBoop.db.profile.arenaFrames.showUnusedIcons );
                                end
                            },

                            headerPosition = {
                                order = 13,
                                type = "header",
                                name = "Positioning",
                            },

                            arenaCooldownGrowDirection = {
                                order = 14,
                                type = "select",
                                width = 0.75,
                                name = "Grow direction",
                                values = {
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN] = "Right",
                                    --[addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_UP] = "Right up",
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_DOWN] = "Left",
                                    --[addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_UP] = "Left up",
                                },
                            },

                            arenaCooldownOffsetX = {
                                order = 15,
                                type = "range",
                                min = -300,
                                max = 300,
                                step = 1,
                                name = "X offset",
                                desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end
                            },
                            arenaCooldownOffsetY = {
                                order = 16,
                                type = "range",
                                width = 0.8,
                                min = -150,
                                max = 150,
                                step = 1,
                                name = "Y offset",
                                desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end
                            },

                            headerPosition2 = {
                                order = 17,
                                type = "header",
                                name = "Secondary bar positioning",
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },

                            arenaCooldownGrowDirectionSecondary = {
                                order = 18,
                                type = "select",
                                width = 0.75,
                                name = "Grow direction",
                                values = {
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN] = "Right",
                                    --[addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_UP] = "Right up",
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_DOWN] = "Left",
                                    --[addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_UP] = "Left up",
                                },
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },

                            arenaCooldownOffsetXSecondary = {
                                order = 19,
                                type = "range",
                                min = -300,
                                max = 300,
                                step = 1,
                                name = "X offset",
                                desc = "Horizontal offset of the arena cooldown defensive group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end,
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },
                            arenaCooldownOffsetYSecondary = {
                                order = 20,
                                type = "range",
                                width = 0.8,
                                min = -150,
                                max = 150,
                                step = 1,
                                name = "Y offset",
                                desc = "Vertical offset of the arena cooldown defensive group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end,
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },
                        },
                    },

                    spellCatPriority = {
                        order = 5,
                        type = "group",
                        name = "Priority",
                        args = {}, -- Fill this programatically later
                    },

                    spellList = {
                        order = 6,
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
                    },

                    spellList2 = {
                        order = 7,
                        type = "group",
                        name = "Secondary bar spells",
                        desc = "Select which abilities to track cooldown inside arenas",
                        get = function(info) return SweepyBoop.db.profile.arenaFrames.spellList2[info[#info]] end,
                        set = function(info, val) SweepyBoop.db.profile.arenaFrames.spellList2[info[#info]] = val end,
                        args = {
                            restoreDefaults = {
                                order = 1,
                                type = "execute",
                                name = "Uncheck all",
                                func = function ()
                                    SweepyBoop:UncheckAllArenaAbilities();
                                end
                            },
                        },
                        hidden = function()
                            return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                        end
                    }
                },
            },

            interrupts = {
                order = 2,
                type = "group",
                childGroups = "tab",
                name = "Interrupt bar",
                args = {
                    testmode = {
                        order = 1,
                        type = "execute",
                        name = "Test",
                        func = "TestArenaInterrupt",
                        width = "half",
                    },
                    hidetest = {
                        order = 2,
                        type = "execute",
                        name = "Hide",
                        func = "HideTestArenaInterruptBar",
                        width = "half",
                    },

                    general = {
                        order = 4,
                        type = "group",
                        childGroups = "tab",
                        name = "Settings",
                        args = {
                            interruptBarEnabled = {
                                order = 6,
                                width = "full",
                                type = "toggle",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_frost_iceshock")) .. " Enabled",
                            },
                            separateRowForInterrupts = {
                                order = 7,
                                width = "full",
                                type = "toggle",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_groundingtotem")) .. " Separate rows for interrupts and other abilities",
                            },

                            interruptBarShowUnused = {
                                order = 8,
                                type = "toggle",
                                width = "full",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_kick")) .. " Always show icons",
                                desc = "Show icons for abilities that are not on cooldown\nAbilities that are not baseline will only show after they are detected",
                            },

                            interruptBarHideCountDownNumbers = {
                                order = 9,
                                type = "toggle",
                                width = "full",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " Hide countdown numbers",
                                desc = "Hide countdown numbers but show a more visible swiping edge",
                            },

                            interruptBarGrowDirection = {
                                order = 10,
                                type = "select",
                                width = 0.75,
                                name = "Grow direction",
                                values = {
                                    [addon.INTERRUPT_GROW_DIRECTION.CENTER_UP] = "Up",
                                    [addon.INTERRUPT_GROW_DIRECTION.CENTER_DOWN] = "Down",
                                },
                            },

                            interruptBarIconSize = {
                                order = 11,
                                type = "range",
                                width = 0.75,
                                min = 16,
                                max = 64,
                                step = 1,
                                name = "Icon size",
                                desc = "Size of arena defensive cooldown icons",
                            },

                            newline = {
                                order = 12,
                                type = "description",
                                name = "",
                            },

                            interruptBarOffsetX = {
                                order = 13,
                                type = "range",
                                min = -2500,
                                max = 2500,
                                step = 1,
                                name = "X offset",
                                desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaInterruptBar();
                                end
                            },
                            interruptBarOffsetY = {
                                order = 14,
                                type = "range",
                                min = -1500,
                                max = 1500,
                                step = 1,
                                name = "Y offset",
                                desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaInterruptBar();
                                end
                            },
                            interruptBarUnusedIconAlpha = {
                                order = 15,
                                type = "range",
                                isPercent = true,
                                min = 0.5,
                                max = 1,
                                step = 0.1,
                                name = "Off-cooldown alpha",
                                hidden = function ()
                                    return ( not SweepyBoop.db.profile.arenaFrames.interruptBarShowUnused );
                                end
                            },
                            interruptBarUsedIconAlpha = {
                                order = 16,
                                type = "range",
                                isPercent = true,
                                min = 0.5,
                                max = 1,
                                step = 0.1,
                                name = "On-cooldown alpha",
                                hidden = function ()
                                    return ( not SweepyBoop.db.profile.arenaFrames.interruptBarShowUnused );
                                end
                            },
                        },
                    },

                    interruptBarSpellList = {
                        order = 5,
                        type = "group",
                        name = "Spells",
                        desc = "Select which abilities to track cooldown inside arenas",
                        get = function(info) return SweepyBoop.db.profile.arenaFrames.interruptBarSpellList[info[#info]] end,
                        set = function(info, val) SweepyBoop.db.profile.arenaFrames.interruptBarSpellList[info[#info]] = val end,
                        args = {
                            restoreDefaults = {
                                order = 1,
                                type = "execute",
                                name = "Restore default",
                                func = function ()
                                    SweepyBoop:CheckDefaultInterrupts();
                                end
                            },
                        },
                    }
                },
            }
        },
    };

    local indexInClassGroup = {};
    local groupIndex = 3;
    -- Ensure one group for each class, in order
    for _, classID in ipairs(addon.CLASSORDER) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        options.args.arenaFrames.args.individual.args.spellList.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };
        options.args.arenaFrames.args.individual.args.spellList2.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };
        options.args.arenaFrames.args.interrupts.args.interruptBarSpellList.args[classInfo.classFile] = {
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
    local function AppendSpellOptions(group, spellList, excludeCategory)
        for spellID, spellInfo in pairs(spellList) do
            local category = spellInfo.category;
            if ( category ~= excludeCategory ) and ( not spellInfo.parent ) then
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

    local function AppendSpellCategoryPriority(group)
        for i = 1, 12 do -- Can we not hard-code this
            group[tostring(i)] = {
                order = i,
                type = "range",
                name = addon.SPELLCATEGORY_NAME[i],
                min = 1,
                max = 100,
                step = 1,
                get = function(info)
                    return SweepyBoop.db.profile.arenaFrames.spellCatPriority[tostring(i)];
                end,
                set = function(info, val)
                    SweepyBoop.db.profile.arenaFrames.spellCatPriority[tostring(i)] = val;
                end,
            }
        end
    end

    AppendSpellOptions(options.args.arenaFrames.args.individual.args.spellList, addon.SpellData, addon.SPELLCATEGORY.INTERRUPT);
    AppendSpellOptions(options.args.arenaFrames.args.individual.args.spellList2, addon.SpellData, addon.SPELLCATEGORY.INTERRUPT);
    AppendSpellOptions(options.args.arenaFrames.args.interrupts.args.interruptBarSpellList, addon.SpellData, addon.SPELLCATEGORY.BURST);
    AppendSpellCategoryPriority(options.args.arenaFrames.args.individual.args.spellCatPriority.args);

    options.args.raidFrames = {
        order = 6,
        type = "group",
        name = "Raid frames",
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
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:SetupHealerInCrowdControl();
                end
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

            header6 = {
                order = 19,
                type = "header",
                name = "",
            },

            showMinimapIcon = {
                order = 20,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Logo") .. " Show minimap icon for invoking options UI",
                set = function(info, val)
                    SweepyBoop.db.profile.minimap.hide = ( not val );
                    if val then
                        icon:Show(addonName);
                    else
                        icon:Hide(addonName);
                    end
                end,
                get = function (info)
                    return ( not SweepyBoop.db.profile.minimap.hide );
                end
            }
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
            hideInBattlegrounds = false;
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
            arenaCooldownSecondaryBar = false,

            arenaCooldownGrowDirection = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN,
            arenaCooldownOffsetX = 0,
            arenaCooldownOffsetY = 0,

            arenaCooldownGrowDirectionSecondary = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN,
            arenaCooldownOffsetXSecondary = 0,
            arenaCooldownOffsetYSecondary = -35,

            arenaCooldownTrackerIconSize = 32,
            unusedIconAlpha = 0.5,
            usedIconAlpha = 1,
            showUnusedIcons = false,
            hideCountDownNumbers = false,
            spellList = {},
            spellList2 = {},

            interruptBarEnabled = false;
            interruptBarGrowDirection = addon.INTERRUPT_GROW_DIRECTION.CENTER_UP,
            interruptBarOffsetX = 0,
            interruptBarOffsetY = -150,
            interruptBarIconSize = 40,
            interruptBarUnusedIconAlpha = 0.5,
            interruptBarUsedIconAlpha = 1,
            interruptBarShowUnused = false,
            interruptBarHideCountDownNumbers = false,
            interruptBarSpellList = {},

            spellCatPriority = {
                [tostring(addon.SPELLCATEGORY.IMMUNITY)] = 100,
                [tostring(addon.SPELLCATEGORY.DEFENSIVE)] = 90,
                [tostring(addon.SPELLCATEGORY.DISPEL)] = 50,
                [tostring(addon.SPELLCATEGORY.MASS_DISPEL)] = 55,
                [tostring(addon.SPELLCATEGORY.INTERRUPT)] = 50,
                [tostring(addon.SPELLCATEGORY.STUN)] = 90,
                [tostring(addon.SPELLCATEGORY.SILENCE)] = 80,
                [tostring(addon.SPELLCATEGORY.KNOCKBACK)] = 30,
                [tostring(addon.SPELLCATEGORY.CROWDCONTROL)] = 70,
                [tostring(addon.SPELLCATEGORY.BURST)] = 90,
                [tostring(addon.SPELLCATEGORY.HEAL)] = 80,
                [tostring(addon.SPELLCATEGORY.OTHERS)] = 10,
            },
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
    defaults.profile.nameplatesFriendly.petIconSize = 1;
    defaults.profile.nameplatesFriendly.showCrowdControl = true;
    defaults.profile.nameplatesEnemy.auraFilterEnabled = true;
    defaults.profile.nameplatesEnemy.showBuffsOnEnemy = true;
    defaults.profile.raidFrames.arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.PLAYER_MID;
    defaults.profile.raidFrames.raidFrameAggroHighlightAnimationSpeed = 5;
    defaults.profile.arenaFrames.arenaCooldownTrackerIconSize = 28;
    defaults.profile.arenaFrames.arenaCooldownOffsetX = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetY = 15;
    defaults.profile.arenaFrames.arenaCooldownOffsetXSecondary = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetYSecondary = -25;
    defaults.profile.arenaFrames.showUnusedIcons = true;
    defaults.profile.arenaFrames.unusedIconAlpha = 1;
    defaults.profile.arenaFrames.usedIconAlpha = 0.5;
    defaults.profile.arenaFrames.interruptBarEnabled = true;
    defaults.profile.arenaFrames.interruptBarShowUnused = true;
    defaults.profile.arenaFrames.interruptBarUnusedIconAlpha = 1;
    defaults.profile.arenaFrames.interruptBarUsedIconAlpha = 0.5;
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
        if ( category == addon.SPELLCATEGORY.BURST ) or ( category == addon.SPELLCATEGORY.DEFENSIVE ) or ( category == addon.SPELLCATEGORY.IMMUNITY ) or ( category == addon.SPELLCATEGORY.HEAL ) then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

local function UncheckAllSpells(profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        profile[tostring(spellID)] = false;
    end
end

local function SetupInterrupts(profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        local category = spellEntry.category;
        -- By default only check interrupts
        if ( category == addon.SPELLCATEGORY.INTERRUPT ) then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

if addon.PROJECT_MAINLINE then
    SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.SpellData);
    SetupInterrupts(defaults.profile.arenaFrames.interruptBarSpellList, addon.SpellData);
end

function SweepyBoop:OnInitialize()
    options.args.nameplatesFriendly = addon.GetFriendlyNameplateOptions(3);
    options.args.nameplatesEnemy = addon.GetEnemyNameplateOptions(4);

    local currentTime = GetTime();
    for _, category in pairs(defaults) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 750, 640);
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?

    icon:Register(addonName, SweepyBoopLDB, self.db.profile.minimap);

    -- Print message on first 3 logins with the addon enabled
    if SweepyBoopDB then
        SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 1;
        if ( SweepyBoopDB.slashCommandInvoked <= 1 ) then
            addon.PRINT("Thank you for supporting my addon! Type /sb or click the minimap icon to bring up the options panel. Have a wonderful PvP journey :)");
        end
    end

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Nameplate module needs optimization to eat less CPU
    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Only nameplate modules for Classic currently
    -- If only enabling nameplates, 7 ms / Sec CPU, otherwise 11 ms / Sec CPU
    if ( not addon.PROJECT_MAINLINE ) then return end

    self:SetupArenaCooldownTracker();

    self:SetupHealerIndicator();

    -- Setup raid frame modules
    self:SetupRaidFrameAggroHighlight();
    self:SetupRaidFrameAuraModule();

    self:SetupQueueReminder();

    self:SetupCombatIndicator();

    self:SetupHealerInCrowdControl();
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

function SweepyBoop:TestArenaInterrupt()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    self:TestArenaInterruptBar();
end

function SweepyBoop:RefreshConfig()
    if addon.PROJECT_MAINLINE then
        self:HideTestArenaCooldownTracker();
        self:HideTestArenaInterruptBar();

        self:SetupCombatIndicator();
        self:HideTestHealerInCrowdControl();
    end

    local currentTime = GetTime();
    for _, category in pairs(self.db.profile) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self:RefreshAllNamePlates(true);

    if self.db.profile.minimap.hide then
        icon:Hide(addonName);
    else
        icon:Show(addonName);
    end
end

function SweepyBoop:CheckDefaultArenaAbilities()
    SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.SpellData);
end

function SweepyBoop:UncheckAllArenaAbilities()
    UncheckAllSpells(SweepyBoop.db.profile.arenaFrames.spellList2, addon.SpellData);
end

function SweepyBoop:CheckDefaultInterrupts()
    SetupInterrupts(SweepyBoop.db.profile.arenaFrames.interruptBarSpellList, addon.SpellData);
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
