local _, addon = ...;

addon.NpcOption = {
    Hide = 0,
    Show = 1,
    ShowWithIcon = 2, -- Units we should be aware (but might be hard to kill)
    Highlight = 3, -- For units that should be killed instantly or avoided at any cost :) (e.g., DK Reanimation)
};

addon.importantNpcList = {
    -- DK
    [addon.classID.DEATHKNIGHT] = {
        [106041] = { name = "Reanimation", icon = 210128, default = addon.NpcOption.Highlight }, -- stuns for 3s and takes 10% HP
    },
    
    [addon.classID.SHAMAN] = {
        -- Shaman
        [59764] = { name = "Healing Tide Totem", icon = 108280, default = addon.NpcOption.Highlight },
        [5925] = { name = "Grounding Totem", icon = 204336, default = addon.NpcOption.Highlight },
        [53006] = { name = "Spirit Link Totem", icon = 98008, default = addon.NpcOption.Highlight },
        [5913] = { name = "Tremor Totem", icon = 8143, default = addon.NpcOption.Highlight },
        [104818] = { name = "Ancestral Protection Totem", icon = 207399, default = addon.NpcOption.Highlight },
        [61245] = { name = "Capacitor Totem", icon = 192058, default = addon.NpcOption.Show },
        [105451] = { name = "Counterstrike Totem", icon = 204331, default = addon.NpcOption.Highlight },
        [100943] = { name = "Earthen Wall Totem", icon = 198838, default = addon.NpcOption.Show }, -- hard to kill, just try to fight outside of its range
        [59712] = { name = "Stone Bulwark Totem", icon = 108270, default = addon.NpcOption.Show }, -- hard to kill
        [3527] = { name = "Healing Stream Totem", icon = 5394, default = addon.NpcOption.Hide },
        [78001] = { name = "Cloudburst Totem", icon = 157153, default = addon.NpcOption.Hide },
        [10467] = { name = "Mana Tide Totem", icon = 16191, default = addon.NpcOption.Hide },
        [97285] = { name = "Wind Rush Totem", icon = 192077, default = addon.NpcOption.Hide },
        [60561] = { name = "Earthgrab Totem", icon = 51485, default = addon.NpcOption.Show }, -- gets players out of stealth
        [2630] = { name = "Earthbind Totem", icon = 2484, default = addon.NpcOption.Hide },
        [105427] = { name = "Totem of Wrath", icon = 204330, default = addon.NpcOption.Highlight },
        [97369] = { name = "Liquid Magma Totem", icon = 192222, default = addon.NpcOption.Hide },
        [179867] = { name = "Static Field Totem", icon = 355580, default = addon.NpcOption.Show },
        [194117] = { name = "Stoneskin Totem", icon = 383017, default = addon.NpcOption.Show },
        [5923] = { name = "Poison Cleansing Totem", icon = 383013, default = addon.NpcOption.Show },
        [194118] = { name = "Tranquil Air Totem", icon = 383019, default = addon.NpcOption.Show },
        [225409] = { name = "Tranquil Air Totem", icon = 444995, default = addon.NpcOption.Show },
        [95061] = { name = "Greater Fire Elemental", icon = 198067, default = addon.NpcOption.Show },
        [61029] = { name = "Primal Fire Elemental", icon = 198067, default = addon.NpcOption.Show },
    },
    
    [addon.classID.WARRIOR] = {
        [119052] = { name = "War Banner", icon = 236320, default = addon.NpcOption.Highlight },
    },

    [addon.classID.PRIEST] = {
        -- Priest
        [101398] = { name = "Psyfiend", icon = 199824, default = addon.NpcOption.Highlight },
        [224466] = { name = "Voidwraith", icon = 451234, default = addon.NpcOption.Show },
        [62982] = { name = "Mindbender", icon = 123040, default = addon.NpcOption.Hide },
        [19668] = { name = "Shadowfiend", icon = 34433, default = addon.NpcOption.Hide },
        [65282] = { name = "Void Tendrils", icon = 108920, default = addon.NpcOption.Show },
        [225672] = { name = "Shadow", icon = 8122, default = addon.NpcOption.Show },
    },

    [addon.classID.WARLOCK] = {
        [107100] = { name = "Observer", icon = 112869, default = addon.NpcOption.Highlight },
        [135002] = { name = "Demonic Tyrant", icon = 265187, default = addon.NpcOption.Show },
        [107024] = { name = "Fel Lord", icon = 212459, default = addon.NpcOption.Show },
        [196111] = { name = "Pit Lord", icon = 138789, default = addon.NpcOption.Show },
        [89] = { name = "Infernal", icon = 1122, default = addon.NpcOption.Show },
    },

    [addon.classID.PALADIN] = {
        [114565] = { name = "Guardian of the Forgotten Queen", icon = 228049, default = addon.NpcOption.Show },
    },

    [addon.classID.EVOKER] = {
        [185800] = { name = "Past Self", icon = 371869, default = addon.NpcOption.Show },
    },

    [addon.classID.HUNTER] = {
        [105419] = { name = "Dire Beast: Basilisk", icon = 205691, default = addon.NpcOption.Show },
    },
};

if addon.isTestMode then
    addon.importantNpcList[addon.classID.HUNTER][219250] = { name = "PVP Training Dummy", icon = 267116, default = addon.NpcOption.Highlight };
end

addon.iconTexture = {};
for classID, spells in pairs(addon.importantNpcList) do
    for npcID, spellInfo in pairs(spells) do
        -- Convert to string since this returns string GUID: local npcID = select(6, strsplit("-", guid));
        addon.iconTexture[tostring(npcID)] = C_Spell.GetSpellTexture(spellInfo.icon);
    end
end

addon.AppendNpcOptionsToGroup = function(group)
    group.args = {};

    group.args.header = {
        order = 1,
        type = "description",
        width = "full",
        name = "Select which non-player nameplates to show in PVP instances\nHighlight option shows an animating icon on top of the nameplate",
    };

    local index = 2;
    for classID, spells in pairs(addon.importantNpcList) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        local classGroup = {
            order = index,
            type = "group",
            icon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
			iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };

        local spellIdx = 1;
        for npcID, spellInfo in pairs(spells) do
            -- https://warcraft.wiki.gg/wiki/SpellMixin
            local description;
            local spell = Spell:CreateFromSpellID(spellInfo.icon);
            spell:ContinueOnSpellLoad(function()
                description = spell:GetSpellDescription();
            end)

            classGroup.args[tostring(npcID)] = {
                order = spellIdx,
                type = "select",
                width = "full",
                values = {
                    [addon.NpcOption.Hide] = "Hide",
                    [addon.NpcOption.Show] = "Show",
                    [addon.NpcOption.Highlight] = "Highlight",
                },
                name = format("|T%s:20|t %s", C_Spell.GetSpellTexture(spellInfo.icon), spellInfo.name),
                desc = description,
            };
            spellIdx = spellIdx + 1;
        end

        group.args[tostring(classID)] = classGroup;
        index = index + 1;
    end
end

addon.FillDefaultToNpcOptions = function(profile)
    for classID, spells in pairs(addon.importantNpcList) do
        for npcID, spellInfo in pairs(spells) do
            profile[tostring(npcID)] = spellInfo.default;
        end
    end
end
