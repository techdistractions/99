99Things! - CGA Version README.TXT
==================================

Version: 1.0.2 - 19th April 2025
4am Programming
Website: www.4am.org/99

See 'Changelog' section of this document for changes.

License Information
-------------------
99Things and its related source code is released as public domain.
Game assets contain work from others - please see the "credits" area 
of this document for more information.

What is 99Things!?
------------------
99Things is a game where you find things on puzzle boards.
When all things are found the puzzle is completed.

It takes inspiration from the game "little things" series of games from klicktock
An early iPad game from the 2010s and I spent a lot of time playing it!

Depending on the difficulty things may:
- Rotate
- Colour differently
- Disappear or remain when found 
- Spread out over multiple boards

Want to shoot for a record best time?
Disable clear/disappearing things and enable the timed game.
Records are ranked on the quickest time, least amount of errors and highest 
streaks of things found in a row.

Want to just chill out?
Enable clear/disappearing things, disable the timed game.
Sit back, relax and clear boards at your own pace.

System Requirements & Recommendations
-------------------------------------
99Things will run on just about any MS-DOS PC.
- Intel 8088 or compatible running at 4.77mhz (IBM-PC, PC-XT)
- 256KB of RAM or above
- CGA Capable Graphics or above
- MS-DOS 2.11 or above
- Floppy disk or hard disk with about 280KB free space

It is recommended to have:
- A Turbo-XT or 286 running at 10mhz or faster
- 512KB of RAM 
- Mouse with CTMouse driver 1.4 or higher (tested)
- Adlib compatible sound card
- EGA/VGA display to render some cool custom CGA palettes

If you're running this through an emulator like DOSBOX I would recommend:
- Setting cycles to match 20K cycles or roughly a 486DX2/66

Game Modes
----------

[Quick Game]
Complete a smaller square puzzle board with preset difficulty.

Board sizes include; 16 (4x4), 25 (5x5), 36 (6x6), 49 (7x7), 64 (8x8)

Difficulties include:
- Easy: Only a small number of things to find
		Things are not rotated and only have 2 color styles
- Normal: More things to find, 2 rotation types and 3 color styles
		This mode is good to attempt a best time (with "clear" disabled).
- Tricky: More things than normal to find
		3 rotation types and 6 color styles
		Designed to give a bit more of a challenge on bigger boards (6+)
- Tough: Maximum amount of things to find
		All 4 rotation types and all 9 color styles are possible
		Will give a strong challenge on bigger boards (6+)
		
[99Things]
99 square puzzle board (9x11) 

Difficulties include:
- 1-4 board count - Please note, 256KB RAM PC's will only get 2 boards max.
					
					Using multiple boards dramatically increases the time 
					needed to complete the puzzle - especially if you are
					playing without "clear" checked. Be warned!
					
- Easy: Find up to 15 different things with no rotations and only 2 color
			styles. Useful for first time players.
			
- Normal: Find up to 30 different things with 2 rotation types and 4 color
			styles. Gives a good challenge but is easily solved.
			
- Tricky: Find up to 45 different things with 3 rotation types and 6 color
			styles. This mode is a step up from normal difficulty.
			
- Tough: Find up to 65 different things with all 4 rotation types and 7
			color styles. Approach with caution - this really amps up the 
			difficulty and when played without "clear" checked could take
			a very long time to complete (especially if multiple boards 
			are used!)

- Insane!: Find up to 90 different things with all 4 rotation types and 
			all 9 color styles. Could take hours to complete a multiple 
			board game - so be warned! 
			
			If anyone is crazy enough to do a multi-board timed/no-clear
			game in this mode I would love to see a screenshot or video 
			of you completing it. 
			
			Game records only go up to about 16 hours (or 999 minutes).
			Keep this in mind!
			
[Custom Game]
In this mode you can set your own game up as easy or as difficult as you prefer.
There are so many combinations possible.
Custom games are not timed and do not contribute to the best-time records.
			
Controls
--------

Mouse:
	Move with the mouse and use left button to activate

Keyboard:
	W/A/S/D or Up/Right/Down/Left to highlight a menu item/puzzle square.
	You can also use TAB if this feels more familiar
	
	ENTER or SPACE to choose/activate a menu item/puzzle square.
	ESC to exit or go back a menu

During a game:
	ESC - to Pause and optionally quit
	F1 - Show Game Info Panel (Clear, Rotate, Style config for puzzle)
	F2 - Show keys and mouse config status
	F7 - Show in-game basic stats for records
		Current Streak, Find Speed and Misses
	F9 - Mute or Unmute Sound (Toggle)
	
Settings
--------
When 99Things first starts it looks for CONFIG.DAT
If it is missing the Settings screen will appear.
You can access this any time from the main menu.

[ ] Enable Mouse Input - If checked mouse cursor will be visible provided
a suitable CTMouse or MOUSE driver is loaded. I used CTMouse 1.4 in development.
Note - if you do not load a mouse driver and check this the PC might hang.
I spotted this with MS-DOS 2.11 which I used for development.

