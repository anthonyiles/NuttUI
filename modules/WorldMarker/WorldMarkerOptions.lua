local _, NuttUI = ...

function NuttUI:CreateWorldMarkerOptions(parentCategory)
    local frame = CreateFrame("Frame", nil, nil)
    frame.name = "World Markers"

    local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, "World Markers")

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("World Markers")

    -- Description
    local desc = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetText("Cycle through world markers with a keybind. Hold ALT to clear all markers.")

    -- Keybind Section
    local keybindLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    keybindLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -30)
    keybindLabel:SetText("Rotate World Markers:")

    local keybindValue = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    keybindValue:SetPoint("LEFT", keybindLabel, "RIGHT", 10, 0)

    local function UpdateKeybindDisplay()
        local key = GetBindingKey("CLICK RMC_CycleButton:LeftButton")
        if key then
            keybindValue:SetText("|cff00ff00" .. key .. "|r")
        else
            keybindValue:SetText("|cffff6666Not bound|r")
        end
    end

    -- Hint text
    local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", keybindLabel, "BOTTOMLEFT", 0, -10)
    hint:SetText("Set this in the Key Bindings menu (Escape → Key Bindings → NuttUI → World Marker Rotator)")

    -- Open Key Bindings button
    local openBindingsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    openBindingsBtn:SetText("Open Key Bindings")
    openBindingsBtn:SetSize(140, 24)
    openBindingsBtn:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
    openBindingsBtn:SetScript("OnClick", function()
        Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID)
    end)

    frame:SetScript("OnShow", UpdateKeybindDisplay)
end
