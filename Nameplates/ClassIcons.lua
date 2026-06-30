local _, addon = ...;

local specialIconScaleFactor = 1.25;
local classIconBorderSize = 44;
local classIconSize = 40;
local specialClassIconSize = 36;
local targetHighlightAnimationThrottle = 0.02;
local targetHighlightAnimationFrequency = 0.9;
local targetHighlightPulseScale = 0.22;
local targetHighlightPulseMaxAlpha = 0.82;
local targetHighlightPulseMinAlpha = 0.22;
local targetHighlightBaseMinAlpha = 0.88;
local targetHighlightColor = { 1, 0.88, 0, 1 };

local crowdControlPriority = { -- sort by remaining time, then priority
    ["stun"] = 100,
    ["controlled_stun"] = 100, -- TBC: same as stun (e.g., Kidney Shot, Cheap Shot)
    ["random_stun"] = 100, -- TBC: same as stun (e.g., Mace Specialization)
    ["silence"] = 90,
    ["cyclone"] = 85, -- TBC: Cyclone has its own DR category
    ["disorient"] = 80,
    ["incapacitate"] = 80,
    ["fear"] = 80, -- TBC: Fear has its own DR category
};

local PvPUnitClassification;
local flagCarrierIcons;
if addon.PROJECT_MAINLINE then
    PvPUnitClassification = Enum.PvPUnitClassification;
    flagCarrierIcons = {
        [PvPUnitClassification.FlagCarrierHorde] = addon.ICON_ID_FLAG_CARRIER_HORDE,
        [PvPUnitClassification.FlagCarrierAlliance] = addon.ICON_ID_FLAG_CARRIER_ALLIANCE,
        [PvPUnitClassification.FlagCarrierNeutral] = addon.ICON_ID_FLAG_CARRIER_NEUTRAL,
    };
end

-- Suppress friendly FC icon and target highlight, as NeatPlates unregisters all UnitFrame events, causing problems for those 2 features
local hasConflict = C_AddOns.IsAddOnLoaded("NeatPlates");

local function EnsureAnimatedTargetHighlightPulse(frame)
    if frame.targetHighlightPulse then
        return;
    end

    local pulse = frame:CreateTexture(nil, "OVERLAY");
    pulse:SetDrawLayer("OVERLAY", 2);
    pulse:SetAtlas("charactercreate-ring-select");
    pulse:SetVertexColor(1, 0.88, 0, 1);
    pulse:SetBlendMode("ADD");
    pulse:SetPoint("CENTER", frame);
    pulse:Hide();
    frame.targetHighlightPulse = pulse;
end


local function SetTargetHighlightAnimation(frame, progress)
    local highlight = frame.targetHighlight;
    local wave = ( math.sin(( progress % 1 ) * math.pi * 2) + 1 ) / 2;
    local width, height = highlight:GetSize();
    local scale = 1 + ( targetHighlightPulseScale * wave );
    local alpha = targetHighlightPulseMaxAlpha - ( ( targetHighlightPulseMaxAlpha - targetHighlightPulseMinAlpha ) * wave );

    highlight:SetVertexColor(unpack(targetHighlightColor));
    highlight:SetRotation(-( progress % 1 ) * math.pi * 2);
    highlight:SetAlpha(targetHighlightBaseMinAlpha + ( ( 1 - targetHighlightBaseMinAlpha ) * ( 1 - wave ) ));
    frame.targetHighlightPulse:SetSize(width * scale, height * scale);
    frame.targetHighlightPulse:SetAlpha(alpha);
    frame.targetHighlightPulse:SetRotation(( progress % 1 ) * math.pi * 2);
end


local function ResetTargetHighlightAnimation(frame)
    if not frame.targetHighlight then
        return;
    end

    frame.targetHighlight:SetVertexColor(unpack(targetHighlightColor));
    frame.targetHighlight:SetRotation(0);
    frame.targetHighlight:SetAlpha(1);
    if frame.targetHighlightPulse then
        frame.targetHighlightPulse:SetRotation(0);
        frame.targetHighlightPulse:SetAlpha(1);
        frame.targetHighlightPulse:Hide();
    end
end

