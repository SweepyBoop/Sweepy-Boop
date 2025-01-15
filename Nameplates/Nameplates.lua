local _, addon = ...;

local function ShouldShowUnitFrame(unitId)
    -- Do not hide personal resource display
    if UnitIsUnit(unitId, "player") then
        return true;
    end

    -- When outside arena or battleground and is not in test mode
    if ( not IsActiveBattlefieldArena() ) and ( not C_PvP.IsBattleground() ) and ( not addon.TEST_MODE ) then
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

local function GetShowInfoForUnit(unitId)
    -- Whether we should show: unit frame, class icon, spec icon, highlight (if not set, defaults to false)
    local showInfo = {};
    showInfo.unitId = unitId;

    if UnitIsUnit(unitId, "player") then
        showInfo.showUnitFrame = true; -- Don't hide personal resource display
        -- nothing else will be shown
    elseif UnitIsPlayer(unitId) then
        local classIconsEnabled = SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled;
        local specIconsEnabled = SweepyBoop.db.profile.nameplatesEnemy.specIconsEnabled;
        if IsActiveBattlefieldArena() then
            if classIconsEnabled then
                showInfo.showUnitFrame = UnitIsUnit(unitId, "arena1") or UnitIsUnit(unitId, "arena2") or UnitIsUnit(unitId, "arena3");
                showInfo.showClassIcon = UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2") or UnitIsUnit(unitId, "party1pet") or UnitIsUnit(unitId, "party2pet");
            else
                showInfo.showUnitFrame = true;
            end

            if specIconsEnabled then
                showInfo.showSpecIcon = UnitIsUnit(unitId, "arena1") or UnitIsUnit(unitId, "arena2") or UnitIsUnit(unitId, "arena3");
            end
        else
            showInfo.showUnitFrame = ( not classIconsEnabled ) or addon.UnitIsHostile(unitId); -- if class icons disabled, show everything; otherwise show hostile
            showInfo.showClassIcon = classIconsEnabled and ( not addon.UnitIsHostile(unitId) ); -- show class icon if enabled and friendly
            showInfo.showSpecIcon = specIconsEnabled and addon.UnitIsHostile(unitId); -- show spec icon if enabled and hostile
        end

        -- Check if we need to hide class icons outside PvP instances
        if SweepyBoop.db.profile.nameplatesFriendly.hideOutsidePvP and ( not C_PvP.IsBattleground() ) and ( not IsActiveBattlefieldArena() )  then
            showInfo.showClassIcon = false;
        end
    else
        -- For non-player units, check whitelist first to see if we should show the unit frame
        local isWhitelisted = ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) or addon.IsNpcInWhiteList(unitId);
        -- If hostilie show if whitelisted and not a hunter secondary pet; for friendly show if class icons are disabled
        if addon.UnitIsHostile(unitId) then
            showInfo.showUnitFrame = isWhitelisted and ( not addon.UnitIsHunterSecondaryPet(unitId) );
        else
            showInfo.showUnitFrame = ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
        end

        if SweepyBoop.db.profile.nameplatesEnemy.filterEnabled then
            local guid = UnitGUID(unitId);
            local npcID = select(6, strsplit("-", guid));
            local option = SweepyBoop.db.profile.nameplatesEnemy.filterList[tostring(npcID)];
            if ( option == addon.NpcOption.Highlight ) then
                showInfo.showNpcHighlight = addon.UnitIsHostile(unitId);
            end
        end
    end

    return showInfo;
end

local function HideWidgets(frame)
    addon.HideClassIcon(frame);
    addon.HideNpcHighlight(frame);
    addon.HideSpecIcon(frame);
end

local function UpdateHealthBar(frame, shouldShow)
    if shouldShow then
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

local function IsRestricted()
    local instanceType = select(2, IsInInstance());
    return restricted[instanceType];
end

local function ShouldUpdateUnitFrame(frame)
    if frame.unit and ( string.sub(frame.unit, 1, 9) == "nameplate" ) then
        -- Check if in restricted areas
        if IsRestricted() then
            -- In restricted instance, should skip all the nameplate logic
            -- But hide all the widgets, we don't want to show class icons, spec icons, etc. in dungeons
            HideWidgets(frame);
            return false;
        end

        return true;
    end
end

local function UpdateAll(frame)
    if frame:IsForbidden() then
        return;
    end

    if ( not ShouldUpdateUnitFrame(frame) ) then
        return;
    end

    local showInfo = GetShowInfoForUnit(frame.unit);

    -- Class icon mod will hide/show healthBar when showing/hiding class icons
    addon.UpdateClassIcon(frame, showInfo);
    -- Show enemy nameplate highlight
    addon.UpdateNpcHighlight(frame, showInfo);
    -- Update spec icons
    addon.UpdateSpecIcon(frame, showInfo);
    -- Nameplate filter mod could overwrite the healthBar visibility afterwards (need to ensure healthBar and class icon do not show at the same time)
    UpdateHealthBar(frame, showInfo.showUnitFrame);

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
    -- For friendly, full update if unitGUID / PvPClassification / config changes; otherwise just update visibility
    -- For enemy, full update if unitGUID / config changes; otherwise just update visibility

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        UpdateAll(frame);
    end)

    hooksecurefunc("CompactUnitFrame_UpdateVisible", function (frame)
        if frame:IsForbidden() then
            return;
        end

        if ( not ShouldUpdateUnitFrame(frame) ) then
            return;
        end

        UpdateHealthBar(frame, ShouldShowUnitFrame(frame.unit));
    end)
end

function SweepyBoop:RefreshAllNamePlates()
    if IsRestricted() then return end

    local nameplates = C_NamePlate.GetNamePlates(true); -- isSecure = true to return nameplates in instances (to hide widgets)
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            UpdateAll(nameplate.UnitFrame);
        end
    end
end
