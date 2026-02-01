local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Currencies",
    events = { "CURRENCY_DISPLAY_UPDATE" },
    interval = 5,
    Update = function(self, label)
        local text = ""
        local count = 0
        -- Iterate currencies and append directly, avoiding 'watched' table
        for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(i)
            if info and not info.isHeader and info.isShowInBackpack then
                local iconStr = string.format("|T%s:12:12:2:0|t", info.iconFileID)
                local amount = BreakUpLargeNumbers(info.quantity)
                text = text .. string.format("%s %s%s|r ", iconStr, NuttUI:GetDatabarColor("|cffffffff"), amount)

                count = count + 1
                if count >= 3 then break end -- Limit to 3 inline
            end
        end

        if count > 0 then
            return strtrim(text)
        else
            text = label or "Currencies"
            return string.format("|cffffffff%s|r", strtrim(text))
        end
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Watched Currencies")

        local found = false
        for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
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
