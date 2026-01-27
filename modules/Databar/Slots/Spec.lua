local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "Spec",
    events = {"PLAYER_SPECIALIZATION_CHANGED", "PLAYER_LOOT_SPEC_UPDATED"},
    interval = 2,
    Update = function(self, label)
        local specIndex = GetSpecialization()
        if not specIndex then return string.format("|cffffffff%s:|r N/A", label or "Spec") end
        
        local id, name = GetSpecializationInfo(specIndex)
        if not name then return string.format("|cffffffff%s:|r N/A", label or "Spec") end
        
        return string.format("|cffffffff%s:|r |cff00ff00%s|r", label or "Spec", name)
    end,
    OnEnter = function(self)
        local specIndex = GetSpecialization()
        local _, specName = GetSpecializationInfo(specIndex)
        
        local lootID = GetLootSpecialization()
        local lootName = "Current Spec"
        if lootID > 0 then
             _, lootName = GetSpecializationInfoByID(lootID)
        end
        
        GameTooltip:AddLine("Specialization Info")
        GameTooltip:AddDoubleLine("Current Spec:", specName, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Loot Spec:", lootName, 1, 1, 1, 1, 1, 1)
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Left-Click> Change Spec", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("<Shift+Left-Click> Change Loot Spec", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("<Right-Click> Open Talents", 0.5, 0.5, 0.5)
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                -- Change Loot Spec Menu
                if MenuUtil then
                     MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                        rootDescription:CreateTitle("Select Loot Specialization")
                        local current = GetLootSpecialization()
                        
                        -- Current Spec Option
                        local function SetLootSpec(id) SetLootSpecialization(id) end
                        
                        local currentSpecRadio = rootDescription:CreateRadio("Current Specialization", function() return current == 0 end, function() SetLootSpec(0) end)

                        for i = 1, GetNumSpecializations() do
                            local id, name = GetSpecializationInfo(i)
                            rootDescription:CreateRadio(name, function() return current == id end, function() SetLootSpec(id) end)
                        end
                     end)
                else
                    -- Fallback or older API
                    print("MenuUtil not found.")
                end
            else
                -- Change Spec Menu
                if MenuUtil then
                     MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                        rootDescription:CreateTitle("Activate Specialization")
                        local current = GetSpecialization()
                        
                        local function SetSpec(index) 
                            if SetSpecialization then 
                                SetSpecialization(index) 
                            elseif C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
                                C_SpecializationInfo.SetSpecialization(index)
                            else
                                print("NuttUI Error: SetSpecialization API not found.")
                            end
                        end

                        for i = 1, GetNumSpecializations() do
                            local _, name = GetSpecializationInfo(i)
                            rootDescription:CreateRadio(name, function() return current == i end, function() SetSpec(i) end)
                        end
                     end)
                end
            end
        elseif button == "RightButton" then
            -- Open Talents
            if PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentFrame then
                PlayerSpellsUtil.ToggleClassTalentFrame()
            elseif ClassTalentFrame then
                 ToggleFrame(ClassTalentFrame)
            else
                 ToggleTalentFrame()
            end
        end
    end
})
