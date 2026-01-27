local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Time",
    interval = 1,
    showLocal = false, -- Default to Server time
    Update = function(self, label)
        local hour, minute
        local typeStr = "Server"
        
        if self.showLocal then
            local d = date("*t")
            hour, minute = d.hour, d.min
            typeStr = "Local"
        else
            hour, minute = GetGameTime()
        end
        
        return string.format("|cffffffff%s:|r |cff00ff00%02d:%02d|r |cff888888(%s)|r", label or "Time", hour, minute, typeStr)
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Time")
        local date = C_DateAndTime.GetCurrentCalendarTime()
        local dateStr = string.format("%02d/%02d/%d", date.monthDay, date.month, date.year)
        GameTooltip:AddLine(dateStr, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Left-Click> Open Calendar", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("<Right-Click> Switch to " .. (self.showLocal and "Server" or "Local") .. " Time", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        if button == "RightButton" then
            self.showLocal = not self.showLocal
            -- Force update if possible, otherwise wait for next tick
            if self.UpdateInternal then self:UpdateInternal() end 
        else
            ToggleCalendar()
        end
    end
})
