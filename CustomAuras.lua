local _, NS = ...

-- https://wowpedia.fandom.com/wiki/FileDataID
-- https://wow.tools/files/
-- https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua

local WA_GetUnitAura = function(unit, spell, filter)
    if filter and not filter:upper():find("FUL") then
        filter = filter.."|HELPFUL"
    end
    for i = 1, 255 do
      local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
      if not name then return end
      if spell == spellId or spell == name then
        return UnitAura(unit, i, filter)
      end
    end
end

local WA_GetUnitBuff = function(unit, spell, filter)
    filter = filter and filter.."|HELPFUL" or "HELPFUL"
    return WA_GetUnitAura(unit, spell, filter)
end

function Custom_SpellActivationOverlayTexture_OnFadeInFinished(animGroup)
    local overlay = animGroup:GetParent()
	overlay:SetAlpha(0.5)
	overlay.pulse:Play()
end

local function CreateTexture(buff, filePath, width, height, offsetX, offsetY)
    local frame = CreateFrame("Frame", buff, UIParent, "CustomSpellActivationOverlayTemplate")
    frame.buff = buff
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", offsetX, offsetY)
    frame.texture:SetTexture(filePath)
    frame:Hide() -- Hide initially until aura is detected

    frame:RegisterEvent("UNIT_AURA")
    frame:SetScript("OnEvent", function (self, event, unitTarget)
        if ( unitTarget ~= "player" ) then return end
        local duration = select(5, WA_GetUnitBuff("player", self.buff))
        if duration then
            self:Show()
        else
            self:Hide()
        end
    end)

    return frame
end

local soulOfTheForest = CreateTexture("Soul of the Forest", 1518303, 150, 50, 0, 150) -- predatory_swiftness_green.blp
local predatorySwiftness = CreateTexture("Predatory Swiftness", 898423, 150, 50, 0, 150) -- predatory_swiftness.blp
local apexPredatorsCraving = CreateTexture("Apex Predator's Craving", 627609, 150, 50, 0, 180) -- shadow_of_death.blp



-- To monitor stealth, value means whether show duration
local iconPath = "Interface\\Addons\\aSweepyBoop\\AbilityIcons\\"

local playerPortraitStealthAbility = {}
playerPortraitStealthAbility[NS.classId.Druid] = {
    ["Prowl"] = false,
}
playerPortraitStealthAbility[NS.classId.Rogue] = {
    ["Stealth"] = false,
    ["Subterfuge"] = true,
}

local class = select(3, UnitClass("player"))
local classStealthAbility = playerPortraitStealthAbility[class]

local playerPortraitStealthFrame = CreateFrame("Frame", nil, PlayerFrame)
playerPortraitStealthFrame:SetPoint(PlayerFrame.portrait:GetPoint())
playerPortraitStealthFrame:SetSize(PlayerFrame.portrait:GetSize())
playerPortraitStealthFrame:SetFrameStrata("HIGH")
local playerPortraitStealthTexture = playerPortraitStealthFrame:CreateTexture()
playerPortraitStealthTexture:SetAllPoints()

local playerPortraitStealthCooldown = CreateFrame("Cooldown", nil, playerPortraitStealthFrame, "CooldownFrameTemplate")
playerPortraitStealthCooldown:SetAllPoints()

playerPortraitStealthFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerPortraitStealthFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- Between solo shuffle rounds
playerPortraitStealthFrame:RegisterEvent("UNIT_AURA")
playerPortraitStealthFrame:Hide()

function playerPortraitStealthFrame:OnEvent(event, unitTarget)
    if ( event == "UNIT_AURA" and unitTarget ~= "player" ) or ( not classStealthAbility ) then return end

    for spell, showCooldown in pairs(classStealthAbility) do
        local name, _, _, _, duration, expirationTime = select(5, WA_GetUnitBuff("player", spell))
        if ( not name ) then
            playerPortraitStealthFrame:Hide()
            return
        end

        playerPortraitStealthTexture:SetTexture(iconPath .. spell)

        if showCooldown then
            playerPortraitStealthCooldown:SetCooldown(expirationTime - duration, duration)
            playerPortraitStealthCooldown:Show()
        else
            playerPortraitStealthCooldown:Hide()
        end

        playerPortraitStealthFrame:Show()
    end
end
playerPortraitStealthFrame:SetScript("OnEvent", playerPortraitStealthFrame.OnEvent)