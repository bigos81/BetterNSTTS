-- =============================================
-- Abbreviation Manager (separate window — follows same pattern as word excludes)
-- =============================================

local abbrPanel = nil
local abbrKeyInput = nil
local abbrValueInput = nil
local abbrListScrollFrame = nil
local abbrListContainer = nil
local dynamicAbbrRowFrames = {}

function ShowAbbreviationsPanel()
    if not abbrPanel then
        CreateAbbreviationsPanel()
    end

    -- this needs to stay this way for some reason :(
    if (abbrPanel) then
        abbrPanel:Hide()
        abbrPanel:Show()
    end

    -- Refresh the list after showing so scroll frame renders correctly
    RefreshAbbrList()
end

function CreateAbbreviationsPanel()
    -- Create panel using ButtonFrameTemplate (same as word excludes)
    abbrPanel = CreateFrame("Frame", "BetterNSTTS_AbbrevPanel", UIParent, "ButtonFrameTemplate")
    abbrPanel:SetToplevel(true)
    table.insert(UISpecialFrames, "BetterNSTTS_AbbrevPanel")  -- enables /closepanel
    abbrPanel:SetSize(400, 350)
    abbrPanel:SetPoint("CENTER")

    -- Make it movable and clamped to screen (Chattynator pattern)
    abbrPanel:SetMovable(true)
    abbrPanel:SetClampedToScreen(true)
    abbrPanel:RegisterForDrag("LeftButton")
    abbrPanel:SetScript("OnDragStart", function()
        abbrPanel:StartMoving()
        abbrPanel:SetUserPlaced(false)
    end)
    abbrPanel:SetScript("OnDragStop", function()
        abbrPanel:StopMovingOrSizing()
        abbrPanel:SetUserPlaced(false)
    end)

    -- Hide portrait and button bar (Chattynator pattern)
    ButtonFrameTemplate_HidePortrait(abbrPanel)
    ButtonFrameTemplate_HideButtonBar(abbrPanel)
    abbrPanel.Inset:Hide()
    abbrPanel:EnableMouse(true)
    abbrPanel:SetScript("OnMouseWheel", function() end)

    -- Title text
    local titleText = abbrPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetText("Abbreviations")
    titleText:SetPoint("TOP", 0, -36)

    -- Subtitle
    local subtitle = abbrPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetText("Define word substitutions that will be replaced during TTS")
    subtitle:SetPoint("TOP", titleText, "BOTTOM", 0, -4)

    -- Input row with two fields (key + value) + Add button
    local inputRow = CreateFrame("Frame", nil, abbrPanel)
    inputRow:SetSize(360, 28)
    inputRow:SetPoint("TOPLEFT", 20, -70)

    abbrKeyInput = CreateFrame("EditBox", "BetterNSTTS_AbbrevKeyInput", inputRow, "InputBoxTemplate")
    abbrKeyInput:SetSize(150, 28)
    abbrKeyInput:SetPoint("LEFT", 0, 0)
    abbrKeyInput:SetAutoFocus(false)

    -- Placeholder text for key
    local placeholder = abbrKeyInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetText("Trigger word...")
    placeholder:SetPoint("LEFT", abbrKeyInput, "LEFT", 4, 0)

    abbrKeyInput:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
    end)
    abbrKeyInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if #text > 0 then
            placeholder:Hide()
        else
            placeholder:Show()
        end
    end)

    abbrValueInput = CreateFrame("EditBox", "BetterNSTTS_AbbrevValueInput", inputRow, "InputBoxTemplate")
    abbrValueInput:SetSize(140, 28)
    abbrValueInput:SetPoint("LEFT", abbrKeyInput, "RIGHT", 6, -2)
    abbrValueInput:SetAutoFocus(false)

    -- Placeholder text for value
    local placeholder2 = abbrValueInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder2:SetText("Replacement...")
    placeholder2:SetPoint("LEFT", abbrValueInput, "LEFT", 4, 0)

    abbrValueInput:SetScript("OnEditFocusGained", function()
        placeholder2:Hide()
    end)
    abbrValueInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if #text > 0 then
            placeholder2:Hide()
        else
            placeholder2:Show()
        end
    end)

    -- Shared function to add an abbreviation from the input boxes
    local function AddAbbrFromInput()
        local key = string.trim(abbrKeyInput:GetText())
        local value = string.trim(abbrValueInput:GetText())
        if not key or #key == 0 then return end

        -- Check for duplicate keys (case-insensitive)
        for _, existing in ipairs(BNSTTS_CONFIG_DB.abbreviations) do
            if strlower(existing.key) == strlower(key) then
                print("BetterNSTTS: '" .. key .. "' is already defined.")
                return
            end
        end

        table.insert(BNSTTS_CONFIG_DB.abbreviations, {key = key, value = value})
        print("BetterNSTTS: Added abbreviation '" .. key .. "' -> '" .. (value or "") .. "'.")
        abbrKeyInput:SetText("")
        abbrValueInput:SetText("")
        RefreshAbbrList()
    end

    local addButton = CreateFrame("Button", nil, inputRow, "UIPanelDynamicResizeButtonTemplate")
    addButton:SetText("Add")
    DynamicResizeButton_Resize(addButton)
    addButton:SetPoint("LEFT", abbrValueInput, "RIGHT", 6, -2)
    addButton:SetScript("OnClick", AddAbbrFromInput)

    -- Allow pressing Enter on either input to add
    abbrKeyInput:SetScript("OnEnterPressed", function()
        AddAbbrFromInput()
    end)
    abbrValueInput:SetScript("OnEnterPressed", function()
        AddAbbrFromInput()
    end)

    -- Scrollable list container
    abbrListScrollFrame = CreateFrame("ScrollFrame", nil, abbrPanel, "UIPanelScrollFrameTemplate")
    abbrListScrollFrame:SetSize(360, 200)
    abbrListScrollFrame:SetPoint("TOPLEFT", 16, -114)

    abbrListContainer = CreateFrame("Frame", nil, abbrListScrollFrame)
    abbrListContainer:SetSize(350, 10) -- height set dynamically in RefreshAbbrList
    abbrListContainer:EnableMouse(true)
    abbrListContainer:SetScript("OnHide", function()
        -- Clean up dynamic frames when panel closes to avoid memory leaks
        for _, rowFrame in ipairs(dynamicAbbrRowFrames) do
            rowFrame:Hide()
            rowFrame:SetParent(nil)
        end
        table.wipe(dynamicAbbrRowFrames)
    end)

    abbrListScrollFrame:SetScrollChild(abbrListContainer)
    UIPanelScrollFrame_OnLoad(abbrListScrollFrame)

    -- Initial render
    RefreshAbbrList()
