local _, addon = ...;

local function HideWidgets(nameplate)
    addon.HideClassIcon(nameplate);
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

local function UpdateWidgets(nameplate, frame)
    -- Class icon mod will hide/show healthBar when showing/hiding class icons
    addon.UpdateClassIcon(nameplate, frame);
    -- Show enemy nameplate highlight
    addon.UpdateNpcHighlight(nameplate, frame);
    -- Update spec icons
    addon.UpdateSpecIcon(nameplate, frame);

    if IsActiveBattlefieldArena() then
        -- Put arena numbers
        if SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then
            for i = 1, 3 do
                if UnitIsUnit(frame.unit, "arena" .. i) then
                    frame.name:SetText(i);
                    frame.name:SetTextColor(1,1,0); --Yellow
                    return;
                end
            end
        end
    end
end

local function UpdateVisibility(nameplate, frame)
    if ( not addon.UnitIsHostile(frame.unit) ) then -- Friendly units, show class icon for friendly players and party pets
        local configFriendly = SweepyBoop.db.profile.nameplatesFriendly;
        if configFriendly.classIconsEnabled then
            if configFriendly.hideOutsidePvP and ( not IsActiveBattlefieldArena() ) and ( not C_PvP.IsBattleground() ) then
                addon.HideClassIcon(nameplate);
                frame:Hide();
            elseif UnitIsPlayer(frame.unit) or UnitIsUnit(frame.unit, "pet") or UnitIsUnit(frame.unit, "partypet1") or UnitIsUnit(frame.unit, "partypet2") then
                addon.ShowClassIcon(nameplate);
                frame:Hide();
            end
        else
            addon.HideClassIcon(nameplate);
            frame:Show(); -- Will be overriden by nameplate filter later
        end

        addon.HideSpecIcon(nameplate);
        addon.HideNpcHighlight(nameplate);
    else
        addon.ShowSpecIcon(nameplate);
    end
end

function SweepyBoop:SetupNameplateModules()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_REMOVED);
    eventFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        if event == addon.NAME_PLATE_UNIT_ADDED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate);
                UpdateWidgets(nameplate, nameplate.UnitFrame);
                UpdateVisibility(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.NAME_PLATE_UNIT_REMOVED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate);
            end
        elseif event == addon.PLAYER_TARGET_CHANGED then
            if IsRestricted() then return end
            local nameplates = C_NamePlate.GetNamePlates();
            for i = 1, #(nameplates) do
                local nameplate = nameplates[i];
                if nameplate and nameplate.UnitFrame then
                    if nameplate.UnitFrame:IsForbidden() then return end
                    addon.UpdateTargetHighlight(nameplate, nameplate.UnitFrame);
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
        end
    end
end
