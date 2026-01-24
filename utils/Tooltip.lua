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

local function UpdateAnchor(tooltip, parent)
    -- If option is disabled, do nothing (let default behavior happen)
    if not NuttUIDB or not NuttUIDB.PinToCursor then return end

    -- Only modify anchor for GameTooltip when targeting units/world objects typically
    -- We need to be careful not to break other addons or weird anchors
    
    tooltip:SetOwner(parent or UIParent, "ANCHOR_CURSOR")
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
    -- We hook the default anchor setting.
    -- When GameTooltip:SetDefaultAnchor is called (which happens on mouseover of units),
    -- we override it if our setting is enabled.
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        UpdateAnchor(tooltip, parent)
    end)
end
