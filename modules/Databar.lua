local _, NuttUI = ...
NuttUI.Databar = {}

local bits = {}
local frame

-- Default Font Object
local function CreateFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    return fs
end

-- -----------------------------------------------------------------------------
-- Bit Registration
-- -----------------------------------------------------------------------------

function NuttUI.Databar:RegisterBit(data)
    -- data needs: name, Update(self), OnEnter(self), OnClick(self)
    table.insert(bits, data)
end

-- -----------------------------------------------------------------------------
-- Core Frame
-- -----------------------------------------------------------------------------

function NuttUI.Databar:UpdateLayout()
    local previousFrame
    local padding = 10
    local totalWidth = padding
    
    for i, data in ipairs(bits) do
        local bitFrame = data.frame
        if not bitFrame then
            bitFrame = CreateFrame("Button", nil, frame)
            bitFrame:SetHeight(20)
            bitFrame:RegisterForClicks("AnyUp") -- Required to detect RightButton
            bitFrame.text = CreateFontString(bitFrame)
            bitFrame.text:SetPoint("CENTER")
            bitFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                if data.OnEnter then data.OnEnter(self) end
                GameTooltip:Show()
            end)
            bitFrame:SetScript("OnLeave", GameTooltip_Hide)
            bitFrame:SetScript("OnClick", function(self, button)
                if data.OnClick then data.OnClick(self, button) end
            end)
            -- Update script
            bitFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed > (data.interval or 1) then
                    self.elapsed = 0
                    if data.Update then 
                        local text = data.Update(self) 
                        if text then 
                            self.text:SetText(text) 
                            self:SetWidth(self.text:GetStringWidth() + 10)
                        end
                    end
                end
            end)
            -- Allow OnEvent if needed
            if data.events then
                for _, event in ipairs(data.events) do
                    bitFrame:RegisterEvent(event)
                end
                bitFrame:SetScript("OnEvent", function(self, event, ...)
                    if data.OnEvent then data.OnEvent(self, event, ...) end
                    -- Force update
                    if data.Update then
                         local text = data.Update(self) 
                         if text then 
                            self.text:SetText(text) 
                            self:SetWidth(self.text:GetStringWidth() + 10)
                         end
                    end
                end)
            end


            
            data.frame = bitFrame
            
            -- Initial update
            if data.Update then
                 local text = data.Update(bitFrame)
                 if text then 
                    bitFrame.text:SetText(text) 
                    bitFrame:SetWidth(bitFrame.text:GetStringWidth() + 10)
                 end
            end
        end
        
        bitFrame:ClearAllPoints()
        if previousFrame then
            bitFrame:SetPoint("LEFT", previousFrame, "RIGHT", padding, 0)
        else
            bitFrame:SetPoint("LEFT", frame, "LEFT", padding, 0)
        end
        
        totalWidth = totalWidth + bitFrame:GetWidth() + padding
        previousFrame = bitFrame
    end
    
    frame:SetWidth(totalWidth)
end

function NuttUI.Databar:CreateBar()
    frame = CreateFrame("Frame", "NuttUIDatabar", UIParent)
    frame:SetSize(200, 24) -- Height 24
    frame:SetPoint("CENTER")
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.6)
    
    -- Movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.DatabarPosition = { point, relativePoint, x, y }
    end)
    
    self:RegisterBits()
    self:UpdateLayout()
end

function NuttUI.Databar:RestorePosition()
    if NuttUIDB and NuttUIDB.DatabarPosition then
        local pos = NuttUIDB.DatabarPosition
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
end

function NuttUI.Databar:Init()
    self:CreateBar()
    self:RestorePosition()
end

-- -----------------------------------------------------------------------------
-- Bits Implementations
-- -----------------------------------------------------------------------------

