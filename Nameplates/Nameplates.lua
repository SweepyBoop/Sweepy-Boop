local _, addon = ...;

local function HideWidgets(nameplate)
    addon.HideClassIcon(nameplate);
    addon.HidePetIcon(nameplate);
    addon.HideNpcHighlight(nameplate);
    addon.HideCritterIcon(nameplate);
    addon.HideSpecIcon(nameplate);
    if addon.PROJECT_MAINLINE then
        addon.HideBigDebuffs(nameplate);
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

local strsub = string.sub
local strbyte = string.byte

local retailNameplateUnits = {};
for i = 1, 40 do
    retailNameplateUnits[i] = "nameplate" .. i;
end

local function IsUnitIdInvalid(unitId)
    if unitId == nil then return true end
    local b = strbyte(unitId)
    if b == 110 then -- 'n'ameplate
        if strsub(unitId, 1, 9) == "nameplate" then return false end
    elseif b == 97 then -- 'a'rena
        if strsub(unitId, 1, 5) == "arena" then return true end
    elseif b == 98 then -- 'b'oss
        if strsub(unitId, 1, 4) == "boss" then return true end
    elseif b == 114 then -- 'r'aid
        if strsub(unitId, 1, 4) == "raid" then return true end
    elseif b == 112 then -- 'p'arty
        if strsub(unitId, 1, 5) == "party" then return true end
    elseif b == 116 then -- 't'argettarget
        if unitId == "targettarget" then return true end
    elseif b == 102 then -- 'f'ocustarget
        if unitId == "focustarget" then return true end
    end
end

-- Helper to safely check if a frame is forbidden (handles secret values in arena)
local ARENA_NUMBER_VERTICAL_OFFSET = 2;
local ARENA_NUMBER_FONT_SIZE_MULTIPLIER = 2.5;
local ARENA_NUMBER_TEST_UNIT_NAME = "PvP Training Dummy";
local arenaNumberTestEnabled = false;
local arenaNumberFont;
local arenaNumberBaseFontSize;
local arenaNumberFontFlags;

local function IsForbiddenSafe(frame)
    if addon.IsSecretValue(frame) then return true end
    return frame:IsForbidden();
end

local function HideArenaNameplateNumber(frame)
    if frame.sweepyBoopArenaNumberText then
        frame.sweepyBoopArenaNumberText:Hide();
    end
end

local function EnsureArenaNumberFont()
    if arenaNumberFont or arenaNumberBaseFontSize then return end

    arenaNumberFont, arenaNumberBaseFontSize, arenaNumberFontFlags = SystemFont_NamePlate:GetFont();
end

local function EnsureArenaNameplateNumberText(frame)
    if frame.sweepyBoopArenaNumberText then return frame.sweepyBoopArenaNumberText end

    EnsureArenaNumberFont();

    local text = frame:CreateFontString(nil, "OVERLAY");
    if arenaNumberFont and arenaNumberBaseFontSize then
        text:SetFont(arenaNumberFont, arenaNumberBaseFontSize * ARENA_NUMBER_FONT_SIZE_MULTIPLIER, arenaNumberFontFlags or "OUTLINE");
    else
        text:SetFontObject("SystemFont_LargeNamePlate");
    end
    text:SetTextColor(1, 1, 0); -- Yellow
    text:SetJustifyH("CENTER");
    text:SetJustifyV("BOTTOM");
    text:SetPoint("BOTTOM", frame.healthBar or frame, "TOP", 0, ARENA_NUMBER_VERTICAL_OFFSET);
    text:Hide();

    frame.sweepyBoopArenaNumberText = text;
    return text;
end

local function ShowArenaNameplateNumber(frame, arenaNumber)
    if not frame.name then return end

    frame.name:SetText("");
    local text = EnsureArenaNameplateNumberText(frame);
    text:SetText(arenaNumber);
    text:Show();
end

