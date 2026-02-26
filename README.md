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
Because of the way LUA works i'm able to override a global function and replace it with my
own. And that's exactly what I'm doing.

# Can I use it too?
Yes, of course! Though it will require that you mess with the source code a bit. What you
are looking for is ```main.lua``` and those nasty hardcoded paths and spell names. 

The NSRT "reads" name of the spell via TTS, so we are hijacking it, figuring out what it
wanted to "tell" us, and if we recognize it we play appropriate sound, if not we are 
"Healer CD" sound. Those are as you probably can tell hardcoded to work for me :) so I'm
using some of my own sounds and some of the sounds from popular addons:
- EnhanceQoLSharedMedia
- Wildu_SharedMedia

You can either download those addons for those sounds or just go wild and record/generate 
your own - just make sure those are .ogg files.

And yes, you need to edit this code.

# Installation
I guess if you are this far you are able coder, so I guess you know that the addon code 
needs to go to WoW addon folder. Just dump those files into 
```_retail_/Interface/Addons/BetterNSTTS``` folder.   

# How to test it?
It's pretty easy. NSRT has a nice feature to test TTS, and we'll use it.
1. Run WoW, make sure you have Northern Sky Raid Tools and this addon loaded
2. /ns to bring up NSRT main panel
3. Make sure you have TTS option enabled
4. Type in the edit box the name of the spell
5. You should hear either fallback or your .ogg you provided in the code
6. If you hear normal TTS triggering, the addon did not load at all or there was an error
7. User BugSac and BugGrabber to figure out what's wrong
8. Keep in mind that playing non-existent .ogg file results in silent failure with no error message

# Final thoughts
I've written this in couple of hours with no prior LUA experience, guided by NSRT author
remark saying that the function ```NSAPI:TTS(args)``` is global and _I would suggest to instead overwrite the TTS 
function through another addon (or WA if you are using the fork) You can then use the sound name to match it to your 
sound file_. So I did. 

If there would be interest in making this more into legitimate addon with configuration and no necessity of editing
hardcoded paths, phrases, etc. I'm willing to spend some time learning LUA a bit more, though as for now:

It works for me :)

So if noone else is going to use it, why bother?
