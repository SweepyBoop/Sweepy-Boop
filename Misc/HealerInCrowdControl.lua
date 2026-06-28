local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;
local borderSize = iconSize * 1.25;

local containerFrame;
local isInTest = false;

-- The breaker suggestion needs a readable crowd-control spell ID to look up which spell frees the healer.
-- On retail/mainline every arena aura is a secret value, so that spell ID is never readable and the breaker
-- can never be shown - restrict the whole feature to non-mainline clients (no frames, no logic on mainline).
local breakerSupported = ( not addon.PROJECT_MAINLINE );

-- The remaining time may be a secret value, so the Cooldown frame renders the countdown text itself.
-- We can still restyle that built-in text: shrink the font and move it just below the icon's ring. The
-- font string is created lazily, so this is re-applied whenever the cooldown is (re)shown.
local COUNTDOWN_FONT_SIZE = 18; -- base size; sits below the icon so it can be large without blocking it
local COUNTDOWN_FONT_FILE = "Fonts\\2002.TTF";
local countdownFont = CreateFont("SweepyBoopHealerCCCountdownFont");
countdownFont:SetFont(COUNTDOWN_FONT_FILE, COUNTDOWN_FONT_SIZE, "OUTLINE");

local function GetMillisecondsThreshold()
    local config = SweepyBoop.db.profile.misc;
    local threshold = tonumber(config.healerInCrowdControlMillisecondsThreshold) or 5;
    if ( threshold < 1 ) then return 1 end
    if ( threshold > 6 ) then return 6 end
    return threshold;
end

local function StyleCountdownText(cooldown)
    if cooldown.SetCountdownFont then
        cooldown:SetCountdownFont(countdownFont:GetName());
    end
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(GetMillisecondsThreshold());
    end
    if cooldown.GetCountdownFontString then
        local text = cooldown:GetCountdownFontString();
        if text then
            text:ClearAllPoints();
            text:SetPoint("TOP", cooldown:GetParent().border, "BOTTOM", 0, -1);
        end
    end
end

local function HideIcon(frame)
    if ( not frame ) then return end

    frame.cooldown:Clear();
    frame:Hide();
    isInTest = false;
end

local function CreateContainerFrame()
    local frame = CreateFrame("Frame");
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:SetSize(iconSize, iconSize);

    frame.icon = frame:CreateTexture(nil, "BORDER");
    frame.icon:SetSize(iconSize, iconSize);
    frame.icon:SetAllPoints(frame);

    -- Breaker suggestion icon + its proc glow. Only created off mainline (see breakerSupported): on mainline
    -- the CC's spell ID is always a secret value, so we can never identify a breaker to show.
    if breakerSupported then
        frame.breakericon = CreateFrame("Frame", nil, frame);
        frame.breakericon:SetSize(iconSize / 1.5, iconSize / 1.5);
        frame.breakericon:SetPoint("LEFT", frame.icon, "RIGHT");
        frame.breakericonTexture = frame.breakericon:CreateTexture(nil, "BORDER");
        frame.breakericonTexture:SetAllPoints();
        -- Pre-create the overlay with a fixed size so ShowOverlayGlow skips button:GetSize() in restricted contexts.
        frame.breakericon.SpellActivationAlert = addon.CreateOverlayGlow(frame.breakericon, iconSize / 1.5);
    end

    frame.mask = frame:CreateMaskTexture();
    frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
    frame.mask:SetSize(iconSize, iconSize);
    frame.mask:SetAllPoints(frame.icon);
    frame.icon:AddMaskTexture(frame.mask);

    frame.border = frame:CreateTexture(nil, "OVERLAY");
    frame.border:SetAtlas("talents-warmode-ring");
    frame.border:SetSize(borderSize, borderSize);
    frame.border:SetPoint("CENTER", frame);

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(true);
    frame.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    frame.cooldown:SetUseCircularEdge(true);
    frame.cooldown:SetReverse(true);
    frame.cooldown:SetSwipeTexture("Interface/Masks/CircleMaskScalable");
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.5); -- to achieve a transparent background
    -- The remaining time is now a secret value on retail, so we can no longer read it and draw the
    -- countdown ourselves. Let the Cooldown frame render the built-in numbers (Blizzard/OmniCC) which
    -- can display a secret duration safely.
    frame.cooldown:SetHideCountdownNumbers(false);
    StyleCountdownText(frame.cooldown);
    frame.cooldown:SetScript("OnCooldownDone", function (self)
        local parent = self:GetParent();
        if parent:IsShown() then
            HideIcon(parent);
        end
    end)

    frame:Hide(); -- Hide initially
    return frame;
