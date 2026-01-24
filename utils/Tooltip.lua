-- NuttUI: Tooltip Utils
-- Author: Anthony

local _, NuttUI = ...
NuttUI.Tooltip = {}

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function HideStatusBar(tooltip)
    if not NuttUIDB or not NuttUIDB.HideHealthbar then return end

    local statusBar = tooltip.StatusBar
    if not statusBar and _G["GameTooltipStatusBar"] then
        statusBar = _G["GameTooltipStatusBar"]
    end

    if statusBar then
        statusBar:Hide()
        
        if not statusBar.isNuttUIHooked then
            statusBar:HookScript("OnShow", function(self)
                if NuttUIDB and NuttUIDB.HideHealthbar then
                    self:Hide()
                end 
            end)
            statusBar.isNuttUIHooked = true
        end
    end
end

local function GetValueOrDefault(table, key, default)
    if table and table[key] ~= nil then
        return table[key]
    end
    return default
end

local function MoveTooltipToCursor(tooltip)
    local anchor = GetValueOrDefault(NuttUIDB, "PinAnchor", "BOTTOMLEFT")
    local offsetX = GetValueOrDefault(NuttUIDB, "PinOffsetX", 0)
    local offsetY = GetValueOrDefault(NuttUIDB, "PinOffsetY", 0)

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale

    tooltip:ClearAllPoints()
    tooltip:SetPoint(anchor, UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
end

local function UpdateAnchor(tooltip, parent)
    -- If option is disabled, do nothing (let default behavior happen)
    if not NuttUIDB or not NuttUIDB.PinToCursor then 
        tooltip.isNuttUIPinned = false
        return 
    end

    -- Toggle flag so OnUpdate knows to work
    tooltip.isNuttUIPinned = true

    -- "ANCHOR_NONE" gives us full control
    tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
    
    -- Initial position to prevent flashing
    MoveTooltipToCursor(tooltip)
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------

function NuttUI.Tooltip.Init()
    -- 1. Hide Healthbar logic
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            HideStatusBar(tooltip)
        end)
    end

    -- 2. Pin to Cursor logic
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        UpdateAnchor(tooltip, parent)
    end)
    
    -- Continuous movement
    GameTooltip:HookScript("OnUpdate", function(self)
        if self.isNuttUIPinned then
            MoveTooltipToCursor(self)
        end
    end)
    
    -- Cleanup flag
    GameTooltip:HookScript("OnHide", function(self)
        self.isNuttUIPinned = false
    end)
end
