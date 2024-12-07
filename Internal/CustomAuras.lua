local _, addon = ...

local CreateFrame = CreateFrame;
local UnitClass = UnitClass;
local PlayerFrame = PlayerFrame;
local UIParent = UIParent;
local GetSpellInfo = C_Spell.GetSpellInfo;
local GetSpellTexture = C_Spell.GetSpellTexture;
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
findSpellId.enabled = addon.isTestMode;
--findSpellId.enabled = true;

findSpellId.spellName = "Drink";
findSpellId:RegisterEvent(addon.UNIT_AURA);
findSpellId:RegisterEvent(addon.COMBAT_LOG_EVENT_UNFILTERED);
findSpellId:SetScript("OnEvent", function (self, event, unitTarget)
    if ( not self.enabled ) then return end

    if ( event == addon.UNIT_AURA ) and ( unitTarget == "player" ) then
        local auraData = addon.Util_GetUnitAura("player", self.spellName);
        if auraData and auraData.spellId then print("UNIT_AURA", auraData.sourceUnit, auraData.spellId) end
    elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
        local _, subEvent, _, sourceGUID = CombatLogGetCurrentEventInfo();
        if ( subEvent == addon.SPELL_AURA_APPLIED ) and ( sourceGUID == UnitGUID("player") ) then
            local spellId, spellName = select(12, CombatLogGetCurrentEventInfo());
            if spellName == self.spellName then print("COMBATLOG", spellId) end
        end
    end
end)

function SpellActivationOverlayFadeInAnimMixin:CustomOnFinished(animGroup)
    local overlay = self:GetParent();
	overlay:SetAlpha(0.5);
	overlay.pulse:Play();
end

local function CreateTexture(buff, filePath, width, height, offsetX, offsetY, rotate)
    local frame = CreateFrame("Frame", nil, UIParent, "CustomSpellActivationOverlayTemplate")
    frame.buff = buff
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", offsetX, offsetY)
    frame.texture:SetTexture(filePath)
    if rotate then
        frame.texture:SetRotation(rotate)
    end
    frame:Hide() -- Hide initially until aura is detected

    frame:RegisterEvent(addon.UNIT_AURA);
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

if ( class == addon.DRUID ) then
    local soulOfTheForest = CreateTexture(114108, 1518303, 150, 50, 0, 150) -- predatory_swiftness_green.blp
    local bloomingInfusionDamage = CreateTexture(429474, 450915, 100, 100, -100, 150) -- Eclipse_Sun.blp
    local bloomingInfusionHeal = CreateTexture(429438, 450914, 100, 100, 100, 150, math.pi) -- Eclipse_Moon.blp
    local predatorySwiftness = CreateTexture(69369, 898423, 150, 50, 0, 150) -- predatory_swiftness.blp
    local apexPredatorsCraving = CreateTexture(391882, 627609, 150, 50, 0, 180) -- shadow_of_death.blp
end



-- BigDebuffs player portrait override
local playerPortraitStealthAbility = {}
-- If we use table, then we can't do ipairs to keep the order
-- If buff has no duration, duration will be false
playerPortraitStealthAbility[addon.DRUID] = {
    167152, -- Refreshment
    452384, -- Drink
    5215, -- Prowl
}
playerPortraitStealthAbility[addon.ROGUE] = {
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
playerPortraitAuraFrame.cooldown:SetReverse(true)
playerPortraitAuraFrame.cooldown:SetDrawBling(false)
playerPortraitAuraFrame.cooldown:SetDrawEdge(false)
playerPortraitAuraFrame.cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
playerPortraitAuraFrame.cooldown:SetSwipeColor(0, 0, 0, 0.6)

playerPortraitAuraFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
playerPortraitAuraFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS); -- Between solo shuffle rounds
playerPortraitAuraFrame:RegisterEvent(addon.UNIT_AURA);
playerPortraitAuraFrame:Hide();

