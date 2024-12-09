local _, addon = ...;

addon.NpcOption = {
    Hide = 0,
    Show = 1,
    ShowWithIcon = 2, -- Units we should be aware (but might be hard to kill)
    Highlight = 3, -- For units that should be killed instantly or avoided at any cost :) (e.g., DK Reanimation)
};

addon.importantNpcList = {
    -- Unknown
    [225672] = { icon = C_Spell.GetSpellTexture(8122), default = addon.NpcOption.Show }, -- Shadow

    -- DK
    [106041] = { icon = C_Spell.GetSpellTexture(210128), default = addon.NpcOption.Highlight }, -- Reanimation (stuns for 3s and takes 10% HP)

    -- Shaman
    [59764] = { icon = C_Spell.GetSpellTexture(108280), default = addon.NpcOption.Highlight }, -- Healing Tide Totem
    [5925] = { icon = C_Spell.GetSpellTexture(204336), default = addon.NpcOption.Highlight }, -- Grounding Totem
    [53006] = { icon = C_Spell.GetSpellTexture(98008), default = addon.NpcOption.Highlight }, -- Spirit Link Totem
    [5913] = { icon = C_Spell.GetSpellTexture(8143), default = addon.NpcOption.Highlight }, -- Tremor Totem
    [104818] = { icon = C_Spell.GetSpellTexture(207399), default = addon.NpcOption.Highlight }, -- Ancestral Protection Totem
    [61245] = { icon = C_Spell.GetSpellTexture(192058), default = addon.NpcOption.Show }, -- Capacitor Totem (there is a cast bar already, no need to highlight)
    [105451] = { icon = C_Spell.GetSpellTexture(204331), default = addon.NpcOption.Highlight }, -- Counterstrike Totem
    [100943] = { icon = C_Spell.GetSpellTexture(198838), default = addon.NpcOption.Show }, -- Earthen Wall Totem (hard to kill, just try to fight outside of its range)
    [59712] = { icon = C_Spell.GetSpellTexture(108270), default = addon.NpcOption.Show }, -- Stone Bulwark Totem (hard to kill)
    [3527] = { icon = C_Spell.GetSpellTexture(5394), default = addon.NpcOption.Hide }, -- Healing Stream Totem
    [78001] = { icon = C_Spell.GetSpellTexture(157153), default = addon.NpcOption.Hide }, -- Cloudburst Totem
    [10467] = { icon = C_Spell.GetSpellTexture(16191), default = addon.NpcOption.Hide }, -- Mana Tide Totem
    [97285] = { icon = C_Spell.GetSpellTexture(192077), default = addon.NpcOption.Hide }, -- Wind Rush Totem
    [60561] = { icon = C_Spell.GetSpellTexture(51485), default = addon.NpcOption.ShowWithIcon }, -- Earthgrab Totem (gets players out of stealth)
    [2630] = { icon = C_Spell.GetSpellTexture(2484), default = addon.NpcOption.Hide }, -- Earthbind Totem
    [105427] = { icon = C_Spell.GetSpellTexture(204330), default = addon.NpcOption.Highlight }, -- Totem of Wrath (Skyfury Totem)
    [97369] = { icon = C_Spell.GetSpellTexture(192222), default = addon.NpcOption.Hide }, -- Liquid Magma Totem
    [179867] = { icon = C_Spell.GetSpellTexture(355580), default = addon.NpcOption.Show }, -- Static Field Totem
    [194117] = { icon = C_Spell.GetSpellTexture(383017), default = addon.NpcOption.ShowWithIcon }, -- Stoneskin Totem
    [5923] = { icon = C_Spell.GetSpellTexture(383013), default = addon.NpcOption.ShowWithIcon }, -- Poison Cleansing Totem
    [194118] = { icon = C_Spell.GetSpellTexture(383019), default = addon.NpcOption.Show }, -- Tranquil Air Totem
    [225409] = { icon = C_Spell.GetSpellTexture(444995), default = addon.NpcOption.ShowWithIcon }, -- Tranquil Air Totem
    [95061] = { icon = C_Spell.GetSpellTexture(198067), default = addon.NpcOption.Show }, -- Greater Fire Elemental
    [61029] = { icon = C_Spell.GetSpellTexture(198067), default = addon.NpcOption.Show }, -- Primal Fire Elemental

    -- Warrior
    [119052] = { icon = C_Spell.GetSpellTexture(236320), default = addon.NpcOption.Highlight }, -- War Banner

    -- Priest
    [101398] = { icon = C_Spell.GetSpellTexture(199824), default = addon.NpcOption.Highlight }, -- Psyfiend
    [224466] = { icon = C_Spell.GetSpellTexture(451234), default = addon.NpcOption.Show }, -- Voidwraith
    [62982] = { icon = C_Spell.GetSpellTexture(123040), default = addon.NpcOption.Show }, -- Mindbender
    [19668] = { icon = C_Spell.GetSpellTexture(34433), default = addon.NpcOption.Show }, -- Shadowfiend
    [65282] = { icon = C_Spell.GetSpellTexture(108920), default = addon.NpcOption.Show }, -- Void Tendril

    -- Warlock
    [107100] = { icon = C_Spell.GetSpellTexture(112869), default = addon.NpcOption.ShowWithIcon }, -- Observer
    [135002] = { icon = C_Spell.GetSpellTexture(265187), default = addon.NpcOption.ShowWithIcon }, -- Demonic Tyrant
    [107024] = { icon = C_Spell.GetSpellTexture(212459), default = addon.NpcOption.ShowWithIcon }, -- Fel Lord
    [196111] = { icon = C_Spell.GetSpellTexture(138789), default = addon.NpcOption.ShowWithIcon }, -- Pit Lord

    -- Paladin
    [114565] = { icon = C_Spell.GetSpellTexture(228049), default = addon.NpcOption.ShowWithIcon }, -- Guardian of the Forgotten Queen

    -- Evoker
    [185800] = { icon = C_Spell.GetSpellTexture(371869), default = addon.NpcOption.Show }, -- Past Self
};
