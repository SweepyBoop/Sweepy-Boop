local _, addon = ...;
local iconSize = 24;

local healerIconID = "interface/lfgframe/uilfgprompts";

local function ShouldShowSpecIcon(unitId) -- Return icon ID if should show, otherwise nil
    if addon.isTestMode then
        return ( UnitIsUnit(unitId, "focus") and healerIconID ) or ( UnitIsUnit(unitId, "target") and addon.specIconHealer );
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
                        return healerIconID;
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

    if ( not nameplate.SpecIcon ) then
        nameplate.SpecIcon = CreateFrame("Frame", nil, nameplate);
        nameplate.SpecIcon:SetMouseClickEnabled(false);
        nameplate.SpecIcon:SetSize(iconSize, iconSize);
        nameplate.SpecIcon:SetPoint("BOTTOM", frame.name, "TOP");
        nameplate.SpecIcon:SetFrameStrata("HIGH");

        nameplate.SpecIcon.icon = nameplate.SpecIcon:CreateTexture(nil, "BORDER");
        nameplate.SpecIcon.icon:SetAllPoints(nameplate.SpecIcon);

        nameplate.SpecIcon.mask = nameplate.SpecIcon:CreateMaskTexture();
        nameplate.SpecIcon.mask:SetTexture("Interface/Masks/CircleMaskScalable");
        nameplate.SpecIcon.mask:SetAllPoints(nameplate.SpecIcon.icon);
        nameplate.SpecIcon.icon:AddMaskTexture(nameplate.SpecIcon.mask);
    end

    return nameplate.SpecIcon;
end

local function ShowSpecIcon(frame, iconID)
    local specIcon = EnsureSpecIcon(frame);
    if ( not specIcon ) then return end;

    local isHealerIcon = ( iconID == healerIconID );
    if ( specIcon.iconID ~= iconID) then
        specIcon.icon:SetTexture(iconID);
        if isHealerIcon then
            specIcon.icon:SetTexCoord(0.005, 0.116, 0.76, 0.87);
        else
            specIcon.icon:SetTexCoord(0, 1, 0, 1);
        end
        specIcon.iconID = iconID;
    end

    if ( specIcon.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) or ( specIcon.isHealerIcon ~= isHealerIcon ) then
        local scale = SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100;
        if isHealerIcon then
            scale = scale * 1.25;
        end
        specIcon:SetScale(scale);

        specIcon.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
        specIcon.isHealerIcon = isHealerIcon;
    end

    specIcon:Show();
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