local function TargetHighlight_OnUpdate(self, elapsed)
    if ( not self.targetHighlight ) or ( not self.targetHighlightAnimatedShown ) then
        self:SetScript("OnUpdate", nil);
        return;
    end

    self.targetHighlightAnimationElapsed = self.targetHighlightAnimationElapsed + elapsed;
    if self.targetHighlightAnimationElapsed < targetHighlightAnimationThrottle then
        return;
    end

    local step = self.targetHighlightAnimationElapsed;
    self.targetHighlightAnimationElapsed = 0;
    self.targetHighlightAnimationProgress = ( self.targetHighlightAnimationProgress + ( step * targetHighlightAnimationFrequency ) ) % 1;
    SetTargetHighlightAnimation(self, self.targetHighlightAnimationProgress);
end

local HideTargetHighlight;

local function IsTargetHighlightVisible(frame)
    return frame.targetHighlightAnimatedShown or ( frame.targetHighlight and frame.targetHighlight:IsShown() );
end

local function UpdateClassIconBorderShown(frame)
    if frame and frame.border then
        frame.border:SetShown(not IsTargetHighlightVisible(frame));
    end
end

local function ShowAnimatedTargetHighlight(frame)
    if ( not frame ) or ( not frame.targetHighlight ) then
        return;
    end

    local highlight = frame.targetHighlight;
    if frame.targetHighlightAnimatedShown then
        return;
    end

    ResetTargetHighlightAnimation(frame);
    EnsureAnimatedTargetHighlightPulse(frame);
    frame.targetHighlightPulse:Show();

    frame.targetHighlightAnimatedShown = true;
    frame.targetHighlightAnimationElapsed = 0;
    frame.targetHighlightAnimationProgress = 0;
    SetTargetHighlightAnimation(frame, 0);
    highlight:Show();
    UpdateClassIconBorderShown(frame);
    frame:SetScript("OnUpdate", TargetHighlight_OnUpdate);
end

local function ShowStaticTargetHighlight(frame)
    if ( not frame ) or ( not frame.targetHighlight ) then
        return;
    end

    HideTargetHighlight(frame);
    frame.targetHighlight:Show();
    UpdateClassIconBorderShown(frame);
end

HideTargetHighlight = function(frame)
    if ( not frame ) or ( not frame.targetHighlight ) then
        return;
    end

    local highlight = frame.targetHighlight;
    frame.targetHighlightAnimatedShown = false;
    frame:SetScript("OnUpdate", nil);
    ResetTargetHighlightAnimation(frame);
    highlight:Hide();
    UpdateClassIconBorderShown(frame);
end

addon.SetTargetHighlightShown = function(frame, shouldShow, shouldAnimate)
    if not shouldShow then
        HideTargetHighlight(frame);
    elseif shouldAnimate then
        ShowAnimatedTargetHighlight(frame);
    else
        ShowStaticTargetHighlight(frame);
    end
end

local function EnsureClassIcon(nameplate)
    nameplate.classIconContainer = nameplate.classIconContainer or {};

    if ( not nameplate.classIconContainer.FriendlyClassIcon ) then
        nameplate.classIconContainer.FriendlyClassIcon = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "BOTTOM", true);
        nameplate.classIconContainer.FriendlyClassIcon:Hide();
    end

    if ( not nameplate.classIconContainer.FriendlyClassArrow ) then
        nameplate.classIconContainer.FriendlyClassArrow = addon.CreateClassColorArrowFrame(nameplate);
        nameplate.classIconContainer.FriendlyClassArrow:Hide();
    end

    if ( not nameplate.classIconContainer.NameFrame ) then
        nameplate.classIconContainer.NameFrame = CreateFrame("Frame", nil, nameplate);
        nameplate.classIconContainer.NameFrame:SetMouseClickEnabled(false);
        nameplate.classIconContainer.NameFrame:SetAlpha(1);
        nameplate.classIconContainer.NameFrame:SetIgnoreParentAlpha(true);
        nameplate.classIconContainer.NameFrame:SetIgnoreParentScale(true);
        nameplate.classIconContainer.NameFrame:SetSize(200, 15);
        nameplate.classIconContainer.NameFrame:SetPoint("TOP", nameplate, "CENTER");

        local name = nameplate.classIconContainer.NameFrame:CreateFontString(nil, "OVERLAY");
        name:SetFontObject("GameFontNormalOutline");
        name:SetText("");
        name:SetAllPoints();
        nameplate.classIconContainer.NameFrame.name = name;
    end
