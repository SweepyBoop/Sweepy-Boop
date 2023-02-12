local _, NS = ...

local CreateFrame = CreateFrame;
local UnitClass = UnitClass;
local PlayerFrame = PlayerFrame;
local UIParent = UIParent;
local GetSpellInfo = GetSpellInfo;
local GetTime = GetTime;
local UnitStat = UnitStat;
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID;
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;
local UnitGUID = UnitGUID;

-- https://wowpedia.fandom.com/wiki/FileDataID
-- https://wow.tools/files/
-- https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua

-- To find the spellID of an aura
local findSpellId = CreateFrame("Frame");
findSpellId.enabled = false;

findSpellId.spellName = 211336;
findSpellId:RegisterEvent(NS.UNIT_AURA);
findSpellId:RegisterEvent(NS.COMBAT_LOG_EVENT_UNFILTERED);
findSpellId:SetScript("OnEvent", function (self, event, unitTarget)
    if ( not self.enabled ) then return end

    if ( event == NS.UNIT_AURA ) and ( unitTarget == "player" ) then
        local id = select(10, NS.Util_GetUnitAura("player", self.spellName));
        if id then print("UNIT_AURA", id) end
    elseif ( event == NS.COMBAT_LOG_EVENT_UNFILTERED ) then
        local _, subEvent, _, sourceGUID = CombatLogGetCurrentEventInfo();
        if ( subEvent == NS.SPELL_AURA_APPLIED ) and ( sourceGUID == UnitGUID("player") ) then
            local spellId, spellName = select(12, CombatLogGetCurrentEventInfo());
            if spellName == self.spellName then print("COMBATLOG", spellId) end
        end
    end
end)

function Custom_SpellActivationOverlayTexture_OnFadeInFinished(animGroup)
    local overlay = animGroup:GetParent()
    overlay:SetAlpha(0.5)
    overlay.pulse:Play()
end

local function CreateTexture(buff, filePath, width, height, offsetX, offsetY)
    local frame = CreateFrame("Frame", nil, UIParent, "CustomSpellActivationOverlayTemplate")
    frame.buff = buff
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", offsetX, offsetY)
    frame.texture:SetTexture(filePath)
    frame:Hide() -- Hide initially until aura is detected

    frame:RegisterEvent(NS.UNIT_AURA);
    frame:SetScript("OnEvent", function (self, event, unitTarget)
        if ( unitTarget ~= "player" ) then return end
        local aura = GetPlayerAuraBySpellID(self.buff);
        if aura and aura.duration then
            self:Show()
        else
            self:Hide()
        end
    end)

    return frame
end

local class = select(2, UnitClass("player"));

if ( class == NS.DRUID ) then
    local soulOfTheForest = CreateTexture(114108, 1518303, 150, 50, 0, 150) -- predatory_swiftness_green.blp
    local predatorySwiftness = CreateTexture(69369, 898423, 150, 50, 0, 150) -- predatory_swiftness.blp
    local apexPredatorsCraving = CreateTexture(391882, 627609, 150, 50, 0, 180) -- shadow_of_death.blp
end



-- BigDebuffs player portrait override
local playerPortraitStealthAbility = {}
-- If we use table, then we can't do ipairs to keep the order
-- If buff has no duration, duration will be false
playerPortraitStealthAbility[NS.DRUID] = {
    167152, -- Refreshment
    369162, -- Drink
    5215, -- Prowl
}
playerPortraitStealthAbility[NS.ROGUE] = {
    115191, -- Stealth
    115192, -- Subterfuge
}

local classStealthAbility = playerPortraitStealthAbility[class]

local playerPortraitAuraFrame = CreateFrame("Frame", nil, PlayerFrame)
playerPortraitAuraFrame:SetPoint(PlayerFrame.portrait:GetPoint())
playerPortraitAuraFrame:SetSize(PlayerFrame.portrait:GetSize())
playerPortraitAuraFrame:SetFrameStrata("HIGH")
playerPortraitAuraFrame.tex = playerPortraitAuraFrame:CreateTexture()
playerPortraitAuraFrame.tex:SetAllPoints(playerPortraitAuraFrame)
playerPortraitAuraFrame.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- To appear naturally as a round button

