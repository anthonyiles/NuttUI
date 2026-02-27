local _, NuttUI = ...
NuttUI.AutoGossip = {}

local gossipClicked = {}

local function OnGossipShow()
    if NuttUIDB and NuttUIDB.AutoGossip == false then return end

    -- Shift bypass: let user manually interact
    if IsShiftKeyDown() then return end

    -- Get available quests (pickups) and active quests (turnins)
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local numActiveQuests = C_GossipInfo.GetNumActiveQuests()

    -- If quest options exist, don't auto-select gossip
    if (availableQuests and #availableQuests > 0) or (numActiveQuests and numActiveQuests > 0) then
        return
    end

    -- Get pure gossip options
    local options = C_GossipInfo.GetOptions()
    if not options or #options == 0 then return end

    if #options == 1 then
        -- Single option: auto-select if not already clicked this session
        local option = options[1]
        local optionID = option.gossipOptionID

        if optionID and not gossipClicked[optionID] then
            gossipClicked[optionID] = true
            C_GossipInfo.SelectOption(optionID)

            local optionName = option.name or "gossip"
            print(string.format("|cff00ff00NuttUI:|r %s", optionName))
        end
    else
        -- Multiple options: check for vendor/service flags
        for _, option in pairs(options) do
            if option.flags == 1 and option.gossipOptionID then
                C_GossipInfo.SelectOption(option.gossipOptionID)
                return
            end
        end
    end
end

local function OnGossipClosed()
    gossipClicked = {}
end

function NuttUI.AutoGossip:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("GOSSIP_SHOW")
    frame:RegisterEvent("GOSSIP_CLOSED")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "GOSSIP_SHOW" then
            OnGossipShow()
        elseif event == "GOSSIP_CLOSED" then
            OnGossipClosed()
        end
    end)
end
