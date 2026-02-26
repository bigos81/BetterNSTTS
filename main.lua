print ('BNSTTS loaded');

local ns_tts = NSAPI.TTS

NSAPI.TTS = function(arg1, arg2)
    return better_tts(arg1, arg2)
end

local function better_tts(arg1, arg2)
    spell = strlower(tostring(arg2))
    play_ogg(spell)
end

local function play_ogg(spell)
    if (string.find(spell,'divine hymn')) then
        PlaySoundFile("Interface\\AddOns\\SharedMedia_MyMedia\\sound\\divine-hymn1.ogg", "Master")
    elseif (string.find(spell, 'halo')) then
        PlaySoundFile("Interface\\AddOns\\SharedMedia_MyMedia\\sound\\halo1.ogg", "Master")
    elseif (string.find(spell, 'guardian spirit')) then
        PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Guardian Spirit.ogg", "Master")
    elseif (string.find(spell, 'personal')) then
            PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Personal.ogg", "Master")
    elseif (string.find(spell, 'apotheosis')) then
        PlaySoundFile("Interface\\AddOns\\SharedMedia_MyMedia\\sound\\apotheosis1.ogg", "Master")
    elseif (string.find(spell, 'power infusion')) then
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\Pi.ogg", "Master")
    else
        --fallback
        print('Unknown spell requested: '..spell)
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\Healcd.ogg", "Master")
    end
end

