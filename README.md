# What is this?
A small "add-on" for World of Warcraft game, that "hacks" Northern Sky Raid Tools 
(https://www.curseforge.com/wow/addons/northern-sky-raid-tools) addon, and replaces TTS
(Text To Speech) with a small hardcoded(!) lookup for an appropriate .ogg file to play
instead of executing WoWVoiceProxy.exe to read the message.

# Why?
Well ... World of Warcraft on Linux struggles with TTS resulting with WoWVoiceProxy.exe 
process to crash. And I still want to have the addon "telling" me to use a given ability at
a given time. So, instead of using TTS it redirects the addon logic to play a specific file.

# How?
Because of the way LUA works I'm able to override a global function and replace it with my
own. And that's exactly what I'm doing.

# Can I use it too?
Yes, of course! Though it might require that you mess with the source code a bit. What you
are looking for is ```media``` folder containing .ogg files, ```ignore.lua``` containing words that disqualify the 
whole sentence (list of words) from being "played" and ```sounds.lua``` containing registry of available files (see
file comments for explanation on why it's needed).

The NSRT "reads" notes via TTS, so we are hijacking it, figuring out what it wanted to "tell" us, and we recognize 
each word one by one. The addon will play appropriate sound (word) one by one, if not we log the missing sound using
standard output (chat frame print). 

# Installation
I guess if you are this far you know a thing or two about WOW addons, so I guess you know that the addon code 
needs to go to WoW addon folder. Just dump those files into ```_retail_/Interface/Addons``` under ```BetterNSTTS``` 
folder (as in the archive).
Alternatively use the CurseForge: https://www.curseforge.com/wow/addons/better-northern-sky-tts

# How to test it?
It's pretty easy. NSRT has a nice feature to test TTS, and we'll use it.
1. Run WoW, make sure you have Northern Sky Raid Tools and this addon loaded
2. /ns to bring up NSRT main panel
3. Make sure you have TTS option enabled
4. Type in the edit box the sentence
5. You should hear all available words being played from ```media``` folder, and information regarding missing files
6. If you hear normal TTS triggering, the addon did not load at all or there was an error
7. User BugSac and BugGrabber to figure out what's wrong
8. Keep in mind that playing non-existent .ogg file results in silent failure with no error message

# What are currently supported words?
Look into ```media``` folder and/or ```sounds.lua``` file - those are 1:1 words that when encountered will be read using
local .ogg files.

# How do I add my own words and sounds?
1. Create a sound file per word you want to add (I've used https://en.text-to-speech.online/ voice: Jenny - US) and 
converted the mp3 into ogg using https://flathub.org/en/apps/org.soundconverter.SoundConverter
2. Put the file into ```media``` folder, its should be lowercase
3. Either use ```build_sounds.sh``` script to populate ```sounds.lua``` containing available sounds or add it yourself
following convention in the file
4. /reloadui or restart WOW client - test using method mentioned above 

# Can I post my additional words via pull request? 
Yes, go ahead, please remember to include the .ogg file (preferably following the same voice I've used for consistency)
and update ```sounds.ogg``` file.

# Can I post my personal exclusions via pull request?
Sure, if those would be sensible exclusions I see on issue with that.

# I have an idea on how to extend the add-on
Great, either post a PR or contact me directly via GitHub.

# I'd like to thank you for this work
Great! You can write me a nice private message or if you feel generous you can buy me a coffe using the button below.
(NOTE: only donate if you DO HAVE spare income, I don't live of my GitHub donations, so it's really just a coffe for me)

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/black_img.png)](https://www.buymeacoffee.com/bigos81)

# Final thoughts
I've written this in couple of hours with no prior LUA experience, guided by NSRT author
remark saying that the function ```NSAPI:TTS(args)``` is global and _I would suggest to instead overwrite the TTS 
function through another addon (or WA if you are using the fork) You can then use the sound name to match it to your 
sound file_. So I did. 

