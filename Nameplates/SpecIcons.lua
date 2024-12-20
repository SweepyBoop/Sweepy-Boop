local _, addon = ...;
local iconSize = 30;

local function ShouldShowSpecIcon(unitId) -- Return icon ID if should show, otherwise nil
    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena" .. i) then
            -- i is the opponent index
            local specID = GetArenaOpponentSpec(i);
            if ( not specID ) then return end
            local iconID, role = select(4, GetSpecializationInfoByID(specID));

            if ( role == "HEALER" ) and SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer then
                return iconID;
            elseif ( role ~= "HEALER" ) and SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconOthers then
                return iconID;
            end
        end
    end
end

local function EnsureSpecIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end

    if ( not nameplate.SpecIcon ) then
        nameplate.SpecIcon = nameplate:CreateTexture(nil, 'overlay', nil, 6);
        nameplate.SpecIcon:SetSize(iconSize, iconSize);
        nameplate.SpecIcon:SetPoint("BOTTOM", frame.name, "TOP");
        nameplate.SpecIcon:SetAlpha(1);
        nameplate.SpecIcon:SetIgnoreParentAlpha(true);

        nameplate.SpecIcon:SetScale(SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100);
        nameplate.SpecIcon.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
    end

    if ( nameplate.SpecIcon.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) then
        nameplate.SpecIcon:SetScale(SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100);
        nameplate.SpecIcon.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
    end

    return nameplate.SpecIcon;
end

local function ShowSpecIcon(frame, iconID)
    local icon = EnsureSpecIcon(frame);
    if ( not icon ) then return end;

    if ( icon.iconID ~= iconID) then
        icon:SetTexture(iconID);
        icon.iconID = iconID;
    end

    icon:Show();
end

addon.HideSpecIcon = function (frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.SpecIcon then
        nameplate.SpecIcon:Hide();
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
