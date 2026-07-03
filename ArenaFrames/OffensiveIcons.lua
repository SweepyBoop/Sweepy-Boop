local _, addon = ...;

local baseIconSize = addon.DEFAULT_ICON_SIZE;
local blizzardArenaFramePrefix = "CompactArenaFrameMember";
local maxAurasToScan = 255;
local testSpells = { 190319, 31884, 185313 }; -- Combustion, Avenging Wrath, Shadow Dance
local maxOverlayLayers = 12;
local procGlowColor = { 1, 0.82, 0, 1 };
local burstAuraSpellIDs;
local arenaOverlayEventFrame;
local arenaOverlays = {};
local isInTest = false;

local function GetConfig()
    return SweepyBoop.db.profile.arenaFrames;
end

local function GetBurstAuraSpellSet()
    if burstAuraSpellIDs then return burstAuraSpellIDs end

    burstAuraSpellIDs = {};
    for spellID, spell in pairs(addon.SpellData) do
        local parentSpellID = spell.parent or spellID;
        local parent = addon.SpellData[parentSpellID] or spell;
        if parent.category == addon.SPELLCATEGORY.BURST then
            burstAuraSpellIDs[spellID] = true;
            burstAuraSpellIDs[parentSpellID] = true;
        end
    end

    return burstAuraSpellIDs;
end

local function CanUseSpellID(spellID)
    return spellID and ( not addon.IsSecretValue(spellID) );
end

local function GetBurstLookupSpellID(spellID)
    if not CanUseSpellID(spellID) then return end

    return ( addon.AuraParent and addon.AuraParent[spellID] ) or spellID;
end

local function AuraPassesFilter(unit, auraInstanceID, filter)
    if ( not C_UnitAuras ) or ( not C_UnitAuras.IsAuraFilteredOutByInstanceID ) then
        return false;
    end

    local filteredOut = C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraInstanceID, filter);
    if addon.IsSecretValue(filteredOut) then
        return false;
    end

    return ( not filteredOut );
end

local function IsExcludedDefensiveAura(unit, auraInstanceID)
    return AuraPassesFilter(unit, auraInstanceID, "HELPFUL|BIG_DEFENSIVE")
        or AuraPassesFilter(unit, auraInstanceID, "HELPFUL|EXTERNAL_DEFENSIVE");
end

local function BuildBurstOverlaySignal(unit, auraData)
    if ( not auraData ) or ( not auraData.icon ) or ( not auraData.auraInstanceID ) then
        return false;
    end

    local spellID = GetBurstLookupSpellID(auraData.spellId);
    if spellID then
        return GetBurstAuraSpellSet()[spellID] and true or false, spellID;
    end

    if IsExcludedDefensiveAura(unit, auraData.auraInstanceID) then
        return false;
    end

    if addon.PROJECT_MAINLINE and auraData.spellId and C_Spell and C_Spell.IsSpellImportant then
        return C_Spell.IsSpellImportant(auraData.spellId);
    end

    return false;
end

local function CompareBurstOverlays(a, b)
    local aSpellID = a.burstSpellID;
    local bSpellID = b.burstSpellID;
    local aSpell = aSpellID and addon.SpellData[aSpellID];
    local bSpell = bSpellID and addon.SpellData[bSpellID];
    local aPriority = ( aSpell and aSpell.index ) or addon.SPELLPRIORITY.DEFAULT;
    local bPriority = ( bSpell and bSpell.index ) or addon.SPELLPRIORITY.DEFAULT;

    if aPriority ~= bPriority then
        return aPriority < bPriority;
    end

    return ( a.aura.auraInstanceID or 0 ) < ( b.aura.auraInstanceID or 0 );
end

