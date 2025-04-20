local addonName, addon = ...;

addon.GetMiscOptions = function (order, icon, SweepyBoopLDB)
    local optionGroup = {
        order = order,
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
                name = addon.FORMAT_ATLAS("countdown-swords") .. " Show combat indicators on unit frames",
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
                name = "Arena",
            },
            hideBlizzArenaFrames = {
                order = 15,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_arena_3v3_3")) .. " Hide Blizzard arena frames",
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:SetupHideBlizzArenaFrames();
                end
            },
            arenaSurrenderEnabled = {
                order = 16,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_pet_exitbattle")) .. " Type /afk to surrender, type /gg to leave without confirmation",
            },

            showDampenPercentage = {
                order = 17,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_bg_winsoa_underxminutes")) .. " Show dampen percentage on the arena widget",
            },

            healerIndicator = {
                order = 18,
                type = "toggle",
                name = addon.FORMAT_ATLAS("Icon-Healer") .. " Show healer indicator on arena frames",
                desc = "To make it easier to identify the healer in case of class stacking",
                width = "full",
                hidden = function ()
                    return ( not ( Gladius or sArena ) );
                end
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

    return optionGroup;
end
