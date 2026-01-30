local _, NuttUI = ...
NuttUI.Notes = {}
NuttUI.Notes.Instances = {}

StaticPopupDialogs["NUTTUI_DELETE_NOTE"] = {
  text = "Delete this note?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function(self)
      if self.data then
          NuttUI.Notes:Delete(self.data)
      end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
  preferredIndex = 3,
}

StaticPopupDialogs["NUTTUI_HIDE_NOTE"] = {
  text = "Hide this note?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function(self)
      if self.data then
          NuttUI.Notes:SetHidden(self.data, true)
      end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
  preferredIndex = 3,
}

StaticPopupDialogs["NUTTUI_DELETE_ALL_NOTES"] = {
  text = "Are you sure you want to delete ALL notes?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function(self)
      if NuttUIDB and NuttUIDB.Notes then
          for id in pairs(NuttUIDB.Notes) do
              NuttUI.Notes:Delete(id)
          end
          wipe(NuttUIDB.Notes)
          -- Callback triggered by Delete individual calls, but let's ensure one final refresh if needed
          if NuttUI.Notes.UpdateCallback then NuttUI.Notes.UpdateCallback() end
      end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- -----------------------------------------------------------------------------
-- Note Logic
-- -----------------------------------------------------------------------------

function NuttUI.Notes:Create(id, config)
    if self.Instances[id] then return self.Instances[id] end
    
    config = config or {}
    
    local frameName = "NuttUINote_" .. id
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame.id = id
    
    -- Visuals
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Default to saved color or black with 20% opacity
    local r = config.r or 0
    local g = config.g or 0
    local b = config.b or 0
    local a = config.a or 0.2
    
    -- Text Color Defaults (White)
    local tr = config.tr or 1
    local tg = config.tg or 1
    local tb = config.tb or 1
    local ta = config.ta or 1
    
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Sizing & Positioning
    frame:SetSize(config.width or 200, config.height or 150)
    frame:SetResizeBounds(100, 80)
    
    if config.point then
        local p = config.point
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    
    frame:SetScript("OnDragStart", function(self)
        if not NuttUIDB.Notes[self.id].locked then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        if not NuttUIDB.Notes[self.id] then NuttUIDB.Notes[self.id] = {} end
        NuttUIDB.Notes[self.id].point = { point, relativePoint, x, y }
    end)
    
    -- Resizable
    frame:SetResizable(true)
    local resizeBtn = CreateFrame("Button", nil, frame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT")
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeBtn:SetScript("OnMouseDown", function(self)
        if not NuttUIDB.Notes[frame.id].locked then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    
    resizeBtn:SetScript("OnMouseUp", function(self)
        frame:StopMovingOrSizing()
        if not NuttUIDB.Notes[frame.id] then NuttUIDB.Notes[frame.id] = {} end
        NuttUIDB.Notes[frame.id].width = frame:GetWidth()
        NuttUIDB.Notes[frame.id].height = frame:GetHeight()
    end)
    frame.resizeBtn = resizeBtn

    -- Header (Drag Handle & Controls)
    local header = CreateFrame("Frame", nil, frame)
    header:SetHeight(20)
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    
    -- Background Color Picker Button (Left)
    local bgColorBtn = CreateFrame("Button", nil, header)
    bgColorBtn:SetSize(14, 14)
    bgColorBtn:SetPoint("LEFT", 5, 0)
    
    local bgTexture = bgColorBtn:CreateTexture(nil, "ARTWORK")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(r, g, b, 1) 
    local bgBorder = bgColorBtn:CreateTexture(nil, "BORDER")
    bgBorder:SetPoint("TOPLEFT", -1, 1)
    bgBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    bgBorder:SetColorTexture(1, 1, 1, 0.5)
    
    bgColorBtn:SetScript("OnClick", function()
        local cfg = NuttUIDB.Notes[frame.id]
        local info = {
            r = cfg.r or 0, g = cfg.g or 0, b = cfg.b or 0, opacity = cfg.a or 0.2,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                bgTexture:SetColorTexture(nr, ng, nb, 1)
                frame:SetBackdropColor(nr, ng, nb, na)
                cfg.r, cfg.g, cfg.b, cfg.a = nr, ng, nb, na
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                bgTexture:SetColorTexture(nr, ng, nb, 1)
                frame:SetBackdropColor(nr, ng, nb, na)
                cfg.r, cfg.g, cfg.b, cfg.a = nr, ng, nb, na
            end,
            cancelFunc = function(prev) 
                local pa = prev.opacity or 1
                bgTexture:SetColorTexture(prev.r, prev.g, prev.b, 1)
                frame:SetBackdropColor(prev.r, prev.g, prev.b, pa)
                cfg.r, cfg.g, cfg.b, cfg.a = prev.r, prev.g, prev.b, pa
            end
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    -- Text Color Picker Button (Next to BG Color)
    local textColorBtn = CreateFrame("Button", nil, header)
    textColorBtn:SetSize(14, 14)
    textColorBtn:SetPoint("LEFT", bgColorBtn, "RIGHT", 5, 0)
    
    local textTexture = textColorBtn:CreateTexture(nil, "ARTWORK")
    textTexture:SetAllPoints()
    textTexture:SetColorTexture(tr, tg, tb, 1)
    local textBorder = textColorBtn:CreateTexture(nil, "BORDER")
    textBorder:SetPoint("TOPLEFT", -1, 1)
    textBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    textBorder:SetColorTexture(1, 1, 1, 0.5)
    
    -- Helper to update text color
    local function contentEditBox() return frame.editBox end -- Lazy access

    textColorBtn:SetScript("OnClick", function()
        local cfg = NuttUIDB.Notes[frame.id]
        local info = {
            r = cfg.tr or 1, g = cfg.tg or 1, b = cfg.tb or 1, opacity = cfg.ta or 1,
            hasOpacity = true,
            swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                textTexture:SetColorTexture(nr, ng, nb, 1)
                if contentEditBox() then 
                    contentEditBox():SetTextColor(nr, ng, nb, na)
                end
                cfg.tr, cfg.tg, cfg.tb, cfg.ta = nr, ng, nb, na
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = ColorPickerFrame:GetColorAlpha() or 1
                textTexture:SetColorTexture(nr, ng, nb, 1)
                if contentEditBox() then 
                    contentEditBox():SetTextColor(nr, ng, nb, na)
                end
                cfg.tr, cfg.tg, cfg.tb, cfg.ta = nr, ng, nb, na
            end,
            cancelFunc = function(prev) 
                local pa = prev.opacity or 1
                textTexture:SetColorTexture(prev.r, prev.g, prev.b, 1)
                if contentEditBox() then
                    contentEditBox():SetTextColor(prev.r, prev.g, prev.b, pa)
                end
                cfg.tr, cfg.tg, cfg.tb, cfg.ta = prev.r, prev.g, prev.b, pa
            end
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    -- Menu Button (Top Right)
    local menuBtn = CreateFrame("Button", nil, header)
    menuBtn:SetSize(20, 20)
    menuBtn:SetPoint("RIGHT", 0, 0)
    
    local menuIcon = menuBtn:CreateTexture(nil, "ARTWORK")
    menuIcon:SetSize(16, 16)
    menuIcon:SetPoint("CENTER")
    menuIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    menuBtn:SetNormalTexture(menuIcon)
    
    local menuIconH = menuBtn:CreateTexture(nil, "ARTWORK")
    menuIconH:SetSize(16, 16)
    menuIconH:SetPoint("CENTER")
    menuIconH:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    menuBtn:SetHighlightTexture(menuIconH)
    
    -- Menu Frame for Dropdown
    if not frame.menuFrame then
        frame.menuFrame = CreateFrame("Frame", "NuttUINoteMenu_"..id, frame, "UIDropDownMenuTemplate")
    end

    menuBtn:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
            rootDescription:CreateTitle("Options")
            
            -- Lock Note (Checkbox)
            rootDescription:CreateCheckbox(
                "Lock",
                function() return NuttUIDB.Notes[frame.id].locked end,
                function()
                    local wasLocked = NuttUIDB.Notes[frame.id].locked
                    NuttUI.Notes:SetLock(frame.id, not wasLocked)
                end
            )
            
            -- Hide Note (Button)
            rootDescription:CreateButton(
                "Hide",
                function()
                    local dialog = StaticPopup_Show("NUTTUI_HIDE_NOTE")
                    if dialog then dialog.data = frame.id end
                end
            )
            
            -- Delete Note (Button)
            rootDescription:CreateButton(
                "Delete",
                function()
                    local dialog = StaticPopup_Show("NUTTUI_DELETE_NOTE")
                    if dialog then dialog.data = frame.id end
                end
            )
        end)
    end)
    
    frame.menuBtn = menuBtn

    local function UpdateVisuals(locked)
        local cfg = NuttUIDB.Notes[frame.id]

        -- Toggle Controls
        if locked then
            resizeBtn:Hide()
            bgColorBtn:Hide()
            textColorBtn:Hide()
            
            -- Lock EditBox
            if frame.editBox then
                frame.editBox:EnableMouse(false)
                frame.editBox:ClearFocus()
            end
            
            frame:SetBackdropColor((cfg.r or 0), (cfg.g or 0), (cfg.b or 0), (cfg.a or 0.2)) 
            frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5) -- Dimmer border
            
            -- Dim ScrollBar
            if frame.scrollFrame and frame.scrollFrame.ScrollBar then
                 frame.scrollFrame.ScrollBar:SetAlpha(0.5)
            end
        else
            resizeBtn:Show()
            bgColorBtn:Show()
            textColorBtn:Show()
            
            -- Unlock EditBox
            if frame.editBox then
                frame.editBox:EnableMouse(true)
            end
            
            frame:SetBackdropColor((cfg.r or 0), (cfg.g or 0), (cfg.b or 0), (cfg.a or 0.2))
            frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            
            -- Restore ScrollBar
            if frame.scrollFrame and frame.scrollFrame.ScrollBar then
                 frame.scrollFrame.ScrollBar:SetAlpha(1.0)
            end
        end
    end

    -- Store UpdateVisuals on the frame.
    frame.UpdateVisuals = UpdateVisuals
    

    
    if config.hidden then
        frame:Hide()
    end
    
    -- Content EditBox
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame = scrollFrame -- Expose for UpdateVisuals
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 4, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 8) -- Leave room for resize grip
    
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(false)
    editBox:SetText(config.text or "")
    editBox:SetTextColor(tr, tg, tb, ta) -- Set Initial Text Color
    
    scrollFrame:SetScrollChild(editBox)
    
    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if not NuttUIDB.Notes[frame.id] then NuttUIDB.Notes[frame.id] = {} end
        NuttUIDB.Notes[frame.id].text = text
    end)
    
    editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
        self:SetWidth(scrollFrame:GetWidth())
    end)
    
    frame.editBox = editBox
    
    self.Instances[id] = frame
    
    frame:SetScript("OnSizeChanged", function(self, w, h)
        editBox:SetWidth(scrollFrame:GetWidth())
    end)
    
    -- Initial Lock State
    if config.locked then
        UpdateVisuals(true)
    end
    
    -- Trigger Callback (New/Update)
    if self.UpdateCallback then self.UpdateCallback() end
    
    return frame
end

function NuttUI.Notes:SetLock(id, state)
    if not NuttUIDB.Notes[id] then return end
    NuttUIDB.Notes[id].locked = state
    
    local frame = self.Instances[id]
    if frame then
        -- Update Checkbox
        -- Access internal button? Need to expose it or find by name/child.
        -- Finding by structure is fragile. Let's expose it in Create.
        -- Exposing via frame.lockBtn

        
        -- Update Visuals
        if frame.UpdateVisuals then frame.UpdateVisuals(state) end
    end
    
    if self.UpdateCallback then self.UpdateCallback() end
end

function NuttUI.Notes:SetHidden(id, state)
    if not NuttUIDB.Notes[id] then return end
    NuttUIDB.Notes[id].hidden = state
    
    if self.Instances[id] then
        if state then
            self.Instances[id]:Hide()
        else
            self.Instances[id]:Show()
        end
    end
    
    if self.UpdateCallback then self.UpdateCallback() end
end

function NuttUI.Notes:Delete(id)
    if self.Instances[id] then
        self.Instances[id]:Hide()
        self.Instances[id]:SetParent(nil)
        self.Instances[id] = nil
    end
    if NuttUIDB.Notes[id] then
        NuttUIDB.Notes[id] = nil
    end
    
    if self.UpdateCallback then self.UpdateCallback() end
end

function NuttUI.Notes:New()
    if not NuttUIDB.Notes then NuttUIDB.Notes = {} end
    
    local count = 0
    for _ in pairs(NuttUIDB.Notes) do count = count + 1 end
    
    if count >= 10 then
        print("|cFF00FF00NuttUI|r: Maximum of 10 notes reached.")
        return
    end

    -- Find next ID
    local id = 1
    while NuttUIDB.Notes[id] do
        id = id + 1
    end
    
    NuttUIDB.Notes[id] = {
        text = "New note",
        width = 200,
        height = 150,
        locked = false,
        point = {"CENTER", nil, "CENTER", 0, 0},
        r = 0, g = 0, b = 0, a = 0.2, -- Default Black 20%
        tr = 1, tg = 1, tb = 1, ta = 1 -- Default White Text
    }
    
    self:Create(id, NuttUIDB.Notes[id])
end

function NuttUI.Notes:Init()
    if not NuttUIDB.Notes then NuttUIDB.Notes = {} end
    
    for id, config in pairs(NuttUIDB.Notes) do
        self:Create(id, config)
    end
end