end

-- iconID:         the crowd control's icon texture (always readable, even when the spell ID is secret)
-- durationObject: a DurationObject from C_UnitAuras.GetAuraDuration for the real (possibly secret)
--                 remaining time; nil for auras that never expire or for the test path
-- spellID:        the crowd control's spell ID, used to suggest a breaker. May be a secret value for
--                 enemy-applied auras (e.g. rated arena), in which case the suggestion is skipped.
-- startTime/duration: a plain (non-secret) cooldown, used by the test path when there is no DurationObject
local function ShowIcon(iconID, durationObject, spellID, startTime, duration)
    containerFrame = containerFrame or CreateContainerFrame();

    local config = SweepyBoop.db.profile.misc;

    if ( containerFrame.lastModified ~= config.lastModified ) then
        local scale = config.healerInCrowdControlSize / iconSize;
        containerFrame:SetScale(scale);
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

        containerFrame.lastModified = config.lastModified;
    end

    containerFrame.icon:SetTexture(iconID);
    if durationObject then
        containerFrame.cooldown:SetCooldownFromDurationObject(durationObject);
        containerFrame.cooldown:Show();
    elseif duration then
        containerFrame.cooldown:SetCooldown(startTime, duration);
        containerFrame.cooldown:Show();
    else
        containerFrame.cooldown:Clear();
        containerFrame.cooldown:Hide();
    end
    StyleCountdownText(containerFrame.cooldown); -- re-apply: the countdown font string is created lazily

    -- Suggest a spell the player can press to free the healer. Only off mainline (see breakerSupported):
    -- mainline spell IDs are secret, so we can never identify the CC to recommend a breaker for it.
    if breakerSupported then
        local breakerSpellID;
        if spellID then
            local breakers = addon.CrowdControlBreakers[spellID];
            if breakers then
                for candidate in pairs(breakers) do
                    if IsSpellKnown(candidate) or IsSpellKnown(candidate, true) then
                        local cooldown = C_Spell.GetSpellCooldown(candidate);
                        if cooldown and cooldown.duration == 0 then
                            breakerSpellID = candidate;
                            break;
                        end
                    end
                end
            end
        end
        if breakerSpellID then
            local breakerIconID = addon.GetSpellTexture(breakerSpellID);
            containerFrame.breakericonTexture:SetTexture(breakerIconID);
            addon.ShowOverlayGlow(containerFrame.breakericon);
            containerFrame.breakericon:Show();
        else
            addon.HideOverlayGlow(containerFrame.breakericon);
            containerFrame.breakericon:Hide();
        end
    end

    if ( not containerFrame:IsShown() ) and config.healerInCrowdControlSound then
        PlaySoundFile(569006, "master"); -- spell_uni_sonarping_01
    end

    containerFrame:Show();
end

local class = addon.GetUnitClass("player");
local testIcons = {
    [addon.DRUID] = 51514, -- Hex
    [addon.EVOKER] = 51514, -- Hex
    [addon.HUNTER] = 605, -- Mind Control
    [addon.MAGE] = 51514, -- Hex
    [addon.MONK] = 356727, -- Spider Venom
    [addon.PALADIN] = 356727, -- Spider Venom
    [addon.PRIEST] = 605, -- Mind Control
    [addon.SHAMAN] = 8122, -- Psychic Scream
};
local testSpellID = testIcons[class] or 118; -- Polymorph

function SweepyBoop:TestHealerInCrowdControl()
    if IsInInstance() then
        addon.PRINT("Cannot run test mode inside an instance");
        return;
    end

    -- The test duration is a known literal (not a secret value), so drive the cooldown swipe with a plain
    -- start/duration instead of a DurationObject. The test spell ID is also not secret, so the breaker
    -- suggestion is exercised here too.
    ShowIcon(addon.GetSpellTexture(testSpellID), nil, testSpellID, GetTime(), 8);
    isInTest = true;
