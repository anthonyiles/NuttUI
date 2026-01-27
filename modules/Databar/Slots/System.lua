local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Addon Memory",
    interval = 10,
    Update = function(self, label)
        UpdateAddOnMemoryUsage()
        local usage = GetAddOnMemoryUsage("NuttUI")
        local total = 0
        for i=1, C_AddOns.GetNumAddOns() do
            if C_AddOns.IsAddOnLoaded(i) then
                total = total + GetAddOnMemoryUsage(i)
            end
        end
        
        local text = ""
        if total > 1000 then 
            text = string.format("%.1fmb", total / 1000)
        else
            text = string.format("%dmb", total)
        end
        
        return string.format("|cffffffff%s:|r |cff00ff00%s|r", label or "Mem", text)
    end,
    OnEnter = function(self)
        UpdateAddOnMemoryUsage()
        GameTooltip:AddLine("Addon Memory Usage")
        
        local addons = {}
        for i=1, C_AddOns.GetNumAddOns() do
            if C_AddOns.IsAddOnLoaded(i) then
                local mem = GetAddOnMemoryUsage(i)
                table.insert(addons, {name = C_AddOns.GetAddOnInfo(i), mem = mem})
            end
        end
        
        table.sort(addons, function(a,b) return a.mem > b.mem end)
        
        for i=1, math.min(#addons, 10) do
            local mem = addons[i].mem
            local memStr
            if mem > 1000 then memStr = string.format("%.1fmb", mem/1000)
            else memStr = string.format("%dkb", mem) end
            
            GameTooltip:AddDoubleLine(addons[i].name, memStr, 1, 1, 1, 1, 1, 1)
        end
        
        GameTooltip:AddLine("Top 10 Addons", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("<Left-Click> to collect garbage", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        collectgarbage("collect")
        print("|cff00ff00NuttUI:|r Memory collected.")
    end
})
