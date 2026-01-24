local _, NuttUI = ...

NuttUI.Databar:RegisterBit({
    name = "Durability",
    events = {"UPDATE_INVENTORY_DURABILITY"},
    interval = 5,
    Update = function(self)
        local low = 100
        for i = 1, 18 do
            local current, max = GetInventoryItemDurability(i)
            if current and max and max > 0 then
                local region_pct = (current / max) * 100
                if region_pct < low then low = region_pct end
            end
        end
        local color = "ffffff"
        if low < 20 then color = "ff0000"
        elseif low < 50 then color = "ffff00" end
        
        return string.format("Dur |cff%s%d%%|r", color, low)
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Durability Breakdown")
        local slots = {
            {1, "Head"}, {3, "Shoulder"}, {5, "Chest"}, {6, "Waist"}, {7, "Legs"}, 
            {8, "Feet"}, {9, "Wrist"}, {10, "Hands"}, {16, "Main Hand"}, {17, "Off Hand"}
        }
        for _, info in ipairs(slots) do
            local current, max = GetInventoryItemDurability(info[1])
            if current and max and max > 0 then
                local pct = (current / max) * 100
                if pct < 100 then
                    local color = (pct < 30 and "|cffff0000") or (pct < 70 and "|cffffcc00") or "|cffffffff"
                    GameTooltip:AddDoubleLine(info[2], format("%s%d%%|r", color, pct))
                end
            end
        end
         GameTooltip:AddLine(" ")
         GameTooltip:AddLine("<Left-Click> to open Character", 0.5, 0.5, 0.5)
         GameTooltip:AddLine("<Right-Click> for Auto Repair Settings", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            ToggleCharacter("PaperDollFrame")
        elseif button == "RightButton" then
            -- Context Menu for Auto Repair
             if MenuUtil then
                MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                    rootDescription:CreateTitle("Auto Repair")
                    
                    local current = (NuttUIDB and NuttUIDB.AutoRepair) or "None"
                    local function SetAutoRepair(val) 
                        if not NuttUIDB then NuttUIDB = {} end
                        NuttUIDB.AutoRepair = val
                    end
                    
                    rootDescription:CreateRadio("None", function() return current == "None" end, function() SetAutoRepair("None") end)
                    rootDescription:CreateRadio("Personal Funds", function() return current == "Player" end, function() SetAutoRepair("Player") end)
                    rootDescription:CreateRadio("Guild Funds", function() return current == "Guild" end, function() SetAutoRepair("Guild") end)
                end)
            else
                -- Fallback 
                 if not self.menuFrame then
                    self.menuFrame = CreateFrame("Frame", "NuttUIDurMenu", UIParent, "UIDropDownMenuTemplate")
                end
                 local function SetAutoRepair(val) 
                    if not NuttUIDB then NuttUIDB = {} end
                    NuttUIDB.AutoRepair = val
                end
                local current = (NuttUIDB and NuttUIDB.AutoRepair) or "None"
                
                local menu = {
                    { text = "Auto Repair", isTitle = true, notCheckable = true },
                    { text = "None", func = function() SetAutoRepair("None") end, checked = (current == "None") },
                    { text = "Personal Funds", func = function() SetAutoRepair("Player") end, checked = (current == "Player") },
                    { text = "Guild Funds", func = function() SetAutoRepair("Guild") end, checked = (current == "Guild") }
                }
                EasyMenu(menu, self.menuFrame, "cursor", 0 , 0, "MENU")
            end
        end
    end
})
