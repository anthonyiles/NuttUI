local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Coordinates",
    events = {"ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS"},
    interval = 1,
    Update = function(self, label)
        local mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then return string.format("|cffffffff%s:|r n/a", label or "Coords") end
        
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if not pos then return string.format("|cffffffff%s:|r n/a", label or "Coords") end
        
        return string.format("|cffffffff%s:|r %s%.0f, %.0f|r", label or "Coords", NuttUI:GetDatabarColor("|cff00ff00"), pos.x * 100, pos.y * 100)
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Coordinates")
        local zone = GetZoneText()
        local subzone = GetSubZoneText()
        if subzone == "" then subzone = zone end
        
        GameTooltip:AddDoubleLine("Zone:", zone, 1, 1, 1, 1, 1, 1)
        if zone ~= subzone then
            GameTooltip:AddDoubleLine("Subzone:", subzone, 1, 1, 1, 1, 1, 1)
        end
        GameTooltip:AddLine("<Left-Click> to open World Map", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        ToggleWorldMap()
    end
})
