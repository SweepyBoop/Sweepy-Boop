local _, addon = ...;

local function UpdateComboPoints(frame)
    local isCatForm = ( GetShapeshiftForm() == 2 );
    local cp = UnitPower("player", frame.powerType);
    frame:SetShown(isCatForm or ( cp > 0 ) );

    for i, point in ipairs(frame.classResourceButtonTable) do
        -- Keep track of Blizzard patch notes, in case of breaking changes

        -- While we're at it, show combo points instantly
        if point.activateAnim then
            point.activateAnim:Stop();
        end
        if point.decativeAnim then
            point.deactivateAnim:Stop();
        end

        local isActive = (i <= cp);
        local activeAlpha = ( isActive and 1 ) or 0;
        point.Point_Icon:SetAlpha(activeAlpha);
        point.BG_Active:SetAlpha(activeAlpha);
        point.BG_Inactive:SetAlpha( ( isActive and 0 ) or 1 );
        point.Point_Deplete:SetAlpha(0);
    end
end

function SweepyBoop:SetupAlwaysShowDruidComboPoints()
    if ( addon.GetUnitClass("player") ~= addon.DRUID ) then return end

    local comboPointFrame = DruidComboPointBarFrame;

    comboPointFrame:HookScript("OnHide", function(frame)
        if ( not SweepyBoop.db.profile.misc.alwaysShowDruidComboPoints ) then return end
        if ( UnitPower("player", frame.powerType) > 0 ) then
            frame:Show();
        end
    end);

    local eventFrame = CreateFrame("Frame");
    eventFrame:SetScript("OnEvent", function(_, _, _, powerType)
        if ( powerType == "COMBO_POINTS" ) then
            UpdateComboPoints(comboPointFrame);
        end
    end);
    if SweepyBoop.db.profile.misc.alwaysShowDruidComboPoints then
        eventFrame:RegisterEvent(addon.UNIT_POWER_UPDATE);
        UpdateComboPoints(comboPointFrame); -- Do one-off initial update
    else
        eventFrame:UnregisterAllEvents();
    end
end
