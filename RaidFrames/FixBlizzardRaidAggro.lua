local _, addon = ...;

local explicitFramePrefixes = {
    "CompactPartyFrameMember",
    "CompactArenaFrameMember",
};

local ICON_ATLAS = "groupfinder-waitdot";
local ICON_SIZE = 16;
local ICON_SPACING = 1;
local ICON_ALPHA = 0.9;
local MAX_RAID_FRAME_INDEX = addon.MAX_ARENA_SIZE * 2; -- players plus pets

local trackedFrames = {};
local targeters = {};
local classColors = {};
local wasActive = false;

local function AddTargeter(unit, isEnemy)
    if ( not UnitExists(unit) ) then
        return;
    end

    local class = addon.GetUnitClass(unit);
    if addon.IsSecretValue(class) then
        return;
    end

    local classColor = class and RAID_CLASS_COLORS[class];
    if not classColor then
        return;
    end

    table.insert(targeters, {
        unit = unit,
        target = unit .. "target",
        color = classColor,
        isEnemy = isEnemy,
    });
end

local function BuildTargeters()
    wipe(targeters);
    AddTargeter("player", false);
    for i = 1, addon.MAX_ARENA_SIZE do
        AddTargeter("arena" .. i, true);
        AddTargeter("party" .. i, false);
    end
end

local function IsTrackedUnitTarget(unit)
    if unit == "player" then
        return true;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if ( unit == "arena" .. i ) or ( unit == "party" .. i ) then
            return true;
        end
    end

    return false;
end

local function IsArenaUnit(unit)
    if not unit then
        return false;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if ( unit == "arena" .. i ) or addon.UnitIsUnitSecretValueSafe(unit, "arena" .. i) then
            return true;
        end
    end

    return false;
end

local function AddTargetingClassForFrame(classColors, frameUnit, targeter)
    if addon.UnitIsUnitSecretValueSafe(targeter.target, frameUnit) then
        table.insert(classColors, targeter.color);
    end
end

local function GetTargetingClasses(frameUnit)
    wipe(classColors);
    local showEnemyTargeters = not IsArenaUnit(frameUnit);

    for i = 1, #targeters do
        local targeter = targeters[i];
        if targeter.isEnemy == showEnemyTargeters then
            AddTargetingClassForFrame(classColors, frameUnit, targeter);
        end
    end

    return classColors;
end

local function EnsureTargetIcon(container, index)
    if container.icons[index] then
        return container.icons[index];
    end

    local icon = container:CreateTexture(nil, "OVERLAY");
    icon:SetAtlas(ICON_ATLAS);
    icon:SetDesaturated(true);
    icon:SetSize(ICON_SIZE, ICON_SIZE);
    container.icons[index] = icon;
    return icon;
end

local function ShowCustomAggroHighlight(frame, classColors)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1);
        customAggroHighlight:SetSize(1, ICON_SIZE);
        customAggroHighlight:SetFrameLevel(frame:GetFrameLevel() + 10);
        customAggroHighlight.icons = {};
        frame.customAggroHighlight = customAggroHighlight;
    end

    local container = frame.customAggroHighlight;
    local iconCount = #classColors;
    local rowWidth = ( iconCount * ICON_SIZE ) + ( ( iconCount - 1 ) * ICON_SPACING );
    container:SetSize(rowWidth, ICON_SIZE);

    for i = 1, iconCount do
        local icon = EnsureTargetIcon(container, i);
        local color = classColors[i];
        icon:ClearAllPoints();
        icon:SetPoint("RIGHT", container, "RIGHT", -( i - 1 ) * ( ICON_SIZE + ICON_SPACING ), 0);
        icon:SetVertexColor(color.r, color.g, color.b, ICON_ALPHA);
        icon:Show();
    end

    for i = iconCount + 1, #container.icons do
        container.icons[i]:Hide();
    end

    container:Show();
end

