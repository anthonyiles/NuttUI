local _, NuttUI = ...

print("|cff00ff00NuttUI|r loaded. Type /nui for options.")

-- Default Settings
local defaults = {
    HideHealthbar = true,
    PinToCursor = false,
    PinAnchor = "TOPLEFT",
    PinOffsetX = 25,
    PinOffsetY = -20,
    TooltipFadeOut = 1,
    TooltipFadeDelay = 1,
    EnableTooltipFade = false,
    HideTooltipInCombat = false,
    TooltipCombatOverrideKey = "NONE",
    AutoKeystone = true,
    AutoDeleteConfirm = true,
    AutoRepairFallback = true,
    AutoSellJunk = false,
    AutoRoleAccept = true,
    FastLoot = true,
    AutoRoleAcceptModifier = "NONE",
    ClassColorDatabars = false,
    ShowCustomRaidMenu = true,
    RaidMenuPullTimer = 10,
    DisableTalkingHead = false,
    AutoGossip = false,
    ClassColorTooltipNames = false,
}

function NuttUI:GetDatabarColor(defaultHex)
    if NuttUIDB and NuttUIDB.ClassColorDatabars then
        local _, classFileName = UnitClass("player")
        local color = self:GetClassColorObj(classFileName)
        if color then
            return color:GenerateHexColorMarkup()
        end
    end
    return defaultHex or "|cffffffff"
end

function NuttUI:GetClassColorObj(classFileName)
    if not classFileName then return nil end
    return C_ClassColor.GetClassColor(classFileName)
end

function NuttUI:GetClassColorRGB(classFileName)
    local color = self:GetClassColorObj(classFileName)
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

function NuttUI:WrapTextInClassColor(text, classFileName)
    local color = self:GetClassColorObj(classFileName)
    if color then
        return color:WrapTextInColorCode(text)
    end
    return text
end

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

        if NuttUI.AutoRoleAccept and NuttUI.AutoRoleAccept.Init then
            NuttUI.AutoRoleAccept:Init()
        end

        if NuttUI.FastLoot and NuttUI.FastLoot.Init then
            NuttUI.FastLoot:Init()
        end

        if NuttUI.AutoGossip and NuttUI.AutoGossip.Init then
            NuttUI.AutoGossip:Init()
        end

        if NuttUI.Notes and NuttUI.Notes.Init then
            NuttUI.Notes:Init()
        end

        if NuttUI.RaidMenu and NuttUI.RaidMenu.Init then
            NuttUI.RaidMenu:Init()
        end

        if NuttUI.WorldMarker and NuttUI.WorldMarker.Init then
            NuttUI.WorldMarker:Init()
        end

        if NuttUI.TalkingHead and NuttUI.TalkingHead.Init then
            NuttUI.TalkingHead:Init()
        end

        self:UnregisterEvent("ADDON_LOADED")
    end
end)

