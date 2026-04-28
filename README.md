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

The NSRT "reads" notes via TTS, so we are hijacking it, figuring out what it wanted to "tell" us, and if we recognize 
each word one by one. It will play appropriate sound (word) one by one, if not we log the missing sound on standard output (chat
frame print). 

# Installation
I guess if you are this far you are able coder, so I guess you know that the addon code 
needs to go to WoW addon folder. Just dump those files into 
```_retail_/Interface/Addons``` under ```BetterNSTTS``` folder (as in the archive).   

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

# How do I add my own words and sounds?
1. Create a sound file per word you want to add (I've used https://en.text-to-speech.online/ voice: Jenny - US) and 
converted the mp3 into ogg using https://flathub.org/en/apps/org.soundconverter.SoundConverter
2. Put the file into ```media``` folder, its should be lowercase
3. Either use ```build_sounds.sh``` script to populate ```sounds.lua``` containing available sounds or add it yourself
following convention in the file
4. /reloadui or restart WOW client - test using method mentioned above 

# Final thoughts
I've written this in couple of hours with no prior LUA experience, guided by NSRT author
remark saying that the function ```NSAPI:TTS(args)``` is global and _I would suggest to instead overwrite the TTS 
function through another addon (or WA if you are using the fork) You can then use the sound name to match it to your 
sound file_. So I did. 

