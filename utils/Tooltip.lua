local _, NuttUI = ...
NuttUI.Tooltip = {}

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function HideStatusBar(tooltip)
    if not NuttUIDB or not NuttUIDB.HideHealthbar then return end

    if not statusBar and _G["GameTooltipStatusBar"] then
        statusBar = _G["GameTooltipStatusBar"]
    end

    if statusBar then
        statusBar:Hide()

        if not statusBar.isNuttUIHooked then
            statusBar:HookScript("OnShow", function(self)
                if NuttUIDB and NuttUIDB.HideHealthbar then
                    self:Hide()
                end
            end)
            statusBar.isNuttUIHooked = true
        end
    end
end

local function GetValueOrDefault(table, key, default)
    if table and table[key] ~= nil then
        return table[key]
    end
    return default
end

local function IsModifierActive(key)
    if key == "SHIFT" then return IsShiftKeyDown() end
    if key == "CTRL" then return IsControlKeyDown() end
    if key == "ALT" then return IsAltKeyDown() end
    return false
end

local function ShouldHideInCombat()
    if not NuttUIDB or not NuttUIDB.HideTooltipInCombat then return false end
    if not InCombatLockdown() then return false end
    
    local key = NuttUIDB.TooltipCombatOverrideKey
    if key and key ~= "NONE" then
        if IsModifierActive(key) then
            return false  -- Force show in combat with modifier
        end
    end
    
    return true  -- Hide in combat (no key pressed or NONE)
end

local function MoveTooltipToCursor(tooltip)
    local anchor = GetValueOrDefault(NuttUIDB, "PinAnchor", "BOTTOMLEFT")
    local offsetX = GetValueOrDefault(NuttUIDB, "PinOffsetX", 0)
    local offsetY = GetValueOrDefault(NuttUIDB, "PinOffsetY", 0)

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale

    tooltip:ClearAllPoints()
    tooltip:SetPoint(anchor, UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
end

local function UpdateAnchor(tooltip, parent)
    if not NuttUIDB or not NuttUIDB.PinToCursor then
        tooltip.isNuttUIPinned = false
        return
    end

    tooltip.isNuttUIPinned = true
    tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
    MoveTooltipToCursor(tooltip)
end

local function CreateCustomFade(tooltip)
    if tooltip.NuttUIFadeAnim then return tooltip.NuttUIFadeAnim end

    local group = tooltip:CreateAnimationGroup()
    local anim = group:CreateAnimation("Alpha")
    anim:SetOrder(1)
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetDuration(0.2)
    group:SetScript("OnFinished", function()
        tooltip:Hide()
        tooltip:SetAlpha(1)
    end)
    
    tooltip.NuttUIFadeAnim = group
    tooltip.NuttUIFadeAlpha = anim
    return group
end

local function ApplyCustomFade(tooltip)
    local duration = GetValueOrDefault(NuttUIDB, "TooltipFadeOut", 0.2)
    local delay = GetValueOrDefault(NuttUIDB, "TooltipFadeDelay", 0)
    
    if duration <= 0.01 and delay <= 0.01 then
        tooltip:Hide()
        tooltip:SetAlpha(1)
        return
    end

    local group = CreateCustomFade(tooltip)
    if not group then return end
    
    if tooltip.NuttUIFadeAlpha then
        tooltip.NuttUIFadeAlpha:SetDuration(duration)
        tooltip.NuttUIFadeAlpha:SetStartDelay(delay)
    end
    
    if tooltip:IsShown() then
        if group:IsPlaying() then group:Stop() end
        tooltip:SetAlpha(1) 
        group:Play()
    end
end

function NuttUI.Tooltip.UpdateFade()
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------

function NuttUI.Tooltip.Init()
    -- 1. Hide Healthbar logic
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            HideStatusBar(tooltip)
        end)
    end

    -- 2. Pin to Cursor logic
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        UpdateAnchor(tooltip, parent)
    end)

    -- 3. Override FadeOut
    if GameTooltip.FadeOut then
        local originalFadeOut = GameTooltip.FadeOut
        
        GameTooltip.FadeOut = function(self)
            if NuttUIDB and NuttUIDB.EnableTooltipFade then
                ApplyCustomFade(self)
            else
                originalFadeOut(self)
            end
        end
    end

    -- Hook OnShow to reset alpha/state if interrupted
    GameTooltip:HookScript("OnShow", function(self)
        if ShouldHideInCombat() then
            self:Hide()
            return
        end

        if self.NuttUIFadeAnim and self.NuttUIFadeAnim:IsPlaying() then
            self.NuttUIFadeAnim:Stop()
        end
        self:SetAlpha(1)
    end)

    -- Hook SetOwner to reset alpha/state if switching targets without hiding
    hooksecurefunc(GameTooltip, "SetOwner", function(self)
        if self.NuttUIFadeAnim and self.NuttUIFadeAnim:IsPlaying() then
            self.NuttUIFadeAnim:Stop()
        end
        self:SetAlpha(1)
    end)

    -- Continuous movement
    GameTooltip:HookScript("OnShow", function(self)
        if self.isNuttUIPinned then
            MoveTooltipToCursor(self)
        end
    end)

    GameTooltip:HookScript("OnUpdate", function(self, elapsed)
        if not self.isNuttUIPinned then return end

        self.nuttUIElapsed = (self.nuttUIElapsed or 0) + elapsed
        if self.nuttUIElapsed > 0.016 then -- ~60fps cap
            self.nuttUIElapsed = 0
            MoveTooltipToCursor(self)
        end
    end)

    -- Cleanup flag
    GameTooltip:HookScript("OnHide", function(self)
        self.isNuttUIPinned = false
    end)
end
