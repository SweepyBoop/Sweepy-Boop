local _, addon = ...;
local AceGUI = LibStub("AceGUI-3.0");

addon.CreateExportDialog = function()
    local export = AceGUI:Create("Frame");
    export:SetWidth(550);
    export:EnableResize(false);
    export:SetStatusText("");
    export:SetLayout("Flow");
    export:SetTitle("Export");
    export:SetStatusText("Copy this code to share this profile");
    export:Hide();
    local exportEditBox = AceGUI:Create("MultiLineEditBox");
    exportEditBox:SetLabel("");
    exportEditBox:SetNumLines(29);
    exportEditBox:SetText("");
    exportEditBox:SetFullWidth(true);
    exportEditBox:SetWidth(500);
    exportEditBox.button:Hide();
    exportEditBox.frame:SetClipsChildren(true);
    export:AddChild(exportEditBox);
    export.editBox = exportEditBox;
    return export;
end

addon.CreateImportDialog = function(category)
    local import = AceGUI:Create("Frame");
    import:SetWidth(550);
    import:EnableResize(false);
    import:SetStatusText("");
    import:SetLayout("Flow");
    import:SetTitle("Import");
    import:Hide();
    local importEditBox = AceGUI:Create("MultiLineEditBox");
    importEditBox:SetLabel("");
    importEditBox:SetNumLines(25);
    importEditBox:SetText("");
    importEditBox:SetFullWidth(true);
    importEditBox:SetWidth(500);
    importEditBox.button:Hide();
    importEditBox.frame:SetClipsChildren(true);
    import:AddChild(importEditBox);
    import.editBox = importEditBox;
    local importButton = AceGUI:Create("Button");
    importButton:SetWidth(100);
    importButton:SetText("Import");
    importButton:SetCallback("OnClick", function()
        local data = import.data;
        if (not data) then return end
        if SweepyBoop:ImportProfile(data, category) then import:Hide() end
    end)
    import:AddChild(importButton);
    import.button = importButton;
    importEditBox:SetCallback("OnTextChanged", function(widget)
        local data = SweepyBoop:Decode(widget:GetText());
        if (not data) then return end
        import.statustext:SetTextColor(0,1,0);
        import:SetStatusText("Ready to import");
        importButton:SetDisabled(false);
        import.data = data;
    end)
end
