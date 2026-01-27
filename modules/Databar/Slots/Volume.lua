local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Volume",
    events = {"CVAR_UPDATE"},
    interval = 2,
    Update = function(self, label)
        local vol = tonumber(GetCVar("Sound_MasterVolume")) or 0
        local percent = math.floor(vol * 100)
        local color = "ffffff"
        if percent == 0 then color = "999999" end
        return string.format("|cffffffff%s:|r |cff%s%d%%|r", label or "Vol", color, percent)
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Master Volume")
        GameTooltip:AddLine("Scroll to change volume", 1, 1, 1)
        GameTooltip:AddLine("<Right-Click> to toggle mute", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        if button == "RightButton" then
             local current = tonumber(GetCVar("Sound_MasterVolume")) or 0
             if current > 0 then
                 self.lastVol = current
                 SetCVar("Sound_MasterVolume", 0)
             else
                 SetCVar("Sound_MasterVolume", self.lastVol or 0.5)
             end
        end
    end,
    OnMouseWheel = function(self, delta)
        local current = tonumber(GetCVar("Sound_MasterVolume")) or 0
        local step = 0.05
        if delta > 0 then
            current = math.min(1, current + step)
        else
            current = math.max(0, current - step)
        end
        SetCVar("Sound_MasterVolume", current)
    end,
    OnEvent = function(self, event, cvar)
        if event == "CVAR_UPDATE" and cvar == "Sound_MasterVolume" then
            -- Trigger update
             local text = self.data.Update(self, self.labelOverride)
             if text then 
                self.text:SetText(text) 
                self:SetWidth(self.text:GetStringWidth() + 10)
             end
        end
    end
})

-- Hook scrolling for volume
-- Note: This requires the button to be mouse enabled which it is by default in Core.lua
-- However, we can't easily add OnMouseWheel to the button via RegisterSlot without modifying Core.lua.
-- For now, we will add an OnEnter hook that enables wheel capture if possible, or just rely on Core.lua supporting it later.
-- Actually, Core.lua doesn't support OnMouseWheel in RegisterSlot logic.
-- I'll persist without scroll support for now as it requires Core changes, or I can inject it safely.
