local _, NS = ...

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

-- Test mode: target a raid frame and check if the aggro highlight is showing up
local isTestMode = false

local arenaRoles = {}

local function shouldClearAggro(event)
    return (event == NS.PLAYER_ENTERING_WORLD) or (event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
end

local IsUnitArena = function(unitId)
    if isTestMode then
        if ( unitId == "player" ) then
            if ( arenaRoles["player"] == nil ) then
                local currentSpec = GetSpecialization()
                arenaRoles["player"] = select(5, GetSpecializationInfo(currentSpec))
            end

            return arenaRoles["player"] == "DAMAGER"
        end
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            if (unitId == "arena"..i) then
                if ( arenaRoles[i] == nil ) then
                    local specID = GetArenaOpponentSpec(i)
                    arenaRoles[i] = select(5, GetSpecializationInfoByID(specID))
                end

                return arenaRoles[i] == "DAMAGER"
            end
        end
    end
end

local function calculateAggro(aggro)
    aggro = {}

    if isTestMode then
        if arenaRoles["player"] ~= "DAMAGER" then return end
        local guid = UnitGUID("playertarget")
        if guid then
            aggro[guid] = 1
        end
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            if arenaRoles[i] == "DAMAGER" then
                local guidTarget = UnitGUID("arena" .. i .. "target")
                if guidTarget then
                    aggro[guidTarget] = true
                end
            end
        end
    end

    return aggro
end

local eventHandler = function(frame, event, unitTarget)
    if shouldClearAggro(event) then
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

        local aggro = calculateAggro(aggro)
        
        for i = 1, NS.MAX_PARTY_SIZE do
            local frame = _G["CompactPartyFrameMember"..i]
            -- Check if the user has Blizzard default highlight on
            if frame and frame.optionTable.displayAggroHighlight then return end

            if frame then
                local guid = UnitGUID(frame.unit)
            
                -- 1: 1.00, 1.00, 0.47 (yellow)
                -- 2: 1.00, 0.60, 0.00 (orange)
                -- 3: 1.00, 0.00, 0.00 (red)
                if guid and aggro[guid] then
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
frame:SetScript("OnEvent", eventHandler)

