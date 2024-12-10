local _, addon = ...;

addon.NpcOption = {
    Hide = 0,
    Show = 1,
    ShowWithIcon = 2, -- Units we should be aware (but might be hard to kill)
    Highlight = 3, -- For units that should be killed instantly or avoided at any cost :) (e.g., DK Reanimation)
};

addon.importantNpcList = {
    -- Unknown
    [225672] = { name = "Shadow", icon = C_Spell.GetSpellTexture(8122), default = addon.NpcOption.Show },

    -- DK
    [106041] = { name = "Reanimation", icon = C_Spell.GetSpellTexture(210128), default = addon.NpcOption.Highlight }, -- stuns for 3s and takes 10% HP

    -- Shaman
    [59764] = { name = "Healing Tide Totem", icon = C_Spell.GetSpellTexture(108280), default = addon.NpcOption.Highlight },
    [5925] = { name = "Grounding Totem", icon = C_Spell.GetSpellTexture(204336), default = addon.NpcOption.Highlight },
    [53006] = { name = "Spirit Link Totem", icon = C_Spell.GetSpellTexture(98008), default = addon.NpcOption.Highlight },
    [5913] = { name = "Tremor Totem", icon = C_Spell.GetSpellTexture(8143), default = addon.NpcOption.Highlight },
    [104818] = { name = "Ancestral Protection Totem", icon = C_Spell.GetSpellTexture(207399), default = addon.NpcOption.Highlight },
    [61245] = { name = "Capacitor Totem", icon = C_Spell.GetSpellTexture(192058), default = addon.NpcOption.Show },
    [105451] = { name = "Counterstrike Totem", icon = C_Spell.GetSpellTexture(204331), default = addon.NpcOption.Highlight },
    [100943] = { name = "Earthen Wall Totem", icon = C_Spell.GetSpellTexture(198838), default = addon.NpcOption.Show }, -- hard to kill, just try to fight outside of its range
    [59712] = { name = "Stone Bulwark Totem", icon = C_Spell.GetSpellTexture(108270), default = addon.NpcOption.Show }, -- hard to kill
    [3527] = { name = "Healing Stream Totem", icon = C_Spell.GetSpellTexture(5394), default = addon.NpcOption.Hide },
    [78001] = { name = "Cloudburst Totem", icon = C_Spell.GetSpellTexture(157153), default = addon.NpcOption.Hide },
    [10467] = { name = "Mana Tide Totem", icon = C_Spell.GetSpellTexture(16191), default = addon.NpcOption.Hide },
    [97285] = { name = "Wind Rush Totem", icon = C_Spell.GetSpellTexture(192077), default = addon.NpcOption.Hide },
    [60561] = { name = "Earthgrab Totem", icon = C_Spell.GetSpellTexture(51485), default = addon.NpcOption.Show }, -- gets players out of stealth
    [2630] = { name = "Earthbind Totem", icon = C_Spell.GetSpellTexture(2484), default = addon.NpcOption.Hide },
    [105427] = { name = "Totem of Wrath", icon = C_Spell.GetSpellTexture(204330), default = addon.NpcOption.Highlight },
    [97369] = { name = "Liquid Magma Totem", icon = C_Spell.GetSpellTexture(192222), default = addon.NpcOption.Hide },
    [179867] = { name = "Static Field Totem", icon = C_Spell.GetSpellTexture(355580), default = addon.NpcOption.Show },
    [194117] = { name = "Stoneskin Totem", icon = C_Spell.GetSpellTexture(383017), default = addon.NpcOption.Show },
    [5923] = { name = "Poison Cleansing Totem", icon = C_Spell.GetSpellTexture(383013), default = addon.NpcOption.Show },
    [194118] = { name = "Tranquil Air Totem", icon = C_Spell.GetSpellTexture(383019), default = addon.NpcOption.Show },
    [225409] = { name = "Tranquil Air Totem", icon = C_Spell.GetSpellTexture(444995), default = addon.NpcOption.Show },
    [95061] = { name = "Greater Fire Elemental", icon = C_Spell.GetSpellTexture(198067), default = addon.NpcOption.Show },
    [61029] = { name = "Primal Fire Elemental", icon = C_Spell.GetSpellTexture(198067), default = addon.NpcOption.Show },

    -- Warrior
    [119052] = { name = "War Banner", icon = C_Spell.GetSpellTexture(236320), default = addon.NpcOption.Highlight },

    -- Priest
    [101398] = { name = "Psyfiend", icon = C_Spell.GetSpellTexture(199824), default = addon.NpcOption.Highlight },
    [224466] = { name = "Voidwraith", icon = C_Spell.GetSpellTexture(451234), default = addon.NpcOption.Show },
    [62982] = { name = "Mindbender", icon = C_Spell.GetSpellTexture(123040), default = addon.NpcOption.Hide },
    [19668] = { name = "Shadowfiend", icon = C_Spell.GetSpellTexture(34433), default = addon.NpcOption.Hide },
    [65282] = { name = "Void Tendrils", icon = C_Spell.GetSpellTexture(108920), default = addon.NpcOption.Show },

    -- Warlock
    [107100] = { name = "Observer", icon = C_Spell.GetSpellTexture(112869), default = addon.NpcOption.Highlight },
    [135002] = { name = "Demonic Tyrant", icon = C_Spell.GetSpellTexture(265187), default = addon.NpcOption.Show },
    [107024] = { name = "Fel Lord", icon = C_Spell.GetSpellTexture(212459), default = addon.NpcOption.Show },
    [196111] = { name = "Pit Lord", icon = C_Spell.GetSpellTexture(138789), default = addon.NpcOption.Show },
    [89] = { name = "Infernal", icon = C_Spell.GetSpellTexture(1122), default = addon.NpcOption.Show },

    -- Paladin
    [114565] = { name = "Guardian of the Forgotten Queen", icon = C_Spell.GetSpellTexture(228049), default = addon.NpcOption.Show },

    -- Evoker
    [185800] = { name = "Past Self", icon = C_Spell.GetSpellTexture(371869), default = addon.NpcOption.Show },
};

addon.AppendNpcOptionsToGroup = function(group)
    group.args = {};

    group.args.header = {
        order = 1,
        type = "description",
        width = "full",
        name = "Select which non-player nameplates to show in PVP instances\nHighlight option shows an animating icon on top of the nameplate",
    };

    local index = 2;
    for spellID, spellInfo in pairs(addon.importantNpcList) do
        group.args[tostring(spellID)] = {
            order = index,
            type = "select",
            width = "full",
            values = {
                [addon.NpcOption.Hide] = "Hide",
                [addon.NpcOption.Show] = "Show",
                [addon.NpcOption.Highlight] = "Highlight",
            },
            name = spellInfo.name,
            icon = spellInfo.icon,
        };
        index = index + 1;
    end
end

addon.FillDefaultToNpcOptions = function(profile)
    for spellID, spellInfo in pairs(addon.importantNpcList) do
        profile[tostring(spellID)] = spellInfo.default;
    end
end
