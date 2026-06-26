-- Minimal arena-only Blizzard compact frame sorting.
-- Imports Blizzard friendly compact containers into a restricted sorter and lets
-- secure snippets perform protected frame movement.

local _, addon = ...;

local manager;
local memberHeader;
local petHeader;
local sortPending = false;
local visibilityWatched = {};

local MODE_TOP = "Top";
local MODE_BOTTOM = "Bottom";
local MODE_MIDDLE = "Middle";

local PROVIDER_NAME = "Blizzard";
local CONTAINER_PARTY = 1;
local CONTAINER_RAID = 2;
local LAYOUT_HARD = 2;

local secureMethods = {};

secureMethods.GetUnit = [[
    local frameVariable = ...
    local frame = _G[frameVariable]

    if not frame then
        return nil, nil
    end

    local unit = frame:GetAttribute("unit")
    if not unit then
        return nil, nil
    end

    unit = strlower(unit)
    local displayUnit = unit
    local n = strmatch(displayUnit, "^party(%d+)pet$")
    if n then
        displayUnit = "partypet" .. n
    else
        n = strmatch(displayUnit, "^raid(%d+)pet$")
        if n then
            displayUnit = "raidpet" .. n
        end
    end

    return displayUnit, unit
]];

secureMethods.ExtractUnitFrames = [[
    local childrenVariable, destinationVariable, visibleOnly = ...
    local children = _G[childrenVariable]

    if not children or not destinationVariable then
        return false
    end

    if visibleOnly == nil then
        visibleOnly = true
    end

    local unitFrames = newtable()

    for _, child in ipairs(children) do
        Frame = child
        local unit = self:RunAttribute("GetUnit", "Frame")
        Frame = nil

        if unit and child.GetRect then
            local left, bottom, width, height = child:GetRect()
            local hasSize = left and bottom and width and height

            if hasSize and (child:IsVisible() or not visibleOnly) then
                unitFrames[#unitFrames + 1] = child
            end
        end
    end

    _G[destinationVariable] = unitFrames
    return #unitFrames > 0
]];

secureMethods.SortFramesByUnits = [[
    local framesVariable, unitsVariable, destinationVariable = ...
    local frames = _G[framesVariable]
    local units = _G[unitsVariable]

    if not frames or not units or not destinationVariable then
        return false
    end

    local framesByUnit = newtable()
    local frameWasSorted = newtable()

    for i = 1, #frames do
        local frame = frames[i]
        Frame = frame
        local unit, token = self:RunAttribute("GetUnit", "Frame")
        Frame = nil

        if unit then
            local existing = framesByUnit[unit]
            if not existing then
                framesByUnit[unit] = frame
            else
                Frame = existing
                local _, existingToken = self:RunAttribute("GetUnit", "Frame")
                Frame = nil

                local isPet = token and strfind(token, "pet") ~= nil
                local existingIsPet = existingToken and strfind(existingToken, "pet") ~= nil
                local keepNew = false

                if existingIsPet and not isPet then
                    keepNew = true
                elseif isPet and not existingIsPet then
                    keepNew = false
                else
                    keepNew = (frame:GetHeight() or 0) > (existing:GetHeight() or 0)
                end

                if keepNew then
                    framesByUnit[unit] = frame
                end
            end
        end
    end

    local sorted = newtable()

    for i = 1, #units do
        local unit = units[i]
        local frame = framesByUnit[unit]

        if frame then
            sorted[#sorted + 1] = frame
            frameWasSorted[frame] = true
        end
    end

    for i = 1, #frames do
        local frame = frames[i]

        if not frameWasSorted[frame] then
            Frame = frame
            local _, token = self:RunAttribute("GetUnit", "Frame")
            Frame = nil

            local isPet = token and strfind(token, "pet") ~= nil
            if not isPet and frame:IsVisible() then
                return false
            end
        end
    end

    for i = 1, #frames do
        local frame = frames[i]
        if not frameWasSorted[frame] then
            sorted[#sorted + 1] = frame
        end
    end

    _G[destinationVariable] = sorted
    return true
]];

secureMethods.CompareFrameGroup = [[
    local leftVariable, rightVariable, playerSortMode = ...
    local leftFrame = _G[leftVariable]
    local rightFrame = _G[rightVariable]

    if not leftFrame or not rightFrame then
        return false
    end

    Frame = leftFrame
    local leftUnit, leftToken = self:RunAttribute("GetUnit", "Frame")
    Frame = rightFrame
    local rightUnit, rightToken = self:RunAttribute("GetUnit", "Frame")
    Frame = nil

    if not leftUnit or not rightUnit then
        return false
    end

    local leftPet = leftToken and strfind(leftToken, "pet") ~= nil
    local rightPet = rightToken and strfind(rightToken, "pet") ~= nil
    if leftPet ~= rightPet then
        return not leftPet
    end

    if playerSortMode and leftUnit == "player" then
        return playerSortMode == "Top"
    end

    if playerSortMode and rightUnit == "player" then
        return playerSortMode == "Bottom"
    end

    local leftIndex = tonumber(strmatch(leftUnit, "%d+")) or 0
    local rightIndex = tonumber(strmatch(rightUnit, "%d+")) or 0
    return leftIndex < rightIndex
]];

secureMethods.Sort = [[
    local arrayName, compareName, extraArg1 = ...
    local array = _G[arrayName]

    if not array or not compareName or #array <= 1 then
        return
    end

    for i = 2, #array do
        local currentValue = array[i]
        local insertPos = i - 1

        while insertPos >= 1 do
            Left = currentValue
            Right = array[insertPos]
            local currentBeforePrevious = self:RunAttribute(compareName, "Left", "Right", extraArg1)

            if currentBeforePrevious then
                array[insertPos + 1] = array[insertPos]
                insertPos = insertPos - 1
            else
                break
            end
        end

        array[insertPos + 1] = currentValue
    end

    Left = nil
    Right = nil
]];

secureMethods.HardArrange = [[
    local framesVariable, containerVariable = ...
    local frames = _G[framesVariable]
    local container = _G[containerVariable]

    if not frames or not container or #frames == 0 then
        return false
    end

    local firstValid = nil
    for _, frame in ipairs(frames) do
        if frame and frame.GetHeight and frame.GetWidth then
            local h = frame:GetHeight()
            local w = frame:GetWidth()
            if h and h > 0 and w and w > 0 then
                firstValid = frame
                break
            end
        end
    end

    if not firstValid then
        return false
    end

    local blockWidth = firstValid:GetWidth()
    local blockHeight = firstValid:GetHeight()
    local horizontal = container.IsHorizontalLayout == true
    local offset = container.Offset or newtable()
    offset.X = offset.X or 0
    offset.Y = offset.Y or 0

    local pointsByFrame = newtable()
    local row = 0
    local col = 0
    local xOffset = offset.X
    local yOffset = offset.Y
    local currentBlockHeight = 0

    for _, frame in ipairs(frames) do
        local height = frame and frame.GetHeight and frame:GetHeight()

        if height and height > 0 then
            local isNewBlock = currentBlockHeight > 0 and (currentBlockHeight >= (blockHeight - 1) or (currentBlockHeight + height) >= (blockHeight + 1))

            if isNewBlock then
                currentBlockHeight = 0

                if horizontal then
                    col = col + 1
                else
                    row = row + 1
                end

                xOffset = col * blockWidth + offset.X
                yOffset = -row * blockHeight + offset.Y
            end

            local point = newtable()
            point.Point = container.AnchorPoint or "TOPLEFT"
            point.RelativePoint = container.AnchorPoint or "TOPLEFT"
            point.XOffset = xOffset
            point.YOffset = yOffset
            pointsByFrame[frame] = point

            currentBlockHeight = currentBlockHeight + height
            yOffset = yOffset - height
        end
    end

    local moved = false
    for _, frame in ipairs(frames) do
        local to = frame and pointsByFrame[frame]

        if to and frame.ClearAllPoints and frame.SetPoint then
            frame:ClearAllPoints()
            frame:SetPoint(to.Point, "$parent", to.RelativePoint, to.XOffset or 0, to.YOffset or 0)
            moved = true
        end
    end

    return moved
]];

secureMethods.LoadUnits = [[
    FriendlyUnits = newtable()
    local friendlyUnitsCount = self:GetAttribute("FriendlyUnitsCount") or 0

    for i = 1, friendlyUnitsCount do
        local unit = self:GetAttribute("FriendlyUnit" .. i)
        if unit then
            FriendlyUnits[#FriendlyUnits + 1] = unit
        end
    end
]];

secureMethods.LoadProvider = [[
    Providers = Providers or newtable()
    local provider = newtable()
    provider.Name = "Blizzard"
    provider.Containers = newtable()
    Providers.Blizzard = provider

    local count = self:GetAttribute("BlizzardContainersCount") or 0
    for i = 1, count do
        local prefix = "BlizzardContainer" .. i
        local container = newtable()
        container.Frame = self:GetFrameRef(prefix .. "Frame")
        container.Type = self:GetAttribute(prefix .. "Type")
        container.LayoutType = self:GetAttribute(prefix .. "LayoutType")
        container.VisibleOnly = self:GetAttribute(prefix .. "VisibleOnly")
        container.IsHorizontalLayout = self:GetAttribute(prefix .. "IsHorizontalLayout")
        container.AnchorPoint = self:GetAttribute(prefix .. "AnchorPoint")

        local offsetX = self:GetAttribute(prefix .. "OffsetX")
        local offsetY = self:GetAttribute(prefix .. "OffsetY")
        if offsetX or offsetY then
            container.Offset = newtable()
            container.Offset.X = offsetX or 0
            container.Offset.Y = offsetY or 0
        end

        provider.Containers[#provider.Containers + 1] = container
    end
]];

secureMethods.TrySortContainer = [[
    local containerVariable = ...
    local container = _G[containerVariable]

    if not container or not container.Frame or not container.Frame:IsVisible() then
        return false
    end

    Children = newtable()
    Frames = newtable()
    container.Frame:GetChildList(Children)

    if not self:RunAttribute("ExtractUnitFrames", "Children", "Frames", container.VisibleOnly) then
        Children = nil
        Frames = nil
        return false
    end

    if not Frames or #Frames <= 1 then
        Children = nil
        Frames = nil
        return false
    end

    SortedFrames = nil
    local couldSort = self:RunAttribute("SortFramesByUnits", "Frames", "FriendlyUnits", "SortedFrames")

    if not couldSort then
        self:RunAttribute("Sort", "Frames", "CompareFrameGroup", self:GetAttribute("FriendlyPlayerSortMode"))
        SortedFrames = Frames
    end

    local sorted = false
    if container.LayoutType == 2 then
        sorted = self:RunAttribute("HardArrange", "SortedFrames", containerVariable)
    end

    SortedFrames = nil
    Children = nil
    Frames = nil
    return sorted
]];

secureMethods.TrySort = [[
    self:SetAttribute("LastSortResult", "start")
    self:SetAttribute("LastEntryCount", 0)

    if not self:GetAttribute("Enabled") then
        self:SetAttribute("LastSortResult", "disabled")
        return false
    end

    if not FriendlyUnits then
        self:RunAttribute("LoadUnits")
    end

    local provider = Providers and Providers.Blizzard
    if not provider or not provider.Containers then
        self:SetAttribute("LastSortResult", "no-provider")
        return false
    end

    local sorted = false
    local attempted = 0

    for _, container in ipairs(provider.Containers) do
        if container and container.Frame and container.Frame:IsVisible() then
            Container = container
            attempted = attempted + 1
            sorted = self:RunAttribute("TrySortContainer", "Container") or sorted
            Container = nil
        end
    end

    self:SetAttribute("LastEntryCount", attempted)
    self:SetAttribute("LastSortResult", sorted and "sorted" or "not-sorted")
    return sorted
]];

secureMethods.Init = [[
    Providers = newtable()
    FriendlyUnits = newtable()
]];

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

    if not frame.WrapScript and SecureHandlerWrapScript then
        function frame:WrapScript(targetFrame, script, preBody, postBody)
            return SecureHandlerWrapScript(targetFrame, script, self, preBody, postBody);
        end
    end

    if not frame.SetFrameRef and SecureHandlerSetFrameRef then
        function frame:SetFrameRef(label, refFrame)
            return SecureHandlerSetFrameRef(self, label, refFrame);
        end
    end
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

local function NormaliseUnit(unit)
    if not unit then
        return nil;
    end

    local partyPet = string.match(unit, "^party(%d+)pet$");
    if partyPet then
        return "partypet" .. partyPet;
    end

    local raidPet = string.match(unit, "^raid(%d+)pet$");
    if raidPet then
        return "raidpet" .. raidPet;
    end

    return unit;
end

local function UnitIndex(unit)
    if not unit then
        return 998;
    end

    local index = string.match(unit, "^party(%d+)")
        or string.match(unit, "^raid(%d+)")
        or string.match(unit, "^partypet(%d+)")
        or string.match(unit, "^raidpet(%d+)");

    return tonumber(index) or 998;
end

local function FrameUnit(frame)
    if not frame then
        return nil;
    end

    local unit = frame.GetAttribute and frame:GetAttribute("unit") or frame.unit;
    return NormaliseUnit(unit);
end

local function FrameEntry(frame)
    local unit = FrameUnit(frame);
    if not unit then
        return nil;
    end

    return {
        frame = frame,
        unit = unit,
        isPet = string.find(unit, "pet") ~= nil,
        isPlayer = UnitIsUnit(unit, "player"),
        index = UnitIndex(unit),
    };
end

local function CompareEntries(left, right)
    if left.isPet ~= right.isPet then
        return not left.isPet;
    end

    if left.isPlayer ~= right.isPlayer then
        local mode = CurrentSortMode();
        if mode == MODE_BOTTOM then
            return right.isPlayer;
        elseif mode == MODE_MIDDLE then
            if left.isPlayer then
                return right.index > 1;
            end

            return left.index <= 1;
        end

        return left.isPlayer;
    end

    if left.index ~= right.index then
        return left.index < right.index;
    end

    return left.unit < right.unit;
end

local function EntriesFromContainer(container)
    if not container or not container.GetChildren then
        return {};
    end

    local entries = {};
    for _, child in ipairs({ container:GetChildren() }) do
        if child and child.IsVisible and child:IsVisible() and child.GetHeight and child:GetHeight() > 0 then
            local entry = FrameEntry(child);
            if entry then
                entries[#entries + 1] = entry;
            end
        end
    end

    return entries;
end

local function CompareGroupOrder(left, right)
    if left.index ~= right.index then
        return left.index < right.index;
    end

    return left.unit < right.unit;
end

local function AddUnit(units, seen, entry)
    if entry and entry.unit and not seen[entry.unit] then
        units[#units + 1] = entry.unit;
        seen[entry.unit] = true;
    end
end

local function SortedFriendlyUnits()
    local members = {};
    local pets = {};
    local playerEntry;

    local function AddEntries(containerEntries)
        for _, entry in ipairs(containerEntries) do
            if entry.isPet then
                pets[#pets + 1] = entry;
            elseif entry.isPlayer then
                playerEntry = playerEntry or entry;
            else
                members[#members + 1] = entry;
            end
        end
    end

    AddEntries(EntriesFromContainer(CompactPartyFrame));
    AddEntries(EntriesFromContainer(CompactRaidFrameContainer));

    table.sort(members, CompareGroupOrder);
    table.sort(pets, CompareGroupOrder);

    local units = {};
    local seen = {};
    local mode = CurrentSortMode();

    if mode == MODE_TOP then
        AddUnit(units, seen, playerEntry);
    end

    local middleInsertIndex;
    if mode == MODE_MIDDLE and playerEntry then
        middleInsertIndex = math.floor(#members / 2) + 1;
    end

    for i, entry in ipairs(members) do
        if middleInsertIndex == i then
            AddUnit(units, seen, playerEntry);
        end

        AddUnit(units, seen, entry);
    end

    if middleInsertIndex and middleInsertIndex > #members then
        AddUnit(units, seen, playerEntry);
    end

    if mode == MODE_BOTTOM then
        AddUnit(units, seen, playerEntry);
    end

    for _, entry in ipairs(pets) do
        AddUnit(units, seen, entry);
    end

    return units;
end

local function CurrentTitleHeight(container)
    local title = (container == CompactPartyFrame and CompactPartyFrameTitle) or (container and container.title);
    if not title or not title.GetHeight then
        return 0;
    end

    local ok, height = pcall(title.GetHeight, title);
    if ok and type(height) == "number" then
        return height;
    end

    return 0;
end

local function CurrentHorizontalLayout()
    if EditModeManagerFrame and Enum and Enum.EditModeSystem and Enum.EditModeUnitFrameSystemIndices and Enum.EditModeUnitFrameSetting then
        local ok, horizontal = pcall(
            EditModeManagerFrame.GetSettingValueBool,
            EditModeManagerFrame,
            Enum.EditModeSystem.UnitFrame,
            Enum.EditModeUnitFrameSystemIndices.Party,
            Enum.EditModeUnitFrameSetting.UseHorizontalGroups
        );

        if ok then
            return horizontal;
        end
    end

    if CompactRaidFrameManager_GetSetting then
        return CompactRaidFrameManager_GetSetting("HorizontalGroups");
    end

    return false;
end

local function LoadFriendlyUnits()
    if not manager then
        return;
    end

    local units = SortedFriendlyUnits();
    for i, unit in ipairs(units) do
        SetAttributeNoHandler(manager, "FriendlyUnit" .. i, unit);
    end

    SetAttributeNoHandler(manager, "FriendlyUnitsCount", #units);
    manager:Execute([[ self:RunAttribute("LoadUnits") ]]);
end

local function AddContainer(containers, frame, containerType)
    if not frame then
        return;
    end

    containers[#containers + 1] = {
        Frame = frame,
        Type = containerType,
        LayoutType = LAYOUT_HARD,
        VisibleOnly = true,
        IsHorizontalLayout = CurrentHorizontalLayout(),
        OffsetX = 0,
        OffsetY = -CurrentTitleHeight(frame),
        AnchorPoint = "TOPLEFT",
    };
end

local function LoadProvider()
    if not manager then
        return;
    end

    local containers = {};
    AddContainer(containers, CompactPartyFrame, CONTAINER_PARTY);
    AddContainer(containers, CompactRaidFrameContainer, CONTAINER_RAID);

    SetAttributeNoHandler(manager, "BlizzardContainersCount", #containers);

    for i, container in ipairs(containers) do
        local prefix = "BlizzardContainer" .. i;
        manager:SetFrameRef(prefix .. "Frame", container.Frame);
        SetAttributeNoHandler(manager, prefix .. "Type", container.Type);
        SetAttributeNoHandler(manager, prefix .. "LayoutType", container.LayoutType);
        SetAttributeNoHandler(manager, prefix .. "VisibleOnly", container.VisibleOnly);
        SetAttributeNoHandler(manager, prefix .. "IsHorizontalLayout", container.IsHorizontalLayout);
        SetAttributeNoHandler(manager, prefix .. "OffsetX", container.OffsetX);
        SetAttributeNoHandler(manager, prefix .. "OffsetY", container.OffsetY);
        SetAttributeNoHandler(manager, prefix .. "AnchorPoint", container.AnchorPoint);
    end

    manager:Execute([[ self:RunAttribute("LoadProvider") ]]);
end

local function LoadSortState()
    if not manager then
        return false;
    end

    local enabled = SortingEnabled() and IsArena() and IsInGroup();

    SetAttributeNoHandler(manager, "Enabled", enabled);
    SetAttributeNoHandler(manager, "FriendlyPlayerSortMode", CurrentSortMode());

    return enabled;
end

local function WatchContainerVisibility(container)
    if not manager or not container or not container.GetChildren then
        return;
    end

    for _, child in ipairs({ container:GetChildren() }) do
        if child and not visibilityWatched[child] and child.GetAttribute and FrameUnit(child) then
            SecureHandlerSetFrameRef(child, "SweepyBoopSortManager", manager);
            SecureHandlerWrapScript(child, "OnShow", manager, [[
                local manager = control
                manager:SetAttribute("state-sweepyboop-sort-run", "ignore")
            ]]);
            SecureHandlerWrapScript(child, "OnHide", manager, [[
                local manager = control
                manager:SetAttribute("state-sweepyboop-sort-run", "ignore")
            ]]);

            visibilityWatched[child] = true;
        end
    end
end

local function WatchVisibility()
    WatchContainerVisibility(CompactPartyFrame);
    WatchContainerVisibility(CompactRaidFrameContainer);
end

local function ConfigureHeader(header)
    EnsureSecureHelpers(header);

    function header:UnitButtonCreated(id)
        if InCombatLockdown() or not id then
            return;
        end

        for _, child in ipairs({ header:GetChildren() }) do
            if child and child.GetID and child:GetID() == id then
                child:SetAttribute("_onattributechanged", [[
                    local manager = self:GetAttribute("Manager")
                    if manager then
                        manager:SetAttribute("state-sweepyboop-sort-run", "ignore")
                    end
                ]]);
                break;
            end
        end
    end

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
        self:SetAttribute("Header", Header)
        self:SetAttribute("refreshUnitChange", [[
            local manager = self:GetAttribute("Manager")
            if manager then
                manager:SetAttribute("state-sweepyboop-sort-run", "ignore")
            end
        ]])

        Header:CallMethod("UnitButtonCreated", UnitButtonsCount)
    ]=]);

    header:SetFrameRef("Manager", manager);
    header:Execute([[
        Header = self
        Manager = self:GetFrameRef("Manager")
    ]]);
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

    manager:Execute([[ self:RunAttribute("Init") ]]);

    manager:SetAttribute("_onstate-sweepyboop-sort-run", [[
        if newstate == "ignore" then
            return
        end

        self:RunAttribute("TrySort")
    ]]);

    RegisterAttributeDriver(manager, "state-sweepyboop-sort-run", "[pet] pet; nopet;");

    memberHeader = CreateFrame("Frame", nil, UIParent, "SecureGroupHeaderTemplate");
    petHeader = CreateFrame("Frame", nil, UIParent, "SecureGroupPetHeaderTemplate");

    ConfigureHeader(memberHeader);
    ConfigureHeader(petHeader);

    return true;
end

local function RunSecureSort()
    if not manager then
        return;
    end

    manager:Execute([[ self:RunAttribute("TrySort") ]]);
end

local function PrepareOutOfCombat()
    if not EnsureSecureFrames() then
        return false;
    end

    local enabled = LoadSortState();
    LoadProvider();
    LoadFriendlyUnits();
    WatchVisibility();

    return enabled;
end

local function TrySort()
    if InCombatLockdown() then
        sortPending = true;
        if manager then
            SetAttributeNoHandler(manager, "LastSortResult", "combat-deferred");
        end
        return;
    end

    if PrepareOutOfCombat() then
        RunSecureSort();
    end

    sortPending = false;
end

local function PrepareForCombat()
    if not manager then
        sortPending = true;
        return;
    end

    LoadSortState();
    LoadProvider();
    LoadFriendlyUnits();
    WatchVisibility();

    if memberHeader then
        memberHeader:UnregisterEvent(addon.GROUP_ROSTER_UPDATE);
        memberHeader:UnregisterEvent("UNIT_NAME_UPDATE");
        memberHeader:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
        memberHeader:RegisterEvent("UNIT_NAME_UPDATE");
    end

    if petHeader then
        petHeader:UnregisterEvent(addon.GROUP_ROSTER_UPDATE);
        petHeader:UnregisterEvent(addon.UNIT_PET);
        petHeader:UnregisterEvent("UNIT_NAME_UPDATE");
        petHeader:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
        petHeader:RegisterEvent(addon.UNIT_PET);
        petHeader:RegisterEvent("UNIT_NAME_UPDATE");
    end
end

function SweepyBoop:RefreshArenaRaidFrameSort()
    TrySort();
end

local function DebugFrameOrder(container)
    if not container or not container.GetChildren then
        return "none";
    end

    local orderedFrames = {};
    for _, child in ipairs({ container:GetChildren() }) do
        if child and child.IsVisible and child:IsVisible() and child.GetTop and child.GetLeft then
            local unit = FrameUnit(child);
            if unit then
                orderedFrames[#orderedFrames + 1] = {
                    name = child.GetName and child:GetName() or "?",
                    unit = unit,
                    top = child:GetTop() or 0,
                    left = child:GetLeft() or 0,
                };
            end
        end
    end

    table.sort(orderedFrames, function(left, right)
        if left.top ~= right.top then
            return left.top > right.top;
        end

        return left.left < right.left;
    end);

    local parts = {};
    for i, entry in ipairs(orderedFrames) do
        parts[#parts + 1] = i .. ":" .. entry.unit .. "(" .. entry.name .. ")";
    end

    return table.concat(parts, " > ");
end

function SweepyBoop:DebugArenaRaidFrameSort()
    local loadedUnits = {};
    if manager then
        local count = manager:GetAttribute("FriendlyUnitsCount") or 0;
        for i = 1, count do
            loadedUnits[#loadedUnits + 1] = tostring(manager:GetAttribute("FriendlyUnit" .. i));
        end
    end

    print(
        "SweepyBoop sort",
        "order=", SweepyBoop.db.profile.raidFrames.arenaRaidFrameSortOrder,
        "arena=", IsArena(),
        "group=", IsInGroup(),
        "combat=", InCombatLockdown(),
        "pending=", sortPending,
        "manager=", manager ~= nil,
        "result=", manager and manager:GetAttribute("LastSortResult") or "none",
        "containers=", manager and manager:GetAttribute("LastEntryCount") or "none",
        "units=", manager and manager:GetAttribute("FriendlyUnitsCount") or "none",
        "cpf=", CompactPartyFrame ~= nil,
        "cpfVisible=", CompactPartyFrame and CompactPartyFrame:IsVisible(),
        "crfc=", CompactRaidFrameContainer ~= nil,
        "crfcVisible=", CompactRaidFrameContainer and CompactRaidFrameContainer:IsVisible()
    );
    print("SweepyBoop loaded units", table.concat(loadedUnits, " > "));
    print("SweepyBoop CPF frames", DebugFrameOrder(CompactPartyFrame));
    print("SweepyBoop CRFC frames", DebugFrameOrder(CompactRaidFrameContainer));
end

local function OnEvent(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        PrepareForCombat();
        return;
    end

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
