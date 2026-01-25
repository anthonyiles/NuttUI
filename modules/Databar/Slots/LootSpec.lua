local _, NuttUI = ...

NuttUI.Databar:RegisterSlot({
    name = "LootSpec",
    events = {"PLAYER_LOOT_SPEC_UPDATED", "PLAYER_SPECIALIZATION_CHANGED"},
    interval = 2,
    Update = function(self, label)
        local specID = GetLootSpecialization()
        if specID == 0 then specID = GetSpecializationInfo(GetSpecialization()) end
        
        local labelText = label or "Spec"
        
        if not specID then return string.format("|cffffffff%s:|r |cff999999N/A|r", labelText) end
        
        local _, name, _, icon = GetSpecializationInfoByID(specID)
        local val = name or "Spec"
        if icon then
            val = string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, name)
        end
        return string.format("|cffffffff%s:|r |cff00ff00%s|r", labelText, val)
    end,
    OnEnter = function(self)
        GameTooltip:AddLine("Loot Specialization")
        GameTooltip:AddLine("Right-Click to change spec", 1, 1, 1)
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            if TogglePlayerSpellsFrame then
                TogglePlayerSpellsFrame(1)
            elseif ToggleTalentFrame then 
                 ToggleTalentFrame()
            end
        elseif button == "RightButton" then
            local function SetSpec(id) SetLootSpecialization(id) end
            
            if MenuUtil then
                MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                    rootDescription:CreateTitle("Loot Specialization")
                    
                    -- Helper to wrap boolean check in function for CreateRadio
                    local function IsSelected(id)
                         local current = GetLootSpecialization()
                         if current == 0 then return id == 0 end
                         return current == id
                    end

                    rootDescription:CreateRadio("Current Specialization", function() return IsSelected(0) end, function() SetSpec(0) end)
                    
                    for i = 1, GetNumSpecializations() do
                         local id, name, _, icon = GetSpecializationInfo(i)
                         rootDescription:CreateRadio(name, function() return IsSelected(id) end, function() SetSpec(id) end)
                    end
                end)
            else
                -- Legacy fallback
                 if not self.menuFrame then
                    self.menuFrame = CreateFrame("Frame", "NuttUILootSpecMenu", UIParent, "UIDropDownMenuTemplate")
                end
                
                local menu = {
                    { text = "Loot Specialization", isTitle = true, notCheckable = true },
                    { text = "Current Specialization", func = function() SetSpec(0) end, checked = (GetLootSpecialization() == 0) }
                }
                
                for i = 1, GetNumSpecializations() do
                     local id, name = GetSpecializationInfo(i)
                     table.insert(menu, {
                         text = name,
                         func = function() SetSpec(id) end,
                         checked = (GetLootSpecialization() == id)
                     })
                end
                
                EasyMenu(menu, self.menuFrame, "cursor", 0 , 0, "MENU") 
            end
        end
    end
})
