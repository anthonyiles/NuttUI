local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "FPS",
    interval = 1,
    Update = function(self, label)
        local fps = GetFramerate()
        local color = "00ff00"
        if fps < 30 then color = "ff0000"
        elseif fps < 60 then color = "ffff00" end
        return string.format("|cffffffff%s:|r |cff%s%d|r", label or "FPS", color, math.floor(fps))
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Frames Per Second")
        GameTooltip:AddLine("Target: 60+", 1, 1, 1)
    end,
    OnClick = function(self, button)
        ToggleFrame(VideoOptionsFrame)
    end
})
