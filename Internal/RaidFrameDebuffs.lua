local _, NS = ...;

local centerAura = {}; -- Show an important aura at the center of a raid frame
local topRightAura = {}; -- Show a warning aura to the top right of a raid frame

local function SetupRaidFrame(frame)
    if ( not centerAura[frame] ) then
        local centerSize = 25;
        centerAura[frame] = CreateFrame("Frame", nil, frame, "CompactBuffTemplate");
        centerAura[frame]:SetSize(centerSize, centerSize);
        centerAura[frame]:SetPoint("BOTTOM", frame, "CENTER");
    end

    if ( not topRightAura[frame] ) then
        local topRightSize = 27;
        topRightAura[frame] = CreateFrame("Frame", nil, frame, "CompactBuffTemplate");
        topRightAura[frame]:SetSize(topRightSize, topRightSize);
        topRightAura[frame]:SetPoint("TOPLEFT", frame, "TOPRIGHT");
    end

    return centerAura[frame], topRightAura[frame];
end

local function UpdateRaidFrame(frame)
    local center, topRight = SetupRaidFrame(frame);

    
end

hooksecurefunc("CompactUnitFrame_UpdateAuras", function (frame)
    if (not frame) or frame:IsForbidden() then return end
    if (not UnitIsPlayer(frame.displayedUnit)) then return end

    UpdateRaidFrame(frame);
end)