local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Guild",
    events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE" },
    -- interval = 10, -- Removed to prevent polling garbage
    Update = function(self, label)
        if not IsInGuild() then
            self.guildCache = nil
            return string.format("|cffffffff%s:|r |cff999999N/A|r", label or "Guild")
        end

        -- Initialize Cache
        if not self.guildCache then self.guildCache = {} end
        table.wipe(self.guildCache)

        local total, online = GetNumGuildMembers()
        online = online or 0

        -- Build Cache
        local count = 0
        for i = 1, total do
            local name, rank, _, _, _, _, _, _, isOnline, status, classFileName = GetGuildRosterInfo(i)
            if isOnline then
                count = count + 1
                -- Limit cache size for tooltip performance if guild is huge, but user wants to see them.
                -- Let's cache up to 50 for tooltip display to be safe?
                -- Original code had a limit of 30 in OnEnter. Let's keep data for 40.
                if count <= 40 then
                    local nameStr = Ambiguate(name, "none")
                    if status and status ~= "" and status ~= 0 and status ~= "0" then
                        nameStr = nameStr .. " " .. status
                    end

                    table.insert(self.guildCache, {
                        name = nameStr,
                        rank = rank,
                        className = classFileName
                    })
                end
            end
        end
        self.totalOnline = online -- Store total for "and X more"

        return string.format("|cffffffff%s:|r %s%d|r", label or "Guild", NuttUI:GetDatabarColor("|cff00ff00"), online)
    end,
    OnEnter = function(self)
        if not IsInGuild() then
            GameTooltip:AddLine("Not in a Guild")
            return
        end
        local guildName = GetGuildInfo("player")
        GameTooltip:AddLine(string.format("%s", guildName or "Guild"), 0, 1, 0)

        if self.guildCache then
            for _, info in ipairs(self.guildCache) do
                local classColor = C_ClassColor.GetClassColor(info.className)
                if classColor then
                    GameTooltip:AddDoubleLine(info.name, info.rank, classColor.r, classColor.g, classColor.b, 1, 1, 1)
                else
                    GameTooltip:AddDoubleLine(info.name, info.rank, 1, 1, 1, 1, 1, 1)
                end
            end

            local shown = #self.guildCache
            if self.totalOnline and self.totalOnline > shown then
                GameTooltip:AddLine(string.format("... and %d more", self.totalOnline - shown), 0.6, 0.6, 0.6)
            end
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
