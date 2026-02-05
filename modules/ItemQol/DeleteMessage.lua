local popupsToAutofill = {
    ["DELETE_ITEM"] = true,
    ["DELETE_GOOD_ITEM"] = true,
    ["DELETE_GOOD_QUEST_ITEM"] = true,
    ["DELETE_QUEST_ITEM"] = true,
}

hooksecurefunc("StaticPopup_Show", function(which)
    if NuttUIDB and NuttUIDB.AutoDeleteConfirm == false then return end
    if not popupsToAutofill[which] then return end

    for i = 1, 4 do
        local frame = _G["StaticPopup" .. i]
        if frame and frame.which == which and frame:IsShown() then
            local textField = frame.editBox or _G["StaticPopup" .. i .. "EditBox"]
            if textField then
                textField:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
                local onTextChanged = textField:GetScript("OnTextChanged")
                if onTextChanged then
                    onTextChanged(textField)
                end
            end
            break
        end
    end
end)