function NuttUI.Databar:RegisterBits()
    
    -- 1. Guild
    self:RegisterBit({
        name = "Guild",
        events = {"GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE"},
        interval = 10,
        Update = function(self)
            if not IsInGuild() then return "Guild: N/A" end
            local total = GetNumGuildMembers()
            local online = 0
            for i = 1, total do
                local _, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
                if isOnline then online = online + 1 end
            end
            return string.format("Guild: %d", online)
        end,
        OnEnter = function(self)
            if not IsInGuild() then 
                GameTooltip:AddLine("Not in a Guild") 
                return 
            end
            local guildName = GetGuildInfo("player")
            local total = GetNumGuildMembers()
            local onlineCount = 0
            
            GameTooltip:AddLine(string.format("%s", guildName or "Guild"), 0, 1, 0)
            
            for i = 1, total do
                local name, rank, _, _, _, _, _, _, isOnline, status, classFileName = GetGuildRosterInfo(i)
                if isOnline then
                    onlineCount = onlineCount + 1
                    if onlineCount <= 30 then
                        local classColor = C_ClassColor.GetClassColor(classFileName)
                        local nameStr = name
                        if status and status ~= "" then nameStr = nameStr .. " " .. status end
                        if classColor then
                           GameTooltip:AddDoubleLine(nameStr, rank, classColor.r, classColor.g, classColor.b, 1, 1, 1)
                        else
                           GameTooltip:AddDoubleLine(nameStr, rank, 1, 1, 1, 1, 1, 1)
                        end
                    end
                end
            end
            
            if onlineCount > 30 then
                GameTooltip:AddLine(string.format("... and %d more", onlineCount - 30), 0.6, 0.6, 0.6)
            end

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("<Left-Click> to open Guild", 0.5, 0.5, 0.5)
        end,
        OnClick = function(self, button)
            ToggleGuildFrame()
        end
    })

    -- 2. Friends
    self:RegisterBit({
        name = "Friends",
        events = {"FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED"},
        interval = 10,
        Update = function(self)
            local onlineFriends = C_FriendList.GetNumOnlineFriends()
            local _, numBNet = BNGetNumFriends()
            local wowBNetOnline = 0
            
            for i = 1, numBNet do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
                    if accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
                        wowBNetOnline = wowBNetOnline + 1
                    end
                end
            end
            
            return string.format("Friends: %d", (onlineFriends + wowBNetOnline))
        end,
        OnEnter = function(self)
            local onlineFriends = C_FriendList.GetNumOnlineFriends()
            local numBNet = BNGetNumFriends()
            local wowBNetOnline = 0
            
            -- Calculate total for header (optional, or just list them)
             for i = 1, numBNet do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline and accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
                    wowBNetOnline = wowBNetOnline + 1
                end
            end
            
            GameTooltip:AddLine("Friends List", 0, 1, 0)
            GameTooltip:AddLine(string.format("Online: %d", onlineFriends + wowBNetOnline), 1, 1, 1)
            
            -- WoW Friends
            for i = 1, C_FriendList.GetNumFriends() do
                local info = C_FriendList.GetFriendInfoByIndex(i)
                if info and info.connected then
                     local classColor = C_ClassColor.GetClassColor(info.className)
                     if classColor then
                         GameTooltip:AddDoubleLine(info.name, info.area, classColor.r, classColor.g, classColor.b, 1, 1, 1)
                     else
                         GameTooltip:AddDoubleLine(info.name, info.area, 1, 1, 1, 1, 1, 1)
                     end
                end
            end
            
            -- BN Friends (WoW Only)
            for i = 1, numBNet do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
                    local client = accountInfo.gameAccountInfo.clientProgram
                    
                    if client == BNET_CLIENT_WOW then
                        local charName = accountInfo.gameAccountInfo.characterName
                        local zone = accountInfo.gameAccountInfo.areaName or ""
                        local nameStr = accountInfo.accountName 
                        
                        if charName and charName ~= "" then 
                            nameStr = nameStr .. " (" .. charName .. ")"
                        end
    
                        local classFileName = accountInfo.gameAccountInfo.className
                        local classColor = classFileName and C_ClassColor.GetClassColor(classFileName)
                        
                        if classColor then
                             GameTooltip:AddDoubleLine(nameStr, zone, classColor.r, classColor.g, classColor.b, 1, 1, 1)
                        else
                             GameTooltip:AddDoubleLine(nameStr, zone, 0.5, 0.8, 1, 1, 1, 1)
                        end
                    end
                end
            end
            
             GameTooltip:AddLine(" ")
            GameTooltip:AddLine("<Left-Click> to open Friends", 0.5, 0.5, 0.5)
        end,
        OnClick = function(self, button)
            ToggleFriendsFrame()
        end
    })

    -- 3. Loot Spec
    self:RegisterBit({
        name = "LootSpec",
        events = {"PLAYER_LOOT_SPEC_UPDATED", "PLAYER_SPECIALIZATION_CHANGED"},
        interval = 2,
        Update = function(self)
            local specID = GetLootSpecialization()
            if specID == 0 then specID = GetSpecializationInfo(GetSpecialization()) end
            
            if not specID then return "Spec: N/A" end
            
            local _, name, _, icon = GetSpecializationInfoByID(specID)
            if icon then
                return string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, name)
            end
            return name or "Spec"
        end,
        OnEnter = function(self)
            GameTooltip:AddLine("Loot Specialization")
            GameTooltip:AddLine("Right-Click to change spec", 1, 1, 1)
        end,
        MenuGenerator = function(owner, rootDescription)
             rootDescription:CreateTitle("Loot Specialization")
             local function SetSpec(id) SetLootSpecialization(id) end
             
             local current = GetLootSpecialization()
             rootDescription:CreateRadio("Current Specialization", (current == 0), function() SetSpec(0) end)
             
             for i = 1, GetNumSpecializations() do
                  local id, name, _, icon = GetSpecializationInfo(i)
                  rootDescription:CreateRadio(name, (current == id), function() SetSpec(id) end)
             end
        end,
        OnClick = function(self, button)
            if button == "LeftButton" then
                if TogglePlayerSpellsFrame then
                    TogglePlayerSpellsFrame(1)
                elseif ToggleTalentFrame then 
                     ToggleTalentFrame()
                end
            elseif button == "RightButton" then
                local function SetSpec(id) SetLootSpecialization(id) end
                
                if MenuUtil then
                    MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                        rootDescription:CreateTitle("Loot Specialization")
                        
                        -- Helper to wrap boolean check in function for CreateRadio
                        local function IsSelected(id)
                             local current = GetLootSpecialization()
                             if current == 0 then return id == 0 end
                             return current == id
                        end

                        rootDescription:CreateRadio("Current Specialization", function() return IsSelected(0) end, function() SetSpec(0) end)
                        
                        for i = 1, GetNumSpecializations() do
                             local id, name, _, icon = GetSpecializationInfo(i)
                             rootDescription:CreateRadio(name, function() return IsSelected(id) end, function() SetSpec(id) end)
                        end
                    end)
                else
                    -- Legacy fallback
                     if not self.menuFrame then
                        self.menuFrame = CreateFrame("Frame", "NuttUILootSpecMenu", UIParent, "UIDropDownMenuTemplate")
                    end
                    
                    local menu = {
                        { text = "Loot Specialization", isTitle = true, notCheckable = true },
                        { text = "Current Specialization", func = function() SetSpec(0) end, checked = (GetLootSpecialization() == 0) }
                    }
                    
                    for i = 1, GetNumSpecializations() do
                         local id, name = GetSpecializationInfo(i)
                         table.insert(menu, {
                             text = name,
                             func = function() SetSpec(id) end,
                             checked = (GetLootSpecialization() == id)
                         })
                    end
                    
                    EasyMenu(menu, self.menuFrame, "cursor", 0 , 0, "MENU") 
                end
            end
        end
    })

    -- 4. Durability
    self:RegisterBit({
        name = "Durability",
        events = {"UPDATE_INVENTORY_DURABILITY", "MERCHANT_SHOW"},
        interval = 5,
        OnEvent = function(self, event)
            if event == "MERCHANT_SHOW" then
                 if CanMerchantRepair() then
                    local autoRepair = NuttUIDB and NuttUIDB.AutoRepair
                    if not autoRepair or autoRepair == "None" then return end
                    
                    local cost, canRepair = GetRepairAllCost()
                    
                    -- Formatter: Gold & Silver Icons (Hide Copper)
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
                    
                    if canRepair and cost > 0 then
                        local repaired = false
                        local source = ""
                        
                        -- Try Guild First if requested
                        if autoRepair == "Guild" then
                            if CanGuildBankRepair() then
                                local withdraw = GetGuildBankWithdrawMoney()
                                local bankMoney = GetGuildBankMoney()
                                if (withdraw == -1 or withdraw >= cost) and bankMoney >= cost then
                                    RepairAllItems(true)
                                    repaired = true
                                    source = "Guild Funds"
                                else
                                    print("|cff00ff00NuttUI:|r Guild repair failed (Insufficient Funds/Limit).")
                                end
                            else
                                print("|cff00ff00NuttUI:|r Cannot use guild repair.")
                            end
                        end
                        
                        -- Fallback to Personal (if Player mode OR Guild mode failed)
                        if not repaired then
                            if GetMoney() >= cost then
                                RepairAllItems()
                                repaired = true
                                source = "Personal Funds"
                            end
                        end
                        
                        if repaired then
                            print(string.format("|cff00ff00NuttUI:|r Auto-repaired using %s (%s)", source, FormatCost(cost)))
                        else
                             print("|cff00ff00NuttUI:|r Auto-repair failed (Insufficient Funds).")
                        end
                    end
                 end
            end
        end,
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

end
