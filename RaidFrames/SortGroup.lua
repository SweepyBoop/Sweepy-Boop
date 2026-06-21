local _, addon = ...;

local MAX_PARTY_FRAMES = 5;
local SECURE_MANAGER_NAME = "SweepyBoopArenaSortSecureManager";
local SECURE_RUN_STATE = "state-sweepy-arena-sort";
local sortPending = false;
local manager;
local memberHeader;

local function IsArenaInstance()
    return IsActiveBattlefieldArena() or ( select(2, IsInInstance()) == "arena" );
end

local function IsEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive and EditModeManagerFrame:IsEditModeActive();
end

local function IsSortEnabled()
    return addon.PROJECT_MAINLINE
        and SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder ~= addon.RAID_FRAME_SORT_ORDER.DISABLED
        and IsArenaInstance()
        and IsInGroup()
        and CompactPartyFrame
        and ( not IsEditModeActive() );
end

local function UnitSortWeight(unit)
    if unit == "player" then
        return 0;
    end

    local partyIndex = unit and string.match(unit, "^party(%d+)$");
    if partyIndex then
        return tonumber(partyIndex);
    end

    return 100 + ( unit and tonumber(string.match(unit, "%d+")) or 0 );
end

local function InsertUnit(units, unit)
    if not unit then return end
    for i = 1, #units do
        if units[i] == unit then
            return;
        end
    end
    units[#units + 1] = unit;
end

local function NormalizeFrameUnit(frame)
    local unit = frame and ( frame.displayedUnit or frame.unit or frame:GetAttribute("unit") );
    if not unit then return nil end

    if unit == "player" then return "player" end
    for i = 1, MAX_PARTY_FRAMES - 1 do
        local partyUnit = "party" .. i;
        if ( unit == partyUnit ) or addon.UnitIsUnitSecretValueSafe(unit, partyUnit) then
            return partyUnit;
        end
    end
    if addon.UnitIsUnitSecretValueSafe(unit, "player") then
        return "player";
    end

    return nil;
end

local function BuildSortedUnits()
    local playerUnit;
    local otherUnits = {};

    for i = 1, MAX_PARTY_FRAMES do
        local frame = _G["CompactPartyFrameMember" .. i];
        local unit = NormalizeFrameUnit(frame);
        if unit == "player" then
            playerUnit = "player";
        elseif unit then
            InsertUnit(otherUnits, unit);
        end
    end

    if not playerUnit then
        playerUnit = "player";
    end

    table.sort(otherUnits, function(left, right)
        return UnitSortWeight(left) < UnitSortWeight(right);
    end);

    local sortOrder = SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder;
    local sorted = {};

    if sortOrder == addon.RAID_FRAME_SORT_ORDER.PLAYER_BOTTOM then
        for i = 1, #otherUnits do sorted[#sorted + 1] = otherUnits[i] end
        sorted[#sorted + 1] = playerUnit;
    elseif sortOrder == addon.RAID_FRAME_SORT_ORDER.PLAYER_MID then
        local insertAfter = math.floor(#otherUnits / 2);
        for i = 1, #otherUnits do
            if i == insertAfter + 1 then
                sorted[#sorted + 1] = playerUnit;
            end
            sorted[#sorted + 1] = otherUnits[i];
        end
        if #otherUnits == insertAfter then
            sorted[#sorted + 1] = playerUnit;
        end
    else
        sorted[#sorted + 1] = playerUnit;
        for i = 1, #otherUnits do sorted[#sorted + 1] = otherUnits[i] end
    end

    return sorted;
end

local function ClearLoadedUnits()
    if not manager then return end
    for i = 1, MAX_PARTY_FRAMES do
        manager:SetAttribute("Unit" .. i, nil);
    end
    manager:SetAttribute("UnitCount", 0);
end

local function LoadUnitOrder()
    if not manager then return end

    local sorted = IsSortEnabled() and BuildSortedUnits() or {};
    for i = 1, MAX_PARTY_FRAMES do
        manager:SetAttribute("Unit" .. i, sorted[i]);
    end
    manager:SetAttribute("UnitCount", #sorted);
    manager:SetAttribute("Enabled", #sorted > 0);
end

local function LoadFrameRefs()
    if not manager or InCombatLockdown() then
        sortPending = true;
        return;
    end

    manager:SetFrameRef("Container", CompactPartyFrame);
    for i = 1, MAX_PARTY_FRAMES do
        manager:SetFrameRef("Member" .. i, _G["CompactPartyFrameMember" .. i]);
    end

    local titleHeight = 0;
    if CompactPartyFrameTitle and CompactPartyFrameTitle.GetHeight then
        titleHeight = CompactPartyFrameTitle:GetHeight() or 0;
    elseif CompactPartyFrame.title and CompactPartyFrame.title.GetHeight then
        titleHeight = CompactPartyFrame.title:GetHeight() or 0;
    end
    manager:SetAttribute("StartYOffset", -titleHeight);
end

local function RunSecureSort()
    if not manager then return end
    manager:SetAttribute(SECURE_RUN_STATE, "manual" .. tostring(GetTime()));
end

local function DisableSecureSort()
    ClearLoadedUnits();
    if manager then
        manager:SetAttribute("Enabled", false);
    end
end

local secureSortSnippet = [=[
    if not self:GetAttribute("Enabled") then return end

    local container = self:GetFrameRef("Container")
    if not container then return end

    local desired = newtable()
    local count = self:GetAttribute("UnitCount") or 0
    for i = 1, count do
        local unit = self:GetAttribute("Unit" .. i)
        if unit then
            desired[#desired + 1] = unit
        end
    end
    if #desired == 0 then return end

    local framesByUnit = newtable()
    local leftovers = newtable()
    for i = 1, 5 do
        local frame = self:GetFrameRef("Member" .. i)
        if frame then
            local unit = frame:GetAttribute("unit")
            if unit then
                unit = string.lower(unit)
                if unit == "player" or string.match(unit, "^party%d+$") then
                    framesByUnit[unit] = frame
                else
                    leftovers[#leftovers + 1] = frame
                end
            else
                leftovers[#leftovers + 1] = frame
            end
        end
    end

    local ordered = newtable()
    local used = newtable()
    for i = 1, #desired do
        local frame = framesByUnit[desired[i]]
        if frame then
            ordered[#ordered + 1] = frame
            used[frame] = true
        end
    end
    for i = 1, #leftovers do
        local frame = leftovers[i]
        if frame and not used[frame] then
            ordered[#ordered + 1] = frame
        end
    end

    local y = self:GetAttribute("StartYOffset") or 0
    for i = 1, #ordered do
        local frame = ordered[i]
        if frame and frame.ClearAllPoints and frame.SetPoint and frame.GetHeight then
            frame:ClearAllPoints()
            frame:SetPoint("TOP", "$parent", "TOP", 0, y)
            y = y - (frame:GetHeight() or 0)
        end
    end
]=];

local function ConfigureSecureHeader(header)
    header:SetAttribute("showParty", true);
    header:SetAttribute("showPlayer", true);
    header:SetAttribute("showSolo", false);
    header:SetAttribute("showRaid", false);
    header:SetAttribute("template", "SecureHandlerAttributeTemplate");
    header:SetAttribute("initialConfigFunction", [=[
        self:SetWidth(0)
        self:SetHeight(0)
        self:SetAttribute("refreshUnitChange", [[
            local manager = _G["SweepyBoopArenaSortSecureManager"]
            if manager then
                manager:SetAttribute("state-sweepy-arena-sort", "group")
            end
        ]])
    ]=]);
    header:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
    header:Show();
end

local function EnsureSecureSorter()
    if manager then return end

    manager = CreateFrame("Frame", SECURE_MANAGER_NAME, UIParent, "SecureHandlerStateTemplate");
    manager:SetAttribute("_onstate-sweepy-arena-sort", secureSortSnippet);
    RegisterAttributeDriver(manager, SECURE_RUN_STATE, "[group] grouped; ungrouped;");

    memberHeader = CreateFrame("Frame", nil, UIParent, "SecureGroupHeaderTemplate");
    ConfigureSecureHeader(memberHeader);
end

local function ApplySort()
    EnsureSecureSorter();

    if not IsSortEnabled() then
        DisableSecureSort();
        return;
    end

    LoadUnitOrder();
    LoadFrameRefs();
    RunSecureSort();
    sortPending = false;
end

function SweepyBoop:RefreshArenaRaidFrameSort()
    ApplySort();
end

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
eventFrame:RegisterEvent(addon.UNIT_PET);
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
eventFrame:SetScript("OnEvent", function (_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        EnsureSecureSorter();
        LoadUnitOrder();
        if not InCombatLockdown() then
            LoadFrameRefs();
        end
        RunSecureSort();
    elseif event == "PLAYER_REGEN_ENABLED" then
        ApplySort();
    else
        ApplySort();
    end
end);
