local _, addon = ...;

local maxPartyMembers = 4;
local petIconSize = 40;
local petIconBorderSize = 64;
local targetHighlightSize = 55;
local targetHighlightPulseScale = 0.22;
local targetHighlightPulseMaxAlpha = 0.82;
local targetHighlightPulseMinAlpha = 0.22;
local targetHighlightAnimationFrequency = 0.9;
local hunterPetFamilyAuras = {
    [264662] = true,
    [264656] = true,
    [264663] = true,
    [284301] = true,
};

local PET_ICON_MODE_LOCAL = "local";
local PET_ICON_MODE_OTHER = "other";

local function EnsureIcon(nameplate)
    if ( not nameplate.FriendlyPetIcon ) then
        nameplate.FriendlyPetIcon = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "BOTTOM", true);
        nameplate.FriendlyPetIcon.icon:SetTexture(addon.ICON_ID_PET);
        nameplate.FriendlyPetIcon:Hide();
    end

    return nameplate.FriendlyPetIcon;
end

local function HideTargetHighlight(iconFrame)
    if not iconFrame then return end

    if addon.SetTargetHighlightShown then
        addon.SetTargetHighlightShown(iconFrame, false, false);
    elseif iconFrame.targetHighlight then
        iconFrame.targetHighlight:Hide();
    end
end

local function ApplyPetIconLayout(iconFrame, nameplate, config)
    if ( not iconFrame.petIconLayoutApplied )
            or iconFrame.lastModifiedFriendly ~= config.lastModified then
        iconFrame:SetScale(config.petIconSize);
        iconFrame:ClearAllPoints();
        iconFrame:SetPoint(
            "BOTTOM",
            nameplate,
            "BOTTOM",
            config.classIconHorizontalOffset or 0,
            config.classIconOffset or 0
        );
        iconFrame.lastModifiedFriendly = config.lastModified;
        iconFrame.petIconLayoutApplied = true;
    end
end

local function CreateGatedPetIcon(parent)
    local iconFrame = addon.CreateClassOrSpecIcon(parent, "CENTER", "CENTER", true);
    -- The parent carries protected ownership. Unlike ordinary nameplate icons,
    -- this descendant must inherit its parent's alpha gate.
    iconFrame:SetIgnoreParentAlpha(false);
    iconFrame.icon:SetTexture(addon.ICON_ID_PET);
    iconFrame:Hide();
    return iconFrame;
end

local function CreateHunterPetIcon(button)
    local iconFrame = CreateFrame("Frame", nil, button);
    iconFrame:SetAllPoints(button);
    iconFrame:SetMouseClickEnabled(false);

    local icon = iconFrame:CreateTexture(nil, "BORDER");
    icon:SetAllPoints(iconFrame);
    icon:SetTexture(addon.ICON_ID_PET);

    local mask = iconFrame:CreateMaskTexture();
    mask:SetAllPoints(icon);
    mask:SetTexture("Interface/Masks/CircleMaskScalable");
    icon:AddMaskTexture(mask);

    local border = iconFrame:CreateTexture(nil, "OVERLAY");
    border:SetPoint("CENTER", iconFrame);
    border:SetSize(petIconBorderSize, petIconBorderSize);
    border:SetTexture(addon.INTERFACE_SWEEPY .. "Art/ClassIconBorder");
end

local function CreateHunterPetTargetHighlight(button)
    local highlight = button:CreateTexture(nil, "OVERLAY");
    highlight:SetPoint("CENTER", button);
    highlight:SetSize(targetHighlightSize, targetHighlightSize);
    highlight:SetAtlas("charactercreate-ring-select");
    highlight:SetVertexColor(1, 0.88, 0);
end

local function CreateHunterAuraRoot(ownerGate, slotKey, initializeFrame)
    local root = CreateFrame("Frame", nil, ownerGate);
    root:SetAllPoints(ownerGate);
    root:SetMouseClickEnabled(false);
    root:SetIgnoreParentAlpha(false);
    root:SetAlpha(0);
    root:Hide();

    local presentation = CreateFrame("Frame", nil, root);
    presentation:SetAllPoints(root);

    local container = CreateFrame(
        "AuraContainer",
        nil,
        presentation,
        "CustomAuraContainerTemplate"
    );
    container:SetAllPoints(presentation);
    container:SetEnabled(false);
    container:Hide();
    container:AddAuraSlot(slotKey, "HELPFUL", {
        candidateFilters = {
            includeSpellIDs = hunterPetFamilyAuras,
        },
        sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            button:SetAllPoints(container);
            initializeFrame(button);
        end,
    });

    root.presentation = presentation;
    root.container = container;
    root.activationGeneration = 0;
    return root;
