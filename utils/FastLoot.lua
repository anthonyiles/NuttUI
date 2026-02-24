local _, NuttUI = ...
NuttUI.FastLoot = {}

local lootRetryPending = false

-- Instantly ping all items in the loot window
local function TryLootAll()
    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            LootSlot(slotIndex)
        end
    end
end

-- Checks for "stuck" server-side loot 0.1s later
local function CheckRemainingLoot()
    lootRetryPending = false
    
    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            -- Loot still present, fire again
            TryLootAll()
            return
        end
    end
end

local function OnLootReady()
    if NuttUIDB and NuttUIDB.FastLoot == false then return end

    -- Ensure Blizzard's internal Auto-Loot switch is flipped on
    if not GetCVarBool("autoLootDefault") then
        SetCVar("autoLootDefault", "1")
    end

    TryLootAll()

    -- Schedule check for stuck items
    if not lootRetryPending then
        lootRetryPending = true
        C_Timer.After(0.1, CheckRemainingLoot)
    end
end

function NuttUI.FastLoot:Init()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("LOOT_READY")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "LOOT_READY" then
            OnLootReady()
        end
    end)
end