local function GetArenaNameplateNumber(frame)
    if arenaNumberTestEnabled and frame.unit and UnitName(frame.unit) == ARENA_NUMBER_TEST_UNIT_NAME then
        if not frame.sweepyBoopArenaNumberTestNumber then
            frame.sweepyBoopArenaNumberTestNumber = random(1, 3);
        end
        return frame.sweepyBoopArenaNumberTestNumber;
    end

    if not IsActiveBattlefieldArena() then return end
    if not SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then return end

    if addon.PROJECT_MAINLINE then
        -- Retail 12.1 keeps queried player names readable in PvP even when broader
        -- unit identity is secret, so resolve arena slots by normalized name and realm.
        if UnitIsPlayer(frame.unit) and addon.UnitIsHostile(frame.unit) then
            return addon.GetArenaNumber(frame.unit);
        end
    else
        for i = 1, 3 do
            if UnitIsUnit(frame.unit, "arena" .. i) then
                return i;
            end
        end
    end
end

local function UpdateArenaNameplateNumber(frame)
    local arenaNumber = GetArenaNameplateNumber(frame);
    if arenaNumber then
        ShowArenaNameplateNumber(frame, arenaNumber);
    else
        HideArenaNameplateNumber(frame);
    end
end

local function GetNameplateCastBar(frame)
    -- TODO: Once 12.1 arrives, remove the frame.castBar fallback.
    return frame.castBar or ( frame.CastBarsContainer and frame.CastBarsContainer.castBar );
end

local function UpdateUnitFrameVisibility(nameplate, frame, show)
    -- Force frame's child elements to not ignore parent alpha
    -- This is still problematic at least in Retail, sometimes both healthBar and castBar show up
    -- healthBar seems fixed now, but name and castBar still show up
    -- When the issue occurs, HealthBarsContainer:IsIgnoringParentAlpha() returns false, so why is it not following parent alpha?
    -- Seems to happen when arena match starts (also lots of LUA errors)
    if ( not frame.unsetIgnoreParentAlpha ) then
        for key, region in pairs(frame) do
            if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                --print("[SweepyBoop] frame key:", key, "type:", type(region.SetIgnoreParentAlpha), "hasGetObjectType:", region.GetObjectType ~= nil);
                if addon.PROJECT_MAINLINE then
                    if (key ~= "HitTestFrame") then
                        region:SetIgnoreParentAlpha(false);
                    end
                else
                    if (key == "healthBar" or key == "selectionHighlight") then
                        region:SetIgnoreParentAlpha(false);
                    end
                end
            end
        end

        if addon.PROJECT_MAINLINE then
            local castBar = GetNameplateCastBar(frame);
            if castBar then
                for _, region in pairs(castBar) do
                    if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                        region:SetIgnoreParentAlpha(false);
                    end
                end
            end
        end

        frame.unsetIgnoreParentAlpha = true;
    end

    local alpha = ( show and 1 ) or 0;
    frame:SetAlpha(alpha);

    if addon.PROJECT_MAINLINE then
        local castBar = GetNameplateCastBar(frame);
        if castBar then
            castBar:SetAlpha(alpha);
        end
    end

    if nameplate.extended then -- NeatPlates
        -- Setting alpha on extended itself did not work, just set alpha on child elements
        for _, region in pairs(nameplate.extended.bars) do
            if ( type(region) == "table" ) and region.SetAlpha then
                region:SetAlpha(alpha);
            end
        end

        for _, region in pairs(nameplate.extended) do
            if ( type(region) == "table" ) and region.SetAlpha then
                region:SetAlpha(alpha);
            end
        end
    end
end