end

local function EnsureOwnerGate(nameplate, partyIndex)
    nameplate.FriendlyPetOwnerGates = nameplate.FriendlyPetOwnerGates or {};
    local gate = nameplate.FriendlyPetOwnerGates[partyIndex];
    if gate then return gate end

    gate = CreateFrame("Frame", nil, nameplate);
    gate:SetMouseClickEnabled(false);
    gate:SetIgnoreParentAlpha(true);
    gate:SetSize(petIconSize, petIconSize);
    gate:SetFrameStrata("HIGH");
    gate:SetAlpha(0);
    gate:Hide();
    nameplate.FriendlyPetOwnerGates[partyIndex] = gate;
    return gate;
end

local function EnsureNonHunterPetIcon(ownerGate)
    if not ownerGate.petIcon then
        ownerGate.petIcon = CreateGatedPetIcon(ownerGate);
    end
    return ownerGate.petIcon;
end

local function EnsureHunterPetAuraRoots(ownerGate)
    if not ownerGate.hunterPetAuraRoot then
        ownerGate.hunterPetAuraRoot = CreateHunterAuraRoot(
            ownerGate,
            "HunterPetFamilyIcon",
            CreateHunterPetIcon
        );
        ownerGate.hunterPetTargetRoot = CreateHunterAuraRoot(
            ownerGate,
            "HunterPetFamilyTarget",
            CreateHunterPetTargetHighlight
        );
        ownerGate.hunterPetTargetRoot.presentation:SetAlpha(0);
    end

    return ownerGate.hunterPetAuraRoot, ownerGate.hunterPetTargetRoot;
end

local function StopHunterPetTargetAnimation(root)
    root:SetScript("OnUpdate", nil);
    root.targetAnimationProgress = 0;
    root.presentation:SetAlpha(0);
    root.presentation:SetScale(1);
end

local function ApplyHunterPetTargetHighlight(root)
    if not root.isArmed then return end

    root:SetScript("OnUpdate", nil);
    root.presentation:SetScale(1);
    if not root.targetHighlightShown then
        root.presentation:SetAlpha(0);
        return;
    end

    if not root.targetHighlightAnimated then
        root.presentation:SetAlpha(1);
        return;
    end

    root.targetAnimationProgress = root.targetAnimationProgress or 0;
    root:SetScript("OnUpdate", function(self, elapsed)
        self.targetAnimationProgress =
            ( self.targetAnimationProgress
                + ( elapsed * targetHighlightAnimationFrequency ) ) % 1;
        local wave =
            ( math.sin(self.targetAnimationProgress * math.pi * 2) + 1 ) / 2;
        self.presentation:SetScale(1 + ( targetHighlightPulseScale * wave ));
        self.presentation:SetAlpha(
            targetHighlightPulseMaxAlpha
                - ( ( targetHighlightPulseMaxAlpha
                    - targetHighlightPulseMinAlpha ) * wave )
        );
    end);
end

local function DeactivateHunterAuraRoot(root, isTargetRoot)
    root.activationGeneration = root.activationGeneration + 1;
    root.isArmed = false;
    root:SetScript("OnUpdate", nil);
    root:SetAlpha(0);
    root:Hide();
    root.container:SetEnabled(false);
    root.container:Hide();

    if isTargetRoot then
        StopHunterPetTargetAnimation(root);
        root.targetHighlightShown = false;
        root.targetHighlightAnimated = false;
    end
end

local function DeactivateOwnerGate(ownerGate)
    ownerGate.ownerClass = nil;
    ownerGate.activeUnit = nil;
    ownerGate:SetAlpha(0);
    ownerGate:Hide();

    if ownerGate.petIcon then
        HideTargetHighlight(ownerGate.petIcon);
        ownerGate.petIcon:Hide();
    end
    if ownerGate.hunterPetAuraRoot then
        DeactivateHunterAuraRoot(ownerGate.hunterPetAuraRoot, false);
        DeactivateHunterAuraRoot(ownerGate.hunterPetTargetRoot, true);
    end
end

local function HideOtherPlayerPetIcons(nameplate)
    local ownerGates = nameplate.FriendlyPetOwnerGates;
    if not ownerGates then return end

    for _, ownerGate in pairs(ownerGates) do
        DeactivateOwnerGate(ownerGate);
    end
end

