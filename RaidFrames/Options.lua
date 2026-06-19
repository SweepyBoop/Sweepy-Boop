local _, addon = ...;

addon.GetRaidFrameOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        name = "Raid frames",
        get = function(info) return SweepyBoop.db.profile.raidFrames[info[#info]] end,
        set = function(info, val) SweepyBoop.db.profile.raidFrames[info[#info]] = val end,
        args = {
            header1 = {
                order = 1,
                type = "header",
                name = "PvP aggro highlight",
                hidden = function () return addon.PROJECT_MAINLINE; end,
            },

            raidFrameAggroHighlightEnabled = {
                order = 2,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_ATLAS("pvptalents-warmode-swords") .. " Enabled",
                desc = "Show an animating dotted line border when a teammate is targeted by enemy players\n\n"
                    .. "The color of the border changes based on the number of enemies targeting the teammate",
                hidden = function () return addon.PROJECT_MAINLINE; end,
            },

            raidFrameAggroHighlightThickness = {
                order = 3,
                type = "range",
                min = 1,
                max = 5,
                step = 1,
                name = "Border thickness",
                hidden = function ()
                    return addon.PROJECT_MAINLINE or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
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
                    return addon.PROJECT_MAINLINE or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
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
                    return addon.PROJECT_MAINLINE or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            header2 = {
                order = 6,
                type = "header",
                name = "",
                hidden = function () return addon.PROJECT_MAINLINE; end,
            },

            druidHoTHelper = {
                order = 7,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_healingtouch")) .. "Druid HoT helper",
                desc = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_misc_herb_felblossom")) .. " For Resto Druids, draw your own HoTs on raid frames: Lifebloom (glowing during its refresh/pandemic window) plus Regrowth, Wild Growth, Rejuvenation and Germination packed in Swiftmend-priority order, with a warning when none of those four are active. Disable Blizzard's raid-frame buffs to rely on this.",
            }
        },
    };

    return optionGroup;
end