end

local function GetIconOptions(class, pvpClassification, specIconID, roleAssigned)
    local iconID;
    local iconCoords = {0, 1, 0, 1};
    local iconScale;
    local isSpecialIcon;

    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local isArena = IsActiveBattlefieldArena();
    local isBattleground = ( UnitInBattleground("player") ~= nil ); -- This returns true for arenas, so for hideInBattlegrounds, we need to ensure we are not in an arena to hide icons

    -- Hide icons but still show name
    if config.hideOutsidePvP and ( not isArena ) and ( not isBattleground ) then
        return iconID, iconCoords, iconScale, isSpecialIcon;
    elseif config.hideInBattlegrounds and isBattleground and ( not isArena ) then
        return iconID, iconCoords, iconScale, isSpecialIcon;
    end

    -- Check regular class, then healer, then flag carrier; latter overwrites the former
    iconID = addon.ICON_ID_CLASSES;
    iconCoords = CLASS_ICON_TCOORDS[class];
    iconScale = config.classIconSize;

    if config.showSpecIcons and specIconID then -- Show spec icon in PvP instances, overwritten by healer / flag carrier icons
        iconID = specIconID;
        iconCoords = {0, 1, 0, 1};
    end

    -- TBC: Skip healer detection since UnitGroupRolesAssigned doesn't work reliably
    -- and there's no spec system to fall back to
    if ( not addon.PROJECT_TBC ) then
        local isHealer = ( roleAssigned == "HEALER" );
        if isHealer and config.useHealerIcon then
            iconID = addon.ICON_ID_HEALER;
            iconCoords = addon.ICON_COORDS_HEALER;
            iconScale = config.healerIconSize;
            isSpecialIcon = true;
        elseif ( not isHealer ) and config.showHealerOnly then
            iconID = nil;
        end
    end

    if addon.PROJECT_MAINLINE and ( not hasConflict ) then
        if ( pvpClassification ~= nil ) and ( flagCarrierIcons[pvpClassification] ) and config.useFlagCarrierIcon then
            iconID = flagCarrierIcons[pvpClassification];
            iconCoords = {0, 1, 0, 1};
            iconScale = config.flagCarrierIconSize;
            isSpecialIcon = true;
        end
    end

    return iconID, iconCoords, iconScale, isSpecialIcon;
end

addon.UpdateClassIconTargetHighlight = function (nameplate, frame)
    local isTarget = UnitIsUnit(frame.unit, "target");
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local featureEnabled = config.targetHighlight and ( not hasConflict );
    if nameplate.classIconContainer then
        if nameplate.classIconContainer.FriendlyClassIcon then
            local iconFrame = nameplate.classIconContainer.FriendlyClassIcon;
            local iconVisible = iconFrame:IsShown() and ( iconFrame.icon:GetAlpha() > 0 );
            addon.SetTargetHighlightShown(iconFrame, isTarget and featureEnabled and iconVisible, config.animatedTargetHighlight);
        end
    end
end

addon.UpdatePlayerName = function (nameplate, frame)
    if ( not nameplate.classIconContainer ) or ( not nameplate.classIconContainer.NameFrame ) then return end

    local nameFrame = nameplate.classIconContainer.NameFrame;

    local shouldUpdate;
    if addon.PROJECT_MAINLINE then
        shouldUpdate = true;
    else
        local unitGUID = UnitGUID(frame.unit);
        shouldUpdate = ( nameFrame.unitGUID ~= unitGUID );
    end

    if shouldUpdate then
        local name = UnitName(frame.unit) or "";
        local class = addon.GetUnitClass(frame.unit);
        local classColor = class and RAID_CLASS_COLORS[class];

        nameFrame.name:SetText(name);
        if classColor then
            nameFrame.name:SetTextColor(classColor.r, classColor.g, classColor.b);
        else
            nameFrame.name:SetTextColor(1, 1, 1);
        end

        if ( not addon.PROJECT_MAINLINE ) then
            nameFrame.unitGUID = unitGUID;
        end
    end
end

local function SortCrowdControlAurasNewestFirst(auraA, auraB)
    return ( auraA.auraInstanceID or 0 ) > ( auraB.auraInstanceID or 0 );
end

