local _, addon = ...;

if ( not addon.PROJECT_MAINLINE ) then return end

-- Blizzard contract:
-- PvpInfoDocumentation.lua documents
-- C_PvP.GetArenaCrowdControlDuration(UnitToken) -> LuaDurationObject.
-- UnitDocumentation.lua documents ARENA_COOLDOWNS_UPDATE without a payload, so every
-- event refreshes all tracked teammate frames.
-- FrameAPICooldownDocumentation.lua documents
-- Cooldown:SetCooldownFromDurationObject(duration, clearIfZero).
-- LuaDurationObjectAPIDocumentation.lua exposes restricted numeric accessors; this
-- module intentionally keeps the object opaque and passes it directly to Cooldown.
-- CompactArenaFrame.lua demonstrates the related opponent-only arenaN flow. Blizzard
-- does not demonstrate partyN/raidN support; this module treats teammate tokens as an
-- experimental capability and hides the icon when the duration API returns no data.

local trinketSpellID = 336126;
local iconBaseSize = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
local frameLevelOffset = 20;
local cufPool = {};
local setupComplete = false;
local refreshScheduled = false;
local layoutPending = false;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function IsEnabled()
    return GetConfig().raidFrameTeammateTrinketEnabled;
end

local function IsInArena()
    local inInstance, instanceType = IsInInstance();
    return inInstance and instanceType == "arena";
end

local function IsFrameVisible(frame)
    local shown = frame:IsShown();
    return ( not addon.IsSecretValue(shown) ) and shown;
end

local function IsTeammateUnit(unit)
    if ( not unit ) or addon.IsSecretValue(unit) then return false end
    if type(unit) ~= "string" then return false end

    local isGroupToken = string.match(unit, "^party%d+$") ~= nil
        or string.match(unit, "^raid%d+$") ~= nil;
    if not isGroupToken then return false end

    local isPlayer = UnitIsUnit(unit, "player");
    if addon.IsSecretValue(isPlayer) then return false end
    return not isPlayer;
end

local function UnitExistsReadable(unit)
    local exists = UnitExists(unit);
    return ( not addon.IsSecretValue(exists) ) and exists;
end

local function ShouldTrackFrameName(name)
    if not name then return false end
    return string.sub(name, 1, 17) == "CompactPartyFrame"
        or string.sub(name, 1, 11) == "CompactRaid";
end

local function GetFrameHeight(frame)
    local height = frame:GetHeight();
    if ( not height ) or height <= 0 then
        local _, _, _, rectHeight = frame:GetRect();
        height = rectHeight;
    end
    return ( height and height > 0 ) and height or 36;
end

local function GetIconSize(frame, config)
    local scale = tonumber(config.raidFrameTeammateTrinketScale) or 0.5;
    if scale <= 0 then scale = 0.5 end
    return GetFrameHeight(frame) * scale;
end

local function GetMillisecondsThreshold(config)
    return Clamp(config.raidFrameTeammateTrinketMillisecondsThreshold, 1, 6);
end

local function UpdateCooldownFontSize(cooldown)
    if not cooldown.sweepyBoopCountdownFontString then
        local numRegions = cooldown:GetNumRegions();
        for i = 1, numRegions do
            local region = select(i, cooldown:GetRegions());
            if region and region:GetObjectType() == "FontString" then
                cooldown.sweepyBoopCountdownFontString = region;
                break;
            end
        end
    end

    local region = cooldown.sweepyBoopCountdownFontString;
    if region then
        local font, _, flags = region:GetFont();
        if font then
            region:SetFont(
                font,
                math.floor(iconBaseSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT),
                flags
            );
        end
    end
end

local function StyleCooldown(cooldown, config)
    local hideCountdown = config.raidFrameTeammateTrinketShowCountdown == false;
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC", 1, 1, 1, 1);
    cooldown:SetHideCountdownNumbers(hideCountdown);
    cooldown.noCooldownCount = hideCountdown;
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(GetMillisecondsThreshold(config));
    end
    UpdateCooldownFontSize(cooldown);
end

local function HideIcon(frame)
    local icon = frame and frame.sweepyBoopTeammateTrinketIcon;
    if not icon then return end

    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    end
    icon:Hide();
end

