local _, addon = ...;

local lastUpdated;

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
eventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PVP_MATCH_ACTIVE" or ( event == "PLAYER_ENTERING_WORLD" and C_PvP.IsMatchActive() ) then
        ResetCPUUsage();
        lastUpdated = GetTime();
    elseif ( event == "PVP_MATCH_COMPLETE" ) then
        local now = GetTime();
        if lastUpdated then
            UpdateAddOnCPUUsage();
            local elapsed = now - lastUpdated;

            local addonInfo = {}; -- each entry contains name and ms spent per Sec
            for i = 1, C_AddOns.GetNumAddOns() do
                local name = C_AddOns.GetAddOnInfo(i);
                local cpuUsage = tonumber(string.format("%.2f", GetAddOnCPUUsage(i) / elapsed));
                table.insert(addonInfo, { name = name, cpuUsage = cpuUsage });
            end

            -- sort by CPU usage
            table.sort(addonInfo, function(a, b) return a.cpuUsage > b.cpuUsage end);

            -- print top 5 add-ons
            print("Top 5 Addons by CPU Usage in last PvP match:");
            for i = 1, math.min(5, #addonInfo) do
                local info = addonInfo[i];
                print(info.name .. ": " .. info.cpuUsage .. " ms / Sec");
            end
        end
        ResetCPUUsage();
        lastUpdated = now;
    end
end)
