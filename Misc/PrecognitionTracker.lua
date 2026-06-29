local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;
local precognitionSpellID = 377362;
local greenGlowColor = { 0, 1, 0, 1 };

local trackerFrame;
local durationMatcher;
local isInTest = false;

local function GetDurationMatcher()
    if durationMatcher then return durationMatcher end

    durationMatcher = C_CurveUtil.CreateCurve();
    durationMatcher:SetType(Enum.LuaCurveType.Step);
    durationMatcher:AddPoint(0, 0);
    durationMatcher:AddPoint(3.9, 0);
    durationMatcher:AddPoint(4, 1);
    durationMatcher:AddPoint(4.1, 0);
    return durationMatcher;
end

local function StyleCooldown(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    cooldown:SetHideCountdownNumbers(false);
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(0);
    end
end

local function SetSecretSafeVisibility(frame, visible)
    if type(visible) == "number" then
        frame:SetAlpha(visible);
    else
        frame:SetAlphaFromBoolean(visible);
    end
end

local function ClearCandidate(candidate)
    if not candidate then return end

    candidate.cooldown:Clear();
    addon.HideProcGlow(candidate);
    candidate:Hide();
    candidate:SetAlpha(1);
end

local function HideTracker()
    if not trackerFrame then return end

    for _, candidate in ipairs(trackerFrame.candidates) do
        ClearCandidate(candidate);
    end
    trackerFrame:Hide();
    isInTest = false;
end

local function CreateTrackerFrame()
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:SetSize(iconSize, iconSize);
    frame.candidates = {};
    frame:Hide();
    return frame;
end

local function EnsureTrackerFrame()
    trackerFrame = trackerFrame or CreateTrackerFrame();
    return trackerFrame;
end

local function EnsureCandidate(index)
    local candidate = trackerFrame.candidates[index];
    if candidate then return candidate end

    candidate = CreateFrame("Frame", nil, trackerFrame);
    candidate:SetMouseClickEnabled(false);
    candidate:SetAllPoints(trackerFrame);
    candidate:SetFrameLevel(trackerFrame:GetFrameLevel() + index * 2);

    candidate.texture = candidate:CreateTexture(nil, "ARTWORK");
    candidate.texture:SetAllPoints(candidate);

    candidate.cooldown = CreateFrame("Cooldown", nil, candidate, "CooldownFrameTemplate");
    candidate.cooldown:SetAllPoints(candidate);
    StyleCooldown(candidate.cooldown);
    candidate.cooldown:SetScript("OnCooldownDone", function()
        if isInTest then
            HideTracker();
        else
            ClearCandidate(candidate);
        end
    end);

    candidate:Hide();
    trackerFrame.candidates[index] = candidate;
    return candidate;
end

local function ClearUnusedCandidates(firstUnusedIndex)
    if not trackerFrame then return end

    for i = firstUnusedIndex or 1, #trackerFrame.candidates do
        ClearCandidate(trackerFrame.candidates[i]);
    end
end

local function RefreshTrackerPosition()
    if not trackerFrame then return end

    local config = SweepyBoop.db.profile.misc;
    local scale = config.precognitionTrackerSize / iconSize;
    trackerFrame:SetScale(scale);
    trackerFrame:ClearAllPoints();
    trackerFrame:SetPoint("CENTER", UIParent, "CENTER", config.precognitionTrackerOffsetX / scale, config.precognitionTrackerOffsetY / scale);
    trackerFrame.lastModified = config.lastModified;
end

local function RefreshTrackerLayout()
    EnsureTrackerFrame();
    if trackerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified then
        RefreshTrackerPosition();
    end
end

local function PaintCandidate(index, auraData, durationObject, visibility)
    local candidate = EnsureCandidate(index);
    candidate.texture:SetTexture(auraData.icon);
    candidate.cooldown:SetCooldownFromDurationObject(durationObject);
    candidate.cooldown:Show();
    SetSecretSafeVisibility(candidate, visibility);
    addon.ShowProcGlow(candidate, greenGlowColor);
    candidate:Show();
end

local function ShowTestIcon()
    RefreshTrackerLayout();
    ClearUnusedCandidates();

    local candidate = EnsureCandidate(1);
    candidate.texture:SetTexture(addon.GetSpellTexture(precognitionSpellID));
    candidate.cooldown:SetCooldown(GetTime(), 8);
    candidate.cooldown:Show();
    candidate:SetAlpha(1);
    addon.ShowProcGlow(candidate, greenGlowColor);
    candidate:Show();
    trackerFrame:Show();
    isInTest = true;
end

local function RefreshRealAuras()
    RefreshTrackerLayout();

    local auras = C_UnitAuras.GetUnitAuras("player", "HELPFUL");
    if not auras then
        HideTracker();
        return;
    end

    local matcher = GetDurationMatcher();
    local candidateCount = 0;
    for _, auraData in ipairs(auras) do
        if auraData.spellId and auraData.icon and auraData.auraInstanceID then
            local durationObject = C_UnitAuras.GetAuraDuration("player", auraData.auraInstanceID);
            if durationObject then
                candidateCount = candidateCount + 1;
                local durationMatches = durationObject:EvaluateTotalDuration(matcher);
                local isImportant = C_Spell.IsSpellImportant(auraData.spellId);
                local shouldShow = C_CurveUtil.EvaluateColorValueFromBoolean(isImportant, durationMatches, 0);
                PaintCandidate(candidateCount, auraData, durationObject, shouldShow);
            end
        end
    end

    ClearUnusedCandidates(candidateCount + 1);
    if candidateCount > 0 then
        trackerFrame:Show();
    else
        HideTracker();
    end
end

function SweepyBoop:UpdatePrecognitionTracker()
    if ( not addon.PROJECT_MAINLINE ) or ( not SweepyBoop.db.profile.misc.precognitionTracker ) then
        HideTracker();
        return;
    end

    if isInTest then
        RefreshTrackerPosition();
        return;
    end

    RefreshRealAuras();
end

function SweepyBoop:TestPrecognitionTracker()
    ShowTestIcon();
end

local eventFrame;
function SweepyBoop:SetupPrecognitionTracker()
    if not eventFrame then
        eventFrame = CreateFrame("Frame");
        eventFrame:SetScript("OnEvent", function(_, event, unit)
            if ( event == addon.UNIT_AURA ) and ( unit ~= "player" ) then return end
            SweepyBoop:UpdatePrecognitionTracker();
        end);
    end

    eventFrame:UnregisterAllEvents();
    if addon.PROJECT_MAINLINE and SweepyBoop.db.profile.misc.precognitionTracker then
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterUnitEvent(addon.UNIT_AURA, "player");
        SweepyBoop:UpdatePrecognitionTracker();
    else
        HideTracker();
    end
end
