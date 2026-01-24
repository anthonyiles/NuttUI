local _, NuttUI = ...

NuttUI.Databar:RegisterBit({
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
