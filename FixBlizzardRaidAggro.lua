local _, NS = ...;

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

-- Test mode: target a raid frame and check if the aggro highlight is showing up
local isTestMode = NS.isTestMode;

-- For raid frames inside arena, checking the first 10 should be more than enough to cover part members (players and pets)
local MAX_ARENAOPPONENT_SIZE = 3;
local MAX_RAIDAGGRO_SIZE = 10;

local function shouldClearAggro(event)
    return (event == NS.PLAYER_ENTERING_WORLD) or (event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
end

local IsUnitArena = function(unitId)
    if isTestMode then return unitId == "player" end

    for i = 1, MAX_ARENAOPPONENT_SIZE do
        if (unitId == "arena"..i) then
            return true;
        end
    end
end

local function getAggroUnitGUID()
    if isTestMode then
        return UnitGUID("playertarget");
    end

    local unitAggro = {};

    for i = 1, MAX_ARENAOPPONENT_SIZE do
        local guidTarget = UnitGUID("arena"..i.."target");
        if guidTarget then
            unitAggro[guidTarget] = 1 + (unitAggro[guidTarget] or 0);
            if (unitAggro[guidTarget] > 1) then
                return guidTarget;
            end
        end
    end
end

local eventHandler = function(frame, event, unitTarget)
    if shouldClearAggro(event) then
        -- Upon entering a new zone, clear the aggro highlight
        for i = 1, MAX_RAIDAGGRO_SIZE do
            local frame = _G["CompactRaidFrame"..i];
            if (not frame) or frame.optionTable.displayAggroHighlight then return end
            frame.aggroHighlight:Hide();
        end
    elseif (event == "UNIT_TARGET") and IsUnitArena(unitTarget) then
        local aggroUnitGUID = getAggroUnitGUID();
        
        for i = 1, MAX_RAIDAGGRO_SIZE do
            local frame = _G["CompactRaidFrame"..i];
            if (not frame) or frame.optionTable.displayAggroHighlight then return end
            
            local showAggro = frame.unit and (UnitGUID(frame.unit) == aggroUnitGUID);
            
            if showAggro then
                frame.aggroHighlight:SetVertexColor(GetThreatStatusColor(3)); -- red
                frame.aggroHighlight:Show();
            else
                frame.aggroHighlight:Hide();
            end
        end
    end
end

local frame = CreateFrame("Frame");
frame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
frame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
frame:RegisterEvent("UNIT_TARGET");
frame:SetScript("OnEvent", eventHandler);

