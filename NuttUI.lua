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
    AutoKeystone = true,
}

--------------------------------------------------------------------------------
-- Initialisation
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
        
        -- Initiliase the default bar if there's no bars yet
        if not NuttUIDB.Databars or next(NuttUIDB.Databars) == nil then
            NuttUIDB.Databars = {
                [1] = {
                    NumSlots = 3,
                    Slots = {"Guild", "Friends", "LootSpec", "Durability"},
                    BgColor = {0, 0, 0, 0.6},
                    Point = {"CENTER", nil, "CENTER", 0, 0}
                }
            }
        end
        
        -- Initialise modules
        if NuttUI.Tooltip and NuttUI.Tooltip.Init then
            NuttUI.Tooltip.Init()
        end

        if NuttUI.Databar and NuttUI.Databar.Init then
            NuttUI.Databar:Init()
        end
        
        if NuttUI.AutoRepair and NuttUI.AutoRepair.Init then
            NuttUI.AutoRepair:Init()
        end

        if NuttUI.AutoKeystone and NuttUI.AutoKeystone.Init then
            NuttUI.AutoKeystone:Init()
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


    -- Pin Tooltip to Cursor Checkbox
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

    -- Tooltip Anchor Dropdown
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

    -- Tooltip Offset X Slider
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

    -- Tooltip Offset Y Slider
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
    
    -- Auto Keystone Checkbox
    local function GetAutoKeystone()
        return GetValueOrDefault(NuttUIDB, "AutoKeystone", defaults.AutoKeystone)
    end
    
    local function SetAutoKeystone(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoKeystone = value
    end

    local settingAutoKeystone = Settings.RegisterProxySetting(
        category, 
        "NuttUI_AutoKeystone", 
        Settings.VarType.Boolean, 
        "Automatically place mythic keystone?",
        defaults.AutoKeystone, 
        GetAutoKeystone, 
        SetAutoKeystone
    )
    Settings.CreateCheckbox(category, settingAutoKeystone, "Automatically slot the correct keystone when opening the Font of Power.")

    Settings.RegisterAddOnCategory(category)
    
    self:CreateDatabarOptions(category)
end

function NuttUI:CreateDatabarOptions(parentCategory)
    local frame = CreateFrame("Frame", nil, nil)
    frame.name = "Databars"
    
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, "Databars")
    
    -- Variables
    local selectedBarID = 1
    if NuttUIDB and NuttUIDB.Databars then
        if not NuttUIDB.Databars[selectedBarID] then
             selectedBarID = next(NuttUIDB.Databars) or 1
        end
    end
    
    -- UI Elements
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Databar Configuration")

    -- Bar Selector Dropdown
    local barSelector = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    barSelector:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -20, -10)
    
    local function GetBarName(id)
        local cfg = NuttUIDB.Databars[id]
        if cfg and cfg.Name and cfg.Name ~= "" then
            return cfg.Name
        end
        return "Databar " .. id
    end
    
    local function UpdateBarDropdown()
        UIDropDownMenu_SetWidth(barSelector, 150)
        UIDropDownMenu_SetText(barSelector, GetBarName(selectedBarID))
        UIDropDownMenu_Initialize(barSelector, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            if NuttUIDB and NuttUIDB.Databars then
                -- Sort keys for consistent order
                local sortedKeys = {}
                for k in pairs(NuttUIDB.Databars) do table.insert(sortedKeys, k) end
                table.sort(sortedKeys)
                
                for _, k in ipairs(sortedKeys) do
                    info.text = GetBarName(k)
                    info.func = function() 
                        selectedBarID = k
                        UIDropDownMenu_SetText(barSelector, GetBarName(k))
                        frame:Refresh()
                    end
                    info.checked = (selectedBarID == k)
                    UIDropDownMenu_AddButton(info, level)
                end
            end
            -- Add New Option
            info.text = "|cff00ff00+ Create New Bar|r"
            info.func = function()
                local newID = 1
                if NuttUIDB.Databars then
                    local max = 0
                    for k in pairs(NuttUIDB.Databars) do if k > max then max = k end end
                    newID = max + 1
                end
                
                NuttUIDB.Databars[newID] = {
                    NumSlots = 3,
                    Slots = {"Guild", "Friends", "LootSpec"},
                    BgColor = {0, 0, 0, 0.6},
                    Point = {"CENTER", nil, "CENTER", 0, - (newID * 30)}
                }
                NuttUI.Databar:Create(newID)
                selectedBarID = newID
                UIDropDownMenu_SetText(barSelector, GetBarName(newID))
                frame:Refresh()
            end
            info.checked = false
            UIDropDownMenu_AddButton(info, level)
        end)
    end
    
    -- Rename Bar EditBox
    local renameBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    renameBox:SetSize(130, 24)
    renameBox:SetPoint("LEFT", barSelector, "RIGHT", 130, 2)
    renameBox:SetAutoFocus(false)
    renameBox:SetTextInsets(5, 5, 0, 0)
    renameBox:SetFontObject("ChatFontNormal")
    
    local renameLabel = renameBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    renameLabel:SetPoint("BOTTOMLEFT", renameBox, "TOPLEFT", 0, 0)
    renameLabel:SetText("Rename:")

    local renameBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    renameBtn:SetSize(50, 22)
    renameBtn:SetPoint("LEFT", renameBox, "RIGHT", 5, 0)
    renameBtn:SetText("Save")
    renameBtn:SetScript("OnClick", function()
        if NuttUIDB.Databars[selectedBarID] then
            NuttUIDB.Databars[selectedBarID].Name = renameBox:GetText()
            frame:Refresh()
        end
        renameBox:ClearFocus()
    end)
    renameBox:SetScript("OnEnterPressed", function() renameBtn:GetScript("OnClick")(renameBtn) end)
    
    -- Delete Button
    local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(100, 24)
    deleteBtn:SetPoint("LEFT", renameBtn, "RIGHT", 30, 0)
    deleteBtn:SetText("Delete Bar")
    deleteBtn.confirming = false
    
    deleteBtn:SetScript("OnClick", function(self)
        if not self.confirming then
            self.confirming = true
            self:SetText("|cffff0000Confirm?|r")
            C_Timer.After(3, function()
                if self.confirming then
                    self.confirming = false
                    self:SetText("Delete Bar")
                end
            end)
        else
            if selectedBarID then
                local count = 0
                for _ in pairs(NuttUIDB.Databars) do count = count + 1 end
                if count <= 1 then
                    print("NuttUI: Cannot delete the last Databar.")
                    self.confirming = false
                    self:SetText("Delete Bar")
                    return 
                end
                
                NuttUI.Databar:Delete(selectedBarID)
                
                selectedBarID = next(NuttUIDB.Databars)
                frame:Refresh()
                
                self.confirming = false
                self:SetText("Delete Bar")
            end
        end
    end)
    
    local oldRefresh = frame.Refresh
    frame.Refresh = function(self)
        if deleteBtn.confirming then
            deleteBtn.confirming = false
            deleteBtn:SetText("Delete Bar")
        end
        oldRefresh(self)
    end
    
    -- Settings Container
    local settingsContainer = CreateFrame("Frame", nil, frame)
    settingsContainer:SetSize(600, 500)
    settingsContainer:SetPoint("TOPLEFT", barSelector, "BOTTOMLEFT", 20, -50)
    
    -- Background Colour
    local colorLabel = settingsContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", 0, 0)
    colorLabel:SetText("Background Colour")
    
    -- Using a standard button to launch ColourPicker
    local colorBtn = CreateFrame("Button", nil, settingsContainer, "UIPanelButtonTemplate")
    colorBtn:SetSize(100, 24)
    colorBtn:SetPoint("LEFT", colorLabel, "RIGHT", 20, 0)
    colorBtn:SetText("Set Colour")
    
    local swatch = settingsContainer:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(24, 24)
    swatch:SetPoint("LEFT", colorBtn, "RIGHT", 10, 0)
    swatch:SetColorTexture(1, 1, 1, 1) -- default
    
    colorBtn:SetScript("OnClick", function()
        local config = NuttUIDB.Databars[selectedBarID]
        if not config then return end
        local r, g, b, a = unpack(config.BgColor or {0,0,0,0.6})
        a = a or 1 -- Ensure alpha is not nil
        
        local info = {
            r = r, g = g, b = b, opacity = a,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                swatch:SetColorTexture(nr, ng, nb, na)
                config.BgColor = {nr, ng, nb, na}
                local barInstance = NuttUI.Databar:Create(selectedBarID)
                NuttUI.Databar:UpdateLayout(barInstance)
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                swatch:SetColorTexture(nr, ng, nb, na)
                config.BgColor = {nr, ng, nb, na}
                local barInstance = NuttUI.Databar:Create(selectedBarID)
                NuttUI.Databar:UpdateLayout(barInstance)
            end,
            cancelFunc = function(prev)
                local pa = prev.opacity or 1
                swatch:SetColorTexture(prev.r, prev.g, prev.b, pa)
                config.BgColor = {prev.r, prev.g, prev.b, pa}
                local barInstance = NuttUI.Databar:Create(selectedBarID)
                NuttUI.Databar:UpdateLayout(barInstance)
            end
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    -- Dimensions (Width / Height)
    -- Width Slider (0 = Auto)
    local widthSlider = CreateFrame("Slider", "NuttUIWidthSlider", settingsContainer, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -30)
    widthSlider:SetWidth(200)
    widthSlider:SetMinMaxValues(0, 1000)
    widthSlider:SetValueStep(10)
    widthSlider:SetObeyStepOnDrag(true)
    _G[widthSlider:GetName() .. "Low"]:SetText("Auto")
    _G[widthSlider:GetName() .. "High"]:SetText("1000")
    _G[widthSlider:GetName() .. "Text"]:SetText("Width: Auto")
    
    widthSlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        local text = (val == 0) and "Auto" or val
        _G[self:GetName() .. "Text"]:SetText("Width: " .. text)
        
        local config = NuttUIDB.Databars[selectedBarID]
        if config then
            config.Width = val
            local barInstance = NuttUI.Databar:Create(selectedBarID)
            NuttUI.Databar:UpdateLayout(barInstance)
        end
    end)

    -- Height Slider
    local heightSlider = CreateFrame("Slider", "NuttUIHeightSlider", settingsContainer, "OptionsSliderTemplate")
    heightSlider:SetPoint("LEFT", widthSlider, "RIGHT", 40, 0)
    heightSlider:SetWidth(200)
    heightSlider:SetMinMaxValues(10, 60)
    heightSlider:SetValueStep(1)
    heightSlider:SetObeyStepOnDrag(true)
    _G[heightSlider:GetName() .. "Low"]:SetText("10")
    _G[heightSlider:GetName() .. "High"]:SetText("60")
    _G[heightSlider:GetName() .. "Text"]:SetText("Height: 24")

    heightSlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText("Height: " .. val)
        
        local config = NuttUIDB.Databars[selectedBarID]
        if config then
            config.Height = val
            local barInstance = NuttUI.Databar:Create(selectedBarID)
            NuttUI.Databar:UpdateLayout(barInstance)
        end
    end)
    
    -- Number of Slots
    local slotsSlider = CreateFrame("Slider", "NuttUISlotsSlider", settingsContainer, "OptionsSliderTemplate")
    slotsSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -40)
    slotsSlider:SetWidth(200)
    slotsSlider:SetMinMaxValues(1, 8)
    slotsSlider:SetValueStep(1)
    slotsSlider:SetObeyStepOnDrag(true)
    _G[slotsSlider:GetName() .. "Low"]:SetText("1")
    _G[slotsSlider:GetName() .. "High"]:SetText("8")
    _G[slotsSlider:GetName() .. "Text"]:SetText("Number of Slots: 3")
    
    slotsSlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText("Number of Slots: " .. val)
        local config = NuttUIDB.Databars[selectedBarID]
        if config and config.NumSlots ~= val then
            config.NumSlots = val
            local barInstance = NuttUI.Databar:Create(selectedBarID)
            NuttUI.Databar:UpdateLayout(barInstance)
            frame:RefreshSlots()
        end
    end)
    
    -- Slot Configuration Area
    local slotConfigFrame = CreateFrame("Frame", nil, settingsContainer)
    slotConfigFrame:SetSize(500, 300)
    slotConfigFrame:SetPoint("TOPLEFT", slotsSlider, "BOTTOMLEFT", 0, -30)
    
    local slotRows = {}
    
    -- Header for Labels
    local labelHeader = slotConfigFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    labelHeader:SetPoint("TOPLEFT", 180, 10)
    labelHeader:SetText("Slot Type")
    
    local customHeader = slotConfigFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    customHeader:SetPoint("TOPLEFT", 320, 10)
    customHeader:SetText("Custom Label")
    
    function frame:RefreshSlots()
        -- Clear old rows (hide)
        for _, row in ipairs(slotRows) do row:Hide() end
        
        local config = NuttUIDB.Databars[selectedBarID]
        if not config then return end
        
        local activeSlots = config.Slots or {}
        local labels = config.SlotLabels or {}
        local num = config.NumSlots or 3
        
        for i = 1, num do
            local row = slotRows[i]
            if not row then
                row = CreateFrame("Frame", nil, slotConfigFrame)
                row:SetSize(480, 40)
                row:SetPoint("TOPLEFT", 0, -((i-1)*45))
                
                -- Label
                row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                row.label:SetPoint("LEFT", 0, 0)
                row.label:SetText("Slot " .. i)
                row.label:SetWidth(50)
                
                -- Dropdown (Type)
                row.dropdown = CreateFrame("Frame", "NuttUISlotDrop"..i, row, "UIDropDownMenuTemplate")
                row.dropdown:SetPoint("LEFT", row.label, "RIGHT", -10, 0)
                
                -- EditBox (Label Override)
                row.editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                row.editBox:SetSize(120, 20)
                row.editBox:SetPoint("LEFT", row.dropdown, "RIGHT", 130, 0)
                row.editBox:SetAutoFocus(false)
                
                -- Save Button
                row.saveBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                row.saveBtn:SetSize(50, 22)
                row.saveBtn:SetPoint("LEFT", row.editBox, "RIGHT", 5, 0)
                row.saveBtn:SetText("Save")
                
                row.saveBtn:SetScript("OnClick", function()
                    row.editBox:ClearFocus()
                    local val = row.editBox:GetText()
                    if val == "" then val = nil end
                    local cfg = NuttUIDB.Databars[selectedBarID]
                    if not cfg.SlotLabels then cfg.SlotLabels = {} end
                    cfg.SlotLabels[row.index] = val
                    
                    local barInstance = NuttUI.Databar:Create(selectedBarID)
                    NuttUI.Databar:UpdateLayout(barInstance)
                end)
                
                -- Update Label on Enter
                row.editBox:SetScript("OnEnterPressed", function(self)
                    row.saveBtn:GetScript("OnClick")(row.saveBtn)
                end)
                
                tinsert(slotRows, row)
            end
            
            row:Show()
            row.index = i
            
            -- Initialise Dropdown
            local currentSlot = activeSlots[i] or "None"
            UIDropDownMenu_SetWidth(row.dropdown, 120)
            UIDropDownMenu_SetText(row.dropdown, currentSlot)
            
            UIDropDownMenu_Initialize(row.dropdown, function(self, level)
                local info = UIDropDownMenu_CreateInfo()
                
                -- Available Slots from Registry
                local options = {}
                for name, _ in pairs(NuttUI.Databar.Registry) do
                    tinsert(options, name)
                end
                table.sort(options)
                
                for _, name in ipairs(options) do
                    info.text = name
                    info.func = function() 
                        activeSlots[i] = name
                        config.Slots = activeSlots
                        UIDropDownMenu_SetText(row.dropdown, name)
                        -- Trigger Update
                        local barInstance = NuttUI.Databar:Create(selectedBarID)
                        NuttUI.Databar:UpdateLayout(barInstance)
                    end
                    info.checked = (currentSlot == name)
                    UIDropDownMenu_AddButton(info, level)
                end
            end)
            
            -- Initialise Editbox
            local currentLabel = labels[i] or ""
            row.editBox:SetText(currentLabel)
            row.editBox:SetCursorPosition(0)
        end
    end
    
    function frame:Refresh()
        -- Ensure valid ID again just in case
        if not NuttUIDB.Databars[selectedBarID] then
             selectedBarID = next(NuttUIDB.Databars) or 1
        end
        UpdateBarDropdown()
        
        local config = NuttUIDB.Databars[selectedBarID]
        if config then
            -- Name
            renameBox:SetText(config.Name or GetBarName(selectedBarID))
            
            -- Colour
            local r, g, b, a = unpack(config.BgColor or {0,0,0,0.6})
            swatch:SetColorTexture(r, g, b, a)
            
            -- Sliders
            widthSlider:SetValue(config.Width or 0)
            heightSlider:SetValue(config.Height or 24)
            slotsSlider:SetValue(config.NumSlots or 3)
            
            -- Slot Rows
            self:RefreshSlots()
        end
    end

    frame:SetScript("OnShow", function()
        frame:Refresh()
    end)

end

-- Initialise Options immediately
NuttUI:CreateOptions()

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

SLASH_NUTTUI1 = "/nui"
SlashCmdList["NUTTUI"] = function(msg)
    Settings.OpenToCategory(category:GetID())
end
