local _, addon = ...;

local function HideWidgets(nameplate)
    addon.HideClassIcon(nameplate);
    addon.HidePetIcon(nameplate);
    addon.HideNpcHighlight(nameplate);
    addon.HideCritterIcon(nameplate);
    addon.HideSpecIcon(nameplate);
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
local function IsForbiddenSafe(frame)
    if addon.IsSecretValue(frame) then return true end
    return frame:IsForbidden();
end

-- Arena number resolver (mainline) -------------------------------------------
-- On mainline, arena units are PvP-restricted: UnitGUID / UnitIsUnit return secret
-- values, so a nameplate cannot be matched to arena1/2/3 directly. We instead
-- fingerprint each arena slot from non-secret attributes (class, race, sex, honor
-- level; class falls back to the sanctioned GetArenaOpponentSpec when the arena unit
-- is out of range) and match a nameplate's fingerprint against those slots.
--
-- The per-nameplate resolution is NOT cached: nameplate tokens (nameplateN) are
-- recycled far too frequently (range / line-of-sight / stealth, not just deaths) for
-- a token-keyed cache to be safe or worthwhile, so each request matches live. (The
-- arena-slot fingerprints themselves ARE cached, by index -- see GetArenaSlotPrint.)
-- A nameplate is numbered only if it uniquely matches one slot; on any ambiguity it
-- is left blank (a wrong number is worse than none). A unique match is necessarily
-- the unit's own slot, so a shown number is never wrong.

local function GetUnitArenaPrint(unit)
    if ( not UnitExists(unit) ) then return end
    local class = UnitClassBase(unit); -- non-secret on arena units
    if ( not class ) then return end
    return {
        class = class,
        race = select(2, UnitRace(unit)), -- locale-independent race file
        sex = UnitSex(unit),
        honor = UnitHonorLevel(unit),
    };
end

-- Per-slot fingerprint cache. The arena1/2/3 -> player identity is fixed for a
-- round, and a player's class/race/sex/honor never change, so once we read a slot's
-- full (in-range) fingerprint we cache it until the comp changes (reset on
-- PLAYER_ENTERING_WORLD / ARENA_PREP_OPPONENT_SPECIALIZATIONS). Keyed by arena index
-- (not by recycled nameplate tokens), so it has none of the staleness a token-keyed
-- cache would, and it lets matching survive a slot temporarily breaking line of sight.
local arenaSlotPrintCache = {};

local function ResetArenaSlotPrintCache()
    wipe(arenaSlotPrintCache);
end

local function GetArenaSlotPrint(i)
    local cached = arenaSlotPrintCache[i];
    if cached then return cached end

    local fp = GetUnitArenaPrint("arena" .. i);
    if fp then
        -- Cache only a complete in-range fingerprint; while out of range the print is
        -- too coarse to lock in for the round.
        if fp.race and fp.sex and fp.honor then
            arenaSlotPrintCache[i] = fp;
        end
        return fp;
    end

    -- Out of range / prep phase: UnitClassBase may be nil, but spec is available.
    local specID = GetArenaOpponentSpec(i);
    if specID and ( specID > 0 ) then
        local class = select(6, GetSpecializationInfoByID(specID)); -- classFilename
        if class then
            return { class = class }; -- class-only; race/sex/honor act as wildcards (not cached)
        end
    end
end

local function ArenaPrintsMatch(plate, slot)
    if ( plate.class ~= slot.class ) then return false end
    if ( slot.race ~= nil ) and ( plate.race ~= slot.race ) then return false end
    if ( slot.sex ~= nil ) and ( plate.sex ~= slot.sex ) then return false end
    if ( slot.honor ~= nil ) and ( plate.honor ~= slot.honor ) then return false end
    return true;
end

-- Returns the arena index (1..N) for a nameplate unit, or nil if it can't be
-- uniquely resolved. The unit's own fingerprint is read live each call and matched
-- against the (cached) arena slots.
local function GetArenaNumber(unit)
    local platePrint = GetUnitArenaPrint(unit);
    if ( not platePrint ) then return end

    local match, count = nil, 0;
    for i = 1, addon.MAX_ARENA_SIZE do
        local slot = GetArenaSlotPrint(i);
        if slot and ArenaPrintsMatch(platePrint, slot) then
            count = count + 1;
            match = i;
        end
    end

    -- Number only on a unique match; 0 or >1 viable slots -> leave blank.
    if ( count == 1 ) then
        return match;
    end
