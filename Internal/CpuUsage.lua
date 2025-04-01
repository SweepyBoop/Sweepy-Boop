local _, addon = ...;

local lastUpdated;

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:SetScript("OnEvent", function ()
    local now = GetTime();
    if lastUpdated then
        local elapsed = now - lastUpdated;
        UpdateAddOnCPUUsage();

        -- ms spent per second
        local cpuUsage = GetAddOnCPUUsage("SweepyBoop") / elapsed;
        local cpuBigDebuffs = GetAddOnCPUUsage("BigDebuffs") / elapsed;
        print("Addon usage:", cpuUsage, "BigDebuffs usage:", cpuBigDebuffs);
    end
    ResetCPUUsage();
    lastUpdated = now;
end)