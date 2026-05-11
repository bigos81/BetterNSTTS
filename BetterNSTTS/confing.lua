local addonName, addon = ...

-- create frame, initialize configuration
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        configuration_init()
        print ('BetterNSTTS loaded')
    end
end)

function configuration_init()
    -- fill in defaults if no variables found
    if not BNSTTS_CONFIG_DB then
        BNSTTS_CONFIG_DB = {}
        BNSTTS_CONFIG_DB["show_missing_media"] = true
        BNSTTS_CONFIG_DB["qol_sound"] = true
        BNSTTS_CONFIG_DB["rc_sound"] = true
        BNSTTS_CONFIG_DB["abbreviations"] = {}
        BNSTTS_CONFIG_DB["sentence_excludes"] = {}
        BNSTTS_CONFIG_DB["word_excludes"] = {}
    end
    register_configuration_panel()
end

-- build configuration panel
function register_configuration_panel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)

    local missing_media_setting = Settings.RegisterAddOnSetting(category, "show_missing_media", "show_missing_media",
        BNSTTS_CONFIG_DB, type(true), "Show missing media messages", true)
    Settings.CreateCheckbox(category, missing_media_setting, "Toggles display of missing media messages")

    local qol_sound_setting = Settings.RegisterAddOnSetting(category, "qol_sound", "qol_sound",
        BNSTTS_CONFIG_DB, type(true), "Play sound on QOL message", true)
    Settings.CreateCheckbox(category, qol_sound_setting, "Toggles QOL sound")

    local rc_sound_setting = Settings.RegisterAddOnSetting(category, "rc_sound", "rc_sound",
        BNSTTS_CONFIG_DB, type(true), "Play sound on Ready Check", true)
    Settings.CreateCheckbox(category, rc_sound_setting, "Toggles Ready Check sound")

    Settings.RegisterAddOnCategory(category)
end