end

function SweepyBoop:UpdateHealerInCrowdControl()
    if containerFrame and containerFrame:IsShown() then
        if ( containerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
            local config = SweepyBoop.db.profile.misc;
            local scale = config.healerInCrowdControlSize / iconSize;
            containerFrame:SetScale(scale);
            containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

            containerFrame.lastModified = SweepyBoop.db.profile.misc.lastModified;
        end
        StyleCountdownText(containerFrame.cooldown);
    end
end

function SweepyBoop:HideTestHealerInCrowdControl()
    HideIcon(containerFrame);
end

local crowdControlPriority = { -- used to pick a CC when its category is known (spell ID not secret)
    ["stun"] = 100,
    ["silence"] = 90,
    ["disorient"] = 80,
    ["incapacitate"] = 80,
};

-- UnitIsUnit can return a secret boolean on retail; treat that as "not the same unit".
local function SameUnit(unitA, unitB)
    if ( unitA == unitB ) then return true end
    local result = UnitIsUnit(unitA, unitB);
    if addon.IsSecretValue(result) then return false end
    return result and true or false;
end

-- Returns the crowd control aura to display on the healer, or nil if there is none.
-- We rely on Blizzard's CROWD_CONTROL filter to decide what counts as crowd control, since the spell
-- ID needed for our own DRList lookup is a secret value for enemy-applied auras. When the spell ID is
-- readable we still prefer the highest-priority category (e.g. a stun over an incapacitate).
local function GetHealerCrowdControl(unit)
    local auras = C_UnitAuras.GetUnitAuras(unit, "HARMFUL|CROWD_CONTROL");
    if ( not auras ) then return end

    local chosen, chosenPriority;
    for _, auraData in ipairs(auras) do
        if ( not chosen ) then
            chosen = auraData; -- fallback: the first crowd control aura returned
        end

        local spellID = auraData.spellId;
        if spellID and ( not addon.IsSecretValue(spellID) ) then
            local category = addon.DRList[spellID];
            local priority = category and crowdControlPriority[category];
            if priority and ( ( not chosenPriority ) or priority > chosenPriority ) then
                chosen = auraData;
                chosenPriority = priority;
            end
        end
    end

    return chosen;
end

local updateFrame;

function SweepyBoop:SetupHealerInCrowdControl()
    if ( not updateFrame ) then
        updateFrame = CreateFrame("Frame"); -- When a frame is hidden it might not receive event, so we create a frame to catch events
        updateFrame:SetScript("OnEvent", function (self, event, unitTarget)
            if ( event ~= addon.UNIT_AURA ) then -- Hide when switching map or entering new round of solo shuffle
                HideIcon(containerFrame);
                return;
            end

            if ( not IsActiveBattlefieldArena() ) and ( not isInTest ) and ( not addon.TEST_MODE ) then
                HideIcon(containerFrame);
                return;
            end

            local isFriendly = unitTarget and ( SameUnit(unitTarget, "party1") or SameUnit(unitTarget, "party2") );
            local role = unitTarget and UnitGroupRolesAssigned(unitTarget);
            local isHealer = role and ( not addon.IsSecretValue(role) ) and ( role == "HEALER" );
            local isFriendlyHealer = ( isHealer and isFriendly ) or ( addon.TEST_MODE and unitTarget == "target" );
            --isFriendlyHealer = isFriendlyHealer or ( unitTarget == "player" ); -- TEST ONLY: also alert when you get CC'd (comment out to revert)
            if isFriendlyHealer then
                local auraData = GetHealerCrowdControl(unitTarget);
                if ( not auraData ) then -- No CC found, hide
                    HideIcon(containerFrame);
                else
                    local durationObject = C_UnitAuras.GetAuraDuration(unitTarget, auraData.auraInstanceID);
                    ShowIcon(auraData.icon, durationObject, auraData.spellId);
                end
            end
        end)
    end

    updateFrame:UnregisterAllEvents();
    if SweepyBoop.db.profile.misc.healerInCrowdControl then
        updateFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        updateFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        updateFrame:RegisterEvent(addon.UNIT_AURA);
    else
        HideIcon(containerFrame);
    end
end
