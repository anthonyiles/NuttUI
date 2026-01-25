local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Guild",
    events = {"GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE"},
    interval = 10,
    Update = function(self, label)
        if not IsInGuild() then return string.format("|cffffffff%s:|r |cff999999N/A|r", label or "Guild") end
        local total = GetNumGuildMembers()
        local online = 0
        for i = 1, total do
            local _, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
            if isOnline then online = online + 1 end
        end
        return string.format("|cffffffff%s:|r |cff00ff00%d|r", label or "Guild", online)
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
                    local nameStr = Ambiguate(name, "none")
                    
                    -- Only append status if it's a valid string (e.g. <AFK>) and not "0"/0
                    if status and status ~= "" and status ~= 0 and status ~= "0" then 
                        nameStr = nameStr .. " " .. status 
                    end
                    
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
        if button == "LeftButton" then
            ToggleGuildFrame()
        elseif button == "RightButton" then
            if MenuUtil then
                MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                    rootDescription:CreateTitle("Guild Actions")
                    
                    local inviteMenu = rootDescription:CreateButton("Invite")
                    local whisperMenu = rootDescription:CreateButton("Whisper")
                    
                    local total = GetNumGuildMembers()
                    local members = {}
                    
                    for i = 1, total do
                        local name, _, _, _, _, _, _, _, isOnline, _, classFileName = GetGuildRosterInfo(i)
                        if isOnline then
                             local cleanName = Ambiguate(name, "none")
                             if cleanName ~= UnitName("player") then 
                                 table.insert(members, { name = cleanName, class = classFileName })
                             end
                        end
                    end
                    
                    table.sort(members, function(a, b) return a.name < b.name end)
                    
                    if #members == 0 then
                        inviteMenu:CreateTitle("No online members")
                        whisperMenu:CreateTitle("No online members")
                    else
                        for _, m in ipairs(members) do
                            local color = C_ClassColor.GetClassColor(m.class)
                            local text = m.name
                            if color then text = color:WrapTextInColorCode(text) end
                            
                            inviteMenu:CreateButton(text, function() C_PartyInfo.InviteUnit(m.name) end)
                            whisperMenu:CreateButton(text, function() ChatFrame_OpenChat("/w " .. m.name .. " ") end)
                        end
                    end
                end)
            else
                print("NuttUI: MenuUtil not available (Retail only feature?)")
            end
        end
    end
})
