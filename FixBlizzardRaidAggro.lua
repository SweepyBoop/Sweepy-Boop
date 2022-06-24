-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight"
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

local isTestMode = false;

local IsUnitArena = function(unitId)
    -- Test mode: target yourself and check if the aggro highlight is shown
    if isTestMode then return unitId == "player" end

    for i = 1,3 do
        if (unitId == "arena"..i) then
            return true;
        end
    end
end

local eventHandler = function(frame, event, unitTarget)
    if (event == "PLAYER_ENTERING_WORLD") then
        -- Upon entering a new zone, clear the aggro
        for i = 1, 10 do
            local frame = _G["CompactRaidFrame"..i];
            if (not frame) or frame.optionTable.displayAggroHighlight then return end
            frame.aggroHighlight:Hide();
        end
    elseif (event == "UNIT_TARGET") and IsUnitArena(unitTarget) then
        local aggro = {};
        local guidAggro;
        
        for i = 1, 3 do
            local guidTarget = UnitGUID("arena"..i.."target");
            if guidTarget then
                aggro[guidTarget] = 1 + (aggro[guidTarget] or 0);
                if (aggro[guidTarget] > 1) then
                    guidAggro = guidTarget;
                end
            end
        end
        
        if isTestMode then
            guidAggro = UnitGUID(unitTarget.."target");
        end
        
        for i = 1, 10 do
            local frame = _G["CompactRaidFrame"..i];
            if (not frame) or frame.optionTable.displayAggroHighlight then return end
            
            local showAggro = false;
            if frame.unit and UnitGUID(frame.unit) == guidAggro then
                showAggro = true;
            end
            
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
frame:RegisterEvent("UNIT_TARGET");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:SetScript("OnEvent", eventHandler);

