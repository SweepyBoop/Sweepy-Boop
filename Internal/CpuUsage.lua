local _, addon = ...;

local lastUpdated;

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
eventFrame:SetScript("OnEvent", function(_, event)
    if ( event == "PLAYER_ENTERING_WORLD" ) then
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
                local cpuUsage = string.format("%.2f", GetAddOnCPUUsage(i) / elapsed);
                table.insert(addonInfo, { name = name, cpuUsage = cpuUsage });
            end

            -- sort by CPU usage
            table.sort(addonInfo, function(a, b) return a.cpuUsage > b.cpuUsage end);

            -- print top 3 add-ons
            print("Top 3 Addons by CPU Usage in last PvP match:");
            for i = 1, math.min(3, #addonInfo) do
                local info = addonInfo[i];
                print(info.name .. ": " .. info.cpuUsage .. " ms/sec");
            end
        end
        ResetCPUUsage();
        lastUpdated = now;
    end
end)
