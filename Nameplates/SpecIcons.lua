local _, addon = ...;
local iconSize = 24;

local healerIconID = "interface/lfgframe/uilfgprompts";

local function ShouldShowSpecIcon(unitId) -- Return icon ID if should show, otherwise nil
    if addon.isTestMode then
        return ( UnitIsUnit(unitId, "target") and addon.specIconHealer ) or (UnitIsUnit(unitId, "focus") and healerIconID );
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
        nameplate.SpecIcon.icon:SetSize(iconSize, iconSize);
        nameplate.SpecIcon.icon:SetPoint("CENTER", nameplate.SpecIcon);
        
        nameplate.SpecIcon.mask = nameplate.SpecIcon:CreateMaskTexture();
        nameplate.SpecIcon.mask:SetTexture("Interface/Masks/CircleMaskScalable");
        nameplate.SpecIcon.mask:SetSize(iconSize, iconSize);
        nameplate.SpecIcon.mask:SetPoint("CENTER", nameplate.SpecIcon.icon);
        nameplate.SpecIcon.icon:AddMaskTexture(nameplate.SpecIcon.mask);

        -- nameplate.SpecIcon.border = nameplate.SpecIcon:CreateTexture(nil, "OVERLAY");
        -- nameplate.SpecIcon.border:SetAtlas("charactercreate-ring-metallight");
        -- nameplate.SpecIcon.border:SetSize(iconSize * 1.25, iconSize * 1.25);
        -- nameplate.SpecIcon.border:SetPoint("CENTER", nameplate.SpecIcon);

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
    local specIcon = EnsureSpecIcon(frame);
    if ( not specIcon ) then return end;

    if ( specIcon.iconID ~= iconID) then
        specIcon.icon:SetTexture(iconID);
        if ( iconID == healerIconID ) then
            specIcon.icon:SetTexCoord(0.005, 0.116, 0.76, 0.87);
        else
            specIcon.icon:SetTexCoord(0, 1, 0, 1);
        end
        specIcon.iconID = iconID;
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