Video Mode
( ) CGA Compatible - 4 Palettes - This is for CGA compatible cards, composite or
MONO CGA. It will only use the standard 4 CGA Palettes and hi-intensity support 
will not be included. It is a fall-back mode unless 6-Palette mode doesn't work.

(-) CGA (REAL) - 6 Palettes - Uses hi-intensity and mono flip bit support to allow
Mode 5h. This should be used for any display and card that supports it. 

(-) EGA/VGA - 4-Color Palettes - This is default for all non-CGA setups.
If your PC has the ability to use EGA/VGA use this setting.
It will simulate the 6-Palette CGA modes and deliver some additional custom 
4-Color palettes. This is safe to use if you have a CGA monitor with an EGA 
graphics card (something I had back in the day myself).

[ ] EGA Custom Palettes - If ticked and EGA/VGA is used, 99Things will use custom
palettes as stored in PALX.CGA. Has no effect for CGA Real or Compatible modes.
	- For Menu/UI it will use a specified mode in the list
	- In-Game will use a random one from the list

[ ] - Disable CGA Hi-Intensity Blank. Use this if you notice mono when you expect
color or if you are using something like a FPGA retro video scaler. 

Sound Mode
- No Sound
- PC Speaker: use internal PC speaker if available
- Adlib: use Adlib compatible sound card if available
Note - Adlib support is basic, it was more of an experiment to get noise out.

[?] Low Memory Mode - Will be enabled if 99Things detects 256KB of RAM.
Boards will be reduced to 2 so you don't run out of memory while trying to play.
You can override this setting but I wouldn't recommend it.

Credits
-------
This game was inspired by "little things" and it's sibling "doodle find".
https://www.klicktock.com/864/games/little-things-remastered/
https://www.klicktock.com/260/games/doodle-find-iphone-2/
You can still download little things for the PC, Mac and Android thesedays - check it out!

I used http://stanislavs.org/helppc/int_33.html for reference of the mouse routines.
Credit to @MontieMongoose (Youtube) for the initial idea of using OUT commands for palettes

Credit to Angelo Mottola soft (C) April 1997 for SoundLab which I understand became
part of the DirectQB package. SoundLab helped me load and play some very basic (pun)
adlib effects into my game. I couldn't find much else that would do this for an 8088
when using QuickBasic. I intend to make a whole-hearted effort to learn this a bit more
for future versions and projects.

I can't find a website for Angelo thesedays, if anyone knows of it please let me know.

Table Patterns are from talented artist Poloviiinkin
The itch page is here: https://poloviiinkin.itch.io/ 
These are stored in the ASSET*.CGA files
These are licenced under Attribution-ShareAlike 4.0 International
Details here: https://creativecommons.org/licenses/by-sa/4.0/deed.en

I have used the pack of tiles and patterns from this pack: 	
https://poloviiinkin.itch.io/1-bit-patterns-and-tiles 
If you find these patterns and tiles interesting - please consider giving 
them a donation.

Notes on EGA/VGA PALX.CGA file
------------------------------
I came up with a few random custom palettes - feel free to change them.
You can test them in game:
	- Play an untimed game
	- Use { to randomly choose a palette, use { to change and display the color codes

Notes on the source code
------------------------
If you plan on making any improvements and changes to the code please make sure it
continues to compile and run on the target PC: 8088 4.77mhz/CGA/256KB RAM

This code went through a few twists and turns as I had to re-scope and remove many
features and items to fit under the 256KB limbo-bar. 		

Changelog

v1.0.2 - 19th April 2025 - Micro Update

[FIX] Mouse Cursor being captured on GET/PUT
Moved Hidemouse before switching

[ADDED] debug key L to skip ahead 50 seconds
[ADDED] DoDebugMode% as setting

[FIX] Timer resets once 109 minutes is hit
Reworked timer events to watch for a minute at the 10 and 100 minute mark to move timer location

---------
v1.0.1 - 18th April 2025 - Micro Update

[WORKAROUND] 'ESC' key doesn't work well in emulators.
Added - F10 key to perform same function as ESC in QuickGame and DoDialog

[FIX] If mouse is used the screen may get glitches when starting a game
	Removed Mouse toggling from RandomPal - make it the calling func's problem
	Implemented mouse toggle in QuickGame -> "{" for RandomPal without clear in EGA

[ADDED] Added mouse button detection as "press any key" on end of game dialog
	-TryRecord and QuickGame (after entering name for record)

[ADDED] Setting for high-intensity colors (dont use hi-intensity palettes)
	Implemented in RandomPal, ApplySetting and DoSetup
	Can be adjusted in CONFIG.DAT manually by setting NoHiPal% = 1 to force 1,3,5 pals

v1.0.0 - 17th April 2025 - Initial release


