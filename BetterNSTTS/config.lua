-- WoW passes (addonName, addonTable) via ... — standard pattern
local addonName, _ = ...  -- luacheck: ignore

-- create frame, initialize configuration
local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("ADDON_LOADED")
configFrame:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        BetterNSTTS.configuration_init()
        print('BetterNSTTS loaded')
    end
end)

function BetterNSTTS.configuration_init()
    -- Ensure config table exists (migration for existing saves)
    if not BNSTTS_CONFIG_DB then
        BNSTTS_CONFIG_DB = {}
    end

    local defaults = {
        show_missing_media = true,
        qol_sound = true,
        rc_sound = true,
        abbreviations = {},
        sentence_excludes = {},
        word_excludes = {},
    }
    for key, value in pairs(defaults) do
        if BNSTTS_CONFIG_DB[key] == nil then
            BNSTTS_CONFIG_DB[key] = value
        end
    end

    BetterNSTTS.register_configuration_panel()
end

-- build configuration panel using Settings API (follows BugSack pattern)
function BetterNSTTS.register_configuration_panel()
    local category = Settings.RegisterVerticalLayoutCategory(addonName)

    -- === Checkbox settings (follows BugSack config.lua pattern) ===
    local missing_media_setting = Settings.RegisterAddOnSetting(
        category, "show_missing_media", "show_missing_media",
        BNSTTS_CONFIG_DB, Settings.VarType.Boolean,
        "Show missing media messages", true)
    Settings.CreateCheckbox(category, missing_media_setting, "Toggles display of missing media messages")

    local qol_sound_setting = Settings.RegisterAddOnSetting(
        category, "qol_sound", "qol_sound",
        BNSTTS_CONFIG_DB, Settings.VarType.Boolean,
        "Play sound on QOL message", true)
    Settings.CreateCheckbox(category, qol_sound_setting, "Toggles QOL sound")

    local rc_sound_setting = Settings.RegisterAddOnSetting(
        category, "rc_sound", "rc_sound",
        BNSTTS_CONFIG_DB, Settings.VarType.Boolean,
        "Play sound on Ready Check", true)
    Settings.CreateCheckbox(category, rc_sound_setting, "Toggles Ready Check sound")

    -- === Button to open word excludes manager (follows BugSack pattern with CreateSettingsButtonInitializer) ===
    local buttonInitializer = CreateSettingsButtonInitializer(
        "",  -- name (empty so no label text is shown)
        "Manage Ignored Words...",  -- buttonText
        function()
            ShowWordExcludesPanel()
        end,                        -- buttonClick
        "Open the word excludes manager",  -- tooltip
        false,                      -- addSearchTags
        nil,                        -- newTagID
        nil                         -- gameDataFunc
    )

    -- === Button to open abbreviation manager (follows same pattern) ===
    local abbrButtonInitializer = CreateSettingsButtonInitializer(
        "",  -- name (empty so no label text is shown)
        "Manage Abbreviations...",  -- buttonText
        function()
            ShowAbbreviationsPanel()
        end,                        -- buttonClick
        "Open abbreviation manager",  -- tooltip
        false,                      -- addSearchTags
        nil,                        -- newTagID
        nil                         -- gameDataFunc
    )

    local addonLayout = SettingsPanel:GetLayout(category)
    addonLayout:AddInitializer(buttonInitializer)
    addonLayout:AddInitializer(abbrButtonInitializer)

    Settings.RegisterAddOnCategory(category)
end

-- =============================================
-- Word Excludes Manager (separate window — follows Chattynator pattern)
-- =============================================

local wordPanel = nil
local wordInput = nil
local wordListScrollFrame = nil
local wordListContainer = nil
local dynamicRowFrames = {}