local function IsCurrentHunterPetAssignment(nameplate, ownerGate, unit)
    return nameplate.FriendlyPetIconMode == PET_ICON_MODE_OTHER
        and nameplate.FriendlyPetIconUnit == unit
        and ownerGate.ownerClass == addon.HUNTER
        and ownerGate.activeUnit == unit
        and addon.IsUsingRealAuraData();
end

local function ArmHunterAuraRoot(root, nameplate, ownerGate, unit, onArmed)
    root.activationGeneration = root.activationGeneration + 1;
    local generation = root.activationGeneration;
    local updateCount = 0;
    root:SetScript("OnUpdate", function(self)
        if self.activationGeneration ~= generation
                or not IsCurrentHunterPetAssignment(
                    nameplate,
                    ownerGate,
                    unit
                ) then
            self:SetScript("OnUpdate", nil);
            return;
        end

        updateCount = updateCount + 1;
        if updateCount >= 2 then
            self:SetScript("OnUpdate", nil);
            self.isArmed = true;
            self:SetAlpha(1);
            if onArmed then
                onArmed(self);
            end
        end
    end);
end

local function ActivateHunterAuraRoot(
    root,
    nameplate,
    ownerGate,
    unit,
    onArmed
)
    root.isArmed = false;
    root:SetAlpha(0);
    root:Show();
    root.container:SetUnit(unit);
    root.container:SetEnabled(true);
    root.container:Show();
    root.container:UpdateAllAuras();

    -- Aura-slot refreshes are deferred to the container's OnUpdate. Keep the
    -- ordinary parent transparent across a full update turn so a recycled slot
    -- cannot flash its old aura assignment before Blizzard rebinds the button.
    ArmHunterAuraRoot(root, nameplate, ownerGate, unit, onArmed);
end

local function ActivateHunterPetGate(ownerGate, nameplate, ownerUnit, petUnit)
    if ownerGate.petIcon then
        HideTargetHighlight(ownerGate.petIcon);
        ownerGate.petIcon:Hide();
    end

    local iconRoot, targetRoot = EnsureHunterPetAuraRoots(ownerGate);
    ActivateHunterAuraRoot(
        iconRoot,
        nameplate,
        ownerGate,
        petUnit
    );
    ActivateHunterAuraRoot(
        targetRoot,
        nameplate,
        ownerGate,
        petUnit,
        ApplyHunterPetTargetHighlight
    );

    ownerGate:SetAlphaFromBoolean(
        UnitIsOwnerOrControllerOfUnit(ownerUnit, petUnit),
        1,
        0
    );
    ownerGate:Show();
end

local function ActivateNonHunterPetGate(ownerGate, ownerUnit, petUnit)
    if ownerGate.hunterPetAuraRoot then
        DeactivateHunterAuraRoot(ownerGate.hunterPetAuraRoot, false);
        DeactivateHunterAuraRoot(ownerGate.hunterPetTargetRoot, true);
    end

    EnsureNonHunterPetIcon(ownerGate):Show();
    ownerGate:SetAlphaFromBoolean(
        UnitIsOwnerOrControllerOfUnit(ownerUnit, petUnit),
        1,
        0
    );
    ownerGate:Show();
end

local function UpdateOtherPlayerPetIcons(nameplate, frame)
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local assignmentChanged =
        nameplate.FriendlyPetIconMode ~= PET_ICON_MODE_OTHER
        or nameplate.FriendlyPetIconUnit ~= frame.unit;

    if assignmentChanged then
        HideOtherPlayerPetIcons(nameplate);
        nameplate.FriendlyPetIconMode = PET_ICON_MODE_OTHER;
        nameplate.FriendlyPetIconUnit = frame.unit;
    end

    for partyIndex = 1, maxPartyMembers do
        local ownerGate = EnsureOwnerGate(nameplate, partyIndex);
        ApplyPetIconLayout(ownerGate, nameplate, config);

        local ownerUnit = "party" .. partyIndex;
        local ownerClass = addon.GetUnitClass(ownerUnit);
        local gateChanged = assignmentChanged
            or ownerClass ~= ownerGate.ownerClass
            or ownerGate.activeUnit ~= frame.unit;

        if not ownerClass then
            DeactivateOwnerGate(ownerGate);
        elseif ownerClass == addon.HUNTER then
            if gateChanged then
                DeactivateOwnerGate(ownerGate);
                ownerGate.ownerClass = ownerClass;
                ownerGate.activeUnit = frame.unit;
                if addon.IsUsingRealAuraData() then
                    ActivateHunterPetGate(
                        ownerGate,
                        nameplate,
                        ownerUnit,
                        frame.unit
                    );
                end
            else
                ownerGate:SetAlphaFromBoolean(
                    UnitIsOwnerOrControllerOfUnit(ownerUnit, frame.unit),
                    1,
                    0
                );
            end
        else
            if gateChanged then
                DeactivateOwnerGate(ownerGate);
                ownerGate.ownerClass = ownerClass;
                ownerGate.activeUnit = frame.unit;
                ActivateNonHunterPetGate(
                    ownerGate,
                    ownerUnit,
                    frame.unit
                );
            else
                ownerGate:SetAlphaFromBoolean(
                    UnitIsOwnerOrControllerOfUnit(ownerUnit, frame.unit),
                    1,
                    0
                );
            end
        end
    end