local function UpdateWidgets(nameplate, frame)
    -- Don't mess with personal resource display
    if addon.UnitIsUnitReadable(frame.unit, "player") then
        HideWidgets(nameplate);
        UpdateUnitFrameVisibility(nameplate, frame, true);
        return;
    end

    -- Comment out when testing on a target dummy
    if ( not addon.PROJECT_MAINLINE ) and ( not UnitPlayerControlled(frame.unit) ) then
        HideWidgets(nameplate);
        UpdateUnitFrameVisibility(nameplate, frame, true);
        return;
    end

    -- Possible issue: after priest mind control, party member shows both class icon and health bar
    if ( not addon.UnitIsHostile(frame.unit) ) then -- Friendly units, show class icon for friendly players and party pets
        local configFriendly = SweepyBoop.db.profile.nameplatesFriendly;
        if configFriendly.classIconsEnabled then
            if UnitIsPlayer(frame.unit) then
                -- Issue: a pet that's not one of the above 3 showed an icon
                -- Maybe it was partypet2 and later someone else joined so this pet became partypet3
                addon.ShowClassIcon(nameplate, frame);
                addon.HidePetIcon(nameplate);
            elseif addon.UnitIsUnitReadable(frame.unit, "pet")
                or addon.UnitIsUnitReadable(frame.unit, "partypet1")
                or addon.UnitIsUnitReadable(frame.unit, "partypet2") then
                local shouldShow = true;
                local isArena = IsActiveBattlefieldArena();
                local isBattleground = ( UnitInBattleground("player") ~= nil );
                if configFriendly.hideOutsidePvP and ( not isArena ) and ( not isBattleground ) then
                    shouldShow = false;
                elseif configFriendly.hideInBattlegrounds and isBattleground and ( not isArena ) then
                    shouldShow = false;
                elseif configFriendly.showMyPetOnly and ( not addon.UnitIsUnitReadable(frame.unit, "pet") ) then
                    shouldShow = false;
                end

                addon.HideClassIcon(nameplate);
                if shouldShow then
                    addon.ShowPetIcon(nameplate, frame);
                else
                    addon.HidePetIcon(nameplate);
                end
            else
                addon.HideClassIcon(nameplate);
                addon.HidePetIcon(nameplate);
            end

            UpdateUnitFrameVisibility(nameplate, frame, configFriendly.keepHealthBar);
        else
            addon.HideClassIcon(nameplate);
            UpdateUnitFrameVisibility(nameplate, frame, true); -- Will be overriden by nameplate filter later
        end

        addon.HideSpecIcon(nameplate);
        addon.HideNpcHighlight(nameplate);
        addon.HideCritterIcon(nameplate);
        if addon.PROJECT_MAINLINE then
            addon.HideBigDebuffs(nameplate);
        end
    else
        addon.HideClassIcon(nameplate);
        addon.HidePetIcon(nameplate);

        if UnitIsPlayer(frame.unit) then
            -- For TBC, no spec/healer detection for enemies.
            -- For MoP Classic, use spec icons from tooltip.
            -- For Retail, use GetArenaOpponentSpec with name-matched arena numbers.
            local shouldShowSpecIcon;
            local configEnemy = SweepyBoop.db.profile.nameplatesEnemy;
            if addon.PROJECT_TBC then
                shouldShowSpecIcon = false; -- TBC: no reliable way to detect enemy specs
            elseif addon.PROJECT_MAINLINE then
                shouldShowSpecIcon = ( configEnemy.arenaSpecIconHealer or configEnemy.arenaSpecIconOthers ) and IsActiveBattlefieldArena();
            else
                shouldShowSpecIcon = ( configEnemy.arenaSpecIconHealer or configEnemy.arenaSpecIconOthers ) and IsActiveBattlefieldArena();
            end

            if shouldShowSpecIcon then
                addon.ShowSpecIcon(nameplate); -- Control alpha in spec icon module for healer / non-healer
            else
                addon.HideSpecIcon(nameplate);
            end

            addon.HideNpcHighlight(nameplate);
            addon.HideCritterIcon(nameplate);
            if addon.PROJECT_MAINLINE then
                addon.UpdateBigDebuffs(nameplate, frame);
            end
            UpdateUnitFrameVisibility(nameplate, frame, true); -- Always show enemy players
            return;
        end

        -- Process non-player hostile units
        addon.HideSpecIcon(nameplate);
        if addon.PROJECT_MAINLINE then
            addon.HideBigDebuffs(nameplate);
        end

        local npcOption

        local npcOption, isCritter, iconTexture, highlightKey = addon.CheckNpcWhiteList(frame.unit);
        local shouldShowUnitFrame = true;
        if ( npcOption == addon.NpcOption.Highlight ) then
            addon.ShowNpcHighlight(nameplate, true, iconTexture, highlightKey);
        elseif ( npcOption == addon.NpcOption.ShowWithIcon ) then
            addon.ShowNpcHighlight(nameplate, false, iconTexture, highlightKey);
        elseif ( npcOption == addon.NpcOption.Show ) then
            addon.HideNpcHighlight(nameplate);
        else
            addon.HideNpcHighlight(nameplate);
            shouldShowUnitFrame = false;
        end

        -- Hide Beast Mastery Hunter secondary pets (this override the above setting)
        -- If we already decided to hide a unit, no need to perform this check!
        if shouldShowUnitFrame and ( not addon.PROJECT_MAINLINE ) and addon.UnitIsHunterSecondaryPet(frame.unit) then
            shouldShowUnitFrame = false;
        end

        if SweepyBoop.db.profile.nameplatesEnemy.showCritterIcons and isCritter and ( not shouldShowUnitFrame ) then
            addon.ShowCritterIcon(nameplate);
        else
            addon.HideCritterIcon(nameplate);
        end

        UpdateUnitFrameVisibility(nameplate, frame, shouldShowUnitFrame);
    end
