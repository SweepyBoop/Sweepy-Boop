local addonName, addon = ...;

local blizzardBuffCVar = "raidFramesDisplayBuffs";

local function RefreshOptions()
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName);
end

local function GetBlizzardBuffsHidden()
    return tostring(GetCVar(blizzardBuffCVar)) == "0";
end

local function SetBlizzardBuffsHidden(hidden)
    local desired = hidden and "0" or "1";
    local callSucceeded, setSucceeded = pcall(SetCVar, blizzardBuffCVar, desired);
    if ( not callSucceeded )
            or ( setSucceeded == false )
            or ( tostring(GetCVar(blizzardBuffCVar)) ~= desired ) then
        print(
            addon.addonTitle
                .. ": "
                .. format(
                    addon.L["Could not change %s."],
                    blizzardBuffCVar
                )
        );
    end
    RefreshOptions();
end

local cvarEventFrame = CreateFrame("Frame");
cvarEventFrame:RegisterEvent("CVAR_UPDATE");
cvarEventFrame:SetScript("OnEvent", function(_, _, cvarName)
    if cvarName
            and ( string.lower(cvarName) == string.lower(blizzardBuffCVar) ) then
        RefreshOptions();
    end
end);

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

local function SetAggroHighlightOptionAndRefresh(info, val)
    SetRaidFrameOptionAndRefresh(info, val, function ()
        SweepyBoop:RefreshRaidFrameAggroHighlight();
        if addon.RefreshRaidFrameAggroPreviewWidgets then
            addon.RefreshRaidFrameAggroPreviewWidgets();
        end
    end);
end

local function RefreshRaidFrameDebuffIconsAndPreview()
    SweepyBoop:RefreshRaidFrameDebuffIcons();
    if addon.RefreshRaidFrameDebuffIconPreviewWidgets then
        addon.RefreshRaidFrameDebuffIconPreviewWidgets();
    end
end

local function SetDebuffIconOptionAndRefresh(info, val)
    SetRaidFrameOptionAndRefresh(info, val, RefreshRaidFrameDebuffIconsAndPreview);
end

local aggroHighlightShapeOrder = {
    "Disabled",
    "Star",
    "Circle",
    "Diamond",
    "Triangle",
    "Moon",
    "Square",
    "Cross",
    "Skull",
};

