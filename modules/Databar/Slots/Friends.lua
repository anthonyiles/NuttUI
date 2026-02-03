local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Friends",
    events = { "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED" },
    Update = function(self, label)
        -- Initialize Cache
        if not self.friendCache then self.friendCache = {} end
        table.wipe(self.friendCache)

        local onlineFriends = C_FriendList.GetNumOnlineFriends() or 0
        local _, numBNet = BNGetNumFriends()
        numBNet = numBNet or 0
        local wowBNetOnline = 0

        -- 1. WoW Friends Cache
        for i = 1, (C_FriendList.GetNumFriends() or 0) do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.connected then
                table.insert(self.friendCache, {
                    type = "WOW",
                    name = info.name,
                    area = info.area,
                    className = info.className
                })
            end
        end

        -- 2. BNet Friends Cache
        for i = 1, numBNet do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
                local client = accountInfo.gameAccountInfo.clientProgram
                if client == BNET_CLIENT_WOW then
                    wowBNetOnline = wowBNetOnline + 1

                    local charName = accountInfo.gameAccountInfo.characterName
                    local zone = accountInfo.gameAccountInfo.areaName or ""
                    local nameStr = accountInfo.accountName
                    if charName and charName ~= "" then
                        nameStr = nameStr .. " (" .. charName .. ")"
                    end

                    table.insert(self.friendCache, {
                        type = "BNET",
                        name = nameStr,
                        area = zone,
                        className = accountInfo.gameAccountInfo.className
                    })
                end
            end
        end

        return string.format("|cffffffff%s:|r %s%d|r", label or "Friends", NuttUI:GetDatabarColor("|cff00ff00"),
            (onlineFriends + wowBNetOnline))
    end,
    OnEnter = function(self)
        if not self.friendCache then return end

        GameTooltip:AddLine("Friends List", 0, 1, 0)
        GameTooltip:AddLine(string.format("Online: %d", #self.friendCache), 1, 1, 1)

        for _, info in ipairs(self.friendCache) do
            local classColor = info.className and C_ClassColor.GetClassColor(info.className)
            if classColor then
                GameTooltip:AddDoubleLine(info.name, info.area, classColor.r, classColor.g, classColor.b, 1, 1, 1)
            else
                local r, g, b = 1, 1, 1
                if info.type == "BNET" then r, g, b = 0.5, 0.8, 1 end
                GameTooltip:AddDoubleLine(info.name, info.area, r, g, b, 1, 1, 1)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Left-Click> to open Friends", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            ToggleFriendsFrame()
        elseif button == "RightButton" then
            if MenuUtil then
                MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                    rootDescription:CreateTitle("Friends Actions")

                    local inviteMenu = rootDescription:CreateButton("Invite")
                    local whisperMenu = rootDescription:CreateButton("Whisper")

                    local friends = {}

                    -- 1. Server Friends
                    local numFriends = C_FriendList.GetNumFriends() or 0
                    for i = 1, numFriends do
                        local info = C_FriendList.GetFriendInfoByIndex(i)
                        if info and info.connected then
                            table.insert(friends, { name = info.name, class = info.className })
                        end
                    end

                    -- 2. BNet Friends (WoW Only)
                    local _, numBNet = BNGetNumFriends()
                    numBNet = numBNet or 0
                    for i = 1, numBNet do
                        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                        if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
                            if accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
                                local charName = accountInfo.gameAccountInfo.characterName
                                local className = accountInfo.gameAccountInfo.className
                                local realmName = accountInfo.gameAccountInfo.realmName or ""

                                if charName and charName ~= "" then
                                    local inviteName = charName
                                    -- Handle Cross-Realm
                                    local cleanRealm = string.gsub(realmName, " ", "")
                                    local myRealm = string.gsub(GetRealmName(), " ", "")

                                    if cleanRealm ~= "" and cleanRealm ~= myRealm then
                                        inviteName = charName .. "-" .. cleanRealm
                                    end

                                    -- Add BNet name too? Usually invite needs CharName
                                    table.insert(friends,
                                        {
                                            name = inviteName,
                                            display = charName,
                                            class = className,
                                            bnet = accountInfo
                                                .accountName
                                        })
                                end
                            end
                        end
                    end

                    table.sort(friends, function(a, b) return a.name < b.name end)

                    -- Dedup (if friend is on both lists?) - Optional, unlikely to be exact dup char name unless added twice

                    if #friends == 0 then
                        inviteMenu:CreateTitle("No online friends")
                        whisperMenu:CreateTitle("No online friends")
                    else
                        for _, f in ipairs(friends) do
                            local color = f.class and C_ClassColor.GetClassColor(f.class)
                            local text = f.display or f.name
                            if f.bnet then text = text .. " (|cff00ccff" .. f.bnet .. "|r)" end

                            local displayText = text
                            if color then displayText = color:WrapTextInColorCode(text) end

                            inviteMenu:CreateButton(displayText, function() C_PartyInfo.InviteUnit(f.name) end)
                            whisperMenu:CreateButton(displayText,
                                function() ChatFrame_OpenChat("/w " .. f.name .. " ") end)
                        end
                    end
                end)
            end
        end
    end
})
