local _, addon = ...;

local function ShouldShowNameplate(unitId)
    -- Do not hide personal resource display
    if UnitIsUnit(unitId, "player") then
        return true;
    end

    -- When outside arena or battleground and is not in test mode
    if ( not IsActiveBattlefieldArena() ) and ( UnitInBattleground("player") == nil ) and ( not addon.TEST_MODE ) then
        if SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled then -- Show everything hostile if we have class & pet icons enabled
            return addon.UnitIsHostile(unitId);
        else -- Otherwise just show everything
            return true;
        end
    end

    -- If we reach here, we're in an arena or battleground

    if ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) and ( not addon.UnitIsHostile(unitId) ) then
        return true; -- Don't hide friendly nameplates if we're not making class icons
    end

    if IsActiveBattlefieldArena() then -- In arenas, be more restrictive
        -- Show arena 1~3
        for i = 1, addon.MAX_ARENA_SIZE do
            if UnitIsUnit(unitId, "arena" .. i) then
                return true;
            end
        end

        -- Show hostile units that are whitelisted (exclude hunter secondary pet if applicable)
        -- Hide hunter secondary pets can be enabled even when filter is disabled => isWhitelisted = true, so we are basically checking hostility and UnitIsHunterSecondaryPet
        local isWhitelisted = ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) or addon.IsNpcInWhiteList(unitId);
        if ( not UnitIsPlayer(unitId) ) and isWhitelisted then
            return addon.UnitIsHostile(unitId) and ( not addon.UnitIsHunterSecondaryPet(unitId) );
        end
    else
        -- In battlegrounds or test mode, show hostile units that are either player or whitelisted
        local isWhitelisted = ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) or addon.IsNpcInWhiteList(unitId);
        if UnitIsPlayer(unitId) or isWhitelisted then
            return addon.UnitIsHostile(unitId);
        end
    end
end

local function HideWidgets(frame)
    addon.HideClassIcon(frame);
    addon.HideNpcHighlight(frame);
    addon.HideSpecIcon(frame);
end

local function UpdateHealthBar(frame)
    if ShouldShowNameplate(frame.unit) then
        frame:Show();
    else
        frame:Hide();
    end
end

-- Protected nameplates in dungeons and raids
local restricted = {
	party = true,
	raid = true,
};

local function ShouldUpdateNamePlate(frame)
    if frame.unit and ( string.sub(frame.unit, 1, 9) == "nameplate" ) then
        -- Check if in restricted areas
        local instanceType = select(2, IsInInstance());
        if restricted[instanceType] then
            -- In restricted instance, should skip all the nameplate logic
            -- But hide all the widgets, we don't want to show class icons, spec icons, etc. in dungeons
            HideWidgets(frame);
            return false;
        end

        return true;
    end
end

local function UpdateName(frame)
    if frame:IsForbidden() then
        return;
    end

    if ( not ShouldUpdateNamePlate(frame) ) then
        return;
    end

    -- Class icon mod will hide/show healthBar when showing/hiding class icons
    addon.UpdateClassIcon(frame);
    -- Show enemy nameplate highlight
    addon.UpdateNpcHighlight(frame);
    -- Update spec icons
    addon.UpdateSpecIcon(frame);
    -- Nameplate filter mod could overwrite the healthBar visibility afterwards (need to ensure healthBar and class icon do not show at the same time)
    UpdateHealthBar(frame);

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

function SweepyBoop:SetupNameplateModules()
    -- If both unitGUID and config remain unchanged, we just need to update the visibility of the widgets
    -- Otherwise, do a full update

    -- Separate flag carrier from class icon feature since it can update more frequently

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        UpdateName(frame);
    end)

    hooksecurefunc("CompactUnitFrame_UpdateVisible", function (frame)
        if frame:IsForbidden() then
            return;
        end

        if ( not ShouldUpdateNamePlate(frame) ) then
            return;
        end

        UpdateHealthBar(frame);
    end)
end

function SweepyBoop:RefreshAllNamePlates()
    local nameplates = C_NamePlate.GetNamePlates(true); -- isSecure = true to return nameplates in instances (to hide widgets)
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            UpdateName(nameplate.UnitFrame);
        end
    end
end
