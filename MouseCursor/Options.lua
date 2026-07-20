local _, addon = ...;
local L = addon.L;

if not addon.PROJECT_MAINLINE then return end

local function SetMouseCursorOption(info, val)
    local config = SweepyBoop.db.profile.mouseCursor;
    config[info[#info]] = val;
    config.lastModified = GetTime();
    SweepyBoop:SetupMouseCursor();
end

local function UpdateMouseCursorOption(info, val)
    local config = SweepyBoop.db.profile.mouseCursor;
    config[info[#info]] = val;
    config.lastModified = GetTime();
    SweepyBoop:UpdateMouseCursor();
end

addon.GetMouseCursorOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        name = L["Mouse cursor"],
        get = function(info)
            return SweepyBoop.db.profile.mouseCursor[info[#info]];
        end,
        set = UpdateMouseCursorOption,
        handler = SweepyBoop,
        args = {
            title = {
                order = 1,
                type = "header",
                name = L["Mouse cursor"],
            },
            description = {
                order = 2,
                type = "description",
                fontSize = "medium",
                name = L["Adds a lightweight ring, GCD indicator, and fading trail around your mouse cursor. Uses built-in UI primitives only; no external cursor media is copied."],
            },
            enabled = {
                order = 3,
                type = "toggle",
                width = 0.8,
                name = addon.FORMAT_ATLAS("CircleMaskScalable") .. " " .. L["Enabled"],
                set = SetMouseCursorOption,
            },
            testGCD = {
                order = 4,
                type = "execute",
                width = 0.6,
                name = L["Test GCD"],
                func = "TestMouseCursorGCD",
                disabled = function()
                    local config = SweepyBoop.db.profile.mouseCursor;
                    return ( not config.enabled ) or ( not config.showGCD );
                end,
            },
            visualHeader = {
                order = 5,
                type = "header",
                name = L["Visuals"],
            },
            showBaseline = {
                order = 6,
                type = "toggle",
                width = 0.8,
                name = L["Baseline ring"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            showTrail = {
                order = 7,
                type = "toggle",
                width = 0.8,
                name = L["Trail"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            showGCD = {
                order = 8,
                type = "toggle",
                width = 0.8,
                name = L["GCD ring"],
                set = SetMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            useClassColor = {
                order = 9,
                type = "toggle",
                width = 1,
                name = L["Use class color"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            ringSize = {
                order = 10,
                type = "range",
                width = 0.9,
                min = 28,
                max = 90,
                step = 1,
                name = L["Ring size"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            ringThickness = {
                order = 11,
                type = "range",
                width = 0.9,
                min = 2,
                max = 6,
                step = 1,
                name = L["Ring thickness"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            scale = {
                order = 12,
                type = "range",
                width = 0.9,
                min = 0.5,
                max = 2,
                step = 0.05,
                name = L["Scale"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            opacity = {
                order = 13,
                type = "range",
                width = 0.9,
                min = 0.2,
                max = 1,
                step = 0.05,
                name = L["Opacity"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            trailHeader = {
                order = 14,
                type = "header",
                name = L["Trail"],
                hidden = function()
                    return not SweepyBoop.db.profile.mouseCursor.showTrail;
                end,
            },
            trailDuration = {
                order = 15,
                type = "range",
                width = 0.9,
                min = 0.1,
                max = 0.8,
                step = 0.05,
                name = L["Trail duration"],
                set = UpdateMouseCursorOption,
                hidden = function()
                    return not SweepyBoop.db.profile.mouseCursor.showTrail;
                end,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            trailDensity = {
                order = 16,
                type = "range",
                width = 0.9,
                min = 0.005,
                max = 0.06,
                step = 0.005,
                name = L["Trail density"],
                set = UpdateMouseCursorOption,
                hidden = function()
                    return not SweepyBoop.db.profile.mouseCursor.showTrail;
                end,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
            trailSize = {
                order = 17,
                type = "range",
                width = 0.9,
                min = 3,
                max = 16,
                step = 1,
                name = L["Trail size"],
                set = UpdateMouseCursorOption,
                hidden = function()
                    return not SweepyBoop.db.profile.mouseCursor.showTrail;
                end,
                disabled = function()
                    return not SweepyBoop.db.profile.mouseCursor.enabled;
                end,
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
