local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Mythic+ Key",
    events = { "BAG_UPDATE" },
    -- interval = 10, -- Removed to prevent polling garbage
    Update = function(self, label)
        local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        local level = C_MythicPlus.GetOwnedKeystoneLevel()

        if not mapID or not level then
            return string.format("|cffffffff%s:|r %sNone|r", label or "Key",
                NuttUI:GetDatabarColor("|cffffffff"))
        end

        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        local color = NuttUI:GetDatabarColor("|cffa335ee")
        return string.format("|cffffffff%s:|r %s%s (%d)|r", label or "Key", color, name, level)
    end,
    OnEnter = function(self)
        local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        local level = C_MythicPlus.GetOwnedKeystoneLevel()

        GameTooltip:AddLine("Mythic+ Keystone")
        if mapID and level then
            local name = C_ChallengeMode.GetMapUIInfo(mapID)
            GameTooltip:AddDoubleLine("Dungeon:", name, 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Level:", level, 1, 1, 1, 1, 1, 1)
        else
            GameTooltip:AddLine("No Keystone found in bags.", 0.6, 0.6, 0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Left-Click> to open Dungeons & Raids", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        ToggleFrame(PVEFrame)
    end
})