local function ConfigureCooldownSwipe(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetDrawSwipe(true);
    cooldown:SetDrawEdge(true);
    cooldown:SetReverse(true);
    if cooldown.SetSwipeColor then
        cooldown:SetSwipeColor(0, 0, 0, 0.55);
    end
    if cooldown.SetEdgeTexture then
        cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    end
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(0);
    end
end

local function UpdateCountdownFontSize(cooldown)
    if not cooldown then return end

    if not cooldown.sweepyBoopCountdownFontString then
        local numRegions = cooldown:GetNumRegions();
        for i = 1, numRegions do
            local region = select(i, cooldown:GetRegions());
            if region and ( region:GetObjectType() == "FontString" ) then
                cooldown.sweepyBoopCountdownFontString = region;
                break;
            end
        end
    end

    local region = cooldown.sweepyBoopCountdownFontString;
    if region then
        local font, _, flags = region:GetFont();
        if font then
            region:SetFont(font, math.floor(baseIconSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT), flags);
        end
    end
end

local function ResetCooldownSwipe(cooldown)
    if cooldown.Clear then
        cooldown:Clear();
    else
        cooldown:SetCooldown(0, 0);
    end
end

local function CreateOverlayLayer(parent)
    local icon = CreateFrame("Frame", nil, parent);
    icon:SetMouseClickEnabled(false);
    icon:SetSize(baseIconSize, baseIconSize);

    icon.texture = icon:CreateTexture(nil, "BORDER");
    icon.texture:SetAllPoints(icon);

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(icon.cooldown);
    UpdateCountdownFontSize(icon.cooldown);

    icon:Hide();
    return icon;
end

local function EnsureArenaOverlay(index)
    local group = arenaOverlays[index];
    if group then return group end

    group = CreateFrame("Frame", nil, UIParent);
    group:SetMouseClickEnabled(false);
    group:SetFrameStrata("HIGH");
    group:SetSize(baseIconSize, baseIconSize);
    group.icons = {};
    group.index = index;
    group.unit = "arena" .. index;
    group:Hide();
    arenaOverlays[index] = group;
    return group;
end

local function EnsureOverlayLayer(group, index)
    local icon = group.icons[index];
    if icon then return icon end

    icon = CreateOverlayLayer(group);
    group.icons[index] = icon;
    return icon;
end

local function ClearArenaOverlay(group)
    if not group then return end

    for _, icon in ipairs(group.icons) do
        ResetCooldownSwipe(icon.cooldown);
        addon.HideProcGlow(icon);
        icon:Hide();
    end
    group:Hide();
end

local function ClearAllArenaOverlays()
    for _, group in pairs(arenaOverlays) do
        ClearArenaOverlay(group);
    end
    isInTest = false;
end

local function AnchorArenaOverlay(group)
    local config = GetConfig();
    local arenaFrame = _G[blizzardArenaFramePrefix .. group.index];
    if not arenaFrame then
        ClearArenaOverlay(group);
        return false;
    end

    local shown = arenaFrame:IsShown();
    local visible = arenaFrame:IsVisible();
    if addon.IsSecretValue(shown) or addon.IsSecretValue(visible) or ( not shown ) or ( not visible ) then
        ClearArenaOverlay(group);
        return false;
    end

    group:SetParent(arenaFrame);
    group:SetFrameStrata(arenaFrame:GetFrameStrata());
    group:SetFrameLevel(arenaFrame:GetFrameLevel() + 20);

    local scale = ( config.arenaOffensiveIconSize or 42 ) / baseIconSize;
    group:SetScale(scale);
    group:ClearAllPoints();
    group:SetPoint(
        "LEFT",
        arenaFrame,
        "LEFT",
        ( config.arenaOffensiveIconOffsetX or 0 ) / scale,
        ( config.arenaOffensiveIconOffsetY or 0 ) / scale
    );
    group.lastModified = config.lastModified;
    return true;
end

local function AnchorOverlayLayer(group, icon)
    icon:ClearAllPoints();
    icon:SetPoint("LEFT", group, "LEFT", 0, 0);
end

local function ApplyAlphaSignal(frame, alphaSignal)
    if addon.IsSecretValue(alphaSignal) then
        frame:SetAlphaFromBoolean(alphaSignal);
    elseif alphaSignal then
        frame:SetAlpha(1);
    else
        frame:SetAlpha(0);
    end
end

local function PaintOverlayLayer(icon, overlaySignal, durationObject, startTime, duration)
    local auraData = overlaySignal.aura;
    icon.texture:SetTexture(auraData.icon);

    if durationObject and icon.cooldown.SetCooldownFromDurationObject then
        icon.cooldown:SetCooldownFromDurationObject(durationObject);
        icon.cooldown:Show();
    elseif startTime and duration then
        icon.cooldown:SetCooldown(startTime, duration);
        icon.cooldown:Show();
    else
        ResetCooldownSwipe(icon.cooldown);
        icon.cooldown:Hide();
    end

    UpdateCountdownFontSize(icon.cooldown);
    ApplyAlphaSignal(icon, overlaySignal.alphaSignal);
    addon.ShowProcGlow(icon, procGlowColor);
    icon:Show();
end

local function ClearOverlayLayersAfter(group, firstUnusedIndex)
    for i = firstUnusedIndex, #group.icons do
        ResetCooldownSwipe(group.icons[i].cooldown);
        addon.HideProcGlow(group.icons[i]);
        group.icons[i]:SetAlpha(1);
        group.icons[i]:Hide();
    end
end

local function GatherBurstOverlaySignals(unit)
    local results = {};
    if ( not UnitExists(unit) ) or ( not C_UnitAuras ) then return results end

    if C_UnitAuras.GetUnitAuras then
        local auras = C_UnitAuras.GetUnitAuras(unit, "HELPFUL");
        if auras then
            for _, auraData in ipairs(auras) do
                local alphaSignal, burstSpellID = BuildBurstOverlaySignal(unit, auraData);
                if addon.IsSecretValue(alphaSignal) or alphaSignal then
                    table.insert(results, { aura = auraData, alphaSignal = alphaSignal, burstSpellID = burstSpellID });
                end
            end
        end
    else
        for i = 1, maxAurasToScan do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL");
            if ( not auraData ) or ( not auraData.name ) then break end
            local alphaSignal, burstSpellID = BuildBurstOverlaySignal(unit, auraData);
            if addon.IsSecretValue(alphaSignal) or alphaSignal then
                table.insert(results, { aura = auraData, alphaSignal = alphaSignal, burstSpellID = burstSpellID });
            end
        end
    end

    table.sort(results, CompareBurstOverlays);
    return results;
end

local function RefreshArenaOverlay(index)
    local config = GetConfig();
    local group = EnsureArenaOverlay(index);

    if ( not config.arenaOffensiveIconsEnabled ) or ( not AnchorArenaOverlay(group) ) then
        return;
    end

    local unit = group.unit;
    local overlaySignals = GatherBurstOverlaySignals(unit);
    if #overlaySignals == 0 then
        ClearOverlayLayersAfter(group, 1);
        group:Hide();
        return;
    end

    local usedCount = math.min(#overlaySignals, maxOverlayLayers);
    for i = 1, usedCount do
        local overlaySignal = overlaySignals[i];
        local auraData = overlaySignal.aura;
        local icon = EnsureOverlayLayer(group, i);
        AnchorOverlayLayer(group, icon);
        icon:SetFrameLevel(group:GetFrameLevel() + maxOverlayLayers - i);

        local durationObject = C_UnitAuras and C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID);
        local startTime, duration;
        if ( not durationObject ) and auraData.duration and auraData.expirationTime
            and ( not addon.IsSecretValue(auraData.duration) ) and ( not addon.IsSecretValue(auraData.expirationTime) ) then
            startTime = auraData.expirationTime - auraData.duration;
            duration = auraData.duration;
        end

        PaintOverlayLayer(icon, overlaySignal, durationObject, startTime, duration);
    end

    ClearOverlayLayersAfter(group, usedCount + 1);
    group:Show();
end

local function RefreshArenaOverlays()
    if ( not SweepyBoop.db ) then return end

    local config = GetConfig();
    if not config.arenaOffensiveIconsEnabled then
        ClearAllArenaOverlays();
        return;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        RefreshArenaOverlay(i);
    end
end

local function PreviewArenaOverlays()
    for i = 1, addon.MAX_ARENA_SIZE do
        local group = EnsureArenaOverlay(i);
        if AnchorArenaOverlay(group) then
            local spellID = testSpells[i] or testSpells[1];
            local icon = EnsureOverlayLayer(group, 1);
            local overlaySignal = {
                aura = {
                    icon = addon.GetSpellTexture(spellID),
                    auraInstanceID = i,
                    spellId = spellID,
                },
                alphaSignal = true,
                burstSpellID = spellID,
            };
            AnchorOverlayLayer(group, icon);
            PaintOverlayLayer(icon, overlaySignal, nil, GetTime() - i, 12 + i);
            ClearOverlayLayersAfter(group, 2);
            group:Show();
        end
    end
    isInTest = true;
end

local function ShowBlizzardArenaFramesForPreview()
    if not CompactArenaFrame then return end

    CompactArenaFrame:Show();
    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[blizzardArenaFramePrefix .. i];
        if frame then
            frame:Show();
        end
    end
end

function SweepyBoop:TestArenaOffensiveIcons()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    ShowBlizzardArenaFramesForPreview();
    PreviewArenaOverlays();
end

function SweepyBoop:HideTestArenaOffensiveIcons()
    ClearAllArenaOverlays();
end

function SweepyBoop:UpdateArenaOffensiveIcons()
    if isInTest then
        PreviewArenaOverlays();
        return;
    end

    RefreshArenaOverlays();
end

function SweepyBoop:SetupArenaOffensiveIcons()
    if not arenaOverlayEventFrame then
        arenaOverlayEventFrame = CreateFrame("Frame");
        arenaOverlayEventFrame:SetScript("OnEvent", function(_, event, unit)
            if event == addon.UNIT_AURA then
                if unit and unit:match("^arena%d+$") then
                    local index = tonumber(unit:match("^arena(%d+)$"));
                    if index then
                        RefreshArenaOverlay(index);
                    end
                end
                return;
            end

            isInTest = false;
            if event == addon.PLAYER_ENTERING_WORLD or event == "PVP_MATCH_COMPLETE" then
                ClearAllArenaOverlays();
            end
            RefreshArenaOverlays();
        end);
    end

    arenaOverlayEventFrame:UnregisterAllEvents();
    if GetConfig().arenaOffensiveIconsEnabled then
        arenaOverlayEventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        arenaOverlayEventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        arenaOverlayEventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        arenaOverlayEventFrame:RegisterEvent(addon.UNIT_AURA);
        if addon.PROJECT_MAINLINE then
            arenaOverlayEventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
            arenaOverlayEventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
            arenaOverlayEventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
        end
        RefreshArenaOverlays();
    else
        ClearAllArenaOverlays();
    end
end
