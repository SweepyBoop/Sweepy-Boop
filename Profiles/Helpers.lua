local _, addon = ...;
local AceGUI = LibStub("AceGUI-3.0");

-- For export, just export the entire profile
-- Then we can selectively import for certain modules only
function SweepyBoop:ExportProfile()
    local LibDeflate = LibStub:GetLibrary("LibDeflate");
    local data = {
        profile = self.db.profile,
        version = 1,
    };
    local serialized = self:Serialize(data);
    if ( not serialized ) then return end
    local compressed = LibDeflate:CompressZlib(serialized);
    if ( not compressed ) then return end
    return LibDeflate:EncodeForPrint(compressed);
end

function SweepyBoop:ImportError(importDialog, message)
    if ( not message ) or ( importDialog.editBox.editBox:GetNumLetters() == 0 ) then
		importDialog.statustext:SetTextColor(1, 0.82, 0);
		importDialog:SetStatusText("Paste code to import a profile");
	else
		importDialog.statustext:SetTextColor(1, 0, 0);
		importDialog:SetStatusText(string.format("Import failed (%s)", message));
	end
	importDialog.button:SetDisabled(true);
end

function SweepyBoop:ImportProfile(data, module)
    local importDialog = addon.importDialogs and addon.importDialogs[module]; -- module = "" for importing the entire profile, it's valid to use "" as table key
    if ( not importDialog ) then return end

    if ( data.version ~= 1 ) then return self:ImportError(importDialog, "Invalid version") end

    local profile = string.format("Imported (%s)", date());

    if ( module ~= "" ) then
        self.db.profile[module] = data.profile;
    else
        self.db.profile = data.profile;
    end

    self:RefreshConfig(); -- TODO: optimize this to only refresh the module that was imported
end

function SweepyBoop:ShowImport(module)
    local importDialog = addon.importDialogs and addon.importDialogs[module];
    if ( not importDialog ) then return end

    importDialog.editBox:SetText("");
	self:ImportError(importDialog);
	importDialog:Show();
	importDialog.button:SetDisabled(true);
	importDialog.editBox:SetFocus();
end

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

addon.CreateImportDialog = function(module)
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
        if SweepyBoop:ImportProfile(data, module) then import:Hide() end
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

    return import;
end
