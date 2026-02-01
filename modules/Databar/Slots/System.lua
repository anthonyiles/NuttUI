local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Addon Memory",
    interval = 10,
    Update = function(self, label)
        -- Garbage Collection is expensive, so we do it here in the update loop (every 10s is fine)
        -- But don't force 'collectgarbage' unless user clicks.
        UpdateAddOnMemoryUsage()

        if not self.addonCache then self.addonCache = {} end
        table.wipe(self.addonCache)

        local total = 0
        local numAddons = C_AddOns.GetNumAddOns()

        for i = 1, numAddons do
            if C_AddOns.IsAddOnLoaded(i) then
                local mem = GetAddOnMemoryUsage(i)
                total = total + mem

                -- Cache logic: Store top X? Or just store all and sort in tooltip?
                -- Sorting all every 10s is better than sorting all every hover.
                table.insert(self.addonCache, {
                    name = C_AddOns.GetAddOnInfo(i),
                    mem = mem
                })
            end
        end

        -- Sort cache once per update
        table.sort(self.addonCache, function(a, b) return a.mem > b.mem end)

        local text = ""
        if total > 1000 then
            text = string.format("%.1fmb", total / 1000)
        else
            text = string.format("%dkb", total)
        end

        return string.format("|cffffffff%s:|r %s%s|r", label or "Mem", NuttUI:GetDatabarColor("|cff00ff00"), text)
    end,
    OnEnter = function(self)
        -- Read from cache
        if not self.addonCache then return end

        GameTooltip:AddLine("Addon Memory Usage")

        -- Show Top 10 from sorted cache
        for i = 1, math.min(#self.addonCache, 10) do
            local mem = self.addonCache[i].mem
            local memStr
            if mem > 1000 then
                memStr = string.format("%.1fmb", mem / 1000)
            else
                memStr = string.format("%dkb", mem)
            end

            GameTooltip:AddDoubleLine(self.addonCache[i].name, memStr, 1, 1, 1, 1, 1, 1)
        end

        GameTooltip:AddLine("Top 10 Addons", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("<Left-Click> to collect garbage", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        collectgarbage("collect")
        print("|cff00ff00NuttUI:|r Memory collected.")
        -- Force immediate update to show new value
        if self.UpdateSlot then self:UpdateSlot(true) end
    end
})
