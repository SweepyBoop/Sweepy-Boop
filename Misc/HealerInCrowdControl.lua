local _, addon = ...;

local iconSize = 40;

local frame;
local isInTest = false;

local function EnsureIconFrame()
    if ( not frame ) then
        frame = CreateFrame("Frame");
        frame:SetMouseClickEnabled(false);
        frame:SetFrameStrata("HIGH");
        frame:SetSize(iconSize, iconSize);
        
        frame.icon = frame:CreateTexture(nil, "BORDER");
        frame.icon:SetSize(iconSize, iconSize);
        frame.icon:SetAllPoints(frame);

        frame.mask = frame:CreateMaskTexture();
        frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
        frame.mask:SetSize(iconSize, iconSize);
        frame.mask:SetAllPoints(frame.icon);
        frame.icon:AddMaskTexture(frame.mask);

        frame.border = frame:CreateTexture(nil, "OVERLAY");
        frame.border:SetAtlas("Azerite-Trait-RingGlow");
        frame.border:SetSize(iconSize * 1.25, iconSize * 1.25);
        frame.border:SetPoint("CENTER", frame, "CENTER");
    end

    if ( not frame.lastModified ) or ( frame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
        local config = SweepyBoop.db.profile.misc;
        frame:SetScale(config.healerInCrowdControlSize / iconSize);
        frame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX, config.healerInCrowdControlOffsetY);

        frame.lastModified = SweepyBoop.db.profile.misc.lastModified;
    end
end

local function ShowIcon(iconID, duration)
    EnsureIconFrame();
    frame.icon:SetTexture(iconID);
    frame:Show();
end

function SweepyBoop:TestHealerInCrowdControl()
    ShowIcon(addon.ICON_PATH("spell_nature_polymorph"), 60);
    isInTest = true;
end

function SweepyBoop:HideTestHealerInCrowdControl()
    frame:Hide();
    isInTest = false;
end