end

function RefreshAbbrList()
    if not abbrListContainer then return end

    -- Clear existing rows
    for _, rowFrame in ipairs(dynamicAbbrRowFrames) do
        rowFrame:Hide()
        rowFrame:SetParent(nil)
    end
    table.wipe(dynamicAbbrRowFrames)

    abbrListContainer:SetHeight(#BNSTTS_CONFIG_DB.abbreviations * 24 + 10)
    local yOffset = 0
    for i, entry in ipairs(BNSTTS_CONFIG_DB.abbreviations) do
        local rowFrame = CreateFrame("Frame", nil, abbrListContainer)
        rowFrame:SetSize(350, 24)
        rowFrame:SetPoint("TOPLEFT", 0, yOffset)

        local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetText(entry.key .. " -> " .. (entry.value or ""))
        label:SetPoint("LEFT", 8, 0)

        local removeButton = CreateFrame("Button", nil, rowFrame, "UIPanelDynamicResizeButtonTemplate")
        removeButton:SetText("Remove")
        DynamicResizeButton_Resize(removeButton)
        removeButton:SetPoint("RIGHT", -4, 0)
        removeButton:SetScript("OnClick", function()
            table.remove(BNSTTS_CONFIG_DB.abbreviations, i)
            print("BetterNSTTS: Removed abbreviation '" .. entry.key .. "' -> '" .. (entry.value or "") .. "'.")
            RefreshAbbrList()
        end)

        table.insert(dynamicAbbrRowFrames, rowFrame)
        yOffset = yOffset - 28
    end
end
