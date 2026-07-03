local _, addon = ...;

local baseIconSize = addon.DEFAULT_ICON_SIZE;
local blizzardArenaFramePrefix = "CompactArenaFrameMember";
local maxAurasToScan = 255;
local testSpells = { 190319, 31884, 185313 }; -- Combustion, Avenging Wrath, Shadow Dance
local offensiveAuraSpellIDs;
local eventFrame;
local groups = {};
local isInTest = false;

local function GetConfig()
    return SweepyBoop.db.profile.arenaFrames;
end

local function BuildOffensiveAuraSpellIDs()
    if offensiveAuraSpellIDs then return offensiveAuraSpellIDs end

    offensiveAuraSpellIDs = {};
    for spellID, spell in pairs(addon.SpellData) do
        local parentSpellID = spell.parent or spellID;
        local parent = addon.SpellData[parentSpellID] or spell;
        if parent.category == addon.SPELLCATEGORY.BURST then
            offensiveAuraSpellIDs[spellID] = true;
            offensiveAuraSpellIDs[parentSpellID] = true;
        end
    end

    return offensiveAuraSpellIDs;
end

local function IsReadableSpellID(spellID)
    return spellID and ( not addon.IsSecretValue(spellID) );
end

local function GetTrackedSpellID(spellID)
    if not IsReadableSpellID(spellID) then return end

    return ( addon.AuraParent and addon.AuraParent[spellID] ) or spellID;
end

local function IsKnownOffensiveAura(auraData)
    local spellID = GetTrackedSpellID(auraData.spellId);
    if not spellID then return false end

    return BuildOffensiveAuraSpellIDs()[spellID];
end

local function ShouldShowAura(auraData)
    if ( not auraData ) or ( not auraData.icon ) or ( not auraData.auraInstanceID ) then
        return false;
    end

    return IsKnownOffensiveAura(auraData);
end

local function SortAuras(a, b)
    local aSpellID = GetTrackedSpellID(a.spellId);
    local bSpellID = GetTrackedSpellID(b.spellId);
    local aSpell = aSpellID and addon.SpellData[aSpellID];
    local bSpell = bSpellID and addon.SpellData[bSpellID];
    local aPriority = ( aSpell and aSpell.index ) or addon.SPELLPRIORITY.DEFAULT;
    local bPriority = ( bSpell and bSpell.index ) or addon.SPELLPRIORITY.DEFAULT;

    if aPriority ~= bPriority then
        return aPriority < bPriority;
    end

    return ( a.auraInstanceID or 0 ) < ( b.auraInstanceID or 0 );
end

local function StyleCooldown(cooldown)
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

local function ClearCooldown(cooldown)
    if cooldown.Clear then
        cooldown:Clear();
    else
        cooldown:SetCooldown(0, 0);
    end
end

local function CreateIcon(parent)
    local icon = CreateFrame("Frame", nil, parent);
    icon:SetMouseClickEnabled(false);
    icon:SetSize(baseIconSize, baseIconSize);

    icon.texture = icon:CreateTexture(nil, "BORDER");
    icon.texture:SetAllPoints(icon);

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    StyleCooldown(icon.cooldown);

    icon.border = icon:CreateTexture(nil, "OVERLAY");
    icon.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    icon.border:SetBlendMode("ADD");
    icon.border:SetPoint("CENTER", icon, "CENTER", 0, 0);
    icon.border:SetSize(baseIconSize * 1.75, baseIconSize * 1.75);
    icon.border:SetVertexColor(1, 0.82, 0, 1);

    icon:Hide();
    return icon;
end

local function EnsureGroup(index)
    local group = groups[index];
    if group then return group end

    group = CreateFrame("Frame", nil, UIParent);
    group:SetMouseClickEnabled(false);
    group:SetFrameStrata("HIGH");
    group:SetSize(baseIconSize, baseIconSize);
    group.icons = {};
    group.index = index;
    group.unit = "arena" .. index;
    group:Hide();
    groups[index] = group;
    return group;
end

local function EnsureIcon(group, index)
    local icon = group.icons[index];
    if icon then return icon end

    icon = CreateIcon(group);
    group.icons[index] = icon;
    return icon;
end

local function HideGroup(group)
    if not group then return end

    for _, icon in ipairs(group.icons) do
        ClearCooldown(icon.cooldown);
        icon:Hide();
    end
    group:Hide();
end

local function HideAllGroups()
    for _, group in pairs(groups) do
        HideGroup(group);
    end
    isInTest = false;
end

local function RefreshGroupPosition(group)
    local config = GetConfig();
    local arenaFrame = _G[blizzardArenaFramePrefix .. group.index];
    if not arenaFrame then
        HideGroup(group);
        return false;
    end

    local shown = arenaFrame:IsShown();
    local visible = arenaFrame:IsVisible();
    if addon.IsSecretValue(shown) or addon.IsSecretValue(visible) or ( not shown ) or ( not visible ) then
        HideGroup(group);
        return false;
    end

    local scale = ( config.arenaOffensiveIconSize or 42 ) / baseIconSize;
    group:SetScale(scale);
    group:ClearAllPoints();
    group:SetPoint(
        "TOPRIGHT",
        arenaFrame,
        "TOPLEFT",
        ( config.arenaOffensiveIconOffsetX or -4 ) / scale,
        ( config.arenaOffensiveIconOffsetY or 0 ) / scale
    );
    group.lastModified = config.lastModified;
    return true;
