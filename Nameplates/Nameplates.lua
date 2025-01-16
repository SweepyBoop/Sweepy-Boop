local _, addon = ...;

local function HideWidgets(nameplate, frame)
    addon.HideClassIcon(nameplate);
    addon.HideNpcHighlight(frame);
    addon.HideSpecIcon(frame);
end

-- Protected nameplates in dungeons and raids
local restricted = {
	party = true,
	raid = true,
};

local function IsRestricted()
    local instanceType = select(2, IsInInstance());
    return restricted[instanceType];
end

local function UpdateWidgets(nameplate, frame)
    -- Class icon mod will hide/show healthBar when showing/hiding class icons
    addon.UpdateClassIcon(nameplate, frame);
    -- Show enemy nameplate highlight
    addon.UpdateNpcHighlight(frame);
    -- Update spec icons
    addon.UpdateSpecIcon(frame);
end

local function UpdateUnitFrameVisibility(frame, show)
    local alpha = ( show and 1 ) or 0;
    frame:SetAlpha(alpha);
    frame.healthBar:SetAlpha(alpha);
    frame.selectionHighlight:SetAlpha(alpha);
    frame.BuffFrame:SetAlpha(alpha);
    frame.castBar:SetAlpha(alpha);
end

local function UpdateVisibility(nameplate, frame)
    if ( not addon.UnitIsHostile(frame.unit) ) then -- Friendly units, show class icon for friendly players and party pets
        local configFriendly = SweepyBoop.db.profile.nameplatesFriendly;
        if configFriendly.classIconsEnabled then
            if configFriendly.hideOutsidePvP and ( not IsActiveBattlefieldArena() ) and ( not C_PvP.IsBattleground() ) then
                addon.HideClassIcon(nameplate);
            elseif UnitIsPlayer(frame.unit) or UnitIsUnit(frame.unit, "pet") or UnitIsUnit(frame.unit, "partypet1") or UnitIsUnit(frame.unit, "partypet2") then
                addon.ShowClassIcon(nameplate);
            end

            UpdateUnitFrameVisibility(frame, false); -- if class icons are enabled, all friendly units' health bars should be hidden
        else
            addon.HideClassIcon(nameplate);
            UpdateUnitFrameVisibility(frame, true); -- Will be overriden by nameplate filter later
        end

        addon.HideSpecIcon(frame);
        addon.HideNpcHighlight(frame);
    else
        addon.HideClassIcon(nameplate);

        if UnitIsPlayer(frame.unit) then
            addon.ShowSpecIcon(frame); -- If no spec is available yet, will show an empty icon
            addon.HideNpcHighlight(frame);
            UpdateUnitFrameVisibility(frame, true); -- Always show enemy players
            return;
        end

        -- Process non-player hostile units
        addon.HideSpecIcon(frame);
        local guid = UnitGUID(frame.unit);
        local npcID = select(6, strsplit("-", guid));
        local option = SweepyBoop.db.profile.nameplatesEnemy.filterList[tostring(npcID)];
        if ( option == addon.NpcOption.Highlight ) then
            addon.ShowNpcHighlight(frame);
        else
            addon.HideNpcHighlight(frame);
        end

        local isWhitelisted = ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) or addon.IsNpcInWhiteList(frame.unit);
        UpdateUnitFrameVisibility(frame, isWhitelisted and ( not addon.UnitIsHunterSecondaryPet(frame.unit) ) );
    end
end

function SweepyBoop:SetupNameplateModules()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_REMOVED);
    eventFrame:RegisterEvent(addon.UPDATE_BATTLEFIELD_SCORE);
    eventFrame:RegisterEvent(addon.UNIT_FACTION);
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        if event == addon.NAME_PLATE_UNIT_ADDED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate, nameplate.UnitFrame);
                UpdateWidgets(nameplate, nameplate.UnitFrame);
                UpdateVisibility(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.NAME_PLATE_UNIT_REMOVED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.UPDATE_BATTLEFIELD_SCORE then
            local nameplates = C_NamePlate.GetNamePlates();
            for i = 1, #(nameplates) do
                local nameplate = nameplates[i];
                if nameplate and nameplate.UnitFrame then
                    if nameplate.UnitFrame:IsForbidden() then return end
                    addon.UpdateSpecIcon(nameplate.UnitFrame);
                end
            end
        elseif event == addon.UNIT_FACTION then -- This is triggered for Mind Control
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                UpdateVisibility(nameplate, nameplate.UnitFrame);
            end
        end
    end)

    -- When flag is picked up / dropped
    hooksecurefunc("CompactUnitFrame_UpdateClassificationIndicator", function (frame)
        if frame:IsForbidden() then return end

        if frame.unit and string.sub(frame.unit, 1, 9) == "nameplate" then
            addon.UpdateClassIcon(frame:GetParent(), frame);
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then return end

        if IsActiveBattlefieldArena and SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then
            for i = 1, 3 do
                if UnitIsUnit(frame.unit, "arena" .. i) then
                    frame.name:SetText(i);
                    frame.name:SetTextColor(1,1,0); --Yellow
                    return;
                end
            end
        end

        if frame.unit and string.sub(frame.unit, 1, 9) == "nameplate" then
            addon.UpdateTargetHighlight(frame:GetParent(), frame);
        end
    end)
end

function SweepyBoop:RefreshAllNamePlates()
    if IsRestricted() then return end

    local nameplates = C_NamePlate.GetNamePlates(true); -- isSecure = true to return nameplates in instances (to hide widgets)
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            if nameplate.UnitFrame:IsForbidden() then return end
            UpdateWidgets(nameplate, nameplate.UnitFrame);
            UpdateVisibility(nameplate, nameplate.UnitFrame);
        end
    end
end
