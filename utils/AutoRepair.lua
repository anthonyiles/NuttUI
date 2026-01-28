local _, NuttUI = ...
NuttUI.AutoRepair = {}

local function FormatCost(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local text = ""
    if gold > 0 then 
        text = string.format("%d|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t ", gold) 
    end
    if silver > 0 or gold > 0 then 
        text = text .. string.format("%d|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t", silver) 
    end
    if text == "" then text = "0|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t" end
    return strtrim(text)
end

function NuttUI.AutoRepair:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:SetScript("OnEvent", function(self, event)
        if event ~= "MERCHANT_SHOW" then return end
        if not CanMerchantRepair() then return end
        
        local settings = NuttUIDB or {}
        local repairMode = settings.AutoRepair
        local fallback = settings.AutoRepairFallback
        
        if not repairMode or repairMode == "None" then return end

        local cost, canRepair = GetRepairAllCost()
        if not canRepair or cost <= 0 then return end

        -- Attempt Repair
        local repaired = false
        local source = ""

        if repairMode == "Guild" then
            if CanGuildBankRepair() then
                 -- Prepare for Guild Repair
                 local withdraw = GetGuildBankWithdrawMoney()
                 local bankMoney = GetGuildBankMoney()
                 
                 if (withdraw == -1 or withdraw >= cost) and bankMoney >= cost then
                     RepairAllItems(true)
                     repaired = true
                     source = "Guild Funds"
                 else
                     print("|cff00ff00NuttUI:|r Guild Repair Failed (Insufficient Funds/Limit).")
                 end
            else
                print("|cff00ff00NuttUI:|r Cannot use Guild Repair.")
            end
        end

        -- Fallback to Personal
        if not repaired then
             local canUsePersonal = (repairMode == "Player") or (repairMode == "Guild" and fallback)
             
             if canUsePersonal then
                 if GetMoney() >= cost then
                     RepairAllItems()
                     repaired = true
                     source = "Personal Funds"
                 else
                     print("|cff00ff00NuttUI:|r Personal Repair Failed (Insufficient Funds).")
                 end
             end
        end

        if repaired then
            print(string.format("|cff00ff00NuttUI:|r Auto-Repaired using %s (%s)", source, FormatCost(cost)))
        end
    end)
end
