local _, addon = ...;

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

local healerIndicator; -- Create on first usage
local function EnsureHealerIndicator()
    if ( not healerIndicator ) then
        healerIndicator = CreateFrame("Frame");
        healerIndicator:SetFrameStrata("HIGH");
        healerIndicator:SetMouseClickEnabled(false);
        healerIndicator.icon = healerIndicator:CreateTexture();
        healerIndicator.icon:SetAtlas("Icon-Healer");
        healerIndicator.icon:SetAllPoints(healerIndicator);
    end
end

local function HideHealerIndicator()
    if healerIndicator then
        healerIndicator:Hide();
    end
end

local function UpdateHealerIndicator()
    local healerIndex = GetHealerIndex();
    if ( not healerIndex ) then
        HideHealerIndicator();
        return;
    end

    EnsureHealerIndicator();

    -- Update size in case the player adjusted Gladius / sArena settings
    -- Require a reload when settings are changed during an arena session
    local size = sArenaEnemyFrame1 and sArenaEnemyFrame1.ClassIcon and sArenaEnemyFrame1.ClassIcon:GetSize();
    if ( not size ) then
        HideHealerIndicator();
        return;
    end
    size = size / 2;
    healerIndicator:SetSize(size, size);
    healerIndicator.icon:SetSize(size, size);
    healerIndicator:SetScale(sArena:GetScale());

    local frame = _G["sArenaEnemyFrame" .. healerIndex];
    if ( not frame ) then
        HideHealerIndicator();
        return;
    end

    healerIndicator:SetPoint("CENTER", frame, "RIGHT");
    healerIndicator:Show();
end

function SweepyBoop:SetupHealerIndicator()
    local frame = CreateFrame("Frame");
    frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    frame:SetScript("OnEvent", function ()
        if ( not SweepyBoop.db.profile.arenaFrames.healerIndicator ) or ( not sArena ) then
            HideHealerIndicator();
            return;
        end

        UpdateHealerIndicator();
    end)
end
