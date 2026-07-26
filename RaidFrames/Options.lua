local _, addon = ...;

-- Inline a spell's in-game icon for tooltips (empty string if the texture isn't available yet).
local function SpellIcon(spellId)
    local icon = addon.GetSpellTexture(spellId);
    return icon and addon.FORMAT_TEXTURE(icon) or "";
end

local function SetRaidFrameOptionAndRefresh(info, val, refreshFunc)
    local raidFrames = SweepyBoop.db.profile.raidFrames;
    raidFrames[info[#info]] = val;
    raidFrames.lastModified = GetTime();
    refreshFunc();
end

local function DebuffIconOptionsDisabled()
    return addon.IsConflictingRaidFrameDebuffAddonLoaded() or ( not SweepyBoop.db.profile.raidFrames.raidFrameDebuffIconsEnabled );
end

local function HealerBuffHelperLayoutDisabled()
    if addon.IsConflictingHealerBuffHelperAddonLoaded() then return true end

    local raidFrames = SweepyBoop.db.profile.raidFrames;
    return ( not raidFrames.druidBuffHelper ) and ( not raidFrames.evokerBuffHelper );
end

local function HealerBuffHelperConflictDesc()
    if addon.IsConflictingHealerBuffHelperAddonLoaded() then
        return "Disabled while RaidFrameAuras is loaded to avoid conflicting raid-frame buff indicators.";
    end
end

local function AggroHighlightTestDisabled()
    local raidFrames = SweepyBoop.db.profile.raidFrames;
    return ( not raidFrames.raidFrameAggroHighlightRaidFramesEnabled ) and ( not raidFrames.raidFrameAggroHighlightArenaFramesEnabled );
end

local function SetAggroHighlightOptionAndRefresh(info, val)
    SetRaidFrameOptionAndRefresh(info, val, function ()
        SweepyBoop:RefreshRaidFrameAggroHighlight();
    end);
end

local function BuildAggroHighlightLayoutOptions(args, orderOffset, keyPrefix, sectionName, enabledName, enabledDesc)
    local function LayoutDisabled()
        return not SweepyBoop.db.profile.raidFrames[keyPrefix .. "Enabled"];
    end

    args[keyPrefix .. "Header"] = {
        order = orderOffset,
        type = "header",
        name = sectionName,
    };

    args[keyPrefix .. "Enabled"] = {
            order = orderOffset + 1,
            width = "full",
            type = "toggle",
            name = enabledName,
            desc = enabledDesc,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "Anchor"] = {
            order = orderOffset + 2,
            width = "normal",
            type = "select",
            name = "Anchor",
            desc = "Point on the indicator group used for positioning and first-icon placement.",
            values = {
                TOPLEFT = "TOPLEFT",
                TOP = "TOP",
                TOPRIGHT = "TOPRIGHT",
                LEFT = "LEFT",
                CENTER = "CENTER",
                RIGHT = "RIGHT",
                BOTTOMLEFT = "BOTTOMLEFT",
                BOTTOM = "BOTTOM",
                BOTTOMRIGHT = "BOTTOMRIGHT",
            },
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "RelativePoint"] = {
            order = orderOffset + 3,
            width = "normal",
            type = "select",
            name = "Relative To",
            desc = "Point on the Blizzard frame that the indicator group attaches to.",
            values = {
                TOPLEFT = "TOPLEFT",
                TOP = "TOP",
                TOPRIGHT = "TOPRIGHT",
                LEFT = "LEFT",
                CENTER = "CENTER",
                RIGHT = "RIGHT",
                BOTTOMLEFT = "BOTTOMLEFT",
                BOTTOM = "BOTTOM",
                BOTTOMRIGHT = "BOTTOMRIGHT",
            },
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "GrowDirection"] = {
            order = orderOffset + 4,
            width = "normal",
            type = "select",
            name = "Grow Direction",
            desc = "Direction additional target indicators grow from the first indicator. Centered modes place the full indicator group on the configured relative point.",
            values = {
                RIGHT = "RIGHT",
                LEFT = "LEFT",
                UP = "UP",
                DOWN = "DOWN",
                CENTER_HORIZONTAL = "CENTER_HORIZONTAL",
                CENTER_VERTICAL = "CENTER_VERTICAL",
            },
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "LayoutBreak"] = {
            order = orderOffset + 5,
            type = "description",
            name = "",
            width = "full",
        };

    args[keyPrefix .. "Size"] = {
            order = orderOffset + 6,
            width = "normal",
            type = "range",
            min = 8,
            max = 32,
            step = 1,
            name = "Size",
            desc = "Indicator size in pixels.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "Spacing"] = {
            order = orderOffset + 7,
            width = "normal",
            type = "range",
            min = 0,
            max = 12,
            step = 1,
            name = "Spacing",
            desc = "Spacing between multiple indicators.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "OffsetX"] = {
            order = orderOffset + 8,
            width = "normal",
            type = "range",
            min = -80,
            max = 80,
            step = 1,
            name = "Offset X",
            desc = "Horizontal offset from the selected frame point.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "OffsetY"] = {
            order = orderOffset + 9,
            width = "normal",
            type = "range",
            min = -80,
            max = 80,
            step = 1,
            name = "Offset Y",
            desc = "Vertical offset from the selected frame point.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "Alpha"] = {
            order = orderOffset + 10,
            width = "normal",
            type = "range",
            isPercent = true,
            min = 0.2,
            max = 1,
            step = 0.05,
            name = "Alpha",
            desc = "Opacity of the target indicators.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };
end

addon.GetRaidFrameOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        childGroups = "tab",
        name = "Raid frames",
        get = function(info) return SweepyBoop.db.profile.raidFrames[info[#info]] end,
        set = function(info, val) SweepyBoop.db.profile.raidFrames[info[#info]] = val end,
        args = {
            general = {
                order = 1,
                type = "group",
                name = "General",
                args = {
                    arenaRaidFrameSortHeader = {
                        order = 1,
                        type = "header",
                        name = "Arena party sorting",
                    },

                    arenaRaidFrameSortOrder = {
                        order = 2,
                        type = "select",
                        width = 1.4,
                        name = "Sort order",
                        desc = function()
                            if addon.IsConflictingFrameSortAddonLoaded() then
                                return "Disabled while another frame-sorting addon is loaded to avoid conflicting Blizzard compact frame movement.";
                            end

                            return "Sort Blizzard compact party frames in arenas.";
                        end,
                        disabled = addon.IsConflictingFrameSortAddonLoaded,
                        values = {
                            [addon.RAID_FRAME_SORT_ORDER.DISABLED] = "Disabled",
                            [addon.RAID_FRAME_SORT_ORDER.PLAYER_TOP] = "Player on top",
                            [addon.RAID_FRAME_SORT_ORDER.PLAYER_MID] = "Player in middle",
                            [addon.RAID_FRAME_SORT_ORDER.PLAYER_BOTTOM] = "Player on bottom",
                        },
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshArenaRaidFrameSort();
                        end,
                    },

                    header2 = {
                        order = 5,
                        type = "header",
                        name = "Healer Buff Helper",
                    },

                    healerBuffHelperScale = {
                        order = 6,
                        width = 0.8,
                        type = "range",
                        isPercent = true,
                        min = 0.5,
                        max = 2.5,
                        step = 0.05,
                        name = "Icon Scale",
                        desc = function()
                            return HealerBuffHelperConflictDesc() or "Adjust all helper icons together from 50% to 250%.";
                        end,
                        disabled = HealerBuffHelperLayoutDisabled,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper(); -- repaint frames so the new scale applies immediately
                        end,
                    },

                    healerBuffHelperOffsetX = {
                        order = 6.1,
                        width = 0.8,
                        type = "range",
                        min = -80,
                        max = 80,
                        step = 1,
                        name = "Offset X",
                        desc = function()
                            return HealerBuffHelperConflictDesc() or "Horizontal offset from the helper's default position.";
                        end,
                        disabled = HealerBuffHelperLayoutDisabled,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper();
                        end,
                    },

                    healerBuffHelperOffsetY = {
                        order = 6.2,
                        width = 0.8,
                        type = "range",
                        min = -80,
                        max = 80,
                        step = 1,
                        name = "Offset Y",
                        desc = function()
                            return HealerBuffHelperConflictDesc() or "Vertical offset from the helper's default position.";
                        end,
                        disabled = HealerBuffHelperLayoutDisabled,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper();
                        end,
                    },

                    healerBuffHelperOffsetBreak = {
                        order = 7,
                        type = "description",
                        name = "",
                        width = "full",
                    },

                    druidBuffHelper = {
                        order = 8,
                        width = "normal",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_healingtouch")) .. "Resto Druid",
                        desc = function ()
                            local conflictDesc = HealerBuffHelperConflictDesc();
                            if conflictDesc then return conflictDesc end

                            return table.concat({
                                addon.L["Enable the helper while playing Restoration Druid."],
                                "",
                                "\226\128\162 " .. SpellIcon(1126) .. " " .. addon.L["Mark of the Wild warning."],
                                "\226\128\162 " .. SpellIcon(33763) .. " " .. addon.L["Lifebloom with refresh-window glow."],
                                "\226\128\162 " .. addon.L["Row 2: Regrowth, Wild Growth, Rejuvenation, Germination."],
                                "\226\128\162 " .. addon.L["Hides ALL raid-frame buffs while active; debuffs and dispellable debuffs are unaffected."],
                            }, "\n");
                        end,
                        disabled = addon.IsConflictingHealerBuffHelperAddonLoaded,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper(); -- re-apply the buff-hiding CVar + repaint frames
                        end,
                    },

                    druidBuffHelperWarning = {
                        order = 9,
                        width = 1.4,
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") .. "Missing-buff warning",
                        desc = function()
                            return HealerBuffHelperConflictDesc() or "For Restoration Druid only: show the warning icon when none of the Swiftmend-consumable buffs are active.";
                        end,
                        disabled = function () return addon.IsConflictingHealerBuffHelperAddonLoaded() or ( not SweepyBoop.db.profile.raidFrames.druidBuffHelper ); end,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper(); -- repaint frames so the warning icon appears/disappears immediately
                        end,
                    },

                    druidBuffHelperBreak = {
                        order = 10,
                        type = "description",
                        name = "",
                        width = "full",
                    },

                    evokerBuffHelper = {
                        order = 11,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Classicon_evoker")) .. "Preservation Evoker",
                        desc = function ()
                            local conflictDesc = HealerBuffHelperConflictDesc();
                            if conflictDesc then return conflictDesc end

                            return table.concat({
                                addon.L["Enable the helper while playing Preservation Evoker."],
                                "",
                                "\226\128\162 " .. SpellIcon(381748) .. " " .. addon.L["Blessing of the Bronze warning."],
                                "\226\128\162 " .. SpellIcon(364343) .. " " .. addon.L["Echo without a refresh-window glow."],
                                "\226\128\162 " .. addon.L["Row 2, least-to-most important: Reversion, Dream Breath, Lifebind, Time Dilation."],
                                "\226\128\162 " .. addon.L["Hides ALL raid-frame buffs while active; debuffs and dispellable debuffs are unaffected."],
                            }, "\n");
                        end,
                        disabled = addon.IsConflictingHealerBuffHelperAddonLoaded,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper(); -- re-apply the buff-hiding CVar + repaint frames
                        end,
                    },

                    raidFrameDebuffIconsHeader = {
                        order = 12,
                        type = "header",
                        name = "Big Debuff Icons",
                    },

                    raidFrameDebuffIconsEnabled = {
                        order = 13,
                        width = 0.675,
                        type = "toggle",
                        name = SpellIcon(118) .. " Enabled",
                        desc = function()
                            if addon.IsConflictingRaidFrameDebuffAddonLoaded() then
                                return "Disabled while a conflicting raid-frame debuff addon is loaded to avoid duplicate crowd-control icons.";
                            end

                            return "Show large crowd-control debuffs to the right of Blizzard raid-style frames.";
                        end,
                        disabled = addon.IsConflictingRaidFrameDebuffAddonLoaded,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },

                    raidFrameDebuffIconsTest = {
                        order = 14,
                        type = "execute",
                        width = "half",
                        name = "Test",
                        func = function ()
                            SweepyBoop:TestRaidFrameDebuffIcons();
                        end,
                        disabled = DebuffIconOptionsDisabled,
                    },

                    raidFrameDebuffIconsLayoutBreak1 = {
                        order = 15,
                        type = "description",
                        name = "",
                        width = "full",
                    },

                    raidFrameDebuffIconCount = {
                        order = 16,
                        width = "normal",
                        type = "range",
                        min = 1,
                        max = 5,
                        step = 1,
                        name = "Max Icons",
                        desc = "Maximum number of crowd-control debuff icons to show beside each raid frame.",
                        disabled = DebuffIconOptionsDisabled,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },

                    raidFrameDebuffIconsLayoutBreak2 = {
                        order = 19,
                        type = "description",
                        name = "",
                        width = "full",
                    },

                    raidFrameDebuffIconMillisecondsThreshold = {
                        order = 20,
                        width = "normal",
                        type = "range",
                        min = 1,
                        max = 6,
                        step = 1,
                        name = "Decimal Threshold",
                        desc = "Show decimal countdowns below this many seconds.",
                        disabled = DebuffIconOptionsDisabled,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },

                    raidFrameDebuffIconScale = {
                        order = 22,
                        width = "normal",
                        type = "range",
                        isPercent = true,
                        min = 0.25,
                        max = 1.5,
                        step = 0.05,
                        name = "Other Debuff Scale",
                        desc = "Size of non-dispellable crowd-control debuffs as a percentage of the raid-frame height.",
                        disabled = DebuffIconOptionsDisabled,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },

                    raidFrameDebuffIconDispellableScale = {
                        order = 21,
                        width = "normal",
                        type = "range",
                        isPercent = true,
                        min = 0.25,
                        max = 1.5,
                        step = 0.05,
                        name = "Dispellable Scale",
                        desc = "Size of dispellable crowd-control debuffs as a percentage of the raid-frame height, such as Magic, Curse, Disease, or Poison.",
                        disabled = DebuffIconOptionsDisabled,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },

                    raidFrameDebuffIconOffsetX = {
                        order = 17,
                        width = "normal",
                        type = "range",
                        min = -20,
                        max = 80,
                        step = 1,
                        name = "Offset X",
                        desc = "Horizontal offset from the right edge of the raid frame.",
                        disabled = DebuffIconOptionsDisabled,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },

                    raidFrameDebuffIconOffsetY = {
                        order = 18,
                        width = "normal",
                        type = "range",
                        min = -80,
                        max = 80,
                        step = 1,
                        name = "Offset Y",
                        desc = "Vertical offset from the center of the raid frame.",
                        disabled = DebuffIconOptionsDisabled,
                        set = function(info, val)
                            SetRaidFrameOptionAndRefresh(info, val, function ()
                                SweepyBoop:RefreshRaidFrameDebuffIcons();
                            end);
                        end,
                    },
                },
            },

            aggroHighlight = {
                order = 2,
                type = "group",
                name = "PvP aggro highlight",
                args = (function ()
                    local args = {
                        raidFrameAggroHighlightTest = {
                            order = 1,
                            type = "execute",
                            width = "half",
                            name = "Test",
                            desc = "Preview the configured aggro indicators on visible raid-style frames. Test mode can only be used outside instances.",
                            func = function ()
                                SweepyBoop:TestRaidFrameAggroHighlight();
                            end,
                            disabled = AggroHighlightTestDisabled,
                        },

                        raidFrameAggroHighlightHideTest = {
                            order = 2,
                            type = "execute",
                            width = "half",
                            name = "Hide",
                            desc = "Hide the aggro indicator preview.",
                            func = function ()
                                SweepyBoop:HideTestRaidFrameAggroHighlight();
                            end,
                        },

                        raidFrameAggroHighlightShape = {
                            order = 3,
                            width = "normal",
                            type = "select",
                            name = "Shape",
                            desc = "Shape used for class-colored target indicators.",
                            values = {
                                Star = "Star",
                                Circle = "Circle",
                                Diamond = "Diamond",
                                Triangle = "Triangle",
                                Moon = "Moon",
                                Square = "Square",
                                Cross = "Cross",
                                Skull = "Skull",
                                Flag = "Flag",
                                Murloc = "Murloc",
                            },
                            set = SetAggroHighlightOptionAndRefresh,
                        },
                    };

                    BuildAggroHighlightLayoutOptions(
                        args,
                        10,
                        "raidFrameAggroHighlightRaidFrames",
                        "Raid frames",
                        "Show on raid frames",
                        "Show enemy target indicators on player and party raid-style frames."
                    );
                    BuildAggroHighlightLayoutOptions(
                        args,
                        30,
                        "raidFrameAggroHighlightArenaFrames",
                        "Arena frames",
                        "Show on built-in arena frames",
                        "Show friendly target indicators on Blizzard compact arena frames."
                    );
                    return args;
                end)(),
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
