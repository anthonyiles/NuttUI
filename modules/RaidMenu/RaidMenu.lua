local _, NuttUI = ...
NuttUI.RaidMenu = {}

--------------------------------------------------------------------------------
-- Raid Marker Icon Textures (Target Markers 1-8)
--------------------------------------------------------------------------------
local RAID_TARGET_ICONS = {
    [1] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", -- Yellow Star
    [2] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", -- Orange Circle
    [3] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", -- Purple Diamond
    [4] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", -- Green Triangle
    [5] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", -- Grey Moon
    [6] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", -- Blue Square
    [7] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- Red Cross
    [8] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", -- White Skull
}

-- World marker order matched to target markers
-- Star=Yellow(5), Circle=Orange(6), Diamond=Purple(3), Triangle=Green(2), Moon=Grey(7), Square=Blue(1), Cross=Red(4), Skull=White(8)
local WORLD_MARKER_ORDER = { 5, 6, 3, 2, 7, 1, 4, 8 }

-- Tooltip names
local MARKER_TOOLTIPS = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
}

--------------------------------------------------------------------------------
-- Event/Script Handlers
--------------------------------------------------------------------------------
local function MarkerOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local mode = NuttUI.RaidMenu.mode == "world" and "World" or "Target"
    GameTooltip:SetText(mode .. ": " .. MARKER_TOOLTIPS[self.markerIndex])
    GameTooltip:Show()
end

local function OnDragStop(self)
    self:StopMovingOrSizing()
    NuttUI.RaidMenu:SavePosition()
end

local function ReadyCheckOnClick()
    if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        DoReadyCheck()
    elseif IsInGroup() and UnitIsGroupLeader("player") then
        DoReadyCheck()
    else
        print("|cff00ff00NuttUI|r: You must be raid leader or assistant.")
    end
end

local function PullTimerOnClick()
    local pullTime = NuttUIDB.RaidMenuPullTimer or 10
    if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        C_PartyInfo.DoCountdown(pullTime)
    elseif IsInGroup() and UnitIsGroupLeader("player") then
        C_PartyInfo.DoCountdown(pullTime)
    else
        print("|cff00ff00NuttUI|r: You must be raid leader or assistant.")
    end
end

local function OnVisibilityEvent()
    NuttUI.RaidMenu:UpdateVisibility()
end

--------------------------------------------------------------------------------
-- Layout Configuration
--------------------------------------------------------------------------------
local BTN_SIZE = 20
local TAB_SIZE = 16
local SPACING = 2
local ACTION_BTN_WIDTH = 40
local ACTION_BTN_HEIGHT = 16

--------------------------------------------------------------------------------
-- Create the Main Frame
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:CreateFrame()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "NuttUIRaidMenu", UIParent, "BackdropTemplate")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", OnDragStop)

    self.frame = frame
    self.mode = "target" -- Default mode
    self.markers = {}

    self:CreateAllButtons()
    self:UpdateLayout()
    self:LoadPosition()

    return frame
end

