local _, NuttUI = ...

NuttUI.Databar:RegisterBit({
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
