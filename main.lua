print ('BNSTTS loaded');

local ns_tts = NSAPI.TTS

NSAPI.TTS = function(arg1, arg2)
    return better_tts(arg1, arg2)
end

function better_tts(arg1, arg2)
    spell = strlower(tostring(arg2))
    play_ogg(spell)
end

function play_ogg(spell)
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
    elseif (string.find(spell, '1')) then
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\1.ogg", "Master")
    elseif (string.find(spell, '2')) then
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\2.ogg", "Master")
    elseif (string.find(spell, '3')) then
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\3.ogg", "Master")
    elseif (string.find(spell, 'explosion')) then
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\AoE.ogg", "Master")
    elseif (string.find(spell, 'ironbark')) then
        PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Ironbark.ogg", "Master")
    elseif (string.find(spell, 'mass dispel')) then
        PlaySoundFile("Interface\\AddOns\\SharedMedia_MyMedia\\sound\\mass-dispel.ogg", "Master")
    elseif (string.find(spell, "cc adds")) then
        PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\CC.ogg", "Master")
        C_Timer.After(0.8, function()
            PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Adds.ogg", "Master")
            end)
    elseif (string.find(spell, "don't soak")) then
        PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Don't.ogg", "Master")
        C_Timer.After(0.6, function()
            PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Soak.ogg", "Master")
            end)
    elseif (string.find(spell, 'soak')) then
        PlaySoundFile("Interface\\AddOns\\EnhanceQoLSharedMedia\\Sounds\\Voiceovers\\Soak.ogg", "Master")
    else
        --fallback
        print('Unknown spell requested: '..spell)
        PlaySoundFile("Interface\\AddOns\\Wildu_SharedMedia\\Media\\Sound\\Jenny\\Healcd.ogg", "Master")
    end
end