end

local function PositionIcon(group, icon)
    icon:ClearAllPoints();
    icon:SetPoint("TOPRIGHT", group, "TOPRIGHT", 0, 0);
end

local function PaintIcon(icon, auraData, durationObject, startTime, duration)
    icon.texture:SetTexture(auraData.icon);

    if durationObject and icon.cooldown.SetCooldownFromDurationObject then
        icon.cooldown:SetCooldownFromDurationObject(durationObject);
        icon.cooldown:Show();
    elseif startTime and duration then
        icon.cooldown:SetCooldown(startTime, duration);
        icon.cooldown:Show();
    else
        ClearCooldown(icon.cooldown);
        icon.cooldown:Hide();
    end

    icon:Show();
end

local function ClearUnusedIcons(group, firstUnusedIndex)
    for i = firstUnusedIndex, #group.icons do
        ClearCooldown(group.icons[i].cooldown);
        group.icons[i]:Hide();
    end
end

local function CollectOffensiveAuras(unit)
    local results = {};
    if ( not UnitExists(unit) ) or ( not C_UnitAuras ) then return results end

    if C_UnitAuras.GetUnitAuras then
        local auras = C_UnitAuras.GetUnitAuras(unit, "HELPFUL");
        if auras then
            for _, auraData in ipairs(auras) do
                if ShouldShowAura(auraData) then
                    table.insert(results, auraData);
                end
            end
        end
    else
        for i = 1, maxAurasToScan do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL");
            if ( not auraData ) or ( not auraData.name ) then break end
            if ShouldShowAura(auraData) then
                table.insert(results, auraData);
            end
        end
    end

    table.sort(results, SortAuras);
    return results;
end

local function UpdateGroup(index)
    local config = GetConfig();
    local group = EnsureGroup(index);

    if ( not config.arenaOffensiveIconsEnabled ) or ( not RefreshGroupPosition(group) ) then
        return;
    end

    local unit = group.unit;
    local auraData = CollectOffensiveAuras(unit)[1];
    if not auraData then
        ClearUnusedIcons(group, 1);
        group:Hide();
        return;
    end

    local icon = EnsureIcon(group, 1);
    PositionIcon(group, icon);

    local durationObject = C_UnitAuras and C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID);
    local startTime, duration;
    if ( not durationObject ) and auraData.duration and auraData.expirationTime
        and ( not addon.IsSecretValue(auraData.duration) ) and ( not addon.IsSecretValue(auraData.expirationTime) ) then
        startTime = auraData.expirationTime - auraData.duration;
        duration = auraData.duration;
    end

    PaintIcon(icon, auraData, durationObject, startTime, duration);
    ClearUnusedIcons(group, 2);
    group:Show();
end

local function UpdateAllGroups()
    if ( not SweepyBoop.db ) then return end

    local config = GetConfig();
    if not config.arenaOffensiveIconsEnabled then
        HideAllGroups();
        return;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        UpdateGroup(i);
    end
end

local function ShowTestIcons()
    for i = 1, addon.MAX_ARENA_SIZE do
        local group = EnsureGroup(i);
        if RefreshGroupPosition(group) then
            local spellID = testSpells[i] or testSpells[1];
            local icon = EnsureIcon(group, 1);
            local auraData = {
                icon = addon.GetSpellTexture(spellID),
                auraInstanceID = i,
                spellId = spellID,
            };
            PositionIcon(group, icon);
            PaintIcon(icon, auraData, nil, GetTime() - i, 12 + i);
            ClearUnusedIcons(group, 2);
            group:Show();
        end
    end
    isInTest = true;
end

local function EnsureBlizzardArenaTestFrames()
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

    EnsureBlizzardArenaTestFrames();
    ShowTestIcons();
end

function SweepyBoop:HideTestArenaOffensiveIcons()
    HideAllGroups();
end

function SweepyBoop:UpdateArenaOffensiveIcons()
    if isInTest then
        ShowTestIcons();
        return;
    end

    UpdateAllGroups();
end

function SweepyBoop:SetupArenaOffensiveIcons()
    if not eventFrame then
        eventFrame = CreateFrame("Frame");
        eventFrame:SetScript("OnEvent", function(_, event, unit)
            if event == addon.UNIT_AURA then
                if unit and unit:match("^arena%d+$") then
                    local index = tonumber(unit:match("^arena(%d+)$"));
                    if index then
                        UpdateGroup(index);
                    end
                end
                return;
            end

            isInTest = false;
            if event == addon.PLAYER_ENTERING_WORLD or event == "PVP_MATCH_COMPLETE" then
                HideAllGroups();
            end
            UpdateAllGroups();
        end);
    end

    eventFrame:UnregisterAllEvents();
    if GetConfig().arenaOffensiveIconsEnabled then
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        eventFrame:RegisterEvent(addon.UNIT_AURA);
        if addon.PROJECT_MAINLINE then
            eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
            eventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
            eventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
        end
        UpdateAllGroups();
    else
        HideAllGroups();
    end
end