end
addon.GetArenaNumber = GetArenaNumber;

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
            for _, region in pairs(frame.castBar) do
                if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                    region:SetIgnoreParentAlpha(false);
                end
            end
        end

        frame.unsetIgnoreParentAlpha = true;
    end

    show = show or SweepyBoop.db.profile.nameplatesFriendly.keepHealthBar;

    local alpha = ( show and 1 ) or 0;
    frame:SetAlpha(alpha);

    if addon.PROJECT_MAINLINE then
        frame.castBar:SetAlpha(alpha);
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
    if ( UnitIsUnit(frame.unit, "player") ) then
        HideWidgets(nameplate);
        UpdateUnitFrameVisibility(nameplate, frame, true);
        return;
    end

    -- Comment out when testing on a target dummy
    if ( not UnitPlayerControlled(frame.unit) ) then
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
            elseif UnitIsUnit(frame.unit, "pet") or UnitIsUnit(frame.unit, "partypet1") or UnitIsUnit(frame.unit, "partypet2") then
                local shouldShow = true;
                local isArena = IsActiveBattlefieldArena();
                local isBattleground = ( UnitInBattleground("player") ~= nil );
                if configFriendly.hideOutsidePvP and ( not isArena ) and ( not isBattleground ) then
                    shouldShow = false;
                elseif configFriendly.hideInBattlegrounds and isBattleground and ( not isArena ) then
                    shouldShow = false;
                elseif configFriendly.showMyPetOnly and ( not UnitIsUnit(frame.unit, "pet") ) then
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

            UpdateUnitFrameVisibility(nameplate, frame, false); -- if class icons are enabled, all friendly units' health bars should be hidden
        else
            addon.HideClassIcon(nameplate);
            UpdateUnitFrameVisibility(nameplate, frame, true); -- Will be overriden by nameplate filter later
        end

        addon.HideSpecIcon(nameplate);
        addon.HideNpcHighlight(nameplate);
        addon.HideCritterIcon(nameplate);
    else
        addon.HideClassIcon(nameplate);
        addon.HidePetIcon(nameplate);

        if UnitIsPlayer(frame.unit) then
            -- For TBC, no spec/healer detection for enemies (UnitGroupRolesAssigned doesn't work for enemy arena units)
            -- For MoP Classic, use spec icons from tooltip
            -- For Retail, use UnitGroupRolesAssigned to detect healers in arenas
            local shouldShowSpecIcon;
            local configEnemy = SweepyBoop.db.profile.nameplatesEnemy;
            if addon.PROJECT_TBC then
                shouldShowSpecIcon = false; -- TBC: no reliable way to detect enemy healers
            elseif addon.PROJECT_MAINLINE then
                shouldShowSpecIcon = configEnemy.arenaEnemyHealer and IsActiveBattlefieldArena();
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
            UpdateUnitFrameVisibility(nameplate, frame, true); -- Always show enemy players
            return;
        end

        -- Process non-player hostile units
        addon.HideSpecIcon(nameplate);

        local npcOption, isCritter = addon.CheckNpcWhiteList(frame.unit);
        local shouldShowUnitFrame = true;
        if ( npcOption == addon.NpcOption.Highlight ) then
            addon.ShowNpcHighlight(nameplate, true);
        elseif ( npcOption == addon.NpcOption.ShowWithIcon ) then
            addon.ShowNpcHighlight(nameplate);
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

function SweepyBoop:SetupNameplateModules()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
    if addon.PROJECT_MAINLINE then
        eventFrame:RegisterEvent(addon.UPDATE_BATTLEFIELD_SCORE);
        -- Arena slot fingerprint cache: the comp only changes on a new arena / shuffle round
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
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
            end
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
        elseif event == addon.UNIT_AURA then
            if IsUnitIdInvalid(unitId) then return end

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if IsForbiddenSafe(nameplate.UnitFrame) then return end
                local unitAuraUpdateInfo = ...;
                addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit, unitAuraUpdateInfo);

                addon.UpdateClassIconCrowdControl(nameplate, nameplate.UnitFrame);
            end
        elseif event == addon.PLAYER_ENTERING_WORLD or event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS then
            ResetArenaSlotPrintCache(); -- arena comp changed; drop cached slot fingerprints
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

            if IsActiveBattlefieldArena() and SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then
                if addon.PROJECT_MAINLINE then
                    -- Arena units are secret on mainline; resolve the slot via fingerprint matching.
                    if UnitIsPlayer(frame.unit) and addon.UnitIsHostile(frame.unit) then
                        local arenaNumber = addon.GetArenaNumber(frame.unit);
                        if arenaNumber then
                            frame.name:SetText(arenaNumber);
                            frame.name:SetTextColor(1, 1, 0); -- Yellow
                        end
                    end
                else
                    for i = 1, 3 do
                        if UnitIsUnit(frame.unit, "arena" .. i) then
                            frame.name:SetText(i);
                            frame.name:SetTextColor(1, 1, 0); -- Yellow
                            break;
                        end
                    end
                end
            end
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

        -- Hook CompactUnitFrame_UpdateCenterStatusIcon - this calls frame:SetAlpha(CompactUnitFrame_GetRangeAlpha(frame))
        -- This catches all range-based alpha resets
        hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", function(frame)
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
