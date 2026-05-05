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
        BNSTTS_CONFIG_DB["abbreviations"] = {}
        BNSTTS_CONFIG_DB["sentence_excludes"] = {}
        BNSTTS_CONFIG_DB["word_excludes"] = {}
    end
    register_configuration_panel()
end

-- build configuration panel
function register_configuration_panel()
    local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
    local setting = Settings.RegisterAddOnSetting(category, "show_missing_media", "show_missing_media",
        BNSTTS_CONFIG_DB, type(BNSTTS_CONFIG_DB.show_missing_media), "Show missing media message", true)

    Settings.CreateCheckbox(category, setting, "Toggles display of missing media messages")
    Settings.RegisterAddOnCategory(category)
end