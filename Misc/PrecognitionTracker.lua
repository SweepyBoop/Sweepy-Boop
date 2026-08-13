local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;
local precognitionSpellID = 377362;
local auraSlotKey = "Precognition";
local greenGlowColor = { 0, 1, 0, 1 };

local visualRoot;
local liveContainer;
local testFrame;

local function GetConfig()
    return SweepyBoop.db.profile.misc;
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

local function EnsureVisualRoot()
    if visualRoot then return visualRoot end

    visualRoot = CreateFrame("Frame", nil, UIParent);
    visualRoot:SetMouseClickEnabled(false);
    visualRoot:SetFrameStrata("HIGH");
    visualRoot:SetSize(1, 1);
    return visualRoot;
end

local function ApplyVisualRootLayout()
    local root = EnsureVisualRoot();
    local config = GetConfig();
    local scale = config.precognitionTrackerSize / iconSize;

    root:SetScale(scale);
    root:ClearAllPoints();
    root:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        config.precognitionTrackerOffsetX / scale,
        config.precognitionTrackerOffsetY / scale
    );
end

local function CreateIconVisual(frame)
    frame:SetSize(iconSize, iconSize);
    frame:SetMouseMotionEnabled(false);

    frame.icon = frame:CreateTexture(nil, "ARTWORK");
    frame.icon:SetAllPoints(frame);

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints(frame);
    StyleCooldown(frame.cooldown);
end

local function CreateHighlightTexture(frame, texturePath, layer, alpha)
    local padding = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING;
    local texture = frame:CreateTexture(nil, layer);
    texture:SetTexture(texturePath);
    texture:SetBlendMode("ADD");
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding);
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding);
    texture:SetVertexColor(
        greenGlowColor[1],
        greenGlowColor[2],
        greenGlowColor[3],
        alpha
    );
end

local function CreateStaticHighlight(frame)
    CreateHighlightTexture(
        frame,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        0.9
    );
    CreateHighlightTexture(
        frame,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        1
    );
end

local function InitializeAuraButton(button)
    CreateIconVisual(button);
    CreateStaticHighlight(button);
    button:SetPoint("CENTER", button:GetParent(), "CENTER");
    button:SetIcon(button.icon);
    button:SetDurationCooldown(button.cooldown);
end

local function EnsureLiveContainer()
    if liveContainer then return liveContainer end

    liveContainer = CreateFrame(
        "AuraContainer",
        nil,
        EnsureVisualRoot(),
        "CustomAuraContainerTemplate"
    );
    liveContainer:SetPoint("CENTER", visualRoot, "CENTER");
    liveContainer:SetUnit("player");
    liveContainer:SetEnabled(false);
    liveContainer:Hide();
    liveContainer:AddAuraSlot(
        auraSlotKey,
        "HELPFUL",
        {
            candidateFilters = {
                includeSpellIDs = {
                    [precognitionSpellID] = true,
                },
            },
            sortMethod = AuraContainerSortMethod.AuraInstanceIDOnly,
            sortDirection = AuraContainerSortDirection.Normal,
            initializeFrame = InitializeAuraButton,
        }
    );
    return liveContainer;
end

local function SetLiveContainerEnabled(enabled)
    local container = EnsureLiveContainer();
    container:SetEnabled(enabled);
    container:SetShown(enabled);
end

local function EnsureTestFrame()
    if testFrame then return testFrame end

    testFrame = CreateFrame("Frame", nil, EnsureVisualRoot());
    testFrame:SetPoint("CENTER", visualRoot, "CENTER");
    CreateIconVisual(testFrame);
    CreateStaticHighlight(testFrame);
    testFrame.icon:SetTexture(addon.GetSpellTexture(precognitionSpellID));
    testFrame.cooldown:SetScript("OnCooldownDone", function()
        testFrame:Hide();
        SetLiveContainerEnabled(GetConfig().precognitionTracker);
    end);
    testFrame:Hide();
    return testFrame;
end

function SweepyBoop:UpdatePrecognitionTracker()
    if not addon.PROJECT_MAINLINE then return end

    ApplyVisualRootLayout();
end

function SweepyBoop:TestPrecognitionTracker()
    if not addon.PROJECT_MAINLINE then return end

    ApplyVisualRootLayout();
    SetLiveContainerEnabled(false);

    local frame = EnsureTestFrame();
    frame.cooldown:SetCooldown(GetTime(), 4);
    frame.cooldown:Show();
    frame:Show();
end

function SweepyBoop:SetupPrecognitionTracker()
    if not addon.PROJECT_MAINLINE then return end

    ApplyVisualRootLayout();
    if testFrame then
        testFrame.cooldown:Clear();
        testFrame:Hide();
    end
    SetLiveContainerEnabled(GetConfig().precognitionTracker);
end
