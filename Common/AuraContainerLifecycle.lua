local _, addon = ...;

local providerListeners = {};
local restrictionListeners = {};
local usingRealAuraData = true;
local restrictionReconcileScheduled = false;

function addon.IsUsingRealAuraData()
    return usingRealAuraData;
end

function addon.RegisterAuraDataProviderListener(key, callback)
    providerListeners[key] = callback;
end

function addon.RegisterAuraRestrictionListener(key, callback)
    restrictionListeners[key] = callback;
end

if addon.PROJECT_MAINLINE then
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("AURA_DATA_PROVIDER_SWITCH");
    eventFrame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED");
    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "AURA_DATA_PROVIDER_SWITCH" then
            -- Blizzard_AuraContainer.lua registers this as an intrinsic AuraContainer
            -- event and forwards its boolean payload to OnAuraDataProviderSwitch. Mirror
            -- that contract once for SweepyBoop: false means Blizzard selected its fake
            -- Edit Mode source, so live displays must stay suspended until true restores
            -- the real provider. Consumers re-run their normal eligibility paths instead
            -- of interpreting the provider payload independently.
            if arg1 then
                usingRealAuraData = true;
            else
                usingRealAuraData = false;
            end

            for _, callback in pairs(providerListeners) do
                callback(usingRealAuraData);
            end
            return;
        end

        -- RestrictedActionsDocumentation defines this as a synchronous transition
        -- event fired before activation or after deactivation. In particular, the
        -- restriction predicate is not reliable as an "active now" test during the
        -- activation dispatch. Defer one frame, then let each pending consumer recheck
        -- C_Secrets.ShouldAurasBeSecret before it accesses restricted AuraButtons.
        -- Coalescing protects against several restriction types changing together.
        if not restrictionReconcileScheduled then
            restrictionReconcileScheduled = true;
            C_Timer.After(0, function()
                restrictionReconcileScheduled = false;
                for _, callback in pairs(restrictionListeners) do
                    callback();
                end
            end);
        end
    end);
end