local function EnsureIcon(frame)
    local icon = frame.sweepyBoopTeammateTrinketIcon;
    if icon then return icon end
    if InCombatLockdown() then
        layoutPending = true;
        return;
    end

    icon = CreateFrame("Frame", nil, frame);
    icon:SetSize(iconBaseSize, iconBaseSize);
    icon:SetFrameLevel(frame:GetFrameLevel() + frameLevelOffset);

    local backdrop = icon:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(icon);
    backdrop:SetColorTexture(0, 0, 0, 1);

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    local inset = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET;
    icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset);
    icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset);
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    icon.texture:SetTexture(addon.GetSpellTexture(trinketSpellID));

    local border = icon:CreateTexture(nil, "OVERLAY");
    local padding = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_PADDING;
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", -padding, padding);
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", padding, -padding);
    border:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
    border:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon.texture);
    StyleCooldown(icon.cooldown, GetConfig());
    icon:Hide();
    frame.sweepyBoopTeammateTrinketIcon = icon;
    return icon;
end

local function ApplyLayout(frame, icon)
    if InCombatLockdown() then
        layoutPending = true;
        return;
    end

    local config = GetConfig();
    icon:ClearAllPoints();
    icon:SetPoint(
        "RIGHT",
        frame,
        "LEFT",
        config.raidFrameTeammateTrinketOffsetX or -2,
        config.raidFrameTeammateTrinketOffsetY or 0
    );
    icon:SetScale(GetIconSize(frame, config) / iconBaseSize);
    StyleCooldown(icon.cooldown, config);
end

local function GetTeammateTrinketDuration(unit)
    if ( not C_PvP ) or ( not C_PvP.GetArenaCrowdControlDuration ) then return end

    local succeeded, duration = pcall(C_PvP.GetArenaCrowdControlDuration, unit);
    if not succeeded then return end
    return duration;
end

local function UpdateFrame(frame)
    if ( not frame ) or frame:IsForbidden() then return end

    local unit = frame.displayedUnit or frame.unit;
    if ( not IsEnabled() )
        or ( not IsInArena() )
        or ( not IsFrameVisible(frame) )
        or addon.IsSecretValue(unit)
        or ( not IsTeammateUnit(unit) )
        or ( not UnitExistsReadable(unit) ) then

        HideIcon(frame);
        return;
    end

    local icon = EnsureIcon(frame);
    if not icon then return end
    ApplyLayout(frame, icon);

    local duration = GetTeammateTrinketDuration(unit);
    if ( not duration ) or ( not icon.cooldown.SetCooldownFromDurationObject ) then
        HideIcon(frame);
        return;
    end

    icon.cooldown:SetCooldownFromDurationObject(duration, true);
    icon:Show();
end

local function RefreshAllFrames()
    for frame in pairs(cufPool) do
        UpdateFrame(frame);
    end
end

local function ScheduleRefresh()
    if refreshScheduled then return end

    refreshScheduled = true;
    C_Timer.After(0, function()
        refreshScheduled = false;
        RefreshAllFrames();
    end);
end

local function TrackFrame(frame)
    if ( not frame ) or frame:IsForbidden() then return end

    local name = frame:GetName();
    if ShouldTrackFrameName(name) then
        cufPool[frame] = true;
        UpdateFrame(frame);
    elseif cufPool[frame] then
        cufPool[frame] = nil;
        HideIcon(frame);
    end
end

function SweepyBoop:SetupRaidFrameTeammateTrinkets()
    if ( not addon.PROJECT_MAINLINE ) or setupComplete then return end
    setupComplete = true;

    hooksecurefunc("CompactUnitFrame_UpdateAll", TrackFrame);
    hooksecurefunc("CompactUnitFrame_SetUnit", TrackFrame);
    hooksecurefunc("CompactUnitFrame_UpdateVisible", TrackFrame);

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE");
    eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == addon.GROUP_ROSTER_UPDATE
            or event == addon.PLAYER_ENTERING_WORLD then

            ScheduleRefresh();
            return;
        end

        if event == addon.PLAYER_REGEN_ENABLED then
            layoutPending = false;
        end
        -- ARENA_COOLDOWNS_UPDATE has no documented payload. Refresh every tracked unit.
        RefreshAllFrames();
    end);
end

function SweepyBoop:RefreshRaidFrameTeammateTrinkets()
    RefreshAllFrames();
end