function ShowWordExcludesPanel()
    if not wordPanel then
        CreateWordExcludesPanel()
    end

    -- this needs to stay this way for some reason :(
    if (wordPanel) then
        wordPanel:Hide()
        wordPanel:Show()
    end

    -- Refresh the list after showing so scroll frame renders correctly
    RefreshWordList()
end

function CreateWordExcludesPanel()
    -- Create panel using ButtonFrameTemplate (same as Chattynator)
    wordPanel = CreateFrame("Frame", "BetterNSTTS_WordPanel", UIParent, "ButtonFrameTemplate")
    wordPanel:SetToplevel(true)
    table.insert(UISpecialFrames, "BetterNSTTS_WordPanel")  -- enables /closepanel
    wordPanel:SetSize(400, 350)
    wordPanel:SetPoint("CENTER")

    -- Make it movable and clamped to screen (Chattynator pattern)
    wordPanel:SetMovable(true)
    wordPanel:SetClampedToScreen(true)
    wordPanel:RegisterForDrag("LeftButton")
    wordPanel:SetScript("OnDragStart", function()
        wordPanel:StartMoving()
        wordPanel:SetUserPlaced(false)
    end)
    wordPanel:SetScript("OnDragStop", function()
        wordPanel:StopMovingOrSizing()
        wordPanel:SetUserPlaced(false)
    end)

    -- Hide portrait and button bar (Chattynator pattern)
    ButtonFrameTemplate_HidePortrait(wordPanel)
    ButtonFrameTemplate_HideButtonBar(wordPanel)
    wordPanel.Inset:Hide()
    wordPanel:EnableMouse(true)
    wordPanel:SetScript("OnMouseWheel", function() end)

    -- Title text
    local titleText = wordPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetText("Ignored Words")
    titleText:SetPoint("TOP", 0, -36)

    -- Subtitle
    local subtitle = wordPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetText("Words in this list will not be spoken by TTS")
    subtitle:SetPoint("TOP", titleText, "BOTTOM", 0, -4)

    -- Input + Add button row
    local inputRow = CreateFrame("Frame", nil, wordPanel)
    inputRow:SetSize(360, 28)
    inputRow:SetPoint("TOPLEFT", 20, -70)

    wordInput = CreateFrame("EditBox", "BetterNSTTS_WordInput", inputRow, "InputBoxTemplate")
    wordInput:SetSize(240, 28)
    wordInput:SetPoint("LEFT", 0, 0)
    wordInput:SetAutoFocus(false)

    -- Placeholder text (WoW EditBox doesn't have SetPlaceholderText)
    local placeholder = wordInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetText("Enter a word to ignore...")
    placeholder:SetPoint("LEFT", wordInput, "LEFT", 4, 0)

    -- Hide placeholder when editing starts, show it again if text is cleared
    wordInput:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
    end)
    wordInput:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if #text > 0 then
            placeholder:Hide()
        else
            placeholder:Show()
        end
    end)

    -- Shared function to add a word from the input box
    local function AddWordFromInput()
        local word = string.trim(wordInput:GetText())
        if not word or #word == 0 then return end

        local lower_word = strlower(word)
        -- Check for duplicates (case-insensitive)
        for _, existing in ipairs(BNSTTS_CONFIG_DB.word_excludes) do
            if strlower(existing) == lower_word then
                print("BetterNSTTS: '" .. word .. "' is already ignored.")
                return
            end
        end

        table.insert(BNSTTS_CONFIG_DB.word_excludes, word)
        print("BetterNSTTS: Added '" .. word .. "' to ignored words.")
        wordInput:SetText("")
        RefreshWordList()
    end

    local addWordButton = CreateFrame("Button", nil, inputRow, "UIPanelDynamicResizeButtonTemplate")
    addWordButton:SetText("Add Word")
    DynamicResizeButton_Resize(addWordButton)
    addWordButton:SetPoint("LEFT", wordInput, "RIGHT", 4, -2)
    addWordButton:SetScript("OnClick", AddWordFromInput)

    -- Allow pressing Enter to add a word
    wordInput:SetScript("OnEnterPressed", function()
        AddWordFromInput()
    end)

    -- Scrollable list container
    wordListScrollFrame = CreateFrame("ScrollFrame", nil, wordPanel, "UIPanelScrollFrameTemplate")
    wordListScrollFrame:SetSize(360, 200)
    wordListScrollFrame:SetPoint("TOPLEFT", 16, -114)

    wordListContainer = CreateFrame("Frame", nil, wordListScrollFrame)
    wordListContainer:SetSize(350, 10) -- height set dynamically in RefreshWordList
    wordListContainer:EnableMouse(true)
    wordListContainer:SetScript("OnHide", function()
        -- Clean up dynamic frames when panel closes to avoid memory leaks
        for _, rowFrame in ipairs(dynamicRowFrames) do
            rowFrame:Hide()
            rowFrame:SetParent(nil)
        end
        table.wipe(dynamicRowFrames)
    end)

    wordListScrollFrame:SetScrollChild(wordListContainer)
    UIPanelScrollFrame_OnLoad(wordListScrollFrame)

    -- Initial render
    RefreshWordList()
end

function RefreshWordList()
    if not wordListContainer then return end

    -- Clear existing rows
    for _, rowFrame in ipairs(dynamicRowFrames) do
        rowFrame:Hide()
        rowFrame:SetParent(nil)
    end
    table.wipe(dynamicRowFrames)

    wordListContainer:SetHeight(#BNSTTS_CONFIG_DB.word_excludes * 24 + 10)
    local yOffset = 0
    for i, word in ipairs(BNSTTS_CONFIG_DB.word_excludes) do
        local rowFrame = CreateFrame("Frame", nil, wordListContainer)
        rowFrame:SetSize(350, 24)
        rowFrame:SetPoint("TOPLEFT", 0, yOffset)

        local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetText(word)
        label:SetPoint("LEFT", 8, 0)

        local removeButton = CreateFrame("Button", nil, rowFrame, "UIPanelDynamicResizeButtonTemplate")
        removeButton:SetText("Remove")
        DynamicResizeButton_Resize(removeButton)
        removeButton:SetPoint("RIGHT", -4, 0)
        removeButton:SetScript("OnClick", function()
            table.remove(BNSTTS_CONFIG_DB.word_excludes, i)
            print("BetterNSTTS: Removed '" .. word .. "' from ignored words.")
            RefreshWordList()
        end)

        table.insert(dynamicRowFrames, rowFrame)
        yOffset = yOffset - 28
    end
end

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
