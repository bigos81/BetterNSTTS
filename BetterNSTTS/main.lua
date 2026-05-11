local addonName, addon = ...
local LibDeflate = LibStub("LibDeflate")


QOL_NAMES_TABLE = {
    ["FEAST"] = true,
    ["CAULDRON"] = true,
    ["SOULWELL"] = true,
    ["REPAIR"] = true
}


----------------------------
---- NSAPI:TTS override ----
----------------------------

-- override NS TTS function
local ns_tts = NSAPI.TTS
NSAPI.TTS = function(arg1, arg2)
    return better_tts(arg1, arg2)
end

-- override logic go here
function better_tts(arg1, arg2)
    local spell = strlower(tostring(arg2))
    play_words(spell)
end

----------------------------------------
---- QOL and Ready Check event hook ----
----------------------------------------

-- detects QOL message
function is_qol_message(message)
    if message == nil then
        return false
    end

    for k,v in pairs(QOL_NAMES_TABLE) do
        if string.find(message, k) then
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
        local decompressed = LibDeflate:DecompressDeflate(decoded)
        if decompressed then
            if is_qol_message(decompressed) and BNSTTS_CONFIG_DB.qol_sound then
                play_single_word(0, "qol_sound")
            end
        end
    elseif event == "READY_CHECK" then
        play_single_word(0, "rc_sound")
    end
end)


------------------------------
---- TTS Sound Management ----
------------------------------

-- lookup sound
function sound_exists(word)
    return BetterNSTTS.BNSTTS_SOUNDS[word]
end

-- checks whether given word should be ignored
function word_ignored(word)
    if word == nil then
        return true
    end

    trimmed = string.gsub(word, " ", "") --remove white spaces
    res = BetterNSTTS.BNSTTS_IGNORE_WORDS[word]
    if res then
        return true
    end

    return false
end

-- check whether whole sentence should not be ignored
function words_contain_ignore(words)
    for k,v in pairs(words) do
        if BetterNSTTS.BNSTTS_IGNORE_GLOBAL[v] then
            return true
        end
    end

    return false
end

-- estimate how long would a given word play out in seconds
function estimate_word_delay(word)
    len = strlen(word)
    if len < 6 then
        return 0.5
    elseif len < 11 then
        return 1
    else
        return len * 0.1
    end
end

-- plays list of ordered words
function play_words(words)
    -- cleanup
    words = string.gsub(words, ":", "")
    words = string.gsub(words, ";", "")
    words = string.gsub(words, "{", "")
    words = string.gsub(words, "}", "")
    words = string.gsub(words, "%[", "")
    words = string.gsub(words, "%]", "")
    words = string.gsub(words, "%(", "")
    words = string.gsub(words, "%)", "")
    local chunks = { strsplit(" ", words) }
    if words_contain_ignore(chunks) then
        return
    end
    local delay = 0.0
    for k,v in pairs(chunks) do
        if word_ignored(v) then
            -- nop
        elseif sound_exists(v) then
            play_single_word(delay, v)
            delay = delay + estimate_word_delay(v)
        else
            report_unsupported_sound(v)
        end
    end
end

function report_unsupported_sound(word)
    if BNSTTS_CONFIG_DB.show_missing_media then
        print("BNSTTS: Unsupported sound: "..word)
    end
end

-- play single word with given delay (should start with 0)
function play_single_word(delay, word)
    C_Timer.After(delay, function()
        PlaySoundFile("Interface\\AddOns\\BetterNSTTS\\media\\"..word..".ogg", "Master")
        end)
end
