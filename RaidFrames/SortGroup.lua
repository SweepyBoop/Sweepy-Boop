-- Minimal arena-only Blizzard compact party frame sorting.
-- Hidden secure headers observe party and pet unit changes; restricted snippets
-- perform the protected frame movement.

local _, addon = ...;

local manager;
local memberHeader;
local petHeader;
local sortPending = false;

local MODE_TOP = "Top";
local MODE_BOTTOM = "Bottom";
local MODE_MIDDLE = "Middle";

local secureMethods = {};

secureMethods.SortParty = [=[
    if not self:GetAttribute("Enabled") then
        return false
    end

    local partyFrame = self:GetFrameRef("PartyFrame")
    if not partyFrame or not partyFrame.GetChildList or not partyFrame:IsVisible() then
        return false
    end

    local mode = self:GetAttribute("SortMode") or "Middle"
    local playerUnit = self:GetAttribute("PlayerUnit") or "player"

    local children = newtable()
    local entries = newtable()
    partyFrame:GetChildList(children)

    for _, child in ipairs(children) do
        local unit = child and child.GetAttribute and child:GetAttribute("unit")
        local name = child and child.GetName and child:GetName()

        if unit and name and strmatch(name, "^CompactPartyFrameMember") and child.GetHeight and child:GetHeight() > 0 then
            local entry = newtable()
            entry.Frame = child
            entry.Unit = unit
            entry.IsPet = strfind(unit, "pet") ~= nil
            entry.IsPlayer = unit == "player" or unit == playerUnit

            if entry.IsPlayer then
                entry.Index = 0
            else
                local index = strmatch(unit, "^party(%d+)")
                    or strmatch(unit, "^raid(%d+)")
                    or strmatch(unit, "^partypet(%d+)")
                    or strmatch(unit, "^raidpet(%d+)")
                    or strmatch(unit, "^party(%d+)pet")
                    or strmatch(unit, "^raid(%d+)pet")
                entry.Index = tonumber(index) or 998
            end

            entries[#entries + 1] = entry
        end
    end

    if #entries <= 1 then
        return false
    end

    for i = 2, #entries do
        local current = entries[i]
        local insertPos = i - 1

        while insertPos >= 1 do
            local previous = entries[insertPos]
            local currentBeforePrevious = false

            if current.Unit ~= previous.Unit then
                if current.IsPet ~= previous.IsPet then
                    currentBeforePrevious = not current.IsPet
                elseif current.IsPlayer ~= previous.IsPlayer then
                    if mode == "Bottom" then
                        currentBeforePrevious = previous.IsPlayer
                    elseif mode == "Middle" then
                        if current.IsPlayer then
                            currentBeforePrevious = previous.Index > 1
                        else
                            currentBeforePrevious = current.Index <= 1
                        end
                    else
                        currentBeforePrevious = current.IsPlayer
                    end
                elseif current.Index ~= previous.Index then
                    currentBeforePrevious = current.Index < previous.Index
                else
                    currentBeforePrevious = (current.Unit or "") < (previous.Unit or "")
                end
            end

            if currentBeforePrevious then
                entries[insertPos + 1] = previous
                insertPos = insertPos - 1
            else
                break
            end
        end

        entries[insertPos + 1] = current
    end

    local yOffset = -(self:GetAttribute("TitleHeight") or 0)

    for _, entry in ipairs(entries) do
        local frame = entry.Frame
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 0, yOffset)
        yOffset = yOffset - frame:GetHeight()
    end

    return true
]=];

local function SetAttributeNoHandler(frame, name, value)
    if frame.SetAttributeNoHandler then
        frame:SetAttributeNoHandler(name, value);
    else
        frame:SetAttribute(name, value);
    end
end

local function EnsureSecureHelpers(frame)
    if not frame.Execute and SecureHandlerExecute then
        function frame:Execute(body)
            return SecureHandlerExecute(self, body);
        end
    end

    if not frame.SetFrameRef and SecureHandlerSetFrameRef then
        function frame:SetFrameRef(label, refFrame)
            return SecureHandlerSetFrameRef(self, label, refFrame);
        end
    end
end