StaticPopupDialogs["NUTTUI_DELETE_DATABAR"] = {
    text = "Are you sure you want to delete this Databar?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        if self.data and self.data.id then
            NuttUI.Databar:Delete(self.data.id)
            if self.data.onSuccess then
                self.data.onSuccess()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--------------------------------------------------------------------------------
-- Options Menu (Settings API)
--------------------------------------------------------------------------------

local category, layout

function NuttUI:CreateOptions()
    category, layout = Settings.RegisterVerticalLayoutCategory("NuttUI Tweaks")

    -- Helper for boolean defaults
    local function GetValueOrDefault(table, key, default)
        if table and table[key] ~= nil then
            return table[key]
        end
        return default
    end

    -- Tooltip Settings Submenu
    self:CreateTooltipOptions(category)

    -- 2. Mythic+ Utils Header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Mythic+ Utils"))

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
    Settings.CreateCheckbox(category, settingAutoKeystone,
        "Automatically insert the correct keystone when opening the Font of Power.")

    -- 3. Durability Header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Auto Repair"))

    local function GetAutoRepair()
        return GetValueOrDefault(NuttUIDB, "AutoRepair", "None")
    end

    local function SetAutoRepair(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoRepair = value
    end

    local function GetAutoRepairOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("None", "None")
        container:Add("Player", "Personal Gold")
        container:Add("Guild", "Guild Gold")
        return container:GetData()
    end

    local settingAutoRepair = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoRepair",
        Settings.VarType.String,
        "Auto Repair",
        "None",
        GetAutoRepair,
        SetAutoRepair
    )
    Settings.CreateDropdown(category, settingAutoRepair, GetAutoRepairOptions, "Configure automatic repair preferences.")

    -- Auto Repair Fallback Checkbox
    local function GetAutoRepairFallback()
        return GetValueOrDefault(NuttUIDB, "AutoRepairFallback", defaults.AutoRepairFallback)
    end

    local function SetAutoRepairFallback(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoRepairFallback = value
    end

    local settingFallback = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoRepairFallback",
        Settings.VarType.Boolean,
        "Use personal gold if guild repair fails",
        defaults.AutoRepairFallback,
        GetAutoRepairFallback,
        SetAutoRepairFallback
    )
    Settings.CreateCheckbox(category, settingFallback, "Use personal gold if guild repair fails.")

    -- Auto Sell Junk Checkbox
    local function GetAutoSellJunk()
        return GetValueOrDefault(NuttUIDB, "AutoSellJunk", defaults.AutoSellJunk)
    end

    local function SetAutoSellJunk(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoSellJunk = value
    end

    local settingAutoSellJunk = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoSellJunk",
        Settings.VarType.Boolean,
        "Auto Sell Junk",
        defaults.AutoSellJunk,
        GetAutoSellJunk,
        SetAutoSellJunk
    )
    Settings.CreateCheckbox(category, settingAutoSellJunk, "Automatically sell gray quality items when visiting a merchant.")

    -- 4. Quality of Life Header
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Quality of Life"))

    -- Auto Gossip Checkbox
    local function GetAutoGossip()
        return GetValueOrDefault(NuttUIDB, "AutoGossip", defaults.AutoGossip)
    end

    local function SetAutoGossip(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoGossip = value
    end

    local settingAutoGossip = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoGossip",
        Settings.VarType.Boolean,
        "Auto Select Single Gossip (Shift to override)",
        defaults.AutoGossip,
        GetAutoGossip,
        SetAutoGossip
    )
    Settings.CreateCheckbox(category, settingAutoGossip, "Automatically select single gossip options.")

    -- Fast Loot Checkbox
    local function GetFastLoot()
        return GetValueOrDefault(NuttUIDB, "FastLoot", defaults.FastLoot)
    end

    local function SetFastLoot(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.FastLoot = value
    end

    local settingFastLoot = Settings.RegisterProxySetting(
        category,
        "NuttUI_FastLoot",
        Settings.VarType.Boolean,
        "Fast Loot",
        defaults.FastLoot,
        GetFastLoot,
        SetFastLoot
    )
    Settings.CreateCheckbox(category, settingFastLoot, "Instantly loot all items when the loot window opens.")

    -- Auto Role Accept Checkbox
    local function GetAutoRoleAccept()
        return GetValueOrDefault(NuttUIDB, "AutoRoleAccept", defaults.AutoRoleAccept)
    end

    local function SetAutoRoleAccept(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoRoleAccept = value
    end

    local settingAutoRoleAccept = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoRoleAccept",
        Settings.VarType.Boolean,
        "Auto Role Accept",
        defaults.AutoRoleAccept,
        GetAutoRoleAccept,
        SetAutoRoleAccept
    )
    Settings.CreateCheckbox(category, settingAutoRoleAccept, "Automatically accept role checks when popping LFG queues.")

    -- Auto Role Accept Modifier Dropdown
    local function GetAutoRoleModifier()
        return GetValueOrDefault(NuttUIDB, "AutoRoleAcceptModifier", defaults.AutoRoleAcceptModifier)
    end

    local function SetAutoRoleModifier(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoRoleAcceptModifier = value
    end

    local function GetAutoRoleModifierOptions()
        return function()
            local container = Settings.CreateControlTextContainer()
            container:Add("NONE", "None")
            container:Add("SHIFT", "Shift")
            container:Add("CTRL", "Control")
            container:Add("ALT", "Alt")
            return container:GetData()
        end
    end

    local settingAutoRoleModifier = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoRoleAcceptModifier",
        Settings.VarType.String,
        "Auto Role Override Key",
        defaults.AutoRoleAcceptModifier,
        GetAutoRoleModifier,
        SetAutoRoleModifier
    )
    Settings.CreateDropdown(category, settingAutoRoleModifier, GetAutoRoleModifierOptions(),
        "Press this key to temporarily bypass the auto role accept feature.")

    -- Auto Confirm Delete Checkbox
    local function GetAutoDeleteConfirm()
        return GetValueOrDefault(NuttUIDB, "AutoDeleteConfirm", defaults.AutoDeleteConfirm)
    end

    local function SetAutoDeleteConfirm(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.AutoDeleteConfirm = value
    end

    local settingAutoDelete = Settings.RegisterProxySetting(
        category,
        "NuttUI_AutoDeleteConfirm",
        Settings.VarType.Boolean,
        "Auto Confirm Delete",
        defaults.AutoDeleteConfirm,
        GetAutoDeleteConfirm,
        SetAutoDeleteConfirm
    )
    Settings.CreateCheckbox(category, settingAutoDelete, "Automatically fills 'DELETE' in confirmation popups.")

    -- Disable Talking Head Checkbox
    local function GetDisableTalkingHead()
        return GetValueOrDefault(NuttUIDB, "DisableTalkingHead", defaults.DisableTalkingHead)
    end

    local function SetDisableTalkingHead(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.DisableTalkingHead = value
        if NuttUI.TalkingHead and NuttUI.TalkingHead.UpdateState then
            NuttUI.TalkingHead.UpdateState()
        end
    end

    local settingDisableTalkingHead = Settings.RegisterProxySetting(
        category,
        "NuttUI_DisableTalkingHead",
        Settings.VarType.Boolean,
        "Disable Talking Head",
        defaults.DisableTalkingHead,
        GetDisableTalkingHead,
        SetDisableTalkingHead
    )
    Settings.CreateCheckbox(category, settingDisableTalkingHead, "Hides the talking head frame.")

    Settings.RegisterAddOnCategory(category)

    self:CreateDatabarOptions(category)
    self:CreateNotesOptions(category)
    self:CreateWorldMarkerOptions(category)
    self:CreateRaidMenuOptions(category)
end


function NuttUI:CreateTooltipOptions(parentCategory)
    local category, layout = Settings.RegisterVerticalLayoutSubcategory(parentCategory, "Tooltips")
    
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

    -- Class Color Tooltip Names Checkbox
    local function GetClassColorTooltipNames()
        return GetValueOrDefault(NuttUIDB, "ClassColorTooltipNames", defaults.ClassColorTooltipNames)
    end

    local function SetClassColorTooltipNames(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.ClassColorTooltipNames = value
    end

    local settingClassColorNames = Settings.RegisterProxySetting(
        category,
        "NuttUI_ClassColorTooltipNames",
        Settings.VarType.Boolean,
        "Class Colour Player Names",
        defaults.ClassColorTooltipNames,
        GetClassColorTooltipNames,
        SetClassColorTooltipNames
    )
    Settings.CreateCheckbox(category, settingClassColorNames, "Colour player names in tooltips by their class.")

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
    Settings.CreateDropdown(category, settingAnchor, GetPinAnchorOptions(),
        "Which part of the tooltip attaches to the cursor.")

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

    -- Enable Custom Fade Checkbox
    local function GetEnableFade()
        return GetValueOrDefault(NuttUIDB, "EnableTooltipFade", defaults.EnableTooltipFade)
    end

    local function SetEnableFade(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.EnableTooltipFade = value
    end

    local settingEnableFade = Settings.RegisterProxySetting(
        category,
        "NuttUI_EnableTooltipFade",
        Settings.VarType.Boolean,
        "Enable Custom Fade Animation",
        defaults.EnableTooltipFade,
        GetEnableFade,
        SetEnableFade
    )
    Settings.CreateCheckbox(category, settingEnableFade, "Enable the smooth fade out animation for tooltips.")

    -- Tooltip Fade Delay Slider
    local function GetFadeDelay()
        return GetValueOrDefault(NuttUIDB, "TooltipFadeDelay", defaults.TooltipFadeDelay)
    end

    local function SetFadeDelay(value)
        if not NuttUIDB then NuttUIDB = {} end
        local rounded = math.floor(value * 10 + 0.5) / 10
        NuttUIDB.TooltipFadeDelay = rounded
    end

    local settingFadeDelay = Settings.RegisterProxySetting(
        category,
        "NuttUI_TooltipFadeDelay",
        Settings.VarType.Number,
        "Fade Delay",
        defaults.TooltipFadeDelay,
        GetFadeDelay,
        SetFadeDelay
    )
    -- Range: 0 to 5.0, Step: 0.1
    local optionsDelay = Settings.CreateSliderOptions(0, 5.0, 0.1)
    optionsDelay:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%.1f", value)
    end)
    Settings.CreateSlider(category, settingFadeDelay, optionsDelay, "How long to wait before fading (seconds).")

    -- Tooltip Fade Out Duration Slider
    local function GetTooltipFadeOut()
        return GetValueOrDefault(NuttUIDB, "TooltipFadeOut", defaults.TooltipFadeOut)
    end

    local function SetTooltipFadeOut(value)
        if not NuttUIDB then NuttUIDB = {} end
        local rounded = math.floor(value * 10 + 0.5) / 10
        NuttUIDB.TooltipFadeOut = rounded
        if NuttUI.Tooltip and NuttUI.Tooltip.UpdateFade then
            NuttUI.Tooltip.UpdateFade()
        end
    end

    local settingFadeOut = Settings.RegisterProxySetting(
        category,
        "NuttUI_TooltipFadeOut",
        Settings.VarType.Number,
        "Fade Out Duration",
        defaults.TooltipFadeOut,
        GetTooltipFadeOut,
        SetTooltipFadeOut
    )
    -- Range: 0 to 3.0, Step: 0.1
    local optionsFade = Settings.CreateSliderOptions(0, 3.0, 0.1)
    optionsFade:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%.1f", value)
    end)
    Settings.CreateSlider(category, settingFadeOut, optionsFade, "How quickly the tooltip fades away (seconds).")

    -- Hide in Combat Checkbox
    local function GetHideTooltipInCombat()
        return GetValueOrDefault(NuttUIDB, "HideTooltipInCombat", defaults.HideTooltipInCombat)
    end

    local function SetHideTooltipInCombat(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.HideTooltipInCombat = value
    end

    local settingHideCombat = Settings.RegisterProxySetting(
        category,
        "NuttUI_HideTooltipInCombat",
        Settings.VarType.Boolean,
        "Hide Tooltip in Combat",
        defaults.HideTooltipInCombat,
        GetHideTooltipInCombat,
        SetHideTooltipInCombat
    )
    Settings.CreateCheckbox(category, settingHideCombat, "Hide tooltips while you are in combat.")

    -- Combat Override Key Dropdown
    local function GetCombatOverrideKey()
        return GetValueOrDefault(NuttUIDB, "TooltipCombatOverrideKey", defaults.TooltipCombatOverrideKey)
    end

    local function SetCombatOverrideKey(value)
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.TooltipCombatOverrideKey = value
    end

    local function GetCombatOverrideKeyOptions()
        return function()
            local container = Settings.CreateControlTextContainer()
            container:Add("NONE", "None")
            container:Add("SHIFT", "Shift")
            container:Add("CTRL", "Control")
            container:Add("ALT", "Alt")
            return container:GetData()
        end
    end

    local settingCombatKey = Settings.RegisterProxySetting(
        category,
        "NuttUI_TooltipCombatOverrideKey",
        Settings.VarType.String,
        "Combat Override Key",
        defaults.TooltipCombatOverrideKey,
        GetCombatOverrideKey,
        SetCombatOverrideKey
    )
    Settings.CreateDropdown(category, settingCombatKey, GetCombatOverrideKeyOptions(),
        "Press this key to temporarily show tooltips in combat.")
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

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Databar Configuration")

    -- Class Colour Checkbox
    local classColorCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    classColorCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    classColorCheckbox.text = classColorCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classColorCheckbox.text:SetPoint("LEFT", classColorCheckbox, "RIGHT", 5, 0)
    classColorCheckbox.text:SetText("Class colour for text")

    classColorCheckbox:SetScript("OnShow", function(self)
        self:SetChecked(NuttUIDB.ClassColorDatabars)
    end)

    classColorCheckbox:SetScript("OnClick", function(self)
        NuttUIDB.ClassColorDatabars = self:GetChecked()
    end)

    -- Separator
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetWidth(400)
    separator:SetPoint("TOPLEFT", classColorCheckbox, "BOTTOMLEFT", 0, -10)
    separator:SetColorTexture(1, 1, 1, 0.2)

    -- Delete Button (Top Right)
    local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBtn:SetSize(100, 24)
    deleteBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -16)
    deleteBtn:SetText("Delete Bar")
    deleteBtn.confirming = false

    deleteBtn:SetScript("OnClick", function(self)
        if selectedBarID then
            local dialog = StaticPopup_Show("NUTTUI_DELETE_DATABAR")
            if dialog then
                dialog.data = {
                    id = selectedBarID,
                    onSuccess = function()
                        selectedBarID = next(NuttUIDB.Databars)
                        frame:Refresh()
                    end
                }
            end
        end
    end)

    -- Create Button (Left of Delete)
    local createBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    createBtn:SetSize(120, 24)
    createBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -10, 0)
    createBtn:SetText("Create Bar")

    -- Create Button Script
    createBtn:SetScript("OnClick", function()
        local newID = 1
        if NuttUIDB.Databars then
            local max = 0
            for k in pairs(NuttUIDB.Databars) do if k > max then max = k end end
            newID = max + 1
        end

        NuttUIDB.Databars[newID] = {
            NumSlots = 3,
            Slots = { "Guild", "Friends", "Spec" },
            BgColor = { 0, 0, 0, 0.6 },
            Point = { "CENTER", nil, "CENTER", 0, -(newID * 30) }
        }
        NuttUI.Databar:Create(newID)
        selectedBarID = newID
        frame:Refresh()
    end)

    -- Rename Bar EditBox (Left side, below Separator)
    local renameBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    renameBox:SetSize(150, 24)
    renameBox:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 20, -20)
    renameBox:SetAutoFocus(false)
    renameBox:SetTextInsets(5, 5, 0, 0)
    renameBox:SetFontObject("ChatFontNormal")

    local renameLabel = renameBox:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    renameLabel:SetPoint("BOTTOMLEFT", renameBox, "TOPLEFT", 0, 2)
    renameLabel:SetText("Rename Bar:")

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

    -- Bar Selector Dropdown (Right side, below Separator)
    local barSelector = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    barSelector:SetPoint("TOPLEFT", renameBox, "TOPLEFT", 350, -2)

    -- Lock Checkbox (Below Bar Selector)
    local lockCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    lockCheckbox:SetPoint("TOPLEFT", barSelector, "BOTTOMLEFT", 20, 0)
    lockCheckbox.text = lockCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockCheckbox.text:SetPoint("LEFT", lockCheckbox, "RIGHT", 5, 0)
    lockCheckbox.text:SetText("Lock Bar")

    lockCheckbox:SetScript("OnClick", function(self)
        local isLocked = self:GetChecked()
        if NuttUIDB.Databars[selectedBarID] then
            NuttUIDB.Databars[selectedBarID].Locked = isLocked
            local barInstance = NuttUI.Databar:Create(selectedBarID)
            -- Re-create/update to apply lock state
            NuttUI.Databar:Create(selectedBarID)
        end
    end)

    local function GetBarName(id)
        if not id then return "None" end
        local cfg = NuttUIDB.Databars[id]
        if cfg and cfg.Name and cfg.Name ~= "" then
            return cfg.Name
        end
        return "Databar " .. id
    end

    local function UpdateBarDropdown()
        UIDropDownMenu_SetWidth(barSelector, 150)
        local text = "No Bars Created"
        if selectedBarID then
            text = GetBarName(selectedBarID)
        end
        UIDropDownMenu_SetText(barSelector, text)
    end

    UIDropDownMenu_SetWidth(barSelector, 150)
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
    end)

    -- Settings Container
    local settingsContainer = CreateFrame("Frame", nil, frame)
    settingsContainer:SetSize(600, 500)
    settingsContainer:SetPoint("TOPLEFT", renameBox, "BOTTOMLEFT", -20, -50) -- Moved up slightly

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
        local r, g, b, a = unpack(config.BgColor or { 0, 0, 0, 0.6 })
        a = a or 1 -- Ensure alpha is not nil

        local info = {
            r = r,
            g = g,
            b = b,
            opacity = a,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                swatch:SetColorTexture(nr, ng, nb, na)
                config.BgColor = { nr, ng, nb, na }
                local barInstance = NuttUI.Databar:Create(selectedBarID)
                NuttUI.Databar:UpdateLayout(barInstance)
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                swatch:SetColorTexture(nr, ng, nb, na)
                config.BgColor = { nr, ng, nb, na }
                local barInstance = NuttUI.Databar:Create(selectedBarID)
                NuttUI.Databar:UpdateLayout(barInstance)
            end,
            cancelFunc = function(prev)
                local pa = prev.opacity or 1
                swatch:SetColorTexture(prev.r, prev.g, prev.b, pa)
                config.BgColor = { prev.r, prev.g, prev.b, pa }
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
        if config and config.Width ~= val then
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
        if config and config.Height ~= val then
            config.Height = val
            local barInstance = NuttUI.Databar:Create(selectedBarID)
            NuttUI.Databar:UpdateLayout(barInstance)
        end
    end)

    -- Number of Slots
    local slotsSlider = CreateFrame("Slider", "NuttUISlotsSlider", settingsContainer, "OptionsSliderTemplate")
    slotsSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -40)
    slotsSlider:SetWidth(200)
    slotsSlider:SetMinMaxValues(1, 6)
    slotsSlider:SetValueStep(1)
    slotsSlider:SetObeyStepOnDrag(true)
    _G[slotsSlider:GetName() .. "Low"]:SetText("1")
    _G[slotsSlider:GetName() .. "High"]:SetText("6")
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
    labelHeader:SetPoint("TOPLEFT", 70, 10)
    labelHeader:SetText("Slot Type")

    local customHeader = slotConfigFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    customHeader:SetPoint("TOPLEFT", 370, 10)
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
                row:SetPoint("TOPLEFT", 0, -((i - 1) * 45))

                -- Label
                row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                row.label:SetPoint("LEFT", 0, 0)
                row.label:SetText("Slot " .. i)
                row.label:SetWidth(50)

                -- Dropdown (Type)
                row.dropdown = CreateFrame("Frame", "NuttUISlotDrop" .. i, row, "UIDropDownMenuTemplate")
                row.dropdown:SetPoint("LEFT", row.label, "RIGHT", -10, 0)

                -- EditBox (Label Override)
                row.editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                row.editBox:SetSize(120, 20)
                row.editBox:SetPoint("LEFT", row.dropdown, "RIGHT", 160, 0)
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
        if selectedBarID and not NuttUIDB.Databars[selectedBarID] then
            selectedBarID = next(NuttUIDB.Databars)
        end
        if not selectedBarID and NuttUIDB.Databars then
            selectedBarID = next(NuttUIDB.Databars)
        end

        UpdateBarDropdown()

        local config = nil
        if selectedBarID then
            config = NuttUIDB.Databars[selectedBarID]
        end

        if config then
            settingsContainer:Show()
            renameBox:Show()
            renameBtn:Show()
            deleteBtn:Show()
            lockCheckbox:Show()
            renameLabel:Show()

            -- Name
            renameBox:SetText(config.Name or GetBarName(selectedBarID))

            -- Lock State
            lockCheckbox:SetChecked(config.Locked or false)

            -- Colour
            local r, g, b, a = unpack(config.BgColor or { 0, 0, 0, 0.6 })
            swatch:SetColorTexture(r, g, b, a)

            -- Sliders
            widthSlider:SetValue(config.Width or 0)
            heightSlider:SetValue(config.Height or 24)
            slotsSlider:SetValue(config.NumSlots or 3)

            -- Slot Rows
            self:RefreshSlots()
        else
            settingsContainer:Hide()
            renameBox:Hide()
            renameBtn:Hide()
            deleteBtn:Hide()
            lockCheckbox:Hide()
            renameLabel:Hide()
        end
    end

    frame:SetScript("OnShow", function()
        frame:Refresh()
    end)
