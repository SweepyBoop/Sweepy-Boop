local _, addon = ...;

local healerIndicators = {};
local eventFrame;

local function GetArenaFrame(arenaIndex)
    if GladiusEx then
        return _G["GladiusExButtonFramearena" .. arenaIndex];
    elseif Gladius then
        return _G["GladiusButtonFramearena" .. arenaIndex];
    elseif sArena then
        return _G["sArenaEnemyFrame" .. arenaIndex];
    elseif ArenaLiveUnitFrames then
        return _G["ALUF_ArenaEnemyFramesArenaEnemyFrame" .. arenaIndex];
    elseif SlashCmdList.GLADDY then
        return _G["GladdyButtonFrame" .. arenaIndex];
    end
end

local function GetAnchorFrame(frame, arenaIndex)
    if ( not frame ) then return end

    if GladiusEx then
        return frame.classIcon or frame.ClassIcon or _G["GladiusExButtonFramearena" .. arenaIndex .. "ClassIcon"] or frame;
    elseif Gladius then
        return _G["GladiusClassIconFramearena" .. arenaIndex] or frame.classIcon or frame.ClassIcon or frame;
    elseif sArena then
        return frame.ClassIcon or frame.classIcon or frame;
    elseif ArenaLiveUnitFrames then
        return _G["ALUF_ArenaEnemyFramesArenaEnemyFrame" .. arenaIndex .. "PortraitTexture"] or frame.Portrait or frame;
    elseif SlashCmdList.GLADDY then
        return frame.classIcon or frame.ClassIcon or _G["GladdyButtonFrame" .. arenaIndex .. "ClassIcon"] or frame;
    end

    return frame.classIcon or frame.ClassIcon or frame;
end

local function GetIndicatorSize(anchorFrame)
    if ( not anchorFrame ) or ( not anchorFrame.GetSize ) then return end

    local width, height = anchorFrame:GetSize();
    if addon.IsSecretValue(width) or addon.IsSecretValue(height) then return end

    local size = math.min(width or 0, height or 0);
    if ( size == 0 ) then return end

    return size / 2;
end

local function GetIndicatorScale(frame)
    if sArena and sArena.GetScale then
        local scale = sArena:GetScale();
        if ( not addon.IsSecretValue(scale) ) and scale then
            return scale;
        end
    end

    if frame and frame.GetScale then
        local scale = frame:GetScale();
        if ( not addon.IsSecretValue(scale) ) and scale then
            return scale;
        end
    end

    return 1;
end

local function EnsureHealerIndicator(arenaIndex)
    local indicator = healerIndicators[arenaIndex];
    if indicator then return indicator end

    indicator = CreateFrame("Frame");
    indicator:SetFrameLevel(9999);
    indicator:SetMouseClickEnabled(false);
    indicator.icon = indicator:CreateTexture(nil, "OVERLAY");
    indicator.icon:SetAllPoints(indicator);
    indicator.icon:SetAlpha(0);
    indicator:Hide();
    healerIndicators[arenaIndex] = indicator;
    return indicator;
end

local function HideHealerIndicators()
    for _, indicator in pairs(healerIndicators) do
        indicator:Hide();
    end
end

local function UpdateHealerIndicatorForSlot(arenaIndex, getDisplayInfo)
    local frame = GetArenaFrame(arenaIndex);
    local anchorFrame = GetAnchorFrame(frame, arenaIndex);
    local size = GetIndicatorSize(anchorFrame);
    if ( not size ) then
        local indicator = healerIndicators[arenaIndex];
        if indicator then
            indicator:Hide();
        end
        return;
    end

    local indicator = EnsureHealerIndicator(arenaIndex);
    indicator:ClearAllPoints();
    indicator:SetSize(size, size);
    indicator:SetScale(GetIndicatorScale(frame));
    indicator:SetPoint("CENTER", anchorFrame, "RIGHT");

    if addon.TEST_MODE then
        if arenaIndex == 1 then
            indicator.icon:SetTexture(addon.ARENA_SPEC_ROLE_TEXTURES_FRAME.HEALER);
            indicator.icon:SetAlpha(1);
            indicator:Show();
        else
            indicator:Hide();
        end
        return;
    end

    local info = getDisplayInfo(arenaIndex, addon.ARENA_SPEC_ROLE_TEXTURES_FRAME);
    if ( not info ) then
        indicator:Hide();
        return;
    end

    indicator.icon:SetTexture(info.roleIconTexture);
    indicator.icon:SetAlphaFromBoolean(info.showRoleIcon, 1, 0);
    indicator:Show();
end

local function UpdateHealerIndicators()
    if ( not SweepyBoop.db.profile.misc.healerIndicator )
        or ( ( not addon.TEST_MODE ) and ( not IsActiveBattlefieldArena() ) ) then
        HideHealerIndicators();
        return;
    end

    local getDisplayInfo = UnitFrameUtil and UnitFrameUtil.GetArenaOpponentSpecDisplayInfo;
    if ( not addon.TEST_MODE ) and ( not getDisplayInfo ) then
        HideHealerIndicators();
        return;
    end

    for arenaIndex = 1, addon.MAX_ARENA_SIZE do
        UpdateHealerIndicatorForSlot(arenaIndex, getDisplayInfo);
    end
end

function SweepyBoop:RefreshHealerIndicator()
    UpdateHealerIndicators();
end

function SweepyBoop:SetupHealerIndicator()
    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
        eventFrame:SetScript("OnEvent", function()
            UpdateHealerIndicators();
        end)
    end

    UpdateHealerIndicators();
end
