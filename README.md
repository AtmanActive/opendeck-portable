# opendeck-portable
Windows wrapper exe to run [OpenDeck](https://github.com/ninjadev64/OpenDeck) in portable mode.


## Purpose
Allows you to run OpenDeck from anywhere, including brand new windows that has nothing installed. Also allows you to store several different versions, to be tested in A/B mode or to run on different computers. You can find more portable apps [here](https://portapps.io), [here](https://portableapps.com) and [here](https://www.portablefreeware.com).


## Principle
opendeck-portable doesn't care about the path where it is running from. 
It will run from any path. It is inteligent enough to discover it's path on runtime. 
OpenDeck, on the other hand, requires it's data store to reside in the windows appdata pre-defined folder. 
So, by using opendeck-portable.exe, all your config data will be copied from it's self-contained, dynamically-discovered folder into windows appdata well-known folder, just prior to launching the real opendeck.exe. Then, opendeck-portable.exe will wait for opendeck.exe to finish, and will copy all the data back in reverse. To ensure your portable data is NOT tied to windows logged-in user username, opendeck-portable.exe will wrap/unwrap all paths mentioned in all .json files that do reference windows appdata folder.


## How to merge OpenDeck into this (first time setup)
Copy/move/unpack "opendeck.exe" and the folder "plugins" to opendeck-portable's subfolder titled "App".
Going forward, never execute "opendeck.exe" directly, but always execute "opendeck-portable.exe" instead.


## How to upgrade
Make sure opendeck.exe is not running, then just overwrite the files with new versions.


## How to extract an MSI installer you downloaded from OpenDeck releases
Download the latest version from [here](https://github.com/ninjadev64/OpenDeck/releases). When downloaded, rename the file to "opendeck.msi". Create a new folder and name it "unpack". Start command-prompt window and execute:
```
msiexec /a "%userprofile%\Downloads\opendeck.msi" /qn TARGETDIR="%userprofile%\Downloads\unpack"
```
Now when you navigate into %userprofile%\Downloads\unpack\PFiles\OpenDeck, you'll find "opendeck.exe" and the folder "plugins". Move these two to wherever you keep opendeck-portable, subfolder "App".


## How to make opendeck-portable autostart with windows
Use any of the portsble launcher apps available. We recommend [SKWire Splat](https://www.dcmembers.com/skwire/download/splat/).