local function HideCustomAggroHighlight(frame)
    if frame.customAggroHighlight then
        frame.customAggroHighlight:Hide();
    end
end

local function SetDispelIconAlpha(prefix, index, alpha)
    for i = 1, 3 do
        local frame = _G[prefix .. index .. "DispelDebuff" .. i];
        if frame then
            frame:SetAlpha(alpha);
        end
    end
end

local function SetRaidGroupDispelIconAlpha(alpha)
    for groupIndex = 1, 8 do
        for memberIndex = 1, 5 do
            SetDispelIconAlpha("CompactRaidGroup" .. groupIndex .. "Member", memberIndex, alpha);
        end
    end
end

local function SetDispelIconsSuppressed(suppressed)
    local alpha = suppressed and 0 or 1;
    for i = 1, MAX_RAID_FRAME_INDEX do
        SetDispelIconAlpha("CompactPartyFrameMember", i, alpha);
        SetDispelIconAlpha("CompactArenaFrameMember", i, alpha);
    end
    SetRaidGroupDispelIconAlpha(alpha);
end

local function IsActive()
    return IsActiveBattlefieldArena() and SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled;
end

local function UpdateFrame(frame)
    if frame:IsForbidden() then
        trackedFrames[frame] = nil;
        return;
    end

    if frame.aggroHighlight then
        frame.aggroHighlight:SetAlpha(0);
    end

    local unit = frame.displayedUnit or frame.unit;
    local targetingClassColors = unit and GetTargetingClasses(unit);
    if targetingClassColors and ( #targetingClassColors > 0 ) then
        ShowCustomAggroHighlight(frame, targetingClassColors);
    else
        HideCustomAggroHighlight(frame);
    end
end

local function TrackFrame(frame)
    if frame and ( not frame:IsForbidden() ) then
        trackedFrames[frame] = true;
        if wasActive then
            BuildTargeters();
            UpdateFrame(frame);
        end
    end
end

local function AddExplicitFrames()
    for prefixIndex = 1, #explicitFramePrefixes do
        local prefix = explicitFramePrefixes[prefixIndex];
        for i = 1, MAX_RAID_FRAME_INDEX do
            TrackFrame(_G[prefix .. i]);
        end
    end
end

local function HideAllFrames()
    SetDispelIconsSuppressed(false);
    AddExplicitFrames();
    for frame in pairs(trackedFrames) do
        if frame:IsForbidden() then
            trackedFrames[frame] = nil;
        else
            if frame.aggroHighlight then
                frame.aggroHighlight:SetAlpha(1);
            end
            HideCustomAggroHighlight(frame);
        end
    end
end

local function UpdateAllFrames()
    SetDispelIconsSuppressed(true);
    AddExplicitFrames();
    BuildTargeters();

    for frame in pairs(trackedFrames) do
        UpdateFrame(frame);
    end
end

function SweepyBoop:RefreshRaidFrameAggroHighlight()
    if IsActive() then
        wasActive = true;
        UpdateAllFrames();
    elseif wasActive then
        HideAllFrames();
        wasActive = false;
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    hooksecurefunc("CompactUnitFrame_UpdateAll", function (frame)
        local name = frame and frame.GetName and frame:GetName();
        if name and string.find(name, "^Compact") then -- CompactPartyFrameMemberN, CompactRaidFrameN, CompactArenaFrameMemberN, ...
            TrackFrame(frame);
        end
    end)

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    if addon.PROJECT_MAINLINE then -- Between solo shuffle rounds (retail only)
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    end
    eventFrame:RegisterEvent(addon.UNIT_TARGET);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED); -- For cases when stealthy classes appear (we need to run an update before they change target)
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        if not IsActive() then
            if wasActive then
                HideAllFrames();
                wasActive = false;
            end
            return;
        end

        wasActive = true;
        if ( event ~= addon.UNIT_TARGET ) or IsTrackedUnitTarget(unitId) then
            UpdateAllFrames();
        end
    end);
end
