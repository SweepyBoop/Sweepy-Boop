local _, NS = ...;

local GetSpecialization = GetSpecialization;
local GetSpecializationInfo = GetSpecializationInfo;
local GetArenaOpponentSpec = GetArenaOpponentSpec;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local UnitGUID = UnitGUID;
local IsActiveBattlefieldArena = IsActiveBattlefieldArena;
local GetThreatStatusColor = GetThreatStatusColor;
local CreateFrame = CreateFrame;

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

-- Test mode: target a raid frame and check if the aggro highlight is showing up
local isTestMode = false;

local arenaRoles = {}

local function ShouldClearAggro(event)
    return (event == NS.PLAYER_ENTERING_WORLD) or (event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
end

local function IsUnitArena(unitId)
    if isTestMode then
        return ( unitId == "player" )
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            if ( unitId == "arena" .. i ) then
                return true
            end
        end
    end
end

-- Make sure to only pass "player", "arena".. 1~3
local function GetArenaRole(unitId)
    if ( not arenaRoles[unitId] ) then
        if ( unitId == "player" ) then
            local currentSpec = GetSpecialization()
            arenaRoles[unitId] = select(5, GetSpecializationInfo(currentSpec))
        else
            local arenaIndex = string.sub(unitId, -1, -1)
            local specID = GetArenaOpponentSpec(arenaIndex)
            if specID then
                arenaRoles[unitId] = select(5, GetSpecializationInfoByID(specID))
            end
        end
    end

    return arenaRoles[unitId]
end

local function CalculateAggro()
    local aggro = {}

    if isTestMode then
        if GetArenaRole("player") ~= "DAMAGER" then return end
        local guid = UnitGUID("playertarget")
        if guid then
            aggro[guid] = true
        end
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            if GetArenaRole("arena" .. i) == "DAMAGER" then
                local guidTarget = UnitGUID("arena" .. i .. "target")
                if guidTarget then
                    aggro[guidTarget] = true
                end
            end
        end
    end

    return aggro
end

local function EventHandler(self, event, unitTarget)
    if ShouldClearAggro(event) then
        -- Upon entering a new zone, clear the aggro highlight
        arenaRoles = {}

        for i = 1, NS.MAX_PARTY_SIZE do
            local frame = _G["CompactPartyFrameMember"..i]
            -- Check if the user has Blizzard default highlight on
            if frame and frame.optionTable.displayAggroHighlight then return end

            if frame and frame.aggroHighlight:IsShown() then
                frame.aggroHighlight:Hide()
            end
        end
    elseif (event == "UNIT_TARGET") and IsUnitArena(unitTarget) then
        -- Only enable highlight inside an arena
        if (not IsActiveBattlefieldArena()) and ( not isTestMode ) then return end

        local aggro = CalculateAggro();

        for i = 1, NS.MAX_PARTY_SIZE do
            local frame = _G["CompactPartyFrameMember"..i]
            -- Check if the user has Blizzard default highlight on
            if frame and frame.optionTable.displayAggroHighlight then return end

            if frame then
                local guid = UnitGUID(frame.unit)

                -- 1: 1.00, 1.00, 0.47 (yellow)
                -- 2: 1.00, 0.60, 0.00 (orange)
                -- 3: 1.00, 0.00, 0.00 (red)
                if aggro and guid and aggro[guid] then
                    frame.aggroHighlight:SetVertexColor(GetThreatStatusColor(3)) -- red
                    frame.aggroHighlight:Show()
                else
                    frame.aggroHighlight:Hide()
                end
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent(NS.PLAYER_ENTERING_WORLD)
frame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
frame:RegisterEvent("UNIT_TARGET")
frame:SetScript("OnEvent", EventHandler)