local function BuildAggroHighlightLayoutOptions(args, orderOffset, keyPrefix, sectionName, previewName)
    local function LayoutDisabled()
        return SweepyBoop.db.profile.raidFrames[keyPrefix .. "Shape"] == "Disabled";
    end

    args[keyPrefix .. "Header"] = {
        order = orderOffset,
        type = "header",
        name = sectionName,
    };

    args[keyPrefix .. "Preview"] = {
            order = orderOffset + 1,
            type = "description",
            width = "full",
            name = previewName,
            dialogControl = "RaidFrameAggroPreview-SweepyBoop",
            arg = {
                keyPrefix = keyPrefix,
            },
        };

    args[keyPrefix .. "Shape"] = {
            order = orderOffset + 2,
            width = 0.9,
            type = "select",
            name = "Shape",
            desc = "Shape used for class-colored target indicators.",
            values = {
                Disabled = "Disabled",
                Star = "Star",
                Circle = "Circle",
                Diamond = "Diamond",
                Triangle = "Triangle",
                Moon = "Moon",
                Square = "Square",
                Cross = "Cross",
                Skull = "Skull",
            },
            sorting = aggroHighlightShapeOrder,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "Size"] = {
            order = orderOffset + 3,
            width = 0.65,
            type = "range",
            min = 8,
            max = 32,
            step = 1,
            name = "Size",
            desc = "Indicator size in pixels.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "BorderThickness"] = {
            order = orderOffset + 4,
            width = 0.95,
            type = "range",
            min = 1,
            max = 5,
            step = 1,
            name = "Border Thickness",
            desc = "Thickness of the black marker outline.",
            disabled = LayoutDisabled,
            set = SetAggroHighlightOptionAndRefresh,
        };

    args[keyPrefix .. "FirstRowBreak"] = {
            order = orderOffset + 4.5,
            type = "description",
            name = "",
            width = "full",
        };

    args[keyPrefix .. "Anchor"] = {
            order = orderOffset + 5,
            width = 0.9,
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
            order = orderOffset + 6,
            width = 0.9,
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
            order = orderOffset + 7,
            width = 0.9,
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

    args[keyPrefix .. "SecondRowBreak"] = {
            order = orderOffset + 7.5,
            type = "description",
            name = "",
            width = "full",
        };

    args[keyPrefix .. "Spacing"] = {
            order = orderOffset + 8,
            width = 0.65,
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
            order = orderOffset + 9,
            width = 0.75,
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
            order = orderOffset + 10,
            width = 0.75,
            type = "range",
            min = -80,
            max = 80,
            step = 1,
            name = "Offset Y",
            desc = "Vertical offset from the selected frame point.",
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

                    hideBlizzardRaidFrameBuffs = {
                        order = 5.5,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_ATLAS("gmchat-icon-blizz") .. " Hide Blizzard raid-frame buffs via CVar",
                        desc = "Persistent Blizzard setting. SweepyBoop does not change it automatically or store it in profiles.",
                        confirm = function(_, hidden)
                            return hidden;
                        end,
                        confirmText = addon.L["SweepyBoop will set raidFramesDisplayBuffs to 0. This hides Blizzard's built-in raid-frame buffs until you turn this option off. Continue?"],
                        get = GetBlizzardBuffsHidden,
                        set = function(_, hidden)
                            SetBlizzardBuffsHidden(hidden);
                        end,
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
                                "\226\128\162 " .. SpellIcon(33763) .. " " .. addon.L["Lifebloom with a green glow in its 30% refresh window when timing is readable."],
                                "\226\128\162 " .. addon.L["Row 2: Regrowth, Wild Growth, Rejuvenation, Germination."],
                                "\226\128\162 " .. addon.L["Warn when Mark of the Wild is missing."],
                                "\226\128\162 " .. addon.L["Securely rendered by Blizzard's aura container."],
                            }, "\n");
                        end,
                        disabled = addon.IsConflictingHealerBuffHelperAddonLoaded,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper();
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
                                "\226\128\162 " .. SpellIcon(364343) .. " " .. addon.L["Echo without a refresh-window glow."],
                                "\226\128\162 " .. addon.L["Row 2, least-to-most important: Reversion, Dream Breath, Lifebind, Time Dilation."],
                                "\226\128\162 " .. addon.L["Warn when Blessing of the Bronze is missing."],
                                "\226\128\162 " .. addon.L["Securely rendered by Blizzard's aura container."],
                            }, "\n");
                        end,
                        disabled = addon.IsConflictingHealerBuffHelperAddonLoaded,
                        set = function(info, val)
                            SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                            SweepyBoop:RefreshHealerBuffHelper();
                        end,
                    },

                    raidFrameDebuffIconsHeader = {
                        order = 12,
                        type = "header",
                        name = "Big Debuff Icons",
                    },

                    raidFrameDebuffIconsPreview = {
                        order = 13,
                        type = "description",
                        width = "full",
                        name = "Preview",
                        dialogControl = "RaidFrameDebuffIconPreview-SweepyBoop",
                    },

                    raidFrameDebuffIconsEnabled = {
                        order = 14,
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
                        set = SetDebuffIconOptionAndRefresh,
                    },

                    raidFrameDebuffIconsLayoutBreak1 = {
                        order = 15,
                        type = "description",
                        name = "",
                        width = "full",
                    },

                    raidFrameDebuffIconCount = {
                        order = 16,
                        width = 0.8,
                        type = "range",
                        min = 1,
                        max = 5,
                        step = 1,
                        name = "Max Icons",
                        desc = "Maximum number of crowd-control debuff icons to show beside each raid frame.",
                        disabled = DebuffIconOptionsDisabled,
                        set = SetDebuffIconOptionAndRefresh,
                    },

                    raidFrameDebuffIconsLayoutBreak2 = {
                        order = 19,
                        type = "description",
                        name = "",
                        width = "full",
                    },

                    raidFrameDebuffIconMillisecondsThreshold = {
                        order = 20,
                        width = 0.8,
                        type = "range",
                        min = 1,
                        max = 6,
                        step = 1,
                        name = "Decimal Threshold",
                        desc = "Show decimal countdowns below this many seconds.",
                        disabled = DebuffIconOptionsDisabled,
                        set = SetDebuffIconOptionAndRefresh,
                    },

                    raidFrameDebuffIconScale = {
                        order = 22,
                        width = 0.8,
                        type = "range",
                        isPercent = true,
                        min = 0.25,
                        max = 1.5,
                        step = 0.05,
                        name = "Debuff Scale",
                        desc = "Size of crowd-control debuffs as a percentage of the raid-frame height.",
                        disabled = DebuffIconOptionsDisabled,
                        set = SetDebuffIconOptionAndRefresh,
                    },

                    raidFrameDebuffIconDispellableScale = {
                        order = 21,
                        hidden = true, -- One secure group uses one size and one total icon budget.
                        width = 0.8,
                        type = "range",
                        isPercent = true,
                        min = 0.25,
                        max = 1.5,
                        step = 0.05,
                        name = "Dispellable Scale",
                        desc = "Size of dispellable crowd-control debuffs as a percentage of the raid-frame height, such as Magic, Curse, Disease, or Poison.",
                        disabled = DebuffIconOptionsDisabled,
                        set = SetDebuffIconOptionAndRefresh,
                    },

                    raidFrameDebuffIconOffsetX = {
                        order = 17,
                        width = 0.8,
                        type = "range",
                        min = -20,
                        max = 80,
                        step = 1,
                        name = "Offset X",
                        desc = "Horizontal offset from the right edge of the raid frame.",
                        disabled = DebuffIconOptionsDisabled,
                        set = SetDebuffIconOptionAndRefresh,
                    },

                    raidFrameDebuffIconOffsetY = {
                        order = 18,
                        width = 0.8,
                        type = "range",
                        min = -80,
                        max = 80,
                        step = 1,
                        name = "Offset Y",
                        desc = "Vertical offset from the center of the raid frame.",
                        disabled = DebuffIconOptionsDisabled,
                        set = SetDebuffIconOptionAndRefresh,
                    },
                },
            },

            aggroHighlight = {
                order = 2,
                type = "group",
                name = "Arena target",
                args = (function ()
                    local args = {};

                    BuildAggroHighlightLayoutOptions(
                        args,
                        10,
                        "raidFrameAggroHighlightRaidFrames",
                        "Raid frames",
                        "Raid frames preview (disable: Shape -> Disabled)"
                    );
                    BuildAggroHighlightLayoutOptions(
                        args,
                        30,
                        "raidFrameAggroHighlightArenaFrames",
                        "Arena frames",
                        "Arena frames preview (disable: Shape -> Disabled)"
                    );
                    return args;
                end)(),
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
