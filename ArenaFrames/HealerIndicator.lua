local _, addon = ...;

local healerIndicator;
local eventFrame;

local function GetHealerIndex()
    if addon.TEST_MODE then
        return 1;
    end

    if IsActiveBattlefieldArena() then
        for i = 1, addon.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i);
            if spec then
                local role = select(5, GetSpecializationInfoByID(spec));
                if ( role == "HEALER" ) then
                    return i;
                end
            end
        end
    end
end

local function EnsureHealerIndicator()
    if ( not healerIndicator ) then
        healerIndicator = CreateFrame("Frame");
        healerIndicator:SetFrameLevel(9999);
        healerIndicator:SetMouseClickEnabled(false);
        healerIndicator.icon = healerIndicator:CreateTexture(nil, "OVERLAY");
        healerIndicator.icon:SetAtlas("Icon-Healer");
        healerIndicator.icon:SetAllPoints(healerIndicator);
        healerIndicator:Hide();
    end
end

local function HideHealerIndicator()
    if healerIndicator then
        healerIndicator:Hide();
    end
end

local function GetArenaFrame(healerIndex)
    if GladiusEx then
        return _G["GladiusExButtonFramearena" .. healerIndex];
    elseif Gladius then
        return _G["GladiusButtonFramearena" .. healerIndex];
    elseif sArena then
        return _G["sArenaEnemyFrame" .. healerIndex];
    elseif ArenaLiveUnitFrames then
        return _G["ALUF_ArenaEnemyFramesArenaEnemyFrame" .. healerIndex];
    elseif SlashCmdList.GLADDY then
        return _G["GladdyButtonFrame" .. healerIndex];
    end

    return _G["CompactArenaFrameMember" .. healerIndex];
end

local function GetAnchorFrame(frame, healerIndex)
    if ( not frame ) then return end

    if GladiusEx then
        return frame.classIcon or frame.ClassIcon or _G["GladiusExButtonFramearena" .. healerIndex .. "ClassIcon"] or frame;
    elseif Gladius then
        return _G["GladiusClassIconFramearena" .. healerIndex] or frame.classIcon or frame.ClassIcon or frame;
    elseif sArena then
        return frame.ClassIcon or frame.classIcon or frame;
    elseif ArenaLiveUnitFrames then
        return _G["ALUF_ArenaEnemyFramesArenaEnemyFrame" .. healerIndex .. "PortraitTexture"] or frame.Portrait or frame;
    elseif SlashCmdList.GLADDY then
        return frame.classIcon or frame.ClassIcon or _G["GladdyButtonFrame" .. healerIndex .. "ClassIcon"] or frame;
    end

    return frame.classIcon or frame.ClassIcon or frame;
end

local function GetIndicatorSize(anchorFrame)
    if ( not anchorFrame ) or ( not anchorFrame.GetSize ) then return end

    local width, height = anchorFrame:GetSize();
    local size = math.min(width or 0, height or 0);
    if ( size == 0 ) or addon.IsSecretValue(size) then return end

    return size / 2;
end

local function GetIndicatorScale(frame)
    if sArena and sArena.GetScale then
        local scale = sArena:GetScale();
        if scale and ( not addon.IsSecretValue(scale) ) then
            return scale;
        end
    end

    if frame and frame.GetScale then
        local scale = frame:GetScale();
        if scale and ( not addon.IsSecretValue(scale) ) then
            return scale;
        end
    end

    return 1;
end

local function UpdateHealerIndicator()
    if ( not SweepyBoop.db.profile.misc.healerIndicator ) then
        HideHealerIndicator();
        return;
    end

    local healerIndex = GetHealerIndex();
    if ( not healerIndex ) then
        HideHealerIndicator();
        return;
    end

    local frame = GetArenaFrame(healerIndex);
    local anchorFrame = GetAnchorFrame(frame, healerIndex);
    local size = GetIndicatorSize(anchorFrame);
    if ( not size ) then
        HideHealerIndicator();
        return;
    end

    EnsureHealerIndicator();
    healerIndicator:ClearAllPoints();
    healerIndicator:SetSize(size, size);
    healerIndicator:SetScale(GetIndicatorScale(frame));
    healerIndicator:SetPoint("CENTER", anchorFrame, "RIGHT");
    healerIndicator:Show();
end

function SweepyBoop:RefreshHealerIndicator()
    UpdateHealerIndicator();
end

function SweepyBoop:SetupHealerIndicator()
    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
        eventFrame:SetScript("OnEvent", function()
            UpdateHealerIndicator();
        end)
    end

    UpdateHealerIndicator();
end
