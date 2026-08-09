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