local function GetMainlineClassIconCrowdControl(unit)
    local auras = C_UnitAuras.GetUnitAuras(unit, "HARMFUL|CROWD_CONTROL", nil, Enum.UnitAuraSortRule.Unsorted, Enum.UnitAuraSortDirection.Reverse);
    if ( not auras ) or ( #auras == 0 ) then return end

    table.sort(auras, SortCrowdControlAurasNewestFirst);
    for _, auraData in ipairs(auras) do
        local spellID = auraData.spellId;
        if spellID then
            local isCrowdControl = C_Spell.IsSpellCrowdControl(spellID);
            if addon.IsSecretValue(isCrowdControl) or isCrowdControl then
                return auraData;
            end
        end
    end
end

local function HideClassIconCrowdControl(iconFrame)
    if not iconFrame then return end

    if iconFrame.cooldownCC then
        iconFrame.cooldownCC:SetCooldown(0, 0);
        iconFrame.cooldownCC:Hide();
    end
    if iconFrame.iconCC then
        iconFrame.iconCC:Hide();
    end
end

addon.UpdateClassIconCrowdControl = function(nameplate, frame)
    if ( not nameplate.classIconContainer ) then return end
    local classIconContainer = nameplate.classIconContainer;
    local iconFrame = classIconContainer.FriendlyClassIcon;
    -- No need to update if class icon is not shown
    if ( not iconFrame ) or ( not iconFrame:IsShown() ) then return end
    local iconCC = iconFrame.iconCC;
    local cooldownCC = iconFrame.cooldownCC;

    if addon.PROJECT_MAINLINE then
        if SweepyBoop.db.profile.nameplatesFriendly.showCrowdControl
            and UnitInParty(frame.unit)
            and UnitIsPlayer(frame.unit)
            and UnitIsFriend("player", frame.unit) then
            local auraData = GetMainlineClassIconCrowdControl(frame.unit);
            if auraData then
                iconCC:SetTexture(auraData.icon);
                iconCC:Show();

                local durationObject = C_UnitAuras.GetAuraDuration(frame.unit, auraData.auraInstanceID);
                if durationObject and cooldownCC.SetCooldownFromDurationObject then
                    cooldownCC:SetCooldownFromDurationObject(durationObject);
                    cooldownCC:Show();
                elseif auraData.duration and auraData.expirationTime then
                    cooldownCC:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration);
                    cooldownCC:Show();
                else
                    cooldownCC:SetCooldown(0, 0);
                    cooldownCC:Hide();
                end
                return;
            end
        end

        HideClassIconCrowdControl(iconFrame);
        return;
    end

    local spellID;
    local priority = 0; -- init with a low priority
    local duration;
    local expirationTime;

    if SweepyBoop.db.profile.nameplatesFriendly.showCrowdControl and UnitInParty(frame.unit) then
        for i = 1, 40 do
            local auraData = C_UnitAuras.GetDebuffDataByIndex(frame.unit, i);
            if ( not auraData ) or ( not auraData.spellId ) then break end -- No more auras
            if addon.DRList[auraData.spellId] then
                local category = addon.DRList[auraData.spellId];
                local update = false;
                if crowdControlPriority[category] then -- Found a CC that should be shown
                    -- No expirationTime means this aura never expires, so it should be prioritized
                    if ( not auraData.expirationTime ) or ( expirationTime and auraData.expirationTime and auraData.expirationTime < expirationTime ) then
                        update = true;
                    elseif crowdControlPriority[category] > priority then -- same expirationTime, use priority as tie breaker
                        update = true;
                    end

                    if update then
                        priority = crowdControlPriority[category];
                        duration = auraData.duration;
                        expirationTime = auraData.expirationTime;
                        spellID = auraData.spellId;
                    end
                end
            end
        end
    end

    if ( not spellID ) then
        HideClassIconCrowdControl(iconFrame);
    else
        iconCC:SetTexture(addon.GetSpellTexture(spellID));
        iconCC:Show();

        if duration then
            cooldownCC:SetCooldown(expirationTime - duration, duration);
            cooldownCC:Show();
        else
            cooldownCC:SetCooldown(0, 0);
            cooldownCC:Hide();
        end
    end
end