-- Apply a circle texture mask (https://wowpedia.fandom.com/wiki/UIOBJECT_MaskTexture)
playerPortraitAuraFrame.mask = playerPortraitAuraFrame:CreateMaskTexture()
playerPortraitAuraFrame.mask:SetAllPoints(playerPortraitAuraFrame.tex)
playerPortraitAuraFrame.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
playerPortraitAuraFrame.tex:AddMaskTexture(playerPortraitAuraFrame.mask)

playerPortraitAuraFrame.cooldown = CreateFrame("Cooldown", nil, playerPortraitAuraFrame, "CooldownFrameTemplate")
playerPortraitAuraFrame.cooldown:SetAllPoints()
-- Options copied from BigDebuffs (https://github.com/jordonwow/bigdebuffs/blob/master)
playerPortraitAuraFrame.cooldown:SetReverse(true)
playerPortraitAuraFrame.cooldown:SetDrawBling(false)
playerPortraitAuraFrame.cooldown:SetDrawEdge(false)
playerPortraitAuraFrame.cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
playerPortraitAuraFrame.cooldown:SetSwipeColor(0, 0, 0, 0.6)

playerPortraitAuraFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
playerPortraitAuraFrame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS); -- Between solo shuffle rounds
playerPortraitAuraFrame:RegisterEvent(NS.UNIT_AURA);
playerPortraitAuraFrame:Hide();

function playerPortraitAuraFrame:OnEvent(self, event, unitTarget)
    if ( event == NS.UNIT_AURA and unitTarget ~= "player" ) or ( not classStealthAbility ) then return end

    for i = 1, #(classStealthAbility) do
        local spell = classStealthAbility[i]
        local aura = GetPlayerAuraBySpellID(spell)
        if aura and aura.name then
            playerPortraitAuraFrame.tex:SetTexture(aura.icon)

            if aura.duration and ( aura.duration ~= 0 ) then
                playerPortraitAuraFrame.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
                playerPortraitAuraFrame.cooldown:Show()
            else
                playerPortraitAuraFrame.cooldown:Hide()
            end

            playerPortraitAuraFrame:Show()
            return
        end
    end

    -- No early return means no matching aura
    playerPortraitAuraFrame:Hide()
end
playerPortraitAuraFrame:SetScript("OnEvent", playerPortraitAuraFrame.OnEvent)



-- Glowing buff icon

local function CreateGlowingBuffIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide() -- Hide initially until aura is detected

    frame.spellID = spellID;
    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    frame.texture = frame:CreateTexture();
    local icon = select(3, GetSpellInfo(spellID));
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    -- Copied from bigdebuffs options
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(false);
    frame.cooldown:SetAlpha(1);
    frame.cooldown:SetDrawBling(false);
    frame.cooldown:SetDrawSwipe(true);
    frame.cooldown:SetReverse(true);

    frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
    frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
    frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
    frame.spellActivationAlert:Hide();

    frame:RegisterEvent(NS.UNIT_AURA);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == NS.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            local aura = GetPlayerAuraBySpellID(frame.spellID);
            if aura and aura.duration and ( aura.duration ~= 0 ) then
                self.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration);
                NS.ShowOverlayGlow(self);
                self:Show();
            else
                NS.HideOverlayGlow(self);
                self:Hide();
            end
        end
    end)

    return frame;
end

