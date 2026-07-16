local addonName, addon = ...;
local L = addon.L;

addon.GetMiscOptions = function (order, icon, SweepyBoopLDB)
    local optionGroup = {
        order = order,
        type = "group",
        childGroups = "tab",
        name = L["Misc"],
        get = function(info) return SweepyBoop.db.profile.misc[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.misc[info[#info]] = val;
            SweepyBoop.db.profile.misc.lastModified = GetTime();
        end,
        handler = SweepyBoop,
        args = {
            general = {
                order = 1,
                type = "group",
                name = L["General"],
                args = {
                    header1 = {
                        order = 1,
                        type = "header",
                        name = L["Healer in crowd control reminder in arena"],
                    },
                    healerInCrowdControl = {
                        order = 2,
                        type = "toggle",
                        width = 0.675,
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_polymorph")) .. " " .. L["Enabled"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupHealerInCrowdControl();
                        end
                    },
                    healerInCrowdControlSound = {
                        order = 3,
                        type = "toggle",
                        width = 0.75,
                        name = addon.FORMAT_ATLAS("chatframe-button-icon-voicechat") .. " " .. L["Play sound"],
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                        end
                    },
                    healerInCrowdControlTest = {
                        order = 4,
                        type = "execute",
                        width = "half",
                        name = L["Test"],
                        func = "TestHealerInCrowdControl",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                        end
                    },
                    healerInCrowdControlHide = {
                        order = 5,
                        type = "execute",
                        width = "half",
                        name = L["Hide"],
                        func = "HideTestHealerInCrowdControl",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                        end
                    },
                    newline = {
                        order = 6,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                        end
                    },
                    healerInCrowdControlSize = {
                        order = 7,
                        type = "range",
                        width = 0.8,
                        min = 30,
                        max = 200,
                        step = 1,
                        name = L["Icon size"],
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
                        order = 8,
                        type = "range",
                        width = 1,
                        min = -1000,
                        max = 1000,
                        step = 1,
                        name = L["X offset"],
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
                        order = 9,
                        type = "range",
                        width = 1,
                        min = -1000,
                        max = 1000,
                        step = 1,
                        name = L["Y offset"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHealerInCrowdControl();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                        end
                    },
                    healerInCrowdControlThresholdBreak = {
                        order = 10,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
                        end
                    },
                    healerInCrowdControlMillisecondsThreshold = {
                        order = 11,
                        type = "range",
                        width = 0.8,
                        min = 1,
                        max = 6,
                        step = 1,
                        name = L["Decimal threshold"],
                        desc = L["Show decimal countdowns below this many seconds."],
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
                        order = 12,
                        type = "header",
                        name = "",
                    },
                    queueReminder = {
                        order = 13,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " " .. L["PvP Queue Timer"],
                        desc = L["Shows a timer on arena / battlefield queue pop, and plays an alert when it's about to expire"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop:SetupQueueReminder();
                        end
                    },

                    header3 = {
                        order = 14,
                        type = "header",
                        name = L["Unit frames"],
                    },
                    precognitionTracker = {
                        order = 15,
                        type = "toggle",
                        width = 1.35,
                        name = addon.FORMAT_TEXTURE(addon.GetSpellTexture(377362)) .. " " .. L["Show Precognition on player"],
                        desc = L["Show a glowing icon while Precognition is active on you."],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupPrecognitionTracker();
                        end,
                    },
                    precognitionTrackerTest = {
                        order = 16,
                        type = "execute",
                        width = 0.4,
                        name = L["Test"],
                        func = "TestPrecognitionTracker",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.precognitionTracker );
                        end,
                    },
                    precognitionTrackerOptionsBreak = {
                        order = 17,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.precognitionTracker );
                        end,
                    },
                    precognitionTrackerSize = {
                        order = 18,
                        type = "range",
                        width = 0.8,
                        min = 20,
                        max = 100,
                        step = 1,
                        name = L["Icon size"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePrecognitionTracker();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.precognitionTracker );
                        end,
                    },
                    precognitionTrackerOffsetX = {
                        order = 19,
                        type = "range",
                        width = 0.8,
                        min = -500,
                        max = 500,
                        step = 1,
                        name = L["X offset"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePrecognitionTracker();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.precognitionTracker );
                        end,
                    },
                    precognitionTrackerOffsetY = {
                        order = 20,
                        type = "range",
                        width = 0.8,
                        min = -500,
                        max = 500,
                        step = 1,
                        name = L["Y offset"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePrecognitionTracker();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.precognitionTracker );
                        end,
                    },
                    precognitionTrackerBreak = {
                        order = 21,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.precognitionTracker );
                        end,
                    },
                    combatIndicator = {
                        order = 22,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_ATLAS("countdown-swords") .. " " .. L["Show combat indicators on unit frames"],
                        desc = L["Show combat indicator icons on Player / Target / Focus frames"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupCombatIndicator();
                        end,
                    },
                    alwaysShowDruidComboPoints = {
                        order = 23,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_druid_mangle")) .. " " .. L["Always show Druid combo points"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupAlwaysShowDruidComboPoints();
                        end,
                    },
                    header4 = {
                        order = 24,
                        type = "header",
                        name = L["Arena"],
                    },
                    hideBlizzArenaFrames = {
                        order = 25,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_arena_3v3_3")) .. " " .. L["Hide Blizzard arena frames"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupHideBlizzArenaFrames();
                        end,
                        hidden = function ()
                            return ( not ( Gladius or GladiusEx or sArena ) );
                        end
                    },
                    arenaSurrenderEnabled = {
                        order = 26,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_pet_exitbattle")) .. " " .. L["Type /gg to leave arena without confirmation"],
                        desc = L["Disabling this option requires a UI reload to take effect"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            if ( val == false ) then
                                ReloadUI();
                            end
                        end,
                    },

                    showDampenPercentage = {
                        order = 27,
                        width = "full",
                        type = "toggle",
                        name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_bg_winsoa_underxminutes")) .. " " .. L["Show dampen percentage on the arena widget"],
                    },


                    header6 = {
                        order = 29,
                        type = "header",
                        name = "",
                    },

                    showMinimapIcon = {
                        order = 30,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Logo") .. " " .. L["Show minimap icon for invoking options UI"],
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
            },

            personalDR = {
                order = 3,
                type = "group",
                name = L["Personal DR"],
                args = {
                    personalDR = {
                        order = 1,
                        type = "toggle",
                        width = 1.2,
                        name = addon.FORMAT_TEXTURE(addon.GetSpellTexture(118)) .. " " .. L["Enabled"],
                        desc = L["Track diminishing returns on yourself. A pulsing stun icon means you are clean on stun DR."],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupPersonalDR();
                        end,
                    },
                    personalDRTest = {
                        order = 2,
                        type = "execute",
                        width = 0.4,
                        name = L["Test"],
                        func = "TestPersonalDR",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRHide = {
                        order = 3,
                        type = "execute",
                        width = 0.4,
                        name = L["Hide"],
                        func = "HideTestPersonalDR",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDROptionsBreak = {
                        order = 4,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRSize = {
                        order = 5,
                        type = "range",
                        width = 0.8,
                        min = 20,
                        max = 100,
                        step = 1,
                        name = L["Icon size"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRShowCleanStun = {
                        order = 4.5,
                        type = "toggle",
                        width = "full",
                        name = addon.FORMAT_TEXTURE(addon.GetSpellTexture(1833)) .. " " .. L["Show clean stun DR"],
                        desc = L["Show the glowing stun icon while you are clean on stun DR."],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRAnchorPoint = {
                        order = 6,
                        type = "select",
                        width = 0.8,
                        name = L["Anchor"],
                        values = {
                            CENTER = L["Center"],
                            TOP = L["Top"],
                            BOTTOM = L["Bottom"],
                            LEFT = L["Left"],
                            RIGHT = L["Right"],
                            TOPLEFT = L["Top left"],
                            TOPRIGHT = L["Top right"],
                            BOTTOMLEFT = L["Bottom left"],
                            BOTTOMRIGHT = L["Bottom right"],
                        },
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRRelativePoint = {
                        order = 7,
                        type = "select",
                        width = 0.8,
                        name = L["Relative"],
                        values = {
                            CENTER = L["Center"],
                            TOP = L["Top"],
                            BOTTOM = L["Bottom"],
                            LEFT = L["Left"],
                            RIGHT = L["Right"],
                            TOPLEFT = L["Top left"],
                            TOPRIGHT = L["Top right"],
                            BOTTOMLEFT = L["Bottom left"],
                            BOTTOMRIGHT = L["Bottom right"],
                        },
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRGrowDirection = {
                        order = 8,
                        type = "select",
                        width = 0.8,
                        name = L["Growth"],
                        values = {
                            CENTER = L["Center"],
                            LEFT = L["Left"],
                            RIGHT = L["Right"],
                            UP = L["Up"],
                            DOWN = L["Down"],
                        },
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDROffsetX = {
                        order = 9,
                        type = "range",
                        width = 0.8,
                        min = -500,
                        max = 500,
                        step = 1,
                        name = L["X offset"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDROffsetY = {
                        order = 10,
                        type = "range",
                        width = 0.8,
                        min = -500,
                        max = 500,
                        step = 1,
                        name = L["Y offset"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdatePersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRCategoriesHeader = {
                        order = 11,
                        type = "header",
                        name = L["Tracked DR categories"],
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRTrackStun = {
                        order = 12,
                        type = "toggle",
                        width = 0.8,
                        name = L["Stun"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRTrackIncapacitate = {
                        order = 13,
                        type = "toggle",
                        width = 0.8,
                        name = L["Incap"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRTrackDisorient = {
                        order = 14,
                        type = "toggle",
                        width = 0.8,
                        name = L["Disorient"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRTrackRoot = {
                        order = 15,
                        type = "toggle",
                        width = 0.8,
                        name = L["Root"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRTrackSilence = {
                        order = 16,
                        type = "toggle",
                        width = 0.8,
                        name = L["Silence"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                    personalDRTrackDisarm = {
                        order = 17,
                        type = "toggle",
                        width = 0.8,
                        name = L["Disarm"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:ResetPersonalDR();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.personalDR );
                        end,
                    },
                },
            },

            honorReminder = {
                order = 4,
                type = "group",
                name = L["Honor reminder"],
                args = {
                    honorReminder = {
                        order = 1,
                        type = "toggle",
                        width = 0.75,
                        name = addon.FORMAT_ATLAS("countdown-swords") .. " " .. L["Enabled"],
                        desc = L["Show a pulsing Honor reminder when your current Honor reaches the configured threshold."],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupHonorReminder();
                        end,
                    },
                    honorReminderTest = {
                        order = 2,
                        type = "execute",
                        width = 0.4,
                        name = L["Test"],
                        func = "TestHonorReminder",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                        disabled = function ()
                            return SweepyBoop:IsHonorReminderRealReminderShown();
                        end,
                    },
                    honorReminderHide = {
                        order = 3,
                        type = "execute",
                        width = 0.4,
                        name = L["Hide"],
                        func = "HideTestHonorReminder",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                        disabled = function ()
                            return SweepyBoop:IsHonorReminderRealReminderShown();
                        end,
                    },
                    honorReminderOptionsBreak = {
                        order = 4,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderThreshold = {
                        order = 5,
                        type = "range",
                        width = 0.8,
                        min = 5000,
                        max = 15000,
                        step = 500,
                        name = L["Honor threshold"],
                        desc = L["Show the reminder when your current Honor is at least this amount."],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHonorReminder();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderThresholdBreak = {
                        order = 6,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderFontSize = {
                        order = 7,
                        type = "range",
                        width = 0.8,
                        min = 8,
                        max = 64,
                        step = 1,
                        name = L["Font size"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHonorReminder();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderIconSize = {
                        order = 8,
                        type = "range",
                        width = 0.8,
                        min = 16,
                        max = 128,
                        step = 1,
                        name = L["Icon size"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHonorReminder();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderSizeBreak = {
                        order = 9,
                        type = "description",
                        width = "full",
                        name = "",
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderAnchorPoint = {
                        order = 10,
                        type = "select",
                        width = 0.8,
                        name = L["Anchor"],
                        values = {
                            CENTER = L["Center"],
                            TOP = L["Top"],
                            BOTTOM = L["Bottom"],
                            LEFT = L["Left"],
                            RIGHT = L["Right"],
                            TOPLEFT = L["Top left"],
                            TOPRIGHT = L["Top right"],
                            BOTTOMLEFT = L["Bottom left"],
                            BOTTOMRIGHT = L["Bottom right"],
                        },
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHonorReminder();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderOffsetX = {
                        order = 11,
                        type = "range",
                        width = 0.8,
                        min = -1000,
                        max = 1000,
                        step = 1,
                        name = L["X offset"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHonorReminder();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                    honorReminderOffsetY = {
                        order = 12,
                        type = "range",
                        width = 0.8,
                        min = -1000,
                        max = 1000,
                        step = 1,
                        name = L["Y offset"],
                        set = function(info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:UpdateHonorReminder();
                        end,
                        hidden = function ()
                            return ( not SweepyBoop.db.profile.misc.honorReminder );
                        end,
                    },
                },
            },

            gismo = {
                order = 2,
                type = "group",
                name = L["Range checker"],
                args = {
                    supportGismo = {
                        order = 1,
                        type = "input",
                        width = "full",
                        name = addon.FORMAT_ATLAS("GarrisonTroops-Health") .. " " .. L["Support the original WA author"],
                        desc = L["Press Ctrl+C to copy URL"],
                        dialogControl = "InlineLink-SweepyBoop",
                        get = function ()
                            return "https://www.twitch.tv/gismodruid";
                        end
                    },

                    rangeCheckerEnabled = {
                        order = 2,
                        type = "toggle",
                        width = 0.8,
                        name = "|A:CircleMaskScalable:20:20:0:0:0:255:0|a " .. L["Enabled"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:SetupRangeChecker();
                        end
                    },

                    rangeCheckerShowTest = {
                        order = 3,
                        type = "execute",
                        name = L["Test"],
                        width = 0.8,
                        func = "TestRangeChecker",
                    },
                    rangeCheckerHideTest = {
                        order = 4,
                        type = "execute",
                        name = L["Hide"],
                        width = 0.8,
                        func = "HideTestRangeChecker",
                    },

                    breaker1 = {
                        order = 5,
                        type = "description",
                        name = "",
                    },

                    rangeCheckerSize = {
                        order = 6,
                        type = "range",
                        width = 0.8,
                        min = 4,
                        max = 64,
                        step = 1,
                        name = L["Indicator size"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:RefreshRangeCheckerTestMode();
                        end,
                    },
                    rangeCheckerOffsetX = {
                        order = 7,
                        type = "range",
                        width = 0.8,
                        min = -250,
                        max = 250,
                        step = 1,
                        name = L["X offset"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:RefreshRangeCheckerTestMode();
                        end,
                    },
                    rangeCheckerOffsetY = {
                        order = 8,
                        type = "range",
                        width = 0.8,
                        min = -250,
                        max = 250,
                        step = 1,
                        name = L["Y offset"],
                        set = function (info, val)
                            SweepyBoop.db.profile.misc[info[#info]] = val;
                            SweepyBoop.db.profile.misc.lastModified = GetTime();
                            SweepyBoop:RefreshRangeCheckerTestMode();
                        end,
                    },

                    breaker2 = {
                        order = 9,
                        type = "header",
                        name = L["Tracked spells"],
                    },
                },
            }
        },
    };

    local index = 10;
    for _, classID in ipairs(addon.CLASSORDER) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        local classFile = classInfo.classFile;
        optionGroup.args.gismo.args[classFile] = {
            order = index,
            type = "input",
            width = 0.8,
            name = classInfo.className,
            get = function (info)
                return tostring(SweepyBoop.db.profile.misc.rangeCheckerSpells[info[#info]]);
            end,
            set = function (info, val)
                SweepyBoop.db.profile.misc.rangeCheckerSpells[info[#info]] = val;
                SweepyBoop.db.profile.misc.lastModified = GetTime();
            end,
            pattern = "^%d+$", -- allow numbers only
        };
        index = index + 1;
    end

    return optionGroup;
end