end

function NuttUI:CreateNotesOptions(parentCategory)
    local frame = CreateFrame("Frame", nil, nil)
    frame.name = "Notes"

    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, "Notes")

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Floating Notes")

    -- Description
    local desc = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetText("Create and manage sticky notes on your screen.")

    -- Create Button
    local createBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    createBtn:SetSize(150, 30)
    createBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    createBtn:SetText("Create New Note")

    -- Reset All Button
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 30)
    resetBtn:SetPoint("LEFT", createBtn, "RIGHT", 10, 0)
    resetBtn:SetText("Delete All Notes")

    -- List Container
    local listContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listContainer:SetPoint("TOPLEFT", createBtn, "BOTTOMLEFT", 0, -20)
    listContainer:SetSize(600, 400)
    listContainer:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })

    local scrollFrame = CreateFrame("ScrollFrame", nil, listContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 5)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(570, 1)
    scrollFrame:SetScrollChild(content)

    frame.noteRows = {}

    local function RefreshList()
        -- Hide existing rows
        for _, row in ipairs(frame.noteRows) do row:Hide() end

        if not NuttUIDB or not NuttUIDB.Notes then return end

        local sortedIDs = {}
        for id in pairs(NuttUIDB.Notes) do table.insert(sortedIDs, id) end
        table.sort(sortedIDs)

        local yOffset = 0
        for i, id in ipairs(sortedIDs) do
            local cfg = NuttUIDB.Notes[id]
            if cfg then
                local row = frame.noteRows[i]
                if not row then
                    row = CreateFrame("Frame", nil, content)
                    row:SetSize(570, 30)

                    -- Note Name
                    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    row.name:SetPoint("LEFT", 10, 0)
                    row.name:SetWidth(180)
                    row.name:SetJustifyH("LEFT")

                    -- Delete Button (Right)
                    row.delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    row.delBtn:SetSize(80, 22)
                    row.delBtn:SetPoint("RIGHT", -10, 0)
                    row.delBtn:SetText("Delete")

                    -- Locked Checkbox
                    row.lockBtn = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    row.lockBtn:SetSize(24, 24)
                    row.lockBtn:SetPoint("RIGHT", row.delBtn, "LEFT", -20, 0)
                    row.lockBtn.text = row.lockBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    row.lockBtn.text:SetPoint("RIGHT", row.lockBtn, "LEFT", -5, 0)
                    row.lockBtn.text:SetText("Locked")

                    -- Show/Hide Checkbox
                    row.showBtn = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    row.showBtn:SetSize(24, 24)
                    row.showBtn:SetPoint("RIGHT", row.lockBtn, "LEFT", -60, 0) -- Gap
                    row.showBtn.text = row.showBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    row.showBtn.text:SetPoint("RIGHT", row.showBtn, "LEFT", -5, 0)
                    row.showBtn.text:SetText("Visible")

                    frame.noteRows[i] = row
                end

                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -yOffset)
                row:Show()

                -- Populate Data
                local title = "Note " .. id
                if cfg.text and cfg.text ~= "" then
                    -- Extract first line
                    local firstLine = cfg.text:match("^[^\n]*")
                    if firstLine and #firstLine > 0 then
                        title = firstLine:sub(1, 25)
                        if #firstLine > 25 then title = title .. "..." end
                    end
                end
                row.name:SetText(title)

                -- Logic
                row.showBtn:SetChecked(not cfg.hidden)
                row.showBtn:SetScript("OnClick", function(self)
                    local visible = self:GetChecked()
                    -- Use Centralized Method
                    NuttUI.Notes:SetHidden(id, not visible)
                end)

                row.lockBtn:SetChecked(cfg.locked)
                row.lockBtn:SetScript("OnClick", function(self)
                    local locked = self:GetChecked()
                    -- Use Centralized Method
                    NuttUI.Notes:SetLock(id, locked)
                end)

                row.delBtn:SetScript("OnClick", function()
                    local dialog = StaticPopup_Show("NUTTUI_DELETE_NOTE")
                    if dialog then
                        dialog.data = id
                        -- Hook OnAccept to refresh list
                        local orig = dialog.OnAccept
                        dialog.OnAccept = function(self)
                            if self.data then
                                NuttUI.Notes:Delete(self.data)
                                -- RefreshList will be triggered by Delete callback
                            end
                        end
                    end
                end)

                yOffset = yOffset + 30
            end
        end
        content:SetHeight(yOffset)
    end

    -- Register Callback
    NuttUI.Notes.UpdateCallback = function()
        if frame:IsVisible() then
            RefreshList()
        end
    end

    createBtn:SetScript("OnClick", function()
        if NuttUI.Notes then
            NuttUI.Notes:New()
            -- RefreshList triggered by callback
        end
    end)

    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("NUTTUI_DELETE_ALL_NOTES")
    end)

    frame:SetScript("OnShow", RefreshList)
end

-- Initialise Options immediately
NuttUI:CreateOptions()

--------------------------------------------------------------------------------
-- Slash Commands
--------------------------------------------------------------------------------

SLASH_NUTTUI1 = "/nui"
SlashCmdList["NUTTUI"] = function(msg)
    local cmd, arg1 = string.split(" ", msg)
    if cmd == "note" then
        if NuttUI.Notes then
            NuttUI.Notes:New()
        end
    else
        Settings.OpenToCategory(category:GetID())
    end
end
