-- NuttUI
-- Author: Anthony

local _, NuttUI = ...

print("|cff00ff00NuttUI|r loaded. Type /nui for options.")

-- Default Settings
local defaults = {
    HideHealthbar = true,
    PinToCursor = false,
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
        for k, v in pairs(defaults) do
            if NuttUIDB[k] == nil then
                NuttUIDB[k] = v
            end
        end
        
        -- Initialize modules
        if NuttUI.Tooltip and NuttUI.Tooltip.Init then
            NuttUI.Tooltip.Init()
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
    local function GetValueOrDefault(tbl, key, default)
        if tbl and tbl[key] ~= nil then
            return tbl[key]
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