--------------------------------------------------------------------------------
-- Create All Buttons
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:CreateAllButtons()
    local frame = self.frame

    -- Mode Tabs (T and W)
    local tabT = CreateFrame("Button", nil, frame)
    tabT:SetSize(TAB_SIZE, TAB_SIZE)
    tabT.mode = "target"
    local tabTText = tabT:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabTText:SetPoint("CENTER")
    tabTText:SetText("T")
    tabT.text = tabTText
    tabT:SetScript("OnClick", function() self:SetMode("target") end)
    tabT:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Target Markers")
        GameTooltip:Show()
    end)
    tabT:SetScript("OnLeave", GameTooltip_Hide)
    self.tabT = tabT

    local tabW = CreateFrame("Button", nil, frame)
    tabW:SetSize(TAB_SIZE, TAB_SIZE)
    tabW.mode = "world"
    local tabWText = tabW:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabWText:SetPoint("CENTER")
    tabWText:SetText("W")
    tabW.text = tabWText
    tabW:SetScript("OnClick", function() self:SetMode("world") end)
    tabW:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("World Markers")
        GameTooltip:Show()
    end)
    tabW:SetScript("OnLeave", GameTooltip_Hide)
    self.tabW = tabW

    -- Tab backgrounds
    local tabTBg = tabT:CreateTexture(nil, "BACKGROUND")
    tabTBg:SetAllPoints()
    tabTBg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    tabT.bg = tabTBg

    local tabWBg = tabW:CreateTexture(nil, "BACKGROUND")
    tabWBg:SetAllPoints()
    tabWBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    tabW.bg = tabWBg

    -- Marker Buttons (8) - using target marker icons
    for i = 1, 8 do
        local btn = CreateFrame("Button", "NuttUIRaidMenuMarker" .. i, frame, "SecureActionButtonTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn.markerIndex = i
        btn:RegisterForClicks("AnyUp")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", "/tm " .. i) -- Default to target mode

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(RAID_TARGET_ICONS[i])
        btn.icon = tex

        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        btn:SetScript("OnEnter", MarkerOnEnter)
        btn:SetScript("OnLeave", GameTooltip_Hide)

        self.markers[i] = btn
    end

    -- Ready Check Button
    local readyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    readyBtn:SetSize(ACTION_BTN_WIDTH, ACTION_BTN_HEIGHT)
    readyBtn:SetText("Rdy")
    readyBtn:SetScript("OnClick", ReadyCheckOnClick)
    self.readyBtn = readyBtn

    -- Pull Timer Button
    local pullBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    pullBtn:SetSize(ACTION_BTN_WIDTH, ACTION_BTN_HEIGHT)
    pullBtn:SetText("Pull")
    pullBtn:SetScript("OnClick", PullTimerOnClick)
    self.pullBtn = pullBtn
end

--------------------------------------------------------------------------------
-- Set Mode (Target or World)
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:SetMode(mode)
    self.mode = mode

    -- Update tab visuals
    if mode == "target" then
        self.tabT.bg:SetColorTexture(0.4, 0.4, 0.6, 1)
        self.tabT.text:SetTextColor(1, 1, 1)
        self.tabW.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        self.tabW.text:SetTextColor(0.6, 0.6, 0.6)
    else
        self.tabW.bg:SetColorTexture(0.4, 0.4, 0.6, 1)
        self.tabW.text:SetTextColor(1, 1, 1)
        self.tabT.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        self.tabT.text:SetTextColor(0.6, 0.6, 0.6)
    end

    -- Update button macros (only works out of combat)
    if not InCombatLockdown() then
        for i = 1, 8 do
            local btn = self.markers[i]
            if mode == "target" then
                btn:SetAttribute("macrotext", "/tm " .. i)
            else
                local wmIndex = WORLD_MARKER_ORDER[i]
                btn:SetAttribute("macrotext", "/wm " .. wmIndex)
            end
        end
    end

    -- Save preference
    if NuttUIDB then
        NuttUIDB.RaidMenuMode = mode
    end
end

--------------------------------------------------------------------------------
-- Update Layout
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:UpdateLayout()
    local isVertical = NuttUIDB and NuttUIDB.RaidMenuVertical

    if isVertical then
        self:ApplyVerticalLayout()
    else
        self:ApplyHorizontalLayout()
    end
end

function NuttUI.RaidMenu:ApplyHorizontalLayout()
    -- Horizontal: tabs left, markers in row, action buttons stacked vertically on right
    local frame = self.frame
    local padLeft = 4
    local padRight = 3
    local padTop = 4
    local padBottom = 4
    local tabsWidth = TAB_SIZE + 2
    local markersWidth = 8 * (BTN_SIZE + SPACING) - SPACING
    local buttonsHeight = ACTION_BTN_HEIGHT * 2

    local contentHeight = math.max(BTN_SIZE, buttonsHeight, TAB_SIZE * 2)
    local totalWidth = padLeft + tabsWidth + 4 + markersWidth + 4 + ACTION_BTN_WIDTH + padRight
    local totalHeight = padTop + contentHeight + padBottom

    frame:SetSize(totalWidth, totalHeight)

    -- Center Y offset for vertical centering
    local centerY = -(padTop + contentHeight / 2)

    -- Tabs on left (stacked vertically, centered)
    local tabsHeight = TAB_SIZE * 2 + 1
    self.tabT:ClearAllPoints()
    self.tabT:SetPoint("LEFT", frame, "TOPLEFT", padLeft, centerY + TAB_SIZE / 2 + 0.5)
    self.tabW:ClearAllPoints()
    self.tabW:SetPoint("TOP", self.tabT, "BOTTOM", 0, -1)

    -- Marker buttons (row, centered vertically, reversed order: skull first)
    local startX = padLeft + tabsWidth + 4
    for i = 1, 8 do
        local displayPos = 9 - i -- Reverse: 8,7,6,5,4,3,2,1
        self.markers[i]:ClearAllPoints()
        self.markers[i]:SetPoint("LEFT", frame, "TOPLEFT", startX + (displayPos - 1) * (BTN_SIZE + SPACING), centerY)
    end

    -- Action buttons stacked vertically on right (centered)
    local actionsX = startX + markersWidth + 4
    self.readyBtn:ClearAllPoints()
    self.readyBtn:SetPoint("LEFT", frame, "TOPLEFT", actionsX, centerY + ACTION_BTN_HEIGHT / 2 + 0.5)
    self.pullBtn:ClearAllPoints()
    self.pullBtn:SetPoint("TOP", self.readyBtn, "BOTTOM", 0, -1)
end

function NuttUI.RaidMenu:ApplyVerticalLayout()
    -- Vertical: tabs at top, markers in column below, buttons at bottom
    local frame = self.frame
    local padLeft = 5
    local padRight = 5
    local padTop = 5
    local padBottom = 5
    local tabsHeight = TAB_SIZE + 2
    local columnHeight = 8 * (BTN_SIZE + SPACING) - SPACING
    local buttonsHeight = ACTION_BTN_HEIGHT * 2 + 2

    local contentWidth = math.max(BTN_SIZE, TAB_SIZE * 2 + 2, ACTION_BTN_WIDTH)
    local totalWidth = padLeft + contentWidth + padRight
    local totalHeight = padTop + tabsHeight + columnHeight + SPACING + buttonsHeight + padBottom

    frame:SetSize(totalWidth, totalHeight)

    -- Tabs at top (side by side, centered)
    self.tabT:ClearAllPoints()
    self.tabT:SetPoint("TOP", frame, "TOP", -(TAB_SIZE / 2 + 1), -padTop)
    self.tabW:ClearAllPoints()
    self.tabW:SetPoint("LEFT", self.tabT, "RIGHT", 2, 0)

    -- Marker buttons (column below tabs, reversed order: skull first)
    local markersY = -padTop - tabsHeight
    for i = 1, 8 do
        local displayPos = 9 - i -- Reverse: 8,7,6,5,4,3,2,1
        self.markers[i]:ClearAllPoints()
        self.markers[i]:SetPoint("TOP", frame, "TOP", 0, markersY - (displayPos - 1) * (BTN_SIZE + SPACING))
    end

    -- Action buttons at bottom (stacked)
    local btnY = markersY - columnHeight - SPACING
    self.readyBtn:ClearAllPoints()
    self.readyBtn:SetPoint("TOP", frame, "TOP", 0, btnY)
    self.pullBtn:ClearAllPoints()
    self.pullBtn:SetPoint("TOP", self.readyBtn, "BOTTOM", 0, -2)
end

--------------------------------------------------------------------------------
-- Position Saving/Loading
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:SavePosition()
    if not NuttUIDB.RaidMenu then NuttUIDB.RaidMenu = {} end

    local point, _, relativePoint, x, y = self.frame:GetPoint()
    NuttUIDB.RaidMenu.point = { point, relativePoint, x, y }
end

function NuttUI.RaidMenu:LoadPosition()
    if NuttUIDB.RaidMenu and NuttUIDB.RaidMenu.point then
        local p = NuttUIDB.RaidMenu.point
        self.frame:ClearAllPoints()
        self.frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        self.frame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
    end

    -- Restore mode preference (default to "target")
    self:SetMode(NuttUIDB.RaidMenuMode or "target")

    -- Apply saved background alpha
    self:UpdateBackgroundAlpha()
end

--------------------------------------------------------------------------------
-- Background Transparency
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:UpdateBackgroundAlpha()
    if not self.frame then return end
    local alpha = (NuttUIDB and NuttUIDB.RaidMenuBgAlpha) or 0.9
    self.frame:SetBackdropColor(0.05, 0.05, 0.1, alpha)
end

--------------------------------------------------------------------------------
-- Visibility Logic
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:UpdateVisibility()
    if InCombatLockdown() then return end
    
    local shouldShow = true
    if NuttUIDB and NuttUIDB.ShowCustomRaidMenu == false then
        shouldShow = false
    end

    if IsInRaid() and shouldShow then
        if self.frame then self.frame:Show() end
    else
        if self.frame then self.frame:Hide() end
    end
    self:UpdateBlizzardVisibility()
end

function NuttUI.RaidMenu:UpdateBlizzardVisibility()
    if InCombatLockdown() then return end

    local shouldHide = NuttUIDB and NuttUIDB.RaidMenuHideBlizzard

    if CompactRaidFrameManager then
        if shouldHide then
            CompactRaidFrameManager:Hide()
            CompactRaidFrameManager:EnableMouse(false)
        else
            CompactRaidFrameManager:EnableMouse(true)
            if IsInRaid() or IsInGroup() then
                CompactRaidFrameManager:Show()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------
function NuttUI.RaidMenu:Init()
    if not NuttUIDB.RaidMenu then NuttUIDB.RaidMenu = {} end

    self:CreateFrame()
    self:UpdateVisibility()
    self:UpdateBlizzardVisibility()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    eventFrame:SetScript("OnEvent", OnVisibilityEvent)

    self.eventFrame = eventFrame

    if CompactRaidFrameManager then
        if not CompactRaidFrameManager._NuttUI_HookedShow then
            CompactRaidFrameManager._NuttUI_HookedShow = true
            hooksecurefunc(CompactRaidFrameManager, "Show", function(manager)
                if InCombatLockdown() then return end
                if NuttUIDB and NuttUIDB.RaidMenuHideBlizzard then
                    manager:Hide()
                    manager:EnableMouse(false)
                end
            end)
        end

        if not CompactRaidFrameManager._NuttUI_HookedSetShown then
            CompactRaidFrameManager._NuttUI_HookedSetShown = true
            hooksecurefunc(CompactRaidFrameManager, "SetShown", function(manager, shown)
                if InCombatLockdown() then return end
                if shown and NuttUIDB and NuttUIDB.RaidMenuHideBlizzard then
                    manager:Hide()
                    manager:EnableMouse(false)
                end
            end)
        end
    end
end
