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
    -- Force frame's child elements to not ignore parent alpha
    if ( not frame.forceChildrenFollowAlpha ) then
        for _, region in pairs(frame) do
            if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                region:SetIgnoreParentAlpha(false);
            end
        end
        for _, region in pairs(frame.castBar) do
            if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                region:SetIgnoreParentAlpha(false);
            end
        end
        frame.forceChildrenFollowAlpha = true;
    end

    local alpha = ( show and 1 ) or 0;
    frame:SetAlpha(alpha);
    frame.castBar:SetAlpha(alpha);
end

local function UpdateVisibility(nameplate, frame)
    -- Issue: after priest mind control, party member shows both class icon and health bar

    if ( not addon.UnitIsHostile(frame.unit) ) then -- Friendly units, show class icon for friendly players and party pets
        local configFriendly = SweepyBoop.db.profile.nameplatesFriendly;
        if configFriendly.classIconsEnabled then
            if configFriendly.hideOutsidePvP and ( not IsActiveBattlefieldArena() ) and ( not C_PvP.IsBattleground() ) then
                addon.HideClassIcon(nameplate);
            elseif UnitIsPlayer(frame.unit) or UnitIsUnit(frame.unit, "pet") or UnitIsUnit(frame.unit, "partypet1") or UnitIsUnit(frame.unit, "partypet2") then
                -- Issue: a pet that's not one of the above 3 showed an icon
                -- Maybe it was partypet2 and later someone else joined so this pet became partypet3
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
            if SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer or SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers then
                addon.ShowSpecIcon(frame); -- Control alpha in spec icon module for healer / non-healer
            else
                addon.HideSpecIcon(frame);
            end

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
    eventFrame:RegisterEvent(addon.UNIT_CLASSIFICATION_CHANGED);
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        if event == addon.NAME_PLATE_UNIT_ADDED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate, nameplate.UnitFrame); -- Hide previous widgets and do update first
                if IsRestricted() then
                    UpdateUnitFrameVisibility(nameplate.UnitFrame, true); -- We don't want to hide the unit frame inside dungeons
                    return;
                end -- Cannot show widgets in restricted areas
                UpdateWidgets(nameplate, nameplate.UnitFrame);
                UpdateVisibility(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.NAME_PLATE_UNIT_REMOVED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.UPDATE_BATTLEFIELD_SCORE then -- This cannot be triggered in restricted areas
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
                if IsRestricted() then return end
                UpdateVisibility(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.UNIT_CLASSIFICATION_CHANGED then -- When a flag is picked up / dropped
            -- Listen to this event instead of hooking CompactUnitFrame_UpdateClassificationIndicator
            -- Since CompactUnitFrame_UpdateClassificationIndicator is called in other cases as well
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                if IsRestricted() then return end
                addon.UpdateClassIcon(nameplate, nameplate.UnitFrame);
            end
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then return end

        if frame.unit and string.sub(frame.unit, 1, 9) == "nameplate" then
            addon.UpdateTargetHighlight(frame:GetParent(), frame);

            -- Don't update names on raid frames
            -- In BGs, flag carriers can be arena1 / arena2
            if IsActiveBattlefieldArena() and SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then
                for i = 1, 3 do
                    if UnitIsUnit(frame.unit, "arena" .. i) then
                        frame.name:SetText(i);
                        frame.name:SetTextColor(1,1,0); --Yellow
                        return;
                    end
                end
            end
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