end

local function RefreshArenaIdentityWidgets()
    if ( not IsActiveBattlefieldArena() ) or IsRestricted() then return end

    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = nameplate and nameplate.UnitFrame;
        if frame and ( not IsForbiddenSafe(frame) ) then
            UpdateWidgets(nameplate, frame);
            UpdateArenaNameplateNumber(frame);
        end
    end
end

function SweepyBoop:SetupNameplateModules()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_REMOVED);
    if addon.PROJECT_MAINLINE then
        eventFrame:RegisterUnitEvent(addon.UNIT_AURA, unpack(retailNameplateUnits));
        eventFrame:RegisterUnitEvent(addon.UNIT_SPELLCAST_START, unpack(retailNameplateUnits));
        eventFrame:RegisterUnitEvent(addon.UNIT_SPELLCAST_STOP, unpack(retailNameplateUnits));
        eventFrame:RegisterUnitEvent(addon.UNIT_SPELLCAST_INTERRUPTED, unpack(retailNameplateUnits));
        eventFrame:RegisterUnitEvent(addon.UNIT_SPELLCAST_CHANNEL_START, unpack(retailNameplateUnits));
        eventFrame:RegisterUnitEvent(addon.UNIT_SPELLCAST_CHANNEL_STOP, unpack(retailNameplateUnits));
        eventFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
        eventFrame:RegisterEvent(addon.UPDATE_BATTLEFIELD_SCORE);
        eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
    else
        eventFrame:RegisterEvent(addon.UNIT_AURA); -- Secret values in Retail
    end
    eventFrame:RegisterEvent(addon.UNIT_FACTION);

    eventFrame:SetScript("OnEvent", function (_, event, unitId, ...)
        if event == addon.NAME_PLATE_UNIT_ADDED then
            if IsUnitIdInvalid(unitId) then return end

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if IsForbiddenSafe(nameplate.UnitFrame) then return end
                HideWidgets(nameplate); -- Hide previous widgets (even in restricted areas)
                if IsRestricted() then
                    UpdateUnitFrameVisibility(nameplate, nameplate.UnitFrame, true); -- We don't want to hide the unit frame inside dungeons
                else
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end

                addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit);
                UpdateArenaNameplateNumber(nameplate.UnitFrame);
            end
        elseif event == addon.NAME_PLATE_UNIT_REMOVED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId, issecure());
            if nameplate then
                if nameplate.UnitFrame then
                    HideArenaNameplateNumber(nameplate.UnitFrame);
                end
                HideWidgets(nameplate);
            end
        elseif event == addon.ARENA_OPPONENT_UPDATE then
            RefreshArenaIdentityWidgets();
        elseif event == addon.PLAYER_TARGET_CHANGED then
            SweepyBoop:RefreshAllNamePlates();
        elseif event == addon.UPDATE_BATTLEFIELD_SCORE then -- This cannot be triggered in restricted areas
            if ( UnitInBattleground("player") == nil ) then return end -- Only needed in battlegrounds for updating visible spec icons
            local nameplates = C_NamePlate.GetNamePlates();
            for i = 1, #(nameplates) do
                local nameplate = nameplates[i];
                if nameplate and nameplate.UnitFrame then
                    if IsForbiddenSafe(nameplate.UnitFrame) then return end
                    if nameplate.UnitFrame.optionTable.showPvPClassificationIndicator then
                        addon.UpdateSpecIcon(nameplate);
                    end
                end
            end
        elseif event == addon.UNIT_FACTION then -- This is triggered for Mind Control
            if IsUnitIdInvalid(unitId) then return end

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if IsForbiddenSafe(nameplate.UnitFrame) then return end
                if ( not IsRestricted() ) then
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end
            end
        elseif event == addon.UNIT_AURA or event == addon.UNIT_SPELLCAST_START or event == addon.UNIT_SPELLCAST_STOP or event == addon.UNIT_SPELLCAST_INTERRUPTED
            or event == addon.UNIT_SPELLCAST_CHANNEL_START or event == addon.UNIT_SPELLCAST_CHANNEL_STOP then
            if IsUnitIdInvalid(unitId) then return end

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if IsForbiddenSafe(nameplate.UnitFrame) then return end
                local unitAuraUpdateInfo = ...;
                if event == addon.UNIT_AURA then
                    addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit, unitAuraUpdateInfo);
                    addon.UpdateClassIconCrowdControl(nameplate, nameplate.UnitFrame, unitAuraUpdateInfo);
                    if addon.PROJECT_MAINLINE then
                        addon.UpdateBigDebuffs(nameplate, nameplate.UnitFrame);
                    end
                end

                if addon.PROJECT_MAINLINE and ( not IsRestricted() ) then
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end
            end
        end
    end)

    -- When flag is picked up / dropped
    -- The old CompactUnitFrame_UpdatePvPClassificationIndicator was replaced with NamePlateClassificationFrameMixin
    if addon.PROJECT_MAINLINE then
        hooksecurefunc(NamePlateClassificationFrameMixin, "UpdateClassificationIndicator", function (self)
            if IsForbiddenSafe(self) then return end

            local nameplate = self:GetParent();
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame.optionTable.showPvPClassificationIndicator then
                    -- UpdateClassIcon should include UpdateTargetHighlight
                    -- Otherwise we can't guarantee the order of events
                    -- Consequently we can't guarantee the target highlight is up-to-date on FC
                    addon.UpdateClassIcon(nameplate, nameplate.UnitFrame);
                end
            end
        end)
    end

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if IsForbiddenSafe(frame) then return end

        -- Less efficient check for classic as showPvPClassificationIndicator is not available
        local isNamePlate = frame.optionTable.showPvPClassificationIndicator or ( ( not addon.PROJECT_MAINLINE ) and string.find(frame.unit, "nameplate") );
        if isNamePlate then
            addon.UpdateClassIconTargetHighlight(frame:GetParent(), frame);
            addon.UpdatePetIconTargetHighlight(frame:GetParent(), frame);
            addon.UpdatePlayerName(frame:GetParent(), frame);
            UpdateArenaNameplateNumber(frame);
        end
    end)

    -- Hook CompactUnitFrame_UpdateAll to re-apply our alpha setting after the game resets it
    -- This catches most cases: PLAYER_ENTERING_WORLD, ARENA_OPPONENT_UPDATE, etc.
    if addon.PROJECT_MAINLINE then


        -- Hook DefaultCompactUnitFrameSetup - this directly calls frame:SetAlpha(1)
        hooksecurefunc("DefaultCompactUnitFrameSetup", function(frame)
            if IsForbiddenSafe(frame) then return end

            local isNamePlate = frame.optionTable and frame.optionTable.showPvPClassificationIndicator;
            if isNamePlate then
                local nameplate = frame:GetParent();
                if nameplate and nameplate.UnitFrame then
                    if ( not IsRestricted() ) then
                        UpdateWidgets(nameplate, frame);
                    end
                end
            end
        end)

        -- Hook DefaultCompactMiniFrameSetup - this directly calls frame:SetAlpha(1) for mini frames
        hooksecurefunc("DefaultCompactMiniFrameSetup", function(frame)
            if IsForbiddenSafe(frame) then return end

            local isNamePlate = frame.optionTable and frame.optionTable.showPvPClassificationIndicator;
            if isNamePlate then
                local nameplate = frame:GetParent();
                if nameplate and nameplate.UnitFrame then
                    if ( not IsRestricted() ) then
                        UpdateWidgets(nameplate, frame);
                    end
                end
            end
        end)

    end

    -- Hook CompactUnitFrame_UpdateCenterStatusIcon - this calls frame:SetAlpha(CompactUnitFrame_GetRangeAlpha(frame))
    -- This catches all range-based alpha resets
    hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", function(frame)
        if IsForbiddenSafe(frame) then return end

        local isNamePlate = frame.optionTable and frame.optionTable.showPvPClassificationIndicator;
        -- Less efficient check for classic as showPvPClassificationIndicator is not available
        isNamePlate = isNamePlate or ( ( not addon.PROJECT_MAINLINE ) and string.find(frame.unit, "nameplate") );
        if isNamePlate then
            local nameplate = frame:GetParent();
            if nameplate and nameplate.UnitFrame then
                if ( not IsRestricted() ) then
                    UpdateWidgets(nameplate, frame);
                end
            end
        end
    end)

    -- if addon.PROJECT_MAINLINE then
    --     hooksecurefunc(NameplateBuffButtonTemplateMixin, "OnEnter", function(self)
    --         if self:IsForbidden() then return end
    --         if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled then
    --             self:EnableMouse(false);
    --         else
    --             self:EnableMouse(true);
    --         end
    --     end)
    -- end
