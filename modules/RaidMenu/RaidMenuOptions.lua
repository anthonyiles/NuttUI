local _, NuttUI = ...

local defaults = {
    RaidMenuPullTimer = 10,
    RaidMenuHideBlizzard = false,
}

function NuttUI:CreateRaidMenuOptions(parentCategory)
    local frame = CreateFrame("Frame", nil, nil)
    frame.name = "Raid Menu"

    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, "Raid Menu")

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Raid Menu")

    -- Description
    local desc = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetText("Configure the Raid Menu pull timer and other settings.")

    -- Pull Timer Section
    local pullTimerLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pullTimerLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -30)
    pullTimerLabel:SetText("Pull Timer Duration:")

    -- Pull Timer Slider
    local pullTimerSlider = CreateFrame("Slider", "NuttUIRaidMenuPullTimerSlider", frame, "OptionsSliderTemplate")
    pullTimerSlider:SetPoint("TOPLEFT", pullTimerLabel, "BOTTOMLEFT", 0, -20)
    pullTimerSlider:SetWidth(200)
    pullTimerSlider:SetMinMaxValues(5, 30)
    pullTimerSlider:SetValueStep(1)
    pullTimerSlider:SetObeyStepOnDrag(true)
    _G[pullTimerSlider:GetName() .. "Low"]:SetText("5s")
    _G[pullTimerSlider:GetName() .. "High"]:SetText("30s")
    _G[pullTimerSlider:GetName() .. "Text"]:SetText("Pull Timer: 10s")

    pullTimerSlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText("Pull Timer: " .. val .. "s")
        if NuttUIDB then
            NuttUIDB.RaidMenuPullTimer = val
        end
    end)

    -- Update display when shown
    frame:SetScript("OnShow", function()
        local currentValue = (NuttUIDB and NuttUIDB.RaidMenuPullTimer) or defaults.RaidMenuPullTimer
        pullTimerSlider:SetValue(currentValue)
        _G[pullTimerSlider:GetName() .. "Text"]:SetText("Pull Timer: " .. currentValue .. "s")
    end)

    -- Hide Default Blizzard UI Checkbox
    local hideBlizzardCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    hideBlizzardCheckbox:SetPoint("TOPLEFT", pullTimerSlider, "BOTTOMLEFT", 0, -30)
    hideBlizzardCheckbox.text = hideBlizzardCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hideBlizzardCheckbox.text:SetPoint("LEFT", hideBlizzardCheckbox, "RIGHT", 5, 0)
    hideBlizzardCheckbox.text:SetText("Hide default Blizzard Raid UI")

    hideBlizzardCheckbox:SetScript("OnShow", function(self)
        self:SetChecked(NuttUIDB and NuttUIDB.RaidMenuHideBlizzard)
    end)

    hideBlizzardCheckbox:SetScript("OnClick", function(self)
        if NuttUIDB then
            NuttUIDB.RaidMenuHideBlizzard = self:GetChecked()
            if NuttUI.RaidMenu and NuttUI.RaidMenu.UpdateBlizzardVisibility then
                NuttUI.RaidMenu:UpdateBlizzardVisibility()
            end
        end
    end)

    local hideBlizzardHint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hideBlizzardHint:SetPoint("TOPLEFT", hideBlizzardCheckbox, "BOTTOMLEFT", 26, -5)
    hideBlizzardHint:SetText("Hides the default raid frame manager (left side toggle bar)")

    -- Vertical Orientation Checkbox
    local verticalCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    verticalCheckbox:SetPoint("TOPLEFT", hideBlizzardHint, "BOTTOMLEFT", -26, -15)
    verticalCheckbox.text = verticalCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    verticalCheckbox.text:SetPoint("LEFT", verticalCheckbox, "RIGHT", 5, 0)
    verticalCheckbox.text:SetText("Vertical layout")

    verticalCheckbox:SetScript("OnShow", function(self)
        self:SetChecked(NuttUIDB and NuttUIDB.RaidMenuVertical)
    end)

    verticalCheckbox:SetScript("OnClick", function(self)
        if NuttUIDB then
            NuttUIDB.RaidMenuVertical = self:GetChecked()
            if NuttUI.RaidMenu and NuttUI.RaidMenu.UpdateLayout then
                NuttUI.RaidMenu:UpdateLayout()
            end
        end
    end)

    local verticalHint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    verticalHint:SetPoint("TOPLEFT", verticalCheckbox, "BOTTOMLEFT", 26, -5)
    verticalHint:SetText("Vertical: tabs top, markers stacked | Horizontal: tabs left, markers row")

    -- Background Transparency Slider
    local transparencyLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    transparencyLabel:SetPoint("TOPLEFT", verticalHint, "BOTTOMLEFT", -26, -25)
    transparencyLabel:SetText("Background Transparency:")

    local transparencySlider = CreateFrame("Slider", "NuttUIRaidMenuTransparencySlider", frame, "OptionsSliderTemplate")
    transparencySlider:SetPoint("TOPLEFT", transparencyLabel, "BOTTOMLEFT", 0, -20)
    transparencySlider:SetWidth(200)
    transparencySlider:SetMinMaxValues(0, 100)
    transparencySlider:SetValueStep(5)
    transparencySlider:SetObeyStepOnDrag(true)
    _G[transparencySlider:GetName() .. "Low"]:SetText("0%")
    _G[transparencySlider:GetName() .. "High"]:SetText("100%")
    _G[transparencySlider:GetName() .. "Text"]:SetText("Opacity: 90%")

    transparencySlider:SetScript("OnValueChanged", function(self, value)
        local val = math.floor(value)
        _G[self:GetName() .. "Text"]:SetText("Opacity: " .. val .. "%")
        if NuttUIDB then
            NuttUIDB.RaidMenuBgAlpha = val / 100
            if NuttUI.RaidMenu and NuttUI.RaidMenu.UpdateBackgroundAlpha then
                NuttUI.RaidMenu:UpdateBackgroundAlpha()
            end
        end
    end)

    -- Update transparency slider when shown
    local origOnShow = frame:GetScript("OnShow")
    frame:SetScript("OnShow", function(self)
        if origOnShow then origOnShow(self) end
        local currentAlpha = (NuttUIDB and NuttUIDB.RaidMenuBgAlpha) or 0.9
        transparencySlider:SetValue(currentAlpha * 100)
        _G[transparencySlider:GetName() .. "Text"]:SetText("Opacity: " .. math.floor(currentAlpha * 100) .. "%")
    end)

    local transparencyHint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    transparencyHint:SetPoint("TOPLEFT", transparencySlider, "BOTTOMLEFT", 0, -8)
    transparencyHint:SetText("0% = fully transparent, 100% = fully opaque")
end
