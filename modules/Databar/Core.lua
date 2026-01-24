local _, NuttUI = ...
NuttUI.Databar = {}

local bits = {}
local frame

-- Default Font Object
local function CreateFontString(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    return fs
end

-- -----------------------------------------------------------------------------
-- Bit Registration
-- -----------------------------------------------------------------------------

function NuttUI.Databar:RegisterBit(data)
    -- data needs: name, Update(self), OnEnter(self), OnClick(self)
    table.insert(bits, data)
end

-- -----------------------------------------------------------------------------
-- Core Frame
-- -----------------------------------------------------------------------------

function NuttUI.Databar:UpdateLayout()
    local previousFrame
    local padding = 10
    local totalWidth = padding
    
    for i, data in ipairs(bits) do
        local bitFrame = data.frame
        if not bitFrame then
            bitFrame = CreateFrame("Button", nil, frame)
            bitFrame:SetHeight(20)
            bitFrame:RegisterForClicks("AnyUp") -- Required to detect RightButton
            bitFrame.text = CreateFontString(bitFrame)
            bitFrame.text:SetPoint("CENTER")
            bitFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                if data.OnEnter then data.OnEnter(self) end
                GameTooltip:Show()
            end)
            bitFrame:SetScript("OnLeave", GameTooltip_Hide)
            bitFrame:SetScript("OnClick", function(self, button)
                if data.OnClick then data.OnClick(self, button) end
            end)
            -- Update script
            bitFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed > (data.interval or 1) then
                    self.elapsed = 0
                    if data.Update then 
                        local text = data.Update(self) 
                        if text then 
                            self.text:SetText(text) 
                            self:SetWidth(self.text:GetStringWidth() + 10)
                        end
                    end
                end
            end)
            -- Allow OnEvent if needed
            if data.events then
                for _, event in ipairs(data.events) do
                    bitFrame:RegisterEvent(event)
                end
                bitFrame:SetScript("OnEvent", function(self, event, ...)
                    if data.OnEvent then data.OnEvent(self, event, ...) end
                    -- Force update
                    if data.Update then
                         local text = data.Update(self) 
                         if text then 
                            self.text:SetText(text) 
                            self:SetWidth(self.text:GetStringWidth() + 10)
                         end
                    end
                end)
            end


            
            data.frame = bitFrame
            
            -- Initial update
            if data.Update then
                 local text = data.Update(bitFrame)
                 if text then 
                    bitFrame.text:SetText(text) 
                    bitFrame:SetWidth(bitFrame.text:GetStringWidth() + 10)
                 end
            end
        end
        
        bitFrame:ClearAllPoints()
        if previousFrame then
            bitFrame:SetPoint("LEFT", previousFrame, "RIGHT", padding, 0)
        else
            bitFrame:SetPoint("LEFT", frame, "LEFT", padding, 0)
        end
        
        totalWidth = totalWidth + bitFrame:GetWidth() + padding
        previousFrame = bitFrame
    end
    
    frame:SetWidth(totalWidth)
end

function NuttUI.Databar:CreateBar()
    frame = CreateFrame("Frame", "NuttUIDatabar", UIParent)
    frame:SetSize(200, 24) -- Height 24
    frame:SetPoint("CENTER")
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.6)
    
    -- Movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        if not NuttUIDB then NuttUIDB = {} end
        NuttUIDB.DatabarPosition = { point, relativePoint, x, y }
    end)
    
    self:UpdateLayout()
end

function NuttUI.Databar:RestorePosition()
    if NuttUIDB and NuttUIDB.DatabarPosition then
        local pos = NuttUIDB.DatabarPosition
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
end

function NuttUI.Databar:Init()
    self:CreateBar()
    self:RestorePosition()
end