end

function SweepyBoop:RefreshAllNamePlates(hideFirst)
    if IsRestricted() then return end

    local nameplates = C_NamePlate.GetNamePlates(true); -- isSecure = true to return nameplates in instances (to hide widgets)
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            if IsForbiddenSafe(nameplate.UnitFrame) then return end
            if hideFirst then
                HideWidgets(nameplate);
            end
            UpdateWidgets(nameplate, nameplate.UnitFrame);
        end
    end
end

function SweepyBoop:TestArenaNameplateNumbers()
    arenaNumberTestEnabled = true;

    local nameplates = C_NamePlate.GetNamePlates(issecure());
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        local frame = nameplate and nameplate.UnitFrame;
        if frame then
            if IsForbiddenSafe(frame) then return end
            if frame.unit and UnitName(frame.unit) == ARENA_NUMBER_TEST_UNIT_NAME then
                frame.sweepyBoopArenaNumberTestNumber = random(1, 3);
                UpdateArenaNameplateNumber(frame);
            end
        end
    end
end

function SweepyBoop:HideTestArenaNameplateNumbers()
    arenaNumberTestEnabled = false;

    local nameplates = C_NamePlate.GetNamePlates(issecure());
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            if IsForbiddenSafe(nameplate.UnitFrame) then return end
            nameplate.UnitFrame.sweepyBoopArenaNumberTestNumber = nil;
            HideArenaNameplateNumber(nameplate.UnitFrame);
            CompactUnitFrame_UpdateName(nameplate.UnitFrame);
        end
    end
end

function SweepyBoop:RefreshAurasForAllNamePlates()
    local nameplates = C_NamePlate.GetNamePlates(issecure());
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame and ( nameplate.UnitFrame.BuffFrame or nameplate.UnitFrame.CustomBuffFrame ) then
            if IsForbiddenSafe(nameplate.UnitFrame) then return end
            addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit);
        end
    end
end
