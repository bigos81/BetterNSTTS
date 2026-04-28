print ('BetterNSTTS loaded');
local BNSTTS_SOUNDS = BetterNSTTS.BNSTTS_SOUNDS
DevTools_Dump(BNSTTS_SOUNDS)

local ns_tts = NSAPI.TTS

-- lookup sound
function sound_exists(word)
    return BetterNSTTS.BNSTTS_SOUNDS[word]
end

function words_contain_ignore(words)
    for k,v in pairs(words) do
        if BetterNSTTS.BNSTTS_IGNORE[v] then
            return true
        end
    end

    return false
end

-- override NS TTS function
NSAPI.TTS = function(arg1, arg2)
    return better_tts(arg1, arg2)
end

-- override logic go here
function better_tts(arg1, arg2)
    local spell = strlower(tostring(arg2))
    play_words(spell)
end

function play_words(words)
    local chunks = { strsplit(" ", words) }
    if words_contain_ignore(chunks) then
        return
    end
    for k,v in pairs(chunks) do
        if sound_exists(v) then
            play_single_word(k-1, v)
        else
            print("BNSTTS: Unsupported sound: "..v)
        end
    end
end

function play_single_word(idx, word)
    C_Timer.After(idx, function()
        PlaySoundFile("Interface\\AddOns\\BetterNSTTS\\media\\"..word..".ogg", "Master")
        end)
end