function playerPortraitAuraFrame:OnEvent(event, unitTarget)
    if ( event == addon.UNIT_AURA and unitTarget ~= "player" ) or ( not classStealthAbility ) then return end

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
    local icon = GetSpellTexture(spellID);
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
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

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            local aura = GetPlayerAuraBySpellID(frame.spellID);
            if aura and aura.duration and ( aura.duration ~= 0 ) then
                self.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration);
                addon.ShowOverlayGlow(self);
                self:Show();
            else
                addon.HideOverlayGlow(self);
                self:Hide();
            end
        end
    end)

    return frame;
end

-- No duration text, only show stacks, and glow when max stacks (if set)
local function CreateStackBuffIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY, maxStacks, duration, stackFunc)
    local frame = CreateFrame("Frame", addon.HIDETIMEROMNICC .. "CustomAura" .. spellID, UIParent);
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
    frame.text:SetText("");
    frame.text:SetTextColor(1, 1, 0); -- Yellow

    frame.texture = frame:CreateTexture();
    local icon = GetSpellTexture(spellID);
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    if duration then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
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

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            -- GetPlayerAuraBySpellID does not show count and value correctly, so we have to stick with UnitAura here
            local name, _, count, _, duration, expirationTime, _, _, _, _, _, _, _, _, _, value = AuraUtil.UnpackAuraData(addon.Util_GetUnitBuff("player", frame.spellID));
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
                    addon.ShowOverlayGlow(self);
                else
                    self.text:SetText(stacks);
                    addon.HideOverlayGlow(self);
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
    local icon = GetSpellTexture(spellID);
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    if glowDuration then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
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

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            local aura = GetPlayerAuraBySpellID(frame.spellID);
            if ( not aura) or ( not aura.name ) then
                self.cooldown:SetCooldown(0, 0);
                addon.HideOverlayGlow(self);
                return;
            end

            local startTime = aura.expirationTime - aura.duration;

            if aura.duration and ( aura.duration ~= 0 ) then
                self.cooldown:SetCooldown(startTime, aura.duration);
            end

            local timeElapsed = GetTime() - startTime;
            if ( timeElapsed <= self.glowDuration ) then
                addon.ShowOverlayGlow(self);
            else
                addon.HideOverlayGlow(self);
            end
        end
    end)

    return frame;
end

local testGlowingBuffIcon = false;

-- The first ActionBarButtonSpellActivationAlert created seems to be corrupted by other icons, so we create a dummy here that does nothing
local dummy = CreateFrame("Frame", nil, UIParent, "ActionBarButtonSpellActivationAlert");

local precongnition = CreateGlowingBuffIcon(377362, 35, "CENTER", UIParent, "CENTER", 0, 60);

if ( class == addon.DRUID ) then
    local reforestation = CreateStackBuffIcon(392360, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 50, 3);
    local bloodTalons = CreateStackBuffIcon(145152, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 5, 2, true);
    local treeOfLife = CreateGlowingBuffIcon(117679, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 5);
    local berserk = CreateGlowingBuffIcon(106951, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 50);
    local kingofJungle = CreateGlowingBuffIcon(102543, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 50);

    local function protectorFunc(count, duration, expirationTime, value)
        local currentValue = value or 0;
        -- 1 intellect = 1 spell power
        local _, spellPower = UnitStat("player", 4);
        local percent = math.ceil(((currentValue*100/spellPower)/220)*100);
        return percent;
    end
    local protector = CreateStackBuffIcon(378987, 45, "BOTTOM", _G["ActionButton12"], "TOP", 0, 5, 100, false, protectorFunc);

    local wellHonedInstincts = CreatePlayerPassiveDebuffIcon(382912, 45, "LEFT", _G["MultiBarRightButton8"], "RIGHT", 5, 0, 3);

    if testGlowingBuffIcon then
        local test = CreateGlowingBuffIcon(774, 36, "BOTTOM", _G["MultiBarBottomRightButton4"], "TOP", 0, 5);
    end
elseif ( class == addon.PRIEST ) then
    local harshDiscipline = CreateStackBuffIcon(373181, 40, "BOTTOM", _G["MultiBarBottomLeftButton9"], "TOP", 0, 50, 4);
