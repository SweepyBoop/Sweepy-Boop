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
    -- Getting called a lot in dungeons, possibly causing frame drop?
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

function SweepyBoop:RefreshAllNamePlates()
    -- Refresh all visible nameplates
    -- Skip if we're in a dungeon, changes will be handled by OnNamePlateAdded once we're out of the instance
    if IsRestricted() then return end

    local nameplates = C_NamePlate.GetNamePlates(true); -- isSecure = true to return nameplates in instances (to hide widgets)
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            local frame = nameplate.UnitFrame;
            if frame:IsForbidden() then return end

            addon.UpdateClassIcon(frame);
            addon.UpdateNpcHighlight(frame);
            addon.UpdateSpecIcon(frame);

            UpdateHealthBar(frame);
        end
    end
end

local function TryRefreshAllNamePlates()
    if UnitAffectingCombat("player") then
        print("In combat, retry after 1s");
        C_Timer.After(1, TryRefreshAllNamePlates);
    else
        SweepyBoop:RefreshAllNamePlates();
    end
end

function SweepyBoop:SetupNameplateModules()
    hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
        if frame:IsForbidden() then return end

        if ShouldUpdateUnitFrame(frame) then
            addon.UpdateClassIcon(frame);
            addon.UpdateNpcHighlight(frame);
            addon.UpdateSpecIcon(frame);

            UpdateHealthBar(frame);
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then return end

        if ShouldUpdateUnitFrame(frame) then
            addon.UpdateClassIconTargetHighlight(frame);

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
    end)

    hooksecurefunc("CompactUnitFrame_UpdateVisible", function (frame)
        if frame:IsForbidden() then return end

        if ShouldUpdateUnitFrame(frame) then
            UpdateHealthBar(frame);
        end
    end)

    -- Issue: in one SS round, if I target an enemy player when the round ends and that player joins my side in the next round
    -- this nameplate will be reused and not trigger an update
    -- Perhaps do a full update in CompactUnitFrame_UpdateName, if it's current target

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    eventFrame:RegisterEvent(addon.UNIT_PET);
    eventFrame:SetScript("OnEvent", function()
        TryRefreshAllNamePlates();
    end)
end
