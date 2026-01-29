local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Latency",
    interval = 5,
    Update = function(self, label)
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local latency = math.max(latencyHome, latencyWorld)
        local color = "00ff00"
        if latency > 300 then color = "ff0000"
        elseif latency > 150 then color = "ffff00" end
        return string.format("|cffffffff%s:|r %s%dms|r", label or "MS", NuttUI:GetDatabarColor("|cff" .. color), latency)
    end,
    OnEnter = function(self)
        local _, _, latencyHome, latencyWorld = GetNetStats()
        GameTooltip:AddLine("Latency")
        GameTooltip:AddDoubleLine("Home:", latencyHome .. "ms", 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("World:", latencyWorld .. "ms", 1, 1, 1, 1, 1, 1)
    end
})