elseif ( class == addon.PALADIN ) then
    local auraOfReckoning = CreateStackBuffIcon(247676, 40, "BOTTOM", _G["MultiBarBottomLeftButton9"], "TOP", 0, 5, 100);
    local wing = CreateGlowingBuffIcon(31884, 36, "BOTTOM", _G["MultiBarBottomLeftButton9"], "TOP", 0, 50);
    local meleeWing = CreateGlowingBuffIcon(216331, 36, "BOTTOM", _G["MultiBarBottomLeftButton9"], "TOP", 0, 50);
end

-- Defensive buffs
local teamDefensiveBuffs = {
    145629, -- Anti-Magic Zone

    209426, -- Darkness

    102342, -- Ironbark
    53480, -- Roar of Sacrifice

    116849, -- Life Cocoon

    6940, -- Blessing of Sacrifice
    199448, -- Ultimate Sacrifice
    1022, -- Blessing of Protection

    81782, -- Power Word: Barrier
    47788, -- Guardian Spirit
    33206, -- Pain Suppression

    201633, -- Earthen Wall Totem

    147833, -- Intervene
    97463, -- Rallying Cry
};
local personalDefensiveBuffs = {
    145629, -- Anti-Magic Zone
    48707, -- Anti-Magic Shell
    48792, -- Icebound Fortitude

    209426, -- Darkness
    212800, -- Blur
    196555, -- Netherwalk

    102342, -- Ironbark
    61336, -- Survival Instincts
    22812, -- Barkskin

    363916, -- Obsidian Scales

    53480, -- Roar of Sacrifice
    186265, -- Aspect of the Turtle

    45438, -- Ice Block
    342246, -- Alter Time (Arcane)
    110909, -- Alter Time (Fire/Frost)

    116849, -- Life Cocoon
    125174, -- Touch of Karma

    642, -- Divine Shield
    1022, -- Blessing of Protection
    498, -- Divine Protection

    81782, -- Power Word: Barrier
    47585, -- Dispersion
    47788, -- Guardian Spirit
    33206, -- Pain Suppression

    5277, -- Evasion
    31224, -- Cloak of Shadows

    108271, -- Astral Shift
    210918, -- Ethereal Form
    201633, -- Earthen Wall Totem

    104773, -- Unending Resolve
    108416, -- Dark Pact
    212295, -- Nether Ward

    118038, -- Die by the Sword
    184364, -- Enraged Regeneration
    97463, -- Rallying Cry
};

local function ShouldDisplayDefensiveBuff(icon, aura)
    if icon.external then
        return aura.sourceUnit ~= "player";
    else
        return aura.sourceUnit == "player";
    end
end

local function CreateGlowingDefensiveBuffs(spells, size, point, relativeTo, relativePoint, offsetX, offsetY, external)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide() -- Hide initially until aura is detected

    frame.spells = spells;
    frame.external = external;
    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    frame.texture = frame:CreateTexture();
    frame.texture:SetAllPoints();

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
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

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            for i = 1, #(self.spells) do
                local spell = self.spells[i];
                local aura = GetPlayerAuraBySpellID(spell);
                if aura and aura.name and ShouldDisplayDefensiveBuff(self, aura) then
                    local icon = GetSpellTexture(spell);
                    self.texture:SetTexture(icon);

                    if aura.duration and ( aura.duration ~= 0 ) then
                        self.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration);
                    end

                    addon.ShowOverlayGlow(self);
                    self:Show();
                    return;
                end
            end

            -- If no early return, no matching aura has been found
            addon.HideOverlayGlow(self);
            self:Hide();
        end
    end)

    return frame;
end

local teamBuffIcon = CreateGlowingDefensiveBuffs(teamDefensiveBuffs, 35, "CENTER", UIParent, "CENTER", 0, 100, true);
local selfBuffIcon = CreateGlowingDefensiveBuffs(personalDefensiveBuffs, 35, "CENTER", UIParent, "CENTER", 0, 100, false);
teamBuffIcon:Raise();
selfBuffIcon:Lower();
