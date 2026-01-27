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
    
    createBtn:SetScript("OnClick", function()
        if NuttUI.Notes then
            NuttUI.Notes:New()
        end
    end)
    
    -- Reset All Button
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(150, 30)
    resetBtn:SetPoint("LEFT", createBtn, "RIGHT", 10, 0)
    resetBtn:SetText("Delete All Notes")
    
    resetBtn:SetScript("OnClick", function()
        if NuttUIDB and NuttUIDB.Notes then
            for id in pairs(NuttUIDB.Notes) do
                NuttUI.Notes:Delete(id)
            end
            wipe(NuttUIDB.Notes)
        end
    end)
end
