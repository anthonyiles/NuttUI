local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Currencies",
    events = {"CURRENCY_DISPLAY_UPDATE"},
    interval = 5,
    Update = function(self, label)
        local text = ""
        -- Default to showing expansion specific currencies or just a label
        -- Ideally this would be configurable, but for now we'll pick a few common ones
        -- ID 2032: Flightstones (Dragonflight) - Example, might be old
        -- For robust implementation, we might just show "Currencies" count or similar,
        -- but the request implies showing actual values.
        -- Let's list a few watched currencies if user has them selected in currency tab.
        
        local count = 0
        local watched = {}
        for i=1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(i)
            if info and not info.isHeader and info.isShowInBackpack then
                table.insert(watched, info)
                count = count + 1
                if count >= 3 then break end -- Limit to 3 inline
            end
        end
        
        if #watched > 0 then
            for _, info in ipairs(watched) do
                local iconStr = string.format("|T%s:12:12:2:0|t", info.iconFileID)
                local amount = BreakUpLargeNumbers(info.quantity)
                text = text .. string.format("%s  %s ", iconStr, amount)
            end
        else
            text = label or "Currencies"
        end
        
        return string.format("|cffffffff%s|r", strtrim(text))
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Watched Currencies")
        
        local found = false
        for i=1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(i)
            if info and not info.isHeader and info.isShowInBackpack then
                found = true
                local iconStr = string.format("|T%s:14:14:2:0|t", info.iconFileID)
                
                local totalStr = string.format("%d", info.quantity)
                if info.maxQuantity > 0 then
                     totalStr = totalStr .. " / " .. info.maxQuantity
                end
                
                GameTooltip:AddDoubleLine(iconStr .. " " .. info.name, totalStr, 1, 1, 1, 1, 1, 1)
            end
        end
        
        if not found then
            GameTooltip:AddLine("No currencies marked as 'Show on Backpack'", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("Go to Character > Currency and click a currency to watch it.", 0.6, 0.6, 0.6)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Left-Click> to open Currency Tab", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        ToggleCharacter("TokenFrame")
    end
})