-- No duration text, only show stacks, and glow when max stacks (if set)
local function CreateStackBuffIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY, maxStacks, duration, stackFunc)
    local frame = CreateFrame("Frame", NS.HIDETIMEROMNICC .. "CustomAura" .. spellID, UIParent);
    frame.spellID = spellID;
    frame.maxStacks = maxStacks;
    frame.stackFunc = stackFunc;
    frame:Hide();

    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    frame:SetFrameStrata("HIGH");

    frame.text = frame:CreateFontString(nil, "ARTWORK");
    -- https://wow.tools/files/#search=fonts&page=1&sort=0&desc=asc
    frame.text:SetFont("Fonts\\2002.ttf", size / 2, "OUTLINE");
    frame.text:SetPoint("CENTER", 0, 0);

    frame.texture = frame:CreateTexture();
    local icon = select(3, GetSpellInfo(spellID));
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    if duration then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        -- Copied from bigdebuffs options
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetAlpha(1);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetDrawSwipe(true);
        frame.cooldown:SetReverse(true);

        -- No numeric display on cooldown
        frame.cooldown:SetHideCountdownNumbers(true);
    end

    if maxStacks then
        frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
        frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
        frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
        frame.spellActivationAlert:Hide();
    end

    frame:RegisterEvent(NS.UNIT_AURA);
    frame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == NS.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            -- GetPlayerAuraBySpellID does not show count and value correctly, so we have to stick with UnitAura here
            local name, _, count, _, duration, expirationTime, _, _, _, _, _, _, _, _, _, value = NS.Util_GetUnitBuff("player", frame.spellID);
            if ( not name ) then
                self:Hide();
                return;
            end

            if duration and ( duration ~= 0 ) and self.cooldown then
                self.cooldown:SetCooldown(expirationTime - duration, duration);
            end

            local stacks;
            if self.stackFunc then
                stacks = self.stackFunc(count, duration, expirationTime, value);
            else
                stacks = count;
            end

            if ( stacks > 0 ) then
                if ( stacks >= self.maxStacks ) then
                    self.text:SetText("");
                    NS.ShowOverlayGlow(self);
                else
                    self.text:SetText(stacks);
                    NS.HideOverlayGlow(self);
                end
            end

            self:Show();
        end
    end)

    return frame;
end

local function CreatePlayerPassiveDebuffIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY, glowDuration)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame.spellID = spellID;
    frame.glowDuration = glowDuration;

    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    frame:SetFrameStrata("HIGH");

    frame.texture = frame:CreateTexture();
    local icon = select(3, GetSpellInfo(spellID));
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    if glowDuration then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        -- Copied from bigdebuffs options
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetAlpha(1);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetDrawSwipe(true);
        frame.cooldown:SetReverse(true);
    end

    frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
    frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
    frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
    frame.spellActivationAlert:Hide();

    frame:RegisterEvent(NS.UNIT_AURA);
    frame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == NS.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            local aura = GetPlayerAuraBySpellID(frame.spellID);
            if ( not aura) or ( not aura.name ) then
                self.cooldown:SetCooldown(0, 0);
                NS.HideOverlayGlow(self);
                return;
            end

            local startTime = aura.expirationTime - aura.duration;

            if aura.duration and ( aura.duration ~= 0 ) then
                self.cooldown:SetCooldown(startTime, aura.duration);
            end

            local timeElapsed = GetTime() - startTime;
            if ( timeElapsed <= self.glowDuration ) then
                NS.ShowOverlayGlow(self);
            else
                NS.HideOverlayGlow(self);
            end
        end
    end)

    return frame;
end

local testGlowingBuffIcon = false;

-- The first ActionBarButtonSpellActivationAlert created seems to be corrupted by other icons, so we create a dummy here that does nothing
local dummy = CreateFrame("Frame", nil, UIParent, "ActionBarButtonSpellActivationAlert");

if ( class == "DRUID" ) then
    local wildSynthesis = CreateStackBuffIcon(400534, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 50, 3);
    local bloodTalons = CreateStackBuffIcon(145152, 36, "BOTTOM", _G["MultiBarBottomRightButton4"], "TOP", 0, 5, 2, true);
    local treeOfLife = CreateGlowingBuffIcon(117679, 36, "BOTTOM", _G["MultiBarBottomRightButton2"], "TOP", 0, 50);

    local function protectorFunc(count, duration, expirationTime, value)
        local currentValue = value or 0;
        -- 1 intellect = 1 spell power
        local _, spellPower = UnitStat("player", 4);
        local percent = math.ceil(((currentValue*100/spellPower)/220)*100);
        return percent;
    end
    local protector = CreateStackBuffIcon(378987, 45, "RIGHT", _G["MultiBarBottomLeftButton1"], "LEFT", -5, 0, 100, false, protectorFunc);

    local wellHonedInstincts = CreatePlayerPassiveDebuffIcon(382912, 45, "LEFT", _G["MultiBarBottomLeftButton12"], "RIGHT", 5, 0, 3);

    if testGlowingBuffIcon then
        local test = CreateGlowingBuffIcon(774, 36, "BOTTOM", _G["MultiBarBottomRightButton4"], "TOP", 0, 5);
    end
end
