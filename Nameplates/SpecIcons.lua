local _, addon = ...;

local function ShouldShowSpecIcon(unitId) -- Return icon ID if should show, otherwise nil
    if addon.isTestMode then
        return ( UnitIsUnit(unitId, "focus") and addon.healerIconID ) or ( UnitIsUnit(unitId, "target") and 136041 ); -- Restoration Druid icon
    end

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena" .. i) then
            -- i is the opponent index
            local specID = GetArenaOpponentSpec(i);
            if ( not specID ) then return end
            local iconID, role = select(4, GetSpecializationInfoByID(specID));

            if ( role == "HEALER" ) then
                if config.arenaSpecIconHealer then
                    if config.arenaSpecIconHealerIcon then
                        return addon.healerIconID;
                    else
                        return iconID;
                    end
                end
            elseif config.arenaSpecIconOthers then
                return iconID;
            end
        end
    end
end

local function EnsureSpecIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end

    if ( not nameplate.SpecIconFrame ) then
        nameplate.SpecIconFrame = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "TOP");
    end

    return nameplate.SpecIconFrame;
end

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large

local function ShowSpecIcon(frame, iconID)
    local specIconFrame = EnsureSpecIcon(frame);
    if ( not specIconFrame ) then return end;

    local isHealerIcon = ( iconID == addon.healerIconID );
    if ( specIconFrame.iconID ~= iconID) then
        specIconFrame.icon:SetTexture(iconID);
        if isHealerIcon then
            specIconFrame.icon:SetTexCoord(unpack(addon.healerIconCoords));
        else
            specIconFrame.icon:SetTexCoord(0, 1, 0, 1);
        end
        specIconFrame.iconID = iconID;
    end

    if ( specIconFrame.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) or ( specIconFrame.isHealerIcon ~= isHealerIcon ) then
        local scale = SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100;
        if isHealerIcon then
            scale = scale * 1.25;
        end
        specIconFrame:SetScale(scale * builtInScaleFactor);

        specIconFrame:SetPoint("BOTTOM", specIconFrame:GetParent(), "TOP", 0, SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconVerticalOffset);

        specIconFrame.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
        specIconFrame.isHealerIcon = isHealerIcon;
    end

    specIconFrame:Show();
end

addon.HideSpecIcon = function (frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.SpecIconFrame then
        nameplate.SpecIconFrame:Hide();
    end
end

addon.UpdateSpecIcon = function (frame)
    local iconID = ShouldShowSpecIcon(frame.unit);
    if iconID then
        ShowSpecIcon(frame, iconID);
    else
        addon.HideSpecIcon(frame);
    end
end
