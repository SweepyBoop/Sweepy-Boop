local _, addon = ...;

local framePrefix = ( C_AddOns.IsAddOnLoaded("ElvUI") and "ElvUF_PartyGroup1UnitButton" ) or "CompactPartyFrameMember";

local ICON_ATLAS = "groupfinder-icon-friend";
local ICON_SIZE = 12;
local ICON_SPACING = 1;
local ICON_ALPHA = 0.9;
local MAX_RAID_FRAME_INDEX = addon.MAX_ARENA_SIZE * 2; -- players plus pets

local targeters = {};
local classColors = {};

local function AddTargeter(unit)
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
    });
end

local function BuildTargeters()
    wipe(targeters);
    AddTargeter("player");
    for i = 1, addon.MAX_ARENA_SIZE do
        AddTargeter("arena" .. i);
        AddTargeter("party" .. i);
    end
end

local function AddTargetingClassForFrame(classColors, frameUnit, targeter)
    if addon.UnitIsProbablyUnit(targeter.target, frameUnit) then
        table.insert(classColors, targeter.color);
    end
end

local function GetTargetingClasses(frameUnit)
    wipe(classColors);

    for i = 1, #targeters do
        AddTargetingClassForFrame(classColors, frameUnit, targeters[i]);
    end

    return classColors;
end

local function EnsureTargetIcon(container, index)
    if container.icons[index] then
        return container.icons[index];
    end

    local icon = container:CreateTexture(nil, "OVERLAY");
    icon:SetAtlas(ICON_ATLAS);
    icon:SetSize(ICON_SIZE, ICON_SIZE);
    container.icons[index] = icon;
    return icon;
end

local function ShowCustomAggroHighlight(frame, classColors)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetPoint("TOP", frame, "TOP", 0, -1);
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
        icon:SetPoint("LEFT", container, "LEFT", ( i - 1 ) * ( ICON_SIZE + ICON_SPACING ), 0);
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

function SweepyBoop:SetupRaidFrameAggroHighlight()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    if addon.PROJECT_MAINLINE then -- Between solo shuffle rounds (retail only)
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    end
    eventFrame:RegisterEvent(addon.UNIT_TARGET);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED); -- For cases when stealthy classes appear (we need to run an update before they change target)
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        local shouldUpdate, hideAll;

        if ( not IsActiveBattlefieldArena() ) or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled ) then -- not in arena or feature disabled
            hideAll = true;
        else
            if event == addon.UNIT_TARGET then
                shouldUpdate = ( unitId == "player" ) or ( unitId == "party1" ) or ( unitId == "party2" ) or ( unitId == "party3" ) or ( unitId == "party4" )
                    or ( unitId == "arena1" ) or ( unitId == "arena2" ) or ( unitId == "arena3" ) or ( unitId == "arena4" ) or ( unitId == "arena5" );
            else
                shouldUpdate = true;
            end
        end

        if hideAll then
            for i = 1, MAX_RAID_FRAME_INDEX do
                local frame = _G[framePrefix .. i];
                if frame then
                    if frame.aggroHighlight then
                        frame.aggroHighlight:SetAlpha(1);
                    end
                    HideCustomAggroHighlight(frame);
                end
            end
        elseif shouldUpdate then
            BuildTargeters();
            for i = 1, MAX_RAID_FRAME_INDEX do
                local frame = _G[framePrefix .. i];
                if frame then
                    if frame.aggroHighlight then
                        frame.aggroHighlight:SetAlpha(0);
                    end

                    local unit = frame.unit;
                    local classColors = unit and GetTargetingClasses(unit);
                    if classColors and ( #classColors > 0 ) then
                        ShowCustomAggroHighlight(frame, classColors);
                    else
                        HideCustomAggroHighlight(frame);
                    end
                end
            end
        end
    end);
end
