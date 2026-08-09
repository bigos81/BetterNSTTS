-- WoW passes (addonName, addonTable) via ... — standard pattern
local addonName, addon = ...  -- luacheck: ignore
local LibDeflate = LibStub("LibDeflate")


local QOL_NAMES_TABLE = {
    ["FEAST"] = true,
    ["CAULDRON"] = true,
    ["SOULWELL"] = true,
    ["REPAIR"] = true
}

-- Pre-compute lowercase keywords for case-insensitive matching
local qol_lower_keywords = {}
for keyword in pairs(QOL_NAMES_TABLE) do
    table.insert(qol_lower_keywords, string.lower(keyword))
end


----------------------------
---- NSAPI:TTS override ----
----------------------------

-- override NS TTS function
NSAPI.TTS = function(_, arg2)
    return BetterNSTTS.better_tts(arg2)
end

-- override logic go here
function BetterNSTTS.better_tts(arg2)
    local spell = string.lower(tostring(arg2))
    BetterNSTTS.play_words(spell)
end

----------------------------------------
---- QOL and Ready Check event hook ----
----------------------------------------

-- detects QOL message by checking for any known keyword
function BetterNSTTS.is_qol_message(message)
    if not message then
        return false
    end

    local lower_msg = string.lower(message)
    for _, kw in ipairs(qol_lower_keywords) do
        if string.find(lower_msg, kw, 1, true) then
            return true
        end
    end
    return false
end

local frame = CreateFrame("Frame")
C_ChatInfo.RegisterAddonMessagePrefix("NSI_MSG")
C_ChatInfo.RegisterAddonMessagePrefix("NSI_WHISPER")

frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("READY_CHECK")
frame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix == "NSI_MSG" or prefix == "NSI_WHISPER" then
        -- deflate
        local decoded = LibDeflate:DecodeForWoWAddonChannel(message)
        if (decoded) then
            local decompressed = LibDeflate:DecompressDeflate(decoded)
            if decompressed then
                if BetterNSTTS.is_qol_message(decompressed) and BNSTTS_CONFIG_DB.qol_sound then
                    BetterNSTTS.play_single_word(0, "qol_sound")
                end
            end
        end
    elseif event == "READY_CHECK" and BNSTTS_CONFIG_DB.rc_sound then
        BetterNSTTS.play_single_word(0, "rc_sound")
    end
end)


------------------------------
---- TTS Sound Management ----
------------------------------

-- lookup sound
function BetterNSTTS.sound_exists(word)
    return BetterNSTTS.BNSTTS_SOUNDS[word]
end

-- checks whether given word should be ignored
function BetterNSTTS.word_ignored(word)
    if not word then
        return true
    end

    -- Check hardcoded ignore list
    if BetterNSTTS.BNSTTS_IGNORE_WORDS[word] then
        return true
    end

    -- Check user-configured exclude list (case-insensitive)
    local lower_word = string.lower(word)
    local excludes = BNSTTS_CONFIG_DB and BNSTTS_CONFIG_DB.word_excludes
    for _, excluded in ipairs(excludes or {}) do
        if string.lower(excluded) == lower_word then
            return true
        end
    end

    return false
end

-- check whether whole sentence should not be ignored
function BetterNSTTS.words_contain_ignore(words)
    for _, v in ipairs(words) do
        if BetterNSTTS.BNSTTS_IGNORE_GLOBAL[v] then
            return true
        end
    end

    return false
end

-- estimate how long would a given word play out in seconds
function BetterNSTTS.estimate_word_delay(word)
    local len = strlen(word)
    if len < 6 then
        return 0.5
    elseif len < 11 then
        return 1
    else
        return len * 0.1
    end
end

-- plays list of ordered words
function BetterNSTTS.play_words(words)
    -- cleanup: remove brackets and punctuation in a single pass
    words = string.gsub(words, "[;{}%[%]():]", "")
    local chunks = { strsplit(" ", words) }
    if BetterNSTTS.words_contain_ignore(chunks) then
        return
    end
    local delay = 0.0
    for _, v in ipairs(chunks) do
        if not BetterNSTTS.word_ignored(v) then
            if BetterNSTTS.sound_exists(v) then
                BetterNSTTS.play_single_word(delay, v)
                delay = delay + BetterNSTTS.estimate_word_delay(v)
            else
                BetterNSTTS.report_unsupported_sound(v)
            end
        end
    end
end

function BetterNSTTS.report_unsupported_sound(word)
    if BNSTTS_CONFIG_DB.show_missing_media then
        print("BNSTTS: Unsupported sound: "..word)
    end
end

-- play single word with given delay (should start with 0)
function BetterNSTTS.play_single_word(delay, word)
    C_Timer.After(delay, function()
        PlaySoundFile("Interface\\AddOns\\BetterNSTTS\\media\\"..word..".ogg", "Master")
        end)
end