if addon.internal then
    function SweepyBoop:DebugClassIconCrowdControl(duration, spellID)
        duration = duration or 6;
        spellID = spellID or 118; -- Polymorph

        local iconTexture = addon.GetSpellTexture(spellID);
        local expiresAt = GetTime() + duration;
        local count = 0;

        for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
            local classIconContainer = nameplate.classIconContainer;
            local iconFrame = classIconContainer and classIconContainer.FriendlyClassIcon;
            if iconFrame and iconFrame:IsShown() and iconFrame.iconCC and iconFrame.cooldownCC then
                iconFrame.debugCrowdControlExpiresAt = expiresAt;
                iconFrame.iconCC:SetTexture(iconTexture);
                iconFrame.iconCC:Show();
                iconFrame.cooldownCC:SetCooldown(GetTime(), duration);
                iconFrame.cooldownCC:Show();
                count = count + 1;
            end
        end

        if count > 0 then
            C_Timer.After(duration, function()
                for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
                    local classIconContainer = nameplate.classIconContainer;
                    local iconFrame = classIconContainer and classIconContainer.FriendlyClassIcon;
                    if iconFrame and iconFrame.debugCrowdControlExpiresAt == expiresAt then
                        iconFrame.debugCrowdControlExpiresAt = nil;
                        HideClassIconCrowdControl(iconFrame);
                    end
                end
            end);
        end

        print(string.format("SweepyBoop: showing %ds test Polymorph on %d friendly class icon(s)", duration, count));
    end
end

addon.UpdateClassIcon = function(nameplate, frame)
    if ( not nameplate.classIconContainer ) then return end
    local classIconContainer = nameplate.classIconContainer;
    if ( not classIconContainer.FriendlyClassIcon ) or ( not classIconContainer.FriendlyClassArrow ) then return end

    -- Full update if class, PvPClassification, roleAssigned or configurations have changed
    -- (healer icons work between solo shuffle rounds because UnitGroupRolesAssigned works on opponent healer as well)
    -- Always update visibility and target highlight, since CompactUnitFrame_UpdateName is called on every target change
    local class = addon.GetUnitClass(frame.unit);
    local pvpClassification, specIconID;
    local specInfo;

    if addon.PROJECT_MAINLINE then
        pvpClassification = UnitPvpClassification(frame.unit);
        specInfo = addon.GetPlayerSpec(frame.unit);
        if specInfo then
            specIconID = specInfo.icon;
        end
    end

    -- UnitGroupRolesAssigned doesn't work in open world, fall back to spec-based detection
    local roleAssigned = UnitGroupRolesAssigned(frame.unit);
    if ( roleAssigned == "NONE" or roleAssigned == nil ) and specInfo and specInfo.role then
        roleAssigned = specInfo.role;
    end
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    if ( classIconContainer.class ~= class )
        or ( classIconContainer.pvpClassification ~= pvpClassification )
        or ( classIconContainer.specIconID ~= specIconID )
        or ( classIconContainer.roleAssigned ~= roleAssigned )
        or ( classIconContainer.lastModified ~= config.lastModified ) then
        local iconID, iconCoords, iconScale, isSpecialIcon = GetIconOptions(class, pvpClassification, specIconID, roleAssigned);
        local nameFrame = classIconContainer.NameFrame;
        local iconFrame = classIconContainer.FriendlyClassIcon;
        local arrowFrame = classIconContainer.FriendlyClassArrow;

        if ( not iconID ) or ( not iconCoords ) then -- nil icon ID due to "Show Healer Only" option, or classFileName is not valid
            iconFrame.icon:SetAlpha(0);
            iconFrame.border:SetAlpha(0);
            iconFrame.targetHighlight:SetAlpha(0);
            arrowFrame.icon:SetAlpha(0);
            arrowFrame.targetHighlight:SetAlpha(0);
        else
            iconFrame.icon:SetAlpha(1);
            iconFrame.border:SetAlpha(1);
            iconFrame.targetHighlight:SetAlpha(1);

            local classColor = RAID_CLASS_COLORS[class];
            UpdateClassIconBorderShown(iconFrame);
            iconFrame.border:SetSize(classIconBorderSize, classIconBorderSize);
            if iconFrame.border.mask then
                iconFrame.border.mask:SetSize(classIconBorderSize, classIconBorderSize);
            end

            local iconMaskSize = ( isSpecialIcon and specialClassIconSize ) or classIconSize;
            iconFrame.mask:SetSize(iconMaskSize, iconMaskSize);
            if iconFrame.maskCC then
                iconFrame.maskCC:SetSize(iconMaskSize, iconMaskSize);
            end
            if config.classIconClassColoredBorder then
                iconFrame.border:SetVertexColor(classColor.r, classColor.g, classColor.b);
            else
                iconFrame.border:SetVertexColor(1, 1, 1);
            end

            local showPlayerName = config.showPlayerName and ( not config.keepHealthBar );
            local offset = config.classIconOffset;
            if showPlayerName then
                nameFrame:SetPoint("TOP", nameplate, "CENTER", 0, offset);
            end

            iconFrame.icon:SetTexture(iconID);
            iconFrame.icon:SetTexCoord(unpack(iconCoords));
            iconFrame:SetScale(iconScale);
            iconFrame:ClearAllPoints();
            if showPlayerName then
                iconFrame:SetPoint("BOTTOM", classIconContainer.NameFrame, "TOP");
            else
                iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, offset);
            end

            arrowFrame.icon:SetAlpha(1);
            arrowFrame.targetHighlight:SetAlpha(1);
            arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b);
            arrowFrame:SetScale(iconScale);
            arrowFrame:ClearAllPoints();
            if ( config.classIconStyle == addon.CLASS_ICON_STYLE.ICON_AND_ARROW ) then
                arrowFrame:SetPoint("BOTTOM", iconFrame, "TOP", 0, -2); -- Get the arrow closer to the icon
            elseif showPlayerName then
                arrowFrame:SetPoint("BOTTOM", classIconContainer.NameFrame, "TOP");
            else
                arrowFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, offset);
            end
        end

        if iconFrame.icon:GetAlpha() == 0 then
            addon.SetTargetHighlightShown(iconFrame, false, config.animatedTargetHighlight);
        end

        classIconContainer.isSpecialIcon = isSpecialIcon;

        classIconContainer.class = class;
        classIconContainer.pvpClassification = pvpClassification;
        classIconContainer.specIconID = specIconID;
        classIconContainer.roleAssigned = roleAssigned;
        classIconContainer.lastModified = config.lastModified;
    end

    addon.UpdateClassIconTargetHighlight(nameplate, frame);
