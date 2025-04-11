local _, addon = ...;

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

addon.GetArenaFrameOptions = function(order)
    local optionGroup = {
        order = order,
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
            arenaFrameBars = {
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

                            arenaCooldownTrackerIconPadding = {
                                order = 11,
                                type = "range",
                                width = 0.75,
                                min = 0,
                                max = 10,
                                step = 1,
                                name = "Padding",
                                desc = "Space between icons",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker(true);
                                end
                            },

                            newline = {
                                order = 12,
                                type = "description",
                                name = "",
                            },

                            unusedIconAlpha = {
                                order = 13,
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
                                order = 14,
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
                                order = 15,
                                type = "header",
                                name = "Positioning",
                            },

                            arenaCooldownGrowDirection = {
                                order = 16,
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
                                order = 17,
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
                                order = 18,
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
                                order = 19,
                                type = "header",
                                name = "Secondary bar positioning",
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },

                            arenaCooldownGrowDirectionSecondary = {
                                order = 20,
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
                                order = 21,
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
                                order = 22,
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

            standaloneBars = {
                order = 2,
                type = "group",
                childGroups = "tab",
                name = "Standalone bars",
                args = {
                    testmode = {
                        order = 1,
                        type = "execute",
                        name = "Test all",
                        width = "half",
                    },
                    hidetest = {
                        order = 2,
                        type = "execute",
                        name = "Hide all",
                        width = "half",
                    },
                },
            },
        },
    };

    -- Append options for standalone bars
    for i = 1, 6 do
        local groupName = "Bar " .. i;
        optionGroup.args.standaloneBars.args[groupName] = {
            order = i,
            type = "group",
            childGroups = "tab",
            name = function(info)
                return SweepyBoop.db.profile.arenaFrames.standaloneBars[info[#info]].name;
            end,
            args = {
                general = {
                    order = 1,
                    type = "group",
                    name = "Settings",
                    args = {
                        name = {
                            order = 1,
                            type = "input",
                            name = "Name",
                        },
        
                        enabled = {
                            order = 2,
                            type = "toggle",
                            name = "Enabled",
                        },
        
                        -- Do we need grow direction here
        
                        iconSize = {
                            order = 4,
                            type = "range",
                            min = 16,
                            max = 64,
                            step = 1,
                            name = "Icon size",
                        },
        
                        iconPadding = {
                            order = 5,
                            type = "range",
                            min = 0,
                            max = 10,
                            step = 1,
                            name = "Padding",
                        },
        
                        offsetX = {
                            order = 6,
                            type = "range",
                            min = -2500,
                            max = 2500,
                            step = 1,
                            name = "X offset",
                        },
        
                        offsetY = {
                            order = 7,
                            type = "range",
                            min = -1500,
                            max = 1500,
                            step = 1,
                            name = "Y offset",
                        },
        
                        showUnusedIcons = {
                            order = 8,
                            type = "toggle",
                            name = "Always show icons",
                            desc = "Show icons for abilities that are not on cooldown\nAbilities that are not baseline will only show after they are detected",
                        },
        
                        unusedIconAlpha = {
                            order = 9,
                            type = "range",
                            width = 0.8,
                            isPercent = true,
                            min = 0.5,
                            max = 1,
                            step = 0.1,
                            name = "Off-cooldown alpha",
                        },
        
                        usedIconAlpha = {
                            order = 10,
                            type = "range",
                            width = 0.8,
                            isPercent = true,
                            min = 0.5,
                            max = 1,
                            step = 0.1,
                            name = "On-cooldown alpha",
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
                },
            },
        };
    end

    local indexInClassGroup = {};
    local groupIndex = 3;
    -- Ensure one group for each class, in order
    for _, classID in ipairs(addon.CLASSORDER) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        optionGroup.args.arenaFrameBars.args.spellList.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };
        optionGroup.args.arenaFrameBars.args.spellList2.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };
        for i = 1, 6 do
            local groupName = "Bar " .. i;
            optionGroup.args.standaloneBars.args[groupName].args.spellList.args[classInfo.classFile] = {
                order = groupIndex,
                type = "group",
                icon = addon.ICON_ID_CLASSES,
                iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
                name = classInfo.className,
                args = {},
            };
        end

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

    AppendSpellOptions(optionGroup.args.arenaFrameBars.args.spellList, addon.SpellData, addon.SPELLCATEGORY.INTERRUPT);
    AppendSpellOptions(optionGroup.args.arenaFrameBars.args.spellList2, addon.SpellData, addon.SPELLCATEGORY.INTERRUPT);
    AppendSpellCategoryPriority(optionGroup.args.arenaFrameBars.args.spellCatPriority.args);

    for i = 1, 6 do
        local groupName = "Bar " .. i;
        AppendSpellOptions(optionGroup.args.standaloneBars.args[groupName].args.spellList, addon.SpellData, addon.SPELLCATEGORY.BURST);
    end

    return optionGroup;
end
