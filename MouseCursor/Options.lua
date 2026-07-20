local _, addon = ...;
local L = addon.L;

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

local function GetColor(prefix)
    local config = SweepyBoop.db.profile.mouseCursor;
    return config[prefix .. "ColorR"], config[prefix .. "ColorG"], config[prefix .. "ColorB"];
end

local function SetColor(prefix, r, g, b)
    local config = SweepyBoop.db.profile.mouseCursor;
    config[prefix .. "ColorR"] = r;
    config[prefix .. "ColorG"] = g;
    config[prefix .. "ColorB"] = b;
    config.lastModified = GetTime();
    SweepyBoop:UpdateMouseCursor();
end

local function IsDisabled()
    return not SweepyBoop.db.profile.mouseCursor.enabled;
end

local function IsFeatureDisabled(featureKey)
    local config = SweepyBoop.db.profile.mouseCursor;
    return ( not config.enabled ) or ( not config[featureKey] );
end

local function HideGCDOptions()
    return addon.PROJECT_TBC;
end

local function CreateColorOption(order, name, prefix, featureKey, hidden)
    return {
        order = order,
        type = "color",
        width = 0.9,
        name = name,
        get = function()
            return GetColor(prefix);
        end,
        set = function(_, r, g, b)
            SetColor(prefix, r, g, b);
        end,
        disabled = function()
            return IsFeatureDisabled(featureKey);
        end,
        hidden = hidden,
    };
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
            description = {
                order = 1,
                type = "description",
                fontSize = "medium",
                name = L["A lightweight ring, GCD indicator, and fading trail around your mouse cursor."],
            },
            enabled = {
                order = 2,
                type = "toggle",
                width = 0.8,
                name = addon.FORMAT_ATLAS("CircleMaskScalable") .. " " .. L["Enabled"],
                set = SetMouseCursorOption,
            },
            scale = {
                order = 3,
                type = "range",
                width = 0.9,
                min = 0.5,
                max = 2,
                step = 0.05,
                name = L["Scale"],
                set = UpdateMouseCursorOption,
                disabled = IsDisabled,
            },
            opacity = {
                order = 4,
                type = "range",
                width = 0.9,
                min = 0.2,
                max = 1,
                step = 0.05,
                name = L["Opacity"],
                set = UpdateMouseCursorOption,
                disabled = IsDisabled,
            },
            baselineHeader = {
                order = 10,
                type = "header",
                name = L["Baseline ring"],
            },
            showBaseline = {
                order = 11,
                type = "toggle",
                width = 0.8,
                name = L["Enabled"],
                set = UpdateMouseCursorOption,
                disabled = IsDisabled,
            },
            baselineColor = CreateColorOption(12, L["Baseline color"], "baseline", "showBaseline"),
            ringSize = {
                order = 13,
                type = "range",
                width = 0.9,
                min = 28,
                max = 90,
                step = 1,
                name = L["Ring size"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return IsFeatureDisabled("showBaseline");
                end,
            },
            trailHeader = {
                order = 20,
                type = "header",
                name = L["Trail"],
            },
            showTrail = {
                order = 21,
                type = "toggle",
                width = 0.8,
                name = L["Enabled"],
                set = UpdateMouseCursorOption,
                disabled = IsDisabled,
            },
            trailColor = CreateColorOption(22, L["Trail color"], "trail", "showTrail"),
            trailColorBreak = {
                order = 22.5,
                type = "description",
                width = "full",
                name = "",
            },
            trailDuration = {
                order = 23,
                type = "range",
                width = 0.9,
                min = 0.1,
                max = 0.8,
                step = 0.05,
                name = L["Trail duration"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return IsFeatureDisabled("showTrail");
                end,
            },
            trailDensity = {
                order = 24,
                type = "range",
                width = 0.9,
                min = 0.005,
                max = 0.06,
                step = 0.005,
                name = L["Trail density"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return IsFeatureDisabled("showTrail");
                end,
            },
            trailSize = {
                order = 25,
                type = "range",
                width = 0.9,
                min = 3,
                max = 16,
                step = 1,
                name = L["Trail size"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return IsFeatureDisabled("showTrail");
                end,
            },
            gcdHeader = {
                order = 30,
                type = "header",
                name = L["GCD ring"],
                hidden = HideGCDOptions,
            },
            showGCD = {
                order = 31,
                type = "toggle",
                width = 0.8,
                name = L["Enabled"],
                set = SetMouseCursorOption,
                disabled = IsDisabled,
                hidden = HideGCDOptions,
            },
            gcdColor = CreateColorOption(32, L["GCD color"], "gcd", "showGCD", HideGCDOptions),
            gcdRingSize = {
                order = 33,
                type = "range",
                width = 0.9,
                min = 28,
                max = 110,
                step = 1,
                name = L["GCD ring size"],
                set = UpdateMouseCursorOption,
                disabled = function()
                    return IsFeatureDisabled("showGCD");
                end,
                hidden = HideGCDOptions,
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
