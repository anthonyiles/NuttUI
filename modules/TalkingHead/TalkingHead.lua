local _, NuttUI = ...

NuttUI.TalkingHead = {}

-- Helper to disable mouse interaction so invisible frames don't block clicks
local function DisableTalkingHeadMouse()
    if not TalkingHeadFrame then return end
    
    TalkingHeadFrame:EnableMouse(false)
    local childrenToDisable = {
        "MainFrame",
        "PortraitFrame",
        "BackgroundFrame",
        "TextFrame",
        "NameFrame",
    }
    for _, childName in ipairs(childrenToDisable) do
        local child = TalkingHeadFrame[childName]
        if child and child.EnableMouse then
            child:EnableMouse(false)
        end
    end
end

-- Helper to re-enable mouse interactions
local function EnableTalkingHeadMouse()
    if not TalkingHeadFrame then return end
    
    TalkingHeadFrame:EnableMouse(true)
    local childrenToEnable = {
        "MainFrame",
        "PortraitFrame",
        "BackgroundFrame",
        "TextFrame",
        "NameFrame",
    }
    for _, childName in ipairs(childrenToEnable) do
        local child = TalkingHeadFrame[childName]
        if child and child.EnableMouse then
            child:EnableMouse(true)
        end
    end
end

function NuttUI.TalkingHead:Init()
    self.hooked = false
    
    -- Create an event listener to wait for the UI to load
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(eventFrame, event, addon)
        if event == "ADDON_LOADED" and addon == "Blizzard_TalkingHeadUI" then
            NuttUI.TalkingHead:UpdateState()
            eventFrame:UnregisterEvent("ADDON_LOADED") -- we only need to catch it once
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Catch case where it might already be loaded
            if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_TalkingHeadUI") then
                NuttUI.TalkingHead:UpdateState()
            end
        end
    end)
    
    self:UpdateState()
end

function NuttUI.TalkingHead:UpdateState()
    if not TalkingHeadFrame then return end
    
    local shouldHide = NuttUIDB and NuttUIDB.DisableTalkingHead

    if shouldHide then
        TalkingHeadFrame:Hide()
        DisableTalkingHeadMouse()
        
        -- Hook Show() to keep it hidden if the game tries to force it open
        if not NuttUI.TalkingHead.hooked then
            hooksecurefunc(TalkingHeadFrame, "Show", function(frame)
                if NuttUIDB and NuttUIDB.DisableTalkingHead then
                    frame:Hide()
                    DisableTalkingHeadMouse()
                end
            end)
            NuttUI.TalkingHead.hooked = true
        end
    else
        EnableTalkingHeadMouse()
    end
end
