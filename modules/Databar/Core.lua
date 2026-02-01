local _, NuttUI = ...
NuttUI.Databar = {}
NuttUI.Databar.Registry = {}
NuttUI.Databar.Instances = {}

-- Helper: Create FontString
local function CreateFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    return fs
end

-- -----------------------------------------------------------------------------
-- Slot Registration
-- -----------------------------------------------------------------------------

function NuttUI.Databar:RegisterSlot(data)
    -- data: name, Update(self), OnEnter(self), OnClick(self), events, interval
    if data and data.name then
        NuttUI.Databar.Registry[data.name] = data
    end
end

-- -----------------------------------------------------------------------------
-- Bar Instance Logic
-- -----------------------------------------------------------------------------

function NuttUI.Databar:UpdateLayout(bar)
    local id = bar.id
    local config = NuttUIDB.Databars and NuttUIDB.Databars[id]
    if not config then return end

    -- Layout Settings
    local totalWidth = 0
    local fixedWidth = (config.Width and config.Width > 0) and config.Width
    local fixedHeight = (config.Height and config.Height > 0) and config.Height
    
    if fixedHeight then
        bar:SetHeight(fixedHeight)
    else
        bar:SetHeight(24)
    end
    
    -- Gather active slots to update
    local activeSlotFrames = {}
    local slotLabels = config.SlotLabels or {}
    
    -- Hide all existing slot frames first
    for _, child in ipairs(bar.slotFrames or {}) do
        child:Hide()
        child:ClearAllPoints()
    end
    bar.slotFrames = bar.slotFrames or {}

    local slotIndex = 0
    local activeSlots = config.Slots or {}
    local maxSlots = config.NumSlots or 3
    
    -- Create/Initialise Slots
    for i, slotName in ipairs(activeSlots) do
        if slotIndex >= maxSlots then break end
        
        local data = NuttUI.Databar.Registry[slotName]
        if data then
            slotIndex = slotIndex + 1
            local currentFrameIndex = slotIndex
            -- Reuse or Create Slot Frame
            local slotFrame = bar.slotFrames[currentFrameIndex]
            if not slotFrame then
                slotFrame = CreateFrame("Button", nil, bar)
                slotFrame:SetHeight(fixedHeight or 20)
                slotFrame:RegisterForClicks("AnyUp")
                slotFrame.text = CreateFontString(slotFrame)
                slotFrame.text:SetPoint("CENTER")
                bar.slotFrames[currentFrameIndex] = slotFrame
            end
            
            slotFrame:Show()
            slotFrame:SetHeight(fixedHeight or 20)
            slotFrame.data = data
            slotFrame.labelOverride = slotLabels[i]
            
            table.insert(activeSlotFrames, slotFrame)
            
            local function UpdateSlot(self)
                if data.Update then
                    local text = data.Update(self, self.labelOverride)
                    if text then
                        self.text:SetText(text)
                        -- Width handling depends on layout mode
                        if not fixedWidth then
                            self:SetWidth(self.text:GetStringWidth() + 10)

                            -- Recalculate parent width
                            local padding = 10
                            local newTotal = padding
                            if activeSlotFrames then
                                for _, f in ipairs(activeSlotFrames) do
                                    newTotal = newTotal + f:GetWidth() + padding
                                end
                            end
                            bar:SetWidth(newTotal)
                        end
                    end
                end
            end
            
            slotFrame.UpdateSlot = UpdateSlot

            slotFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                if data.OnEnter then data.OnEnter(self) end
                GameTooltip:Show()
            end)
            slotFrame:SetScript("OnLeave", GameTooltip_Hide)
            slotFrame:SetScript("OnClick", function(self, button)
                if data.OnClick then data.OnClick(self, button) end
            end)
            
            slotFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed > (data.interval or 1) then
                    self.elapsed = 0
                    UpdateSlot(self)
                end
            end)
            
            slotFrame:UnregisterAllEvents()
            if data.events then
                for _, event in ipairs(data.events) do
                    slotFrame:RegisterEvent(event)
                end
                slotFrame:SetScript("OnEvent", function(self, event, ...)
                    if data.OnEvent then data.OnEvent(self, event, ...) end
                    UpdateSlot(self)
                end)
            end
            
            -- Initial Update
            UpdateSlot(slotFrame)
        end
    end
    
    -- Positioning
    if fixedWidth then
        bar:SetWidth(fixedWidth)
        
        local totalContentWidth = 0
        for _, slotFrame in ipairs(activeSlotFrames) do
            slotFrame:SetWidth(slotFrame.text:GetStringWidth() + 10)
            totalContentWidth = totalContentWidth + slotFrame:GetWidth()
        end
        
        local numSlots = #activeSlotFrames
        if numSlots > 0 then
            local availableSpace = fixedWidth - totalContentWidth
            -- Clamp at 0 to prevent overlap if content > fixed width
            if availableSpace < 0 then availableSpace = 0 end
            
            local gap = availableSpace / (numSlots + 1)
            
            local currentX = gap
            for i, slotFrame in ipairs(activeSlotFrames) do
                slotFrame:ClearAllPoints()
                slotFrame:SetPoint("LEFT", bar, "LEFT", currentX, 0)
                currentX = currentX + slotFrame:GetWidth() + gap
            end
        end
    else
        -- Auto Sizing
        local padding = 10
        totalWidth = padding
        local previousFrame
        
        for i, slotFrame in ipairs(activeSlotFrames) do
            slotFrame:ClearAllPoints()
            if previousFrame then
                slotFrame:SetPoint("LEFT", previousFrame, "RIGHT", padding, 0)
            else
                slotFrame:SetPoint("LEFT", bar, "LEFT", padding, 0)
            end
            totalWidth = totalWidth + slotFrame:GetWidth() + padding
            previousFrame = slotFrame
        end
        bar:SetWidth(totalWidth)
    end
    
    -- Apply Background Color
    if config.BgColor then
        bar.bg:SetColorTexture(unpack(config.BgColor))
    else
        bar.bg:SetColorTexture(0, 0, 0, 0.6)
    end
end

function NuttUI.Databar:Create(id)
    if self.Instances[id] then return self.Instances[id] end
    
    local frameName = "NuttUIDatabar_" .. id
    local frame = CreateFrame("Frame", frameName, UIParent)
    frame:SetSize(200, 24)
    frame.id = id
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.6)
    
    -- Movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not NuttUIDB.Databars[self.id] or not NuttUIDB.Databars[self.id].Locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        if not NuttUIDB.Databars[self.id] then NuttUIDB.Databars[self.id] = {} end
        NuttUIDB.Databars[self.id].Point = { point, relativePoint, x, y }
    end)
    
    -- Restore Position
    local config = NuttUIDB.Databars and NuttUIDB.Databars[id]
    if config and config.Point then
        local p = config.Point
        frame:ClearAllPoints()
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, - (id * 30))
    end
    
    self.Instances[id] = frame
    self:UpdateLayout(frame)
    
    return frame
end

function NuttUI.Databar:Delete(id)
    if self.Instances[id] then
        self.Instances[id]:Hide()
        self.Instances[id]:SetParent(nil)
        self.Instances[id] = nil
    end
    if NuttUIDB.Databars[id] then
        NuttUIDB.Databars[id] = nil
    end
end

function NuttUI.Databar:Init()
    -- Initialise Bars from DB
    if not NuttUIDB.Databars then NuttUIDB.Databars = {} end
    
    -- Instantiate bars from SavedVariables
    for id, config in pairs(NuttUIDB.Databars) do
        self:Create(id)
    end
end
