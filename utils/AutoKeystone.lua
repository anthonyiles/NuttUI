local _, NuttUI = ...
NuttUI.AutoKeystone = {}

local function OnKeystoneFrameShow()
    NuttUI.AutoKeystone:TrySlotKeystone()
end

local function HookKeystoneFrame()
    if ChallengesKeystoneFrame then
        ChallengesKeystoneFrame:HookScript("OnShow", OnKeystoneFrameShow)
    end
end

function NuttUI.AutoKeystone:Init()
    if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
        HookKeystoneFrame()
    else
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ADDON_LOADED")
        frame:SetScript("OnEvent", function(self, event, addonName)
            if addonName == "Blizzard_ChallengesUI" then
                HookKeystoneFrame()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end

function NuttUI.AutoKeystone:TrySlotKeystone()
    if NuttUIDB and NuttUIDB.AutoKeystone == false then return end
    
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemInfo(bag, slot)
            if item and item.itemID and C_Item.IsItemKeystoneByID(item.itemID) then
                 C_Container.UseContainerItem(bag, slot)
            end
        end
    end
end
