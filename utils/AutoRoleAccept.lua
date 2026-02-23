local _, NuttUI = ...
NuttUI.AutoRoleAccept = {}

local function OnRoleCheckShow()
    if NuttUIDB and NuttUIDB.AutoRoleAccept == false then return end

    local modifier = NuttUIDB and NuttUIDB.AutoRoleAcceptModifier or "NONE"
    if modifier == "SHIFT" and IsShiftKeyDown() then return end
    if modifier == "CTRL" and IsControlKeyDown() then return end
    if modifier == "ALT" and IsAltKeyDown() then return end

    CompleteLFGRoleCheck(true)
end

function NuttUI.AutoRoleAccept:Init()
    local f = CreateFrame("Frame")
    f:RegisterEvent("LFG_ROLE_CHECK_SHOW")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "LFG_ROLE_CHECK_SHOW" then
            OnRoleCheckShow()
        end
    end)
end