end

addon.ShowClassIcon = function (nameplate, frame)
    EnsureClassIcon(nameplate);
    addon.UpdatePlayerName(nameplate, frame);
    addon.UpdateClassIcon(nameplate, frame);
    if ( not nameplate.classIconContainer ) then return end
    local classIconContainer = nameplate.classIconContainer;
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    classIconContainer.NameFrame:SetShown(config.showPlayerName and ( not config.keepHealthBar ) );
    local style = config.classIconStyle;
    if classIconContainer.FriendlyClassIcon then
        classIconContainer.FriendlyClassIcon:SetShown(style == addon.CLASS_ICON_STYLE.ICON or style == addon.CLASS_ICON_STYLE.ICON_AND_ARROW or classIconContainer.isSpecialIcon);
    end
    if classIconContainer.FriendlyClassArrow then
        local shouldShow = false;
        if style == addon.CLASS_ICON_STYLE.ARROW then
            shouldShow = ( not classIconContainer.isSpecialIcon );
        elseif style == addon.CLASS_ICON_STYLE.ICON_AND_ARROW then
            shouldShow = ( UnitInBattleground("player") ~= nil );
            --shouldShow = true; -- For local testing, comment out before landing in production!
        end
        classIconContainer.FriendlyClassArrow:SetShown(shouldShow);
    end

    addon.UpdateClassIconTargetHighlight(nameplate, frame);
    addon.UpdateClassIconCrowdControl(nameplate, frame);
end

addon.HideClassIcon = function(nameplate)
    if ( not nameplate.classIconContainer ) then return end
    local classIconContainer = nameplate.classIconContainer;

    if classIconContainer.FriendlyClassIcon then
        addon.SetTargetHighlightShown(classIconContainer.FriendlyClassIcon, false, false);
        HideClassIconCrowdControl(classIconContainer.FriendlyClassIcon);
        classIconContainer.FriendlyClassIcon:Hide();
    end
    if classIconContainer.FriendlyClassArrow then
        classIconContainer.FriendlyClassArrow:Hide();
    end
    if classIconContainer.NameFrame then
        classIconContainer.NameFrame:Hide();
    end
end