end

local function SetHunterPetTargetHighlight(
    ownerGate,
    shouldShow,
    shouldAnimate
)
    local root = ownerGate.hunterPetTargetRoot;
    if not root then return end

    root.targetHighlightShown = shouldShow;
    root.targetHighlightAnimated = shouldAnimate;
    ApplyHunterPetTargetHighlight(root);
end

addon.UpdatePetIconTargetHighlight = function (nameplate, frame)
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local highlightStyle = config.targetHighlightStyle;
    local featureEnabled =
        ( highlightStyle ~= addon.TARGET_HIGHLIGHT_STYLE.NONE )
        and ( not C_AddOns.IsAddOnLoaded("NeatPlates") );
    local shouldShow =
        addon.UnitIsUnitReadable(frame.unit, "target")
        and featureEnabled;
    local shouldAnimate =
        highlightStyle == addon.TARGET_HIGHLIGHT_STYLE.ANIMATED;

    if nameplate.FriendlyPetIcon then
        addon.SetTargetHighlightShown(
            nameplate.FriendlyPetIcon,
            shouldShow
                and nameplate.FriendlyPetIconMode == PET_ICON_MODE_LOCAL,
            shouldAnimate
        );
    end

    local ownerGates = nameplate.FriendlyPetOwnerGates;
    if not ownerGates then return end

    for _, ownerGate in pairs(ownerGates) do
        if ownerGate.petIcon then
            addon.SetTargetHighlightShown(
                ownerGate.petIcon,
                shouldShow
                    and nameplate.FriendlyPetIconMode == PET_ICON_MODE_OTHER
                    and ownerGate.ownerClass ~= addon.HUNTER,
                shouldAnimate
            );
        end
        SetHunterPetTargetHighlight(
            ownerGate,
            shouldShow
                and nameplate.FriendlyPetIconMode == PET_ICON_MODE_OTHER
                and ownerGate.ownerClass == addon.HUNTER,
            shouldAnimate
        );
    end
end

addon.UpdatePetIcon = function(nameplate, frame)
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    if nameplate.FriendlyPetIcon then
        ApplyPetIconLayout(nameplate.FriendlyPetIcon, nameplate, config);
    end

    local ownerGates = nameplate.FriendlyPetOwnerGates;
    if ownerGates then
        for _, ownerGate in pairs(ownerGates) do
            ApplyPetIconLayout(ownerGate, nameplate, config);
        end
    end
end

addon.ShowPetIcon = function (nameplate, frame)
    HideOtherPlayerPetIcons(nameplate);
    nameplate.FriendlyPetIconMode = PET_ICON_MODE_LOCAL;
    nameplate.FriendlyPetIconUnit = frame.unit;

    local iconFrame = EnsureIcon(nameplate);
    addon.UpdatePetIcon(nameplate, frame);
    iconFrame:Show();
    addon.UpdatePetIconTargetHighlight(nameplate, frame);
end

addon.ShowOtherPlayerPetIcon = function(nameplate, frame)
    if nameplate.FriendlyPetIcon then
        HideTargetHighlight(nameplate.FriendlyPetIcon);
        nameplate.FriendlyPetIcon:Hide();
    end

    UpdateOtherPlayerPetIcons(nameplate, frame);
    addon.UpdatePetIconTargetHighlight(nameplate, frame);
end

addon.HidePetIcon = function(nameplate)
    nameplate.FriendlyPetIconMode = nil;
    nameplate.FriendlyPetIconUnit = nil;

    if nameplate.FriendlyPetIcon then
        HideTargetHighlight(nameplate.FriendlyPetIcon);
        nameplate.FriendlyPetIcon:Hide();
    end

    HideOtherPlayerPetIcons(nameplate);
end

if addon.PROJECT_MAINLINE then
    addon.RegisterAuraDataProviderListener("FriendlyPetIcons", function()
        if SweepyBoop and SweepyBoop.RefreshAllNamePlates then
            SweepyBoop:RefreshAllNamePlates(true);
        end
    end);
end
