local _, addon = ...;

local function HideWidgets(nameplate)
    addon.HideClassIcon(nameplate);
    addon.HidePetIcon(nameplate);
    addon.HideNpcHighlight(nameplate);
    addon.HideSpecIcon(nameplate);
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

local function UpdateUnitFrameVisibility(frame, show)
    -- Force frame's child elements to not ignore parent alpha
    if ( not frame.unsetIgnoreParentAlpha ) then
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
        frame.unsetIgnoreParentAlpha = true;
    end

    local alpha = ( show and 1 ) or 0;
    frame:SetAlpha(alpha);
    frame.castBar:SetAlpha(alpha);
end

local function UpdateWidgets(nameplate, frame)
    -- Don't mess with personal resource display
    if ( UnitIsUnit(frame.unit, "player") ) then
        HideWidgets(nameplate);
        UpdateUnitFrameVisibility(frame, true);
        return;
    end

    -- Possible issue: after priest mind control, party member shows both class icon and health bar
    if ( not addon.UnitIsHostile(frame.unit) ) then -- Friendly units, show class icon for friendly players and party pets
        local configFriendly = SweepyBoop.db.profile.nameplatesFriendly;
        if configFriendly.classIconsEnabled then
            if configFriendly.hideOutsidePvP and ( not IsActiveBattlefieldArena() ) and ( UnitInBattleground("player") == nil ) then
                addon.HideClassIcon(nameplate);
            elseif UnitIsPlayer(frame.unit) then
                -- Issue: a pet that's not one of the above 3 showed an icon
                -- Maybe it was partypet2 and later someone else joined so this pet became partypet3
                addon.ShowClassIcon(nameplate, frame);
                addon.HidePetIcon(nameplate);
            elseif UnitIsUnit(frame.unit, "pet") or UnitIsUnit(frame.unit, "partypet1") or UnitIsUnit(frame.unit, "partypet2") then
                addon.HideClassIcon(nameplate);
                addon.ShowPetIcon(nameplate, frame);
            else
                addon.HideClassIcon(nameplate);
                addon.HidePetIcon(nameplate);
            end

            UpdateUnitFrameVisibility(frame, false); -- if class icons are enabled, all friendly units' health bars should be hidden
        else
            addon.HideClassIcon(nameplate);
            UpdateUnitFrameVisibility(frame, true); -- Will be overriden by nameplate filter later
        end

        addon.HideSpecIcon(nameplate);
        addon.HideNpcHighlight(nameplate);
    else
        addon.HideClassIcon(nameplate);
        addon.HidePetIcon(nameplate);

        if UnitIsPlayer(frame.unit) then
            if SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer or SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers then
                addon.ShowSpecIcon(nameplate); -- Control alpha in spec icon module for healer / non-healer
            else
                addon.HideSpecIcon(nameplate);
            end

            addon.HideNpcHighlight(nameplate);
            UpdateUnitFrameVisibility(frame, true); -- Always show enemy players
            return;
        end

        -- Process non-player hostile units
        addon.HideSpecIcon(nameplate);

        local npcOption = addon.CheckNpcWhiteList(frame.unit);
        local shouldShowUnitFrame = true;
        if ( npcOption == addon.NpcOption.Highlight ) then
            addon.ShowNpcHighlight(nameplate);
        elseif ( npcOption == addon.NpcOption.Show ) then
            addon.HideNpcHighlight(nameplate);
        else
            addon.HideNpcHighlight(nameplate);
            shouldShowUnitFrame = false;
        end

        -- Hide Beast Mastery Hunter secondary pets (this override the above setting)
        -- If we already decided to hide a unit, no need to perform this check!
        if shouldShowUnitFrame and addon.UnitIsHunterSecondaryPet(frame.unit) then
            shouldShowUnitFrame = false;
        end

        UpdateUnitFrameVisibility(frame, shouldShowUnitFrame);
    end
end

function SweepyBoop:SetupNameplateModules()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
    eventFrame:RegisterEvent(addon.UPDATE_BATTLEFIELD_SCORE);
    eventFrame:RegisterEvent(addon.UNIT_FACTION);
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        if event == addon.NAME_PLATE_UNIT_ADDED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate); -- Hide previous widgets (even in restricted areas)
                if IsRestricted() then
                    UpdateUnitFrameVisibility(nameplate.UnitFrame, true); -- We don't want to hide the unit frame inside dungeons
                else
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end

                if nameplate.UnitFrame.BuffFrame then
                    -- Avoid conflicts with BetterBlizzPlates
                    if BetterBlizzPlatesDB and BetterBlizzPlatesDB.enableNameplateAuraCustomisation then return end
                    
                    if ( not nameplate.UnitFrame.BuffFrame.UpdateBuffsByBlizzard ) then
                        nameplate.UnitFrame.BuffFrame.UpdateBuffsByBlizzard = nameplate.UnitFrame.BuffFrame.UpdateBuffs;
                        nameplate.UnitFrame.BuffFrame.UpdateBuffs = function (self, unit, unitAuraUpdateInfo, auraSettings)
                            if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled then
                                addon.UpdateBuffsOverride(self, unit, unitAuraUpdateInfo, auraSettings);
                            else
                                self:UpdateBuffsByBlizzard(unit, unitAuraUpdateInfo, auraSettings);
                            end
                        end
                    end
                end
            end
        elseif event == addon.UPDATE_BATTLEFIELD_SCORE then -- This cannot be triggered in restricted areas
            if ( UnitInBattleground("player") == nil ) then return end -- Only needed in battlegrounds for updating visible spec icons
            local nameplates = C_NamePlate.GetNamePlates();
            for i = 1, #(nameplates) do
                local nameplate = nameplates[i];
                if nameplate and nameplate.UnitFrame then
                    if nameplate.UnitFrame:IsForbidden() then return end
                    if nameplate.UnitFrame.optionTable.showPvPClassificationIndicator then
                        addon.UpdateSpecIcon(nameplate);
                    end
                end
            end
        elseif event == addon.UNIT_FACTION then -- This is triggered for Mind Control
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                if ( not IsRestricted() ) then
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end
            end
        end
    end)

    -- When flag is picked up / dropped
    -- Issue, not immediately updated to flag carrier icon when someone picked up the flag
    hooksecurefunc("CompactUnitFrame_UpdatePvPClassificationIndicator", function (frame)
        -- This will only be applied to nameplates in PvP instances
        if frame:IsForbidden() then return end
        if frame.optionTable.showPvPClassificationIndicator then
            -- UpdateClassIcon should include UpdateTargetHighlight
            -- Otherwise we can't guarantee the order of events CompactUnitFrame_UpdateClassificationIndicator and CompactUnitFrame_UpdateName
            -- Consequently we can't guarantee the target highlight is up-to-date on FC
            addon.UpdateClassIcon(frame:GetParent(), frame);
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then return end

        if frame.optionTable.showPvPClassificationIndicator then
            addon.UpdateClassIconTargetHighlight(frame:GetParent(), frame);
            addon.UpdatePetIconTargetHighlight(frame:GetParent(), frame);

            if IsActiveBattlefieldArena() and SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then
                for i = 1, 3 do
                    if UnitIsUnit(frame.unit, "arena" .. i) then
                        frame.name:SetText(i);
                        frame.name:SetTextColor(1,1,0); --Yellow
                        break;
                    end
                end
            end
        end
    end)

    hooksecurefunc(NameplateBuffButtonTemplateMixin, "OnEnter", function(self)
        if self:IsForbidden() then return end
        if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled then
            self:EnableMouse(false);
        else
            self:EnableMouse(true);
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
        end
    end
end
