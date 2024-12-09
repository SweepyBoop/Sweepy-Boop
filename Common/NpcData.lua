local _, addon = ...;

addon.NpcOption = {
    Hide = 0,
    Show = 1, -- Units we should be aware (but might be hard to kill)
    Highlight = 2, -- For units that should be killed instantly or avoided (e.g., DK Reanimation)
};

addon.importantNpcList = {
    -- Unknown
    [225672] = { icon = C_Spell.GetSpellTexture(8122), default = addon.NpcOption.Highlight }, -- Shadow

    -- DK
    [106041] = { icon = C_Spell.GetSpellTexture(210128), default = addon.NpcOption.Highlight }, -- Reanimation

    -- Shaman
    [59764] = { icon = C_Spell.GetSpellTexture(108280), default = addon.NpcOption.Highlight }, -- Healing Tide Totem
    [5925] = { icon = C_Spell.GetSpellTexture(204336), defaulit = addon.NpcOption.Highlight }, -- Grounding Totem
    [53006] = { icon = C_Spell.GetSpellTexture(98008), defaulit = addon.NpcOption.Highlight }, -- Spirit Link Totem
    [5913] = { icon = C_Spell.GetSpellTexture(8143), defaulit = addon.NpcOption.Highlight }, -- Tremor Totem
    [104818] = { icon = C_Spell.GetSpellTexture(207399), defaulit = addon.NpcOption.Highlight }, -- Ancestral Protection Totem
    [61245] = { icon = C_Spell.GetSpellTexture(192058), defaulit = addon.NpcOption.Show }, -- Capacitor Totem (there is a cast bar already, no need to highlight)
    [105451] = { icon = C_Spell.GetSpellTexture(204331), defaulit = addon.NpcOption.Highlight }, -- Counterstrike Totem
    [100943] = { icon = C_Spell.GetSpellTexture(198838), defaulit = addon.NpcOption.Show }, -- Earthen Wall Totem (hard to kill, just try to fight outside of its range)
    [59712] = { icon = C_Spell.GetSpellTexture(108270), defaulit = addon.NpcOption.Show }, -- Stone Bulwark Totem (hard to kill)
    [3527] = { icon = C_Spell.GetSpellTexture(5394), defaulit = addon.NpcOption.Hide }, -- Healing Stream Totem
    [78001] = { icon = C_Spell.GetSpellTexture(157153), defaulit = addon.NpcOption.Hide }, -- Cloudburst Totem

    -- Warrior
    [119052] = { icon = C_Spell.GetSpellTexture(236320), default = addon.NpcOption.Highlight }, -- War Banner

    -- Priest
    [101398] = { icon = C_Spell.GetSpellTexture(199824), default = addon.NpcOption.Highlight }, -- Psyfiend
    [224466] = { icon = C_Spell.GetSpellTexture(451234), default = addon.NpcOption.Show }, -- Voidwraith

    -- Warlock
    [107100] = { icon = C_Spell.GetSpellTexture(112869), default = addon.NpcOption.Highlight }, -- Observer
    [135002] = { icon = C_Spell.GetSpellTexture(265187), default = addon.NpcOption.Highlight }, -- Tyrant
    [107024] = { icon = C_Spell.GetSpellTexture(212459), default = addon.NpcOption.Highlight }, -- Fel Lord
    [196111] = { icon = C_Spell.GetSpellTexture(138789), default = addon.NpcOption.Highlight }, -- Pit Lord

    -- Paladin
    [114565] = { icon = C_Spell.GetSpellTexture(228049), default = addon.NpcOption.Show }, -- Guardian of the Forgotten Queen

};