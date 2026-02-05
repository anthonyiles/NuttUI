BINDING_HEADER_NUTTUI = "NuttUI"
_G["BINDING_NAME_CLICK RMC_CycleButton:LeftButton"] = "World Marker Rotator"

local btn = CreateFrame("Button", "RMC_CycleButton", UIParent, "SecureActionButtonTemplate")
btn:RegisterForClicks("AnyDown", "AnyUp")
btn:SetAttribute("type", "macro")

local secureSnippet = [[
    if down == false then
        return
    end

    -- If ALT is held, clear all markers
    if IsAltKeyDown() then
        self:SetAttribute("macrotext", "/cwm all")
        return
    end

    -- Load current index (default to 0)
    local i = self:GetAttribute("wmIndex") or 0

    -- Increment and Cycle (1 to 8)
    i = (i % 8) + 1

    -- Save index for next press
    self:SetAttribute("wmIndex", i)

    -- Set the macro command to place marker at mouse cursor
    self:SetAttribute("macrotext", "/wm [@cursor] " .. i)
]]

SecureHandlerWrapScript(btn, "PreClick", btn, secureSnippet)
