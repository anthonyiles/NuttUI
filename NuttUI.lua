-- NuttUI
-- Author: Anthony

local _, NuttUI = ...

print("|cff00ff00NuttUI|r loaded. Type /nui for options.")

-- Default Settings
local defaults = {
    HideHealthbar = true,
    PinToCursor = false,
    PinAnchor = "BOTTOMLEFT",
    PinOffsetX = 0,
    PinOffsetY = 0,
}

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("ADDON_LOADED")
eventHandler:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "NuttUI" then
        -- Load SavedVariables
        NuttUIDB = NuttUIDB or {}
        for key, value in pairs(defaults) do
            if NuttUIDB[key] == nil then
                NuttUIDB[key] = value
            end
        end
        
        -- Initialize modules
        if NuttUI.Tooltip and NuttUI.Tooltip.Init then
            NuttUI.Tooltip.Init()
        end

        if NuttUI.Databar and NuttUI.Databar.Init then
            NuttUI.Databar:Init()
        end
        
        if NuttUI.AutoRepair and NuttUI.AutoRepair.Init then
            NuttUI.AutoRepair:Init()
        end
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

--------------------------------------------------------------------------------
-- Options Menu (Settings API)
--------------------------------------------------------------------------------

local category, layout

function NuttUI:CreateOptions()
    category = Settings.RegisterVerticalLayoutCategory("NuttUI")
    
    -- Helper for boolean defaults
    local function GetValueOrDefault(table, key, default)
        if table and table[key] ~= nil then
            return table[key]
        end
        return default
    end

    -- Hide Healthbar Checkbox
    local function GetHideHealthbar()
        return GetValueOrDefault(NuttUIDB, "HideHealthbar", defaults.HideHealthbar)
    end
    
    local function SetHideHealthbar(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.HideHealthbar = value
    end
    
    local settingHealth = Settings.RegisterProxySetting(
        category, 
        "NuttUI_HideHealthbar", 
        Settings.VarType.Boolean, 
        "Hide Tooltip Healthbar", 
        defaults.HideHealthbar, 
        GetHideHealthbar, 
        SetHideHealthbar
    )
    Settings.CreateCheckbox(category, settingHealth, "Hide the healthbar under unit tooltips.")


    -- Pin to Cursor Checkbox
    local function GetPinToCursor()
        return GetValueOrDefault(NuttUIDB, "PinToCursor", defaults.PinToCursor)
    end
    
    local function SetPinToCursor(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.PinToCursor = value
    end

    local settingPin = Settings.RegisterProxySetting(
        category, 
        "NuttUI_PinToCursor", 
        Settings.VarType.Boolean, 
        "Pin Tooltip to Cursor", 
        defaults.PinToCursor,
        GetPinToCursor, 
        SetPinToCursor
    )
    Settings.CreateCheckbox(category, settingPin, "Anchor unit tooltips to the mouse cursor.")

    -- Pin Anchor Dropdown
    local function GetPinAnchor()
        return GetValueOrDefault(NuttUIDB, "PinAnchor", defaults.PinAnchor)
    end
    
    local function SetPinAnchor(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.PinAnchor = value
    end

    local function GetPinAnchorOptions()
        return function()
            local container = Settings.CreateControlTextContainer()
            container:Add("BOTTOMLEFT", "Bottom Left")
            container:Add("BOTTOMRIGHT", "Bottom Right")
            container:Add("TOPLEFT", "Top Left")
            container:Add("TOPRIGHT", "Top Right")
            container:Add("CENTER", "Center")
            return container:GetData()
        end
    end

    local settingAnchor = Settings.RegisterProxySetting(
        category,
        "NuttUI_PinAnchor",
        Settings.VarType.String,
        "Anchor Point",
        defaults.PinAnchor,
        GetPinAnchor,
        SetPinAnchor
    )
    Settings.CreateDropdown(category, settingAnchor, GetPinAnchorOptions(), "Which part of the tooltip attaches to the cursor.")

    -- Pin Offset X Slider
    local function GetPinOffsetX()
        return GetValueOrDefault(NuttUIDB, "PinOffsetX", defaults.PinOffsetX)
    end
    
    local function SetPinOffsetX(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.PinOffsetX = value
    end

    local settingOffsetX = Settings.RegisterProxySetting(
        category,
        "NuttUI_PinOffsetX",
        Settings.VarType.Number,
        "Offset X",
        defaults.PinOffsetX,
        GetPinOffsetX,
        SetPinOffsetX
    )
    -- Range: -100 to 100, Step: 1
    local optionsX = Settings.CreateSliderOptions(-100, 100, 1)
    optionsX:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, settingOffsetX, optionsX, "Horizontal offset from cursor.")

    -- Pin Offset Y Slider
    local function GetPinOffsetY()
        return GetValueOrDefault(NuttUIDB, "PinOffsetY", defaults.PinOffsetY)
    end
    
    local function SetPinOffsetY(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.PinOffsetY = value
    end

    local settingOffsetY = Settings.RegisterProxySetting(
        category,
        "NuttUI_PinOffsetY",
        Settings.VarType.Number,
        "Offset Y",
        defaults.PinOffsetY,
        GetPinOffsetY,
        SetPinOffsetY
    )
    -- Range: -100 to 100, Step: 1
    local optionsY = Settings.CreateSliderOptions(-100, 100, 1)
    optionsY:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, settingOffsetY, optionsY, "Vertical offset from cursor.")
    
    Settings.RegisterAddOnCategory(category)
end

-- Initialize Options immediately (Settings API handles lazy loading usually, but safe to register early)
NuttUI:CreateOptions()

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

SLASH_NUTTUI1 = "/nui"
SlashCmdList["NUTTUI"] = function(msg)
    Settings.OpenToCategory(category:GetID())
end
