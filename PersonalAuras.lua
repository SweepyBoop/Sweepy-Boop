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
    local frame = CreateFrame("Frame", nil, UIParent, "CustomSpellActivationOverlayTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", offsetX, offsetY)
    frame.texture:SetTexture(filePath)
    frame:Hide()

    frame:RegisterEvent("UNIT_AURA")
    frame:SetScript("OnEvent", function (self, event, unitTarget)
        if ( unitTarget ~= "player" ) then return end

        local duration = select(5, WA_GetUnitBuff("player", buff))
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