local function ConfigureHeader(header)
    EnsureSecureHelpers(header);

    header:SetAttribute("showRaid", true);
    header:SetAttribute("showParty", true);
    header:SetAttribute("showPlayer", true);
    header:SetAttribute("showSolo", true);
    header:SetAttribute("template", "SecureHandlerAttributeTemplate");
    header:SetAttribute("initialConfigFunction", [=[
        UnitButtonsCount = (UnitButtonsCount or 0) + 1

        self:SetWidth(0)
        self:SetHeight(0)
        self:SetID(UnitButtonsCount)
        self:SetAttribute("Manager", Manager)
        self:SetAttribute("refreshUnitChange", [[
            local manager = self:GetAttribute("Manager")
            if manager then
                manager:SetAttribute("state-sweepyboop-sort-run", "ignore")
            end
        ]])
    ]=]);

    header:SetFrameRef("Manager", manager);
    header:Execute([[ Manager = self:GetFrameRef("Manager") ]]);
    header:SetPoint("TOPLEFT", UIParent, "TOPLEFT");
    header:Show();
end

local function EnsureSecureFrames()
    if manager then
        return true;
    end

    if InCombatLockdown() then
        sortPending = true;
        return false;
    end

    manager = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate");
    EnsureSecureHelpers(manager);

    if not manager.Execute or not manager.SetFrameRef then
        manager = nil;
        return false;
    end

    for name, snippet in pairs(secureMethods) do
        SetAttributeNoHandler(manager, name, snippet);
    end

    manager:SetAttribute("_onstate-sweepyboop-sort-run", [[
        if newstate == "ignore" then
            return
        end

        local run = control or self
        run:RunAttribute("SortParty")
    ]]);

    RegisterAttributeDriver(manager, "state-sweepyboop-sort-run", "[pet] pet; nopet;");

    memberHeader = CreateFrame("Frame", nil, UIParent, "SecureGroupHeaderTemplate");
    petHeader = CreateFrame("Frame", nil, UIParent, "SecureGroupPetHeaderTemplate");

    ConfigureHeader(memberHeader);
    ConfigureHeader(petHeader);

    return true;
end

local function IsArena()
    if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then
        return true;
    end

    local _, instanceType = IsInInstance();
    return instanceType == "arena";
end

local function SortingEnabled()
    return SweepyBoop
        and SweepyBoop.db
        and SweepyBoop.db.profile
        and SweepyBoop.db.profile.raidFrames
        and SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder ~= addon.RAID_FRAME_SORT_ORDER.DISABLED;
end

local function CurrentSortMode()
    local order = SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder;

    if order == addon.RAID_FRAME_SORT_ORDER.PLAYER_TOP then
        return MODE_TOP;
    elseif order == addon.RAID_FRAME_SORT_ORDER.PLAYER_BOTTOM then
        return MODE_BOTTOM;
    end

    return MODE_MIDDLE;
end

local function CurrentPlayerUnit()
    if UnitExists("player") then
        if IsInRaid() then
            for i = 1, MAX_RAID_MEMBERS do
                local unit = "raid" .. i;
                if UnitIsUnit(unit, "player") then
                    return unit;
                end
            end
        else
            for i = 1, MEMBERS_PER_RAID_GROUP - 1 do
                local unit = "party" .. i;
                if UnitIsUnit(unit, "player") then
                    return unit;
                end
            end
        end
    end

    return "player";
end

local function CurrentTitleHeight()
    local title = CompactPartyFrameTitle or (CompactPartyFrame and CompactPartyFrame.title);
    if not title or not title.GetHeight then
        return 0;
    end

    local ok, height = pcall(title.GetHeight, title);
    if ok and type(height) == "number" then
        return height;
    end

    return 0;
end

local function ConfigureForCurrentState()
    if not manager then
        return false;
    end

    local enabled = SortingEnabled() and IsArena() and IsInGroup() and CompactPartyFrame ~= nil;

    SetAttributeNoHandler(manager, "Enabled", enabled);
    SetAttributeNoHandler(manager, "SortMode", enabled and CurrentSortMode() or nil);
    SetAttributeNoHandler(manager, "PlayerUnit", enabled and CurrentPlayerUnit() or nil);
    SetAttributeNoHandler(manager, "TitleHeight", enabled and CurrentTitleHeight() or 0);

    if CompactPartyFrame then
        manager:SetFrameRef("PartyFrame", CompactPartyFrame);
    end

    return enabled;
end

local function TrySort()
    if not EnsureSecureFrames() then
        return;
    end

    if InCombatLockdown() then
        sortPending = true;
        return;
    end

    local enabled = ConfigureForCurrentState();

    if enabled then
        manager:Execute([[
            local run = control or self
            run:RunAttribute("SortParty")
        ]]);
    end

    sortPending = false;
end

function SweepyBoop:RefreshArenaRaidFrameSort()
    TrySort();
end

local function OnEvent(_, event)
    if event == addon.PLAYER_REGEN_ENABLED and sortPending then
        TrySort();
        return;
    end

    C_Timer.After(0, TrySort);
end

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", OnEvent);
eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
eventFrame:RegisterEvent(addon.UNIT_PET);
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
