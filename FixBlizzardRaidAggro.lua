local _, NS = ...;

local GetSpecialization = GetSpecialization;
local GetSpecializationInfo = GetSpecializationInfo;
local GetArenaOpponentSpec = GetArenaOpponentSpec;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local UnitGUID = UnitGUID;
local IsActiveBattlefieldArena = IsActiveBattlefieldArena;
local GetThreatStatusColor = GetThreatStatusColor;
local CreateFrame = CreateFrame;
local hooksecurefunc = hooksecurefunc;
local UnitIsUnit = UnitIsUnit;
local CompactPartyFrame = CompactPartyFrame;

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

-- Test mode: target a raid frame and check if the aggro highlight is showing up
local isTestMode = NS.isTestMode;

local arenaRoles = {};

-- Make sure to only pass "player", "arena".. 1~3
local function GetArenaRole(unitId)
    if ( not arenaRoles[unitId] ) then
        if ( unitId == "player" ) then
            local currentSpec = GetSpecialization();
            arenaRoles[unitId] = select(5, GetSpecializationInfo(currentSpec));
        else
            local arenaIndex = string.sub(unitId, -1, -1);
            local specID = GetArenaOpponentSpec(arenaIndex);
            if specID then
                arenaRoles[unitId] = select(5, GetSpecializationInfoByID(specID));
            end
        end
    end

    return arenaRoles[unitId];
end

local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
refreshFrame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
refreshFrame:SetScript("OnEvent", function ()
    arenaRoles = {};
end)

local function ShouldShowAggro(unit)
    local arena = IsActiveBattlefieldArena();
    if ( not arena ) and ( not isTestMode ) then
        return false;
    end

    if isTestMode then
        if ( GetArenaRole("player") == "DAMAGER" ) then
            return UnitIsUnit(unit, "target");
        end
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            if UnitIsUnit(unit, "arena" .. i .. "target") and ( GetArenaRole("arena" .. i) == "DAMAGER" ) then
                return true;
            end
        end
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    if self.db.profile.raidFrameAggroHighlightEnabled then
        hooksecurefunc("CompactUnitFrame_UpdateName", function (frame)
            if ( not frame ) or frame:IsForbidden() then
                return;
            end

            if ( frame:GetParent() ~= CompactPartyFrame ) then
                return;
            end

            if frame.optionTable.displayAggroHighlight then
                return;
            end

            if ShouldShowAggro(frame.unit) then
                frame.aggroHighlight:SetVertexColor(GetThreatStatusColor(3)); -- red
                frame.aggroHighlight:Show();
            else
                frame.aggroHighlight:Hide();
            end
        end)
    end
end
