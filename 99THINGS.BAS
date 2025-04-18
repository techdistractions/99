'$DYNAMIC

DEFINT A-Z
'$INCLUDE: 'qb.bi'

'99THINGS - A find a thing puzzle game
'Target Specs: 8088 @ 4.77mhz, 256KB RAM and CGA Graphics
'Ensure QB.BI is included and Quickbasic 4.5 is started with /L
'99THINGS.BAS is the core file to load, 99THING2.BAS is the additional include

'====[Declare FUNCTIONS]====
DECLARE FUNCTION GetPuzText$ (ThingNumber%)
DECLARE FUNCTION TryCursor% ()
DECLARE FUNCTION LoadFX% (FileName$)
DECLARE FUNCTION DoDialog% (dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
DECLARE FUNCTION StrSplit% (uSplitBy$, uText$) 'Dumps results into SplitWords$() - Returns count
DECLARE SUB dAddI (uItem%, udItem%, udStartX%, udStartY%, udInitVal%, udMinVal%, udMaxVal%, udText$, udHover$) 'Add Dialog Item
DECLARE FUNCTION SecsToTime$ (inSecs%, fFlag%)
DECLARE FUNCTION GetGameID$ (InRecord%)

'====[Declare SUBS]====
DECLARE SUB PalXInit ()
DECLARE SUB DoSetup ()
DECLARE SUB dAddI (uItem%, udItem%, udStartX%, udStartY%, udInitVal%, udMinVal%, udMaxVal%, udText$, udHover$) 'Add Dialog Item
DECLARE SUB mAddI (umItem%, umOptionText$, umHoverText$, umOptionThing%) 'Add Menu Item
DECLARE SUB CGAPal (UPal%, UCol%) 'Change a CGA Palette Combination and Set a background color
DECLARE SUB uSleep (Waiter!)
DECLARE SUB Mouse (IState%)
DECLARE SUB HndCursor (UseV%)
DECLARE SUB iPrint (uText$, StartX%, StartY%, UseFG%, UseBG%) 'Print from SmallFont%
DECLARE SUB cPrint (UseText$, UseRow%, UseCol%, UseFG%, UseBG%) 'Print using System
DECLARE SUB mPrint (uText$, StartX%, StartY%, UseFG%, UseBG%) 'Print using mFont%
DECLARE SUB PuzzleUI (UType%)
DECLARE SUB LimitMouseXY (StartX%, StartY%, EndX%, EndY%)
DECLARE SUB PlayFX (Num%)
DECLARE SUB DrawPattern (UsePattern%, StartX%, StartY%, EndX%, EndY%, DrawStyle%)
DECLARE SUB LoadThingDef () 'Load THINGS.DEF to describe things
DECLARE SUB DrawBoard () 'Draw the CurrentBoard% (or PUT)
DECLARE SUB GetDiffCalc ()
DECLARE SUB PPUT (UseX%, UseY%, UseThing%, Style%)
DECLARE SUB DispUI (UIType$)
DECLARE SUB UpdateMenu (Text$)
DECLARE SUB QuickGame ()
DECLARE SUB PutUI (Element$, ParmS$(), ParmN%())
DECLARE SUB RandomPal ()
DECLARE SUB ShowMouse ()
DECLARE SUB HideMouse ()
DECLARE SUB DoRecords ()
DECLARE SUB ApplySetting (useInput$)
DECLARE SUB Speak (SpeakFX%)
DECLARE SUB TryRecord ()

'====[VARIABLES]====
COMMON SHARED CGAMode%, NoBlank%, UseMouse%, PuzMax%, PuzFlag%, PuzPos%, UseAdlib%, UsePCSpk%, GameTime%, GameTimeLimit%, GameType%, BoardMax%
COMMON SHARED SUITabVis%, TryX%, TryY%, TryCount%, PuzListCount%
COMMON SHARED UseP%, UseX%, UseY%, UseC%, UseF%, TargetCount%, OffSetX%, OffSetY%, Found%
COMMON SHARED B%, V%, H%, RemoveOnFind%, CurrentBoard%, CFound%, GameStreakCount%, GameCurrentStreak%
COMMON SHARED UseOrientations%, UseDispVar%, PrevBoard%, mButtonUP%, LastMenu%, MixBagSize%, GameErrorCount%, LowMem%, ConfigFlag%, GamePreset%
COMMON SHARED PrevPuzMajor%, PrevTarMajor%, PalXCount%, UseExtendedPal%, NoHiPals%
COMMON SHARED Regs AS RegType 'Registers for interrupts

'====[Temp Assets]====
'!Board%() - Hold boards not on screen
'!Screener%() - Temp holder for Image loading/grabbing
'!TempImage%() - Temporary Image holder
'!Logo%() -99 Things Big LOGO
'!SUIArea%() - [140] Store F1=Info and F2= Keys (stats needs to be generated each time)

'====[Game Assets - Static]====
'Thing%() - [45] 99 Thing Images in sequence (Orientation/Offset; Up(0) Right(13365), Down(8910), Left(4455)
'ThingDef$() - Store description strings for things
'mFont%() - [10] Medium sized font 0-900
'SmallFont%() - [9] Used for holding 3x5 font
'BigFont%() -[32] Large numbers and symbols
'OtherAsset% (150) - Cursors(0),Return(16),Checked(28),UnChecked(48),Minus(68),Plus(88),RadioUnSelected(108), RadioSelected(128)
'Pattern%() - [45] Used to store the inbuilt patterns (16x16px)

'====[Program Setup]====
'CGAMode% - Set palette handling flag [0 CGA 6Pal, 1 EGA-VGA 4col, 2 CGA 4Pal]
'PalX$() - Storage of the PALX.CGA file
'PalXCount% - Count for PalX$()
'UseExtendedPal% - Toggle to use Extended Palettes for EGA+
'NoBlank% - Don't attempt to reset CGA Mono/HI bit [0 Disable, 1 Enable]
'UseAdlib% - Flag to use or not use adlib for sound effects [0-1]. Port hardcoded to &H388/&H389 for now.
'UseMouse% - Enable Mouse Polling/Input [0 Disable, 1 Enable]
'UsePCSpk% - Play music and sound effects through PC Speaker [0-1] (if UseAdlib% = 0)
'ConfigFlag% - 0 None 1 Loaded
'LowMem% - Flag for <64KB free memory after assets loaded. Limit to 2 boards
'NoHiPals% - 0-Default, 1-Only use 1,3,[5] and if CGAMode% = 1 dont use anything with >9 as a color

'====[Program Runtime]====
'B%, V%, H% - Mouse polling button, vertical and horizontal - I used large numbers as when a mouse is not connected it might give an error
'MButtonUp% - Record when Mouse button is up
'SUITabVis% - Current tab visible on Status / Puzzle UI

'UseF%, UseP%, UseX%, UseY%, UseC% - Temporary Integers
'LastMenu% - Which Main Menu area was used
'SplitWords$() - Last StrSplit%() word
'PrvSel%() - Previous # selection of (0-Last Menu Used) (1-4 Board)
'CurSel%() - Current # selection of (0-Last Menu Used) (1-4 Board)

'dItem%() - Item Type, dVal%() - Item Value, dInitVal%() - Default Value, dMinVal%(), dMaxVal%() Bounds
'dStartX%() & dStartY%(),dEndX%(), dEndY%() - End co-ords for item

'====[Game Setup]====
'BoardMax% - 1 Single, 2 L/R, 3 L/M/R, 4 2x2
'GamePreset% - 0-4 Easy,Normal,Tricky,Tough,[Insane -99Things only]
'GameType% [1 Quick Game, 2 99Things! Single, 3 99Things! Multi, 4 Custom Game, 5 Co-Op, 6 VS Game]
'OffSetX%, OffSetY% - board offset XY values
'PuzListCount% - Count of Target(s) to find within PuzList%() and PuzzleListCount%()
'PuzMax% - How many Things in the pool for puzzle selection [2 - 99]
'MixBagSize% - Bag size for generating puzzles
'RemoveOnFind% - Make a found thing disappear (difficulty) [1 Yes, 0 No]
'UseOrientations% - 1-4 for amount of orientations for things
'UseDispVar% - 1-4 for display variations for things
'Puzzle%() - (0- ((BoardMax%*99)-1) Thing# in each seq cell 0=T-Left(0) 98=D-Right(0), 99=T-Left(1)
'PuzzleD%((0- ((BoardMax%*99)-1)) Display Variation for cell (Negated by UseDispVar% = 1)
'PuzzleO%((0- ((BoardMax%*99)-1)) Orientation for cell (Negated by UseOrientations%=1)
'PuzList%() -(0-PuzMax%) List of Thing# in the mix for the puzzle
'PuzzleCount%() - (0-PuzMax%) Counts of the thing in the puzzle

'====[Game Runtime]====
'BoardGenFlag%() - (1-BoardMax%) keep a flag if the board has been generated on screen (for GET/PUT switching)
'CurrentBoard% - Current board in focus (1-BoardMax%)
'PrevBoard% - Previous board in focus

'CFound% - Cumulative Found% count for the current puzzle
'Found% - Previous Found Count
'*?GameTime%, GameTimeLimit% - Elapsed and Limit of game time [0 for none]
'PuzFlag% - Used to determine if a valid target has been found (event)
'PuzzleFlag%() - (0- ((BoardMax%*99)-1) Has Puzzle item been found 0 = No, 1 = Yes
'PuzPos% - Current position of the puzzle (pointer)
'TargetCount% - Iterations of the current thing to find (-1 for FAIL)
'TryCount% - Amount of Tries fired during a puzzle
'GameErrorCount% - Keep track of errors made during the game
'GameStreakCount% - Highest Streak during game [0]
'GameCurrentStreak% - Current Streak during game
'TryX%, TryY% - Last Tried selection position
'PrevPuzMajor%, PrevTarMajor% - 0|1 Flag for if Puzzle or Target was > 9 on last poll

'UseTimer&() - (6) Timer Parms (0) = 1/0 Enable , (1-5) App Defined
'PrvTimer%() - (4) Store last digits of timer display

'====[Game Records]====
'rUser$() - User Name for Records
'rTime%() - Time (seconds) of the record
'rDate$() - Date the record was saved
'rStreak%() - Streak of correct tries
'rErrors%() - Count of incorrect tries

'====[ARRAYS]====
COMMON SHARED Screener%(), Thing%(), PuzList%, SmallFont%(), TempImage%()
COMMON SHARED Logo%(), BigFont%(), PuzzleCount%(), Puzzle%(), Pattern%(), ThingDef$(), ThingsR%(), ThingsD%()
COMMON SHARED Board%(), mFont%(), BoardGenFlag%(), PrvSel%(), CurSel%(), PuzzleFlag%()
COMMON SHARED OtherAsset%(), UseTimer&(), PuzzleO%(), PuzzleD%(), SUIArea%(), PrvTimer%(), dVal%()
COMMON SHARED SplitWords$(), dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$(), dEndX%(), dEndY%()
COMMON SHARED rUser$(), rTime%(), rDate$(), rStreak%(), rErrors%(), PalX$()


REDIM SHARED Snd(1 TO 10) AS STRING * 30 'For adlib sound fx spacing
DIM SHARED Screener%(8001), Thing%(17830), PuzList%(100), SmallFont%(1000), TempImage%(128), TargetList%(196), TargetListFlag$(98), Logo%(570)
DIM SHARED BigFont%(384), PuzzleCount%(100), Puzzle%(100), Pattern%(45 * 15), ThingDef$(400), Board%(1), mFont%(910), BoardGenFlag%(4)
DIM SHARED PrvSel%(5), CurSel%(5), PuzzleFlag%(100), OtherAsset%(302), UseTimer&(6), SUIArea%(1001), PrvTimer%(6), dVal%(20), dEndX%(20), dEndY%(20)
DIM SHARED SplitWords$(128), rUser$(6), rTime%(6), rDate$(6), rStreak%(6), rErrors%(6), PalX$(10)

'---------------

'Internal - Static Settings
LastMenu% = 0: mButtonUP% = -1 'Reset
ConfigFlag% = 0 'No Config loaded yet

'Read and Parse Config
'Put this in config/menu later
NoBlank% = 0
UseAdlib% = 0 'Attempt to use the Adlib
UsePCSpk% = 1 'Use PC Speaker? or 0
UseMouse% = 0 'Attempt to use the mouse
LowMem% = 0 'Over 256KB RAM

'File Check routine
ON ERROR GOTO FailFile
DIM TestFile$(8): TestFile$(0) = "99THINGS.EXE": TestFile$(1) = "ASSET.CGA": TestFile$(2) = "ASSET2.CGA"
TestFile$(3) = "ASSET3.CGA": TestFile$(4) = "ASSET4.CGA": TestFile$(5) = "THINGS.DEF": TestFile$(6) = "THINGS.SND": TestFile$(7) = "PALX.CGA"'Files to test
FOR X% = 0 TO 7: F = FREEFILE: OPEN TestFile$(X%) FOR INPUT AS #F: CLOSE F: NEXT X%:  GOTO VideoDetect'Test - if OK - go check video modes
FailFile: PRINT "99THINGS cannot start - missing file: "; TestFile$(X%); CHR$(13); "Make sure you're executing 99THINGS.EXE from its directory": END: RESUME NEXT'Fail and END

'Video Check routine
VideoDetect: ON ERROR GOTO FailVideoTest: CGAMode% = -1
SCREEN 1: CGAMode% = 0: SCREEN 7: CGAMode% = 1: NoBlank% = 1'Set flag to unsupported then check for Screen 1 (CGA) and 7 (EGA+)
FailVideoTest: RESUME CompleteVideoTest
CompleteVideoTest: IF CGAMode% = -1 THEN PRINT "99Things requires CGA graphics or above": END: RESUME NEXT
ON ERROR GOTO 0  'Disable error handler
SCREEN 1

IF CGAMode% = 1 THEN PalXInit 'Init PALX.CGA for custom palettes

'Load Asset
SELECT CASE CGAMode% 'CGA or EGA/VGA screens
CASE 0, 2: CGAPal 1, 6'Make Background Brown and Text Bright green to hide assets
CASE 1: SCREEN 1: PALETTE 0, 1: PALETTE 1, 14: PALETTE 2, 15: PALETTE 3, 1 'Blue /Yellow for EGA/VGA
END SELECT

cPrint "Load", 24, 34, 1, 0: cPrint "1%", 25, 36, 1, 0 'Initial Load message and progress
REDIM Screener%(8000): DEF SEG = VARSEG(Screener%(0))
BLOAD "ASSET.CGA", 0: PUT (0, 0), Screener%, XOR: DEF SEG : ERASE Screener% 'Load Main Asset File

'Grab to Arrays
GET (202, 99)-(240, 127), Logo%(0): GET (202, 131)-(316, 159), Logo%(148) 'Grab 99 Things Logo

REDIM Pattern%(815) 'Grab Patterns
FOR UseX% = 0 TO 2
	UseU% = UseX% * 17
	FOR UseY% = 0 TO 5
		UseV% = UseY% * 17
		GET (265 + UseU%, 23 + UseV%)-(280 + UseU%, 38 + UseV%), Pattern%(((UseX% * 6) + UseY%) * 45)
	NEXT UseY%
NEXT UseX%

'Grab SmallFont
FOR UseX% = 0 TO 58: GET (UseX% * 4, 164)-((UseX% * 4) + 3, 168), SmallFont%(UseX% * 9): NEXT UseX%

'Grab BigFont
FOR UseX% = 0 TO 8
	UseU% = UseX% * 12 'Calc Once 12042025
	GET (UseU% + 203, 1)-(UseU% + 213, 19), BigFont%(UseX% * 32)
NEXT UseX%

FOR UseX% = 9 TO 11
	UseU% = (UseX% - 9) * 12 'Calc Once 12042025
	GET (UseU% + 203, 22)-(UseU% + 213, 40), BigFont%(UseX% * 32)
NEXT UseX%

'Grab 99 x Things
UseP% = 0
FOR UseY% = 0 TO 8: UseT% = UseY% * 18 'Calc Once 12042025
	FOR UseX% = 0 TO 10: UseU% = UseX% * 18'Calc Once 12042025
		GET (UseU% + 1, UseT% + 1)-(UseU% + 17, UseT% + 17), Thing%(UseP%)
		UseP% = UseP% + 45 'GET memory spacing
	NEXT UseX%
NEXT UseY%

'Grab the Medium Font 0-900
GET (223, 180)-(225, 187), mFont%(0) 'First one has 2px width
FOR UseZ% = 0 TO 52
	UseT% = UseZ% * 10: UseU% = UseZ% * 6 'Calc once 12042025
	GET (UseU% + 1, 170)-(UseU% + 5, 177), mFont%(UseT% + 10)
	IF UseZ% < 37 THEN GET (UseU% + 1, 180)-(UseU% + 5, 187), mFont%(UseT% + 540)
NEXT UseZ%

'Grab Asset2.CGA,Asset3.CGA and Asset4.CGA storing them in Thing% with offsets
FOR UseZ% = 2 TO 4
	cPrint STR$((UseZ% - 1) * 33) + "%", 25, 34, 1, 0 'Progress Update
	REDIM Screener%(5000): DEF SEG = VARSEG(Screener%(0)): BLOAD TestFile$(UseZ%), 0
	PUT (0, 0), Screener%, PSET: DEF SEG : ERASE Screener%: UseP% = 0 'Put and ERASE
	FOR UseY% = 0 TO 8 'GET from Screen
			UseU% = UseY% * 18 'Calc Once 12042025
		FOR UseX% = 0 TO 10
			UseT% = UseX% * 18 'Calc Once 12042025
			StartX% = UseT% + 1: StartY% = UseU% + 1: EndX% = StartX% + 16: EndY% = StartY% + 16
			UseV% = UseP% + (13365 - ((UseZ% - 2) * 4455))'Condense 12042025 [(1)Up=0,(2)Right=13365,(3)Down=8910,(4)Left=4455 Rotates]
			GET (StartX%, StartY%)-(EndX%, EndY%), Thing%(UseV%)
			UseP% = UseP% + 45
		NEXT UseX%
	NEXT UseY%
NEXT UseZ%

'Grab other assets
GET (2, 191)-(14, 197), OtherAsset%(0) 'Cursors
GET (20, 190)-(28, 196), OtherAsset%(16) 'Enter
FOR UseX% = 0 TO 3 'Scrape UI Elements [Checkbox, ScrollBox, RadioButtons]
	UseU% = UseX% * 12
	GET (202 + UseU%, 67)-(212 + UseU%, 77), OtherAsset(28 + (20 * UseX%))
	IF UseX% < 2 THEN GET (202 + UseU%, 80)-(212 + UseU%, 90), OtherAsset(108 + (20 * UseX%))
NEXT UseX%
GET (202, 48)-(216, 61), OtherAsset%(148) 'Computer Tile
GET (231, 37)-(260, 64), OtherAsset%(188) 'Star

CLS 'Final Loading Phase
cPrint "Check Memory..", 24, 24, 1, 0 'Initial Load message and progress
SELECT CASE FRE(-1)
CASE IS < 64000: LowMem% = 1
CASE IS < 42000 'Fail out!
	SCREEN 0: WIDTH 80
	PRINT "Not enough memory to load 99Things:"; FRE(-1)
	END
END SELECT

LoadRecordsFile: 'Does the file exist?
cPrint "Init Records..", 24, 24, 1, 0
ON ERROR GOTO NoRecordsFile
F = FREEFILE: OPEN "RECORDS.DAT" FOR INPUT AS #F: CLOSE #F
GOTO ApplyConfig 'Skip the error handler

NoRecordsFile: 'No - Make a generic records table
CLOSE : F = FREEFILE: OPEN "RECORDS.DAT" FOR OUTPUT AS #F
FOR UseC% = 0 TO 179
	PRINT #F, LTRIM$(RTRIM$(STR$(UseC%))); "|!99THINGS!|30000|NEVER|99|99"
NEXT UseC%
CLOSE #F
RESUME ApplyConfig

'Apply SETUP.CFG or Post DoSetup
ApplyConfig:
cPrint "Apply Config..", 24, 24, 1, 0 'Initial Load message and progress
ON ERROR GOTO NoConfigFile
F = FREEFILE: OPEN "CONFIG.DAT" FOR INPUT AS #F
DO
	LINE INPUT #F, Setting$
	ApplySetting Setting$
	IF EOF(F) THEN EXIT DO
LOOP
CLOSE #F
ConfigFlag% = 1: GOTO PreMenuInit 'Loaded OK

NoConfigFile: RESUME DefaultConfig
DefaultConfig:
ON ERROR GOTO 0 'Disable Handler

PreMenuInit:
'Command Line Overrides
ON ERROR GOTO 0
IF COMMAND$ = "/NOMOUSE" THEN UseMouse% = 0

'Apply EGA/VGA 4Color mode (or fail back to CGA 6Pal)
IF CGAMode% = 1 THEN
VideoDetectTry: ON ERROR GOTO FailVideoTestTry
	CGAMode% = -1: SCREEN 1: CGAMode% = 0: SCREEN 7: CGAMode% = 1'Set flag to unsupported then check for Screen 1 (CGA) and 7 (EGA+)
FailVideoTestTry: RESUME CompleteVideoTestTry
CompleteVideoTestTry:
	ON ERROR GOTO 0  'Disable error handler
	SCREEN 1 'Return back to CGA mode but allow pal changes with CGAMode%=1
END IF

'Sound File Parsing
IF UseAdlib% = 1 THEN
	UsePCSpk% = 0 'Disable PC Speaker
	T% = LoadFX%("THINGS.SND")    'Load Things sound file
END IF

LoadThingDef 'Load in Thing Definitions File

IF ConfigFlag% = 1 THEN
	IF UseAdlib% = 1 THEN PlayFX 9
	IF UsePCSpk% = 1 THEN Speak 1
END IF

'Init Main Screen
DrawMainScreen: 'UI items that will appear regardless of menu items
SELECT CASE CGAMode%: CASE 0, 2: CGAPal 6, 0: CASE 1: CGAPal 7, -1
END SELECT
DrawPattern 3, 0, 0, 319, 39, 1 'Choose Pattern

'Top Logo - Clear, Format & PUT logo
LINE (73, 5)-(247, 43), 0, BF: LINE (78, 10)-(98, 38), 2, BF: LINE (100, 10)-(116, 38), 2, BF: PUT (78, 10), Logo%(0), AND
LINE (127, 10)-(142, 38), 1, BF: LINE (145, 10)-(165, 38), 2, BF: LINE (168, 10)-(175, 38), 3, BF: LINE (178, 10)-(197, 38), 1, BF
LINE (199, 10)-(219, 38), 2, BF: LINE (221, 10)-(241, 38), 3, BF: PUT (127, 10), Logo%(148), AND

REDIM CurSel%(12): REDIM PrvSel%(12): OffSetX% = 22: OffSetY% = 50'Main Menu Offsets (and keep selection memory for 12 ui elements)

'Init Menu Area
LINE (OffSetX%, OffSetY%)-(319 - OffSetX%, 204 - (OffSetY% / 4)), 0, BF
LINE (OffSetX% + 2, OffSetY% + 2)-(319 - OffSetX% - 2, 209 - (OffSetY% / 3) - 2), 3, B
LINE (OffSetX% + 2, (209 - OffSetY% / 3) - 13)-(319 - OffSetX% - 2, 179 - (OffSetY% / 3) - 2), 3, B

SELECT CASE LastMenu% 'Pre-Menu selection for loop backs (default mnuMain)
CASE 1: GOTO mnuQG
CASE 2: GOTO mnu99
CASE 3: GOTO mnuCG
END SELECT

mnuMain: LastMenu% = 0 'Main Menu Items

IF ConfigFlag% = 0 THEN 'Check for config first
	DoSetup
	IF ConfigFlag% = 0 THEN 'Exit Ungracefully
		SCREEN 0: WIDTH 80
		PRINT "Settings not saved, 99Things cannot start"
		END
	ELSE
		GOTO ApplyConfig 'Go back and reload it
	END IF
END IF


dTitle$ = "- Main Menu -": dCount% = 6: REDIM dItem%(dCount%), dStartX%(dCount%), dStartY%(dCount%), dInitVal%(dCount%), dMinVal%(dCount%), dMaxVal%(dCount%), dText$(dCount%), dHover$(dCount%), dEndX%(dCount%), dEndY%(dCount%)
dAddI 0, 7, 42, 68, 77, 1, 2, "Quick Game", "Single Board of 16-64 Things"
dAddI 1, 7, 58, 88, 44, 3, 2, "99Things Game", "1-4 Boards of 99 Things"
dAddI 2, 7, 72, 108, 60, 1, 2, "Custom Game", "Play it your way"
dAddI 3, 7, 88, 128, 54, 1, 2, "Records ", "See your achievements"
dAddI 4, 7, 102, 148, 20, 1, 2, "Settings ", "Configure the game"
dAddI 5, 7, 218, 158, 2, 2, 2, "Exit  ", "Quit back to DOS"
dAddI 6, 99, 0, 0, 0, 0, 0, "", "" '99 Garnish

I% = DoDialog%(dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
'Handle Result
SELECT CASE I%
	CASE 5, -1: SCREEN 0: WIDTH 80: CLS : PRINT "Thank you for playing 99Things!": PRINT "Please visit 4am.org/99 for updates": END
	CASE 0: GOTO mnuQG
	CASE 1: GOTO mnu99
	CASE 2: GOTO mnuCG
	CASE 3: DoRecords
	CASE 4: DoSetup
	SELECT CASE ConfigFlag%
		CASE 1: GOTO ApplyConfig
		CASE 2: ConfigFlag% = 1 'Unchanged.
	END SELECT
END SELECT
GOTO mnuMain 'Loop just in-case

mnuQG: LastMenu% = 1 'Quick Game Menu
dTitle$ = "- Quick Game -": dCount% = 5: REDIM dItem%(dCount%), dStartX%(dCount%), dStartY%(dCount%), dInitVal%(dCount%), dMinVal%(dCount%), dMaxVal%(dCount%), dText$(dCount%), dHover$(dCount%), dEndX%(dCount%), dEndY%(dCount%)
dAddI 1, 0, 55, 98, 1, 1, 2, "Smallest - 16 (4x4)|Smaller - 25 (5x5)|Bigger - 36 (6x6)|Largest - 49 (7x7)|SQUARES OF THINGS", "Select size of the quick game board"
dAddI 2, 0, 55, 116, 1, 1, 2, "Easy 1*ROTATE 2*STYLE|Normal 2*ROTATE 3*STYLE|Tricky 3*ROTATE 6*STYLE|Tough 4*ROTATE 9*STYLE|DIFFICULTY", "How difficult the puzzle will be"
dAddI 3, 3, 55, 132, 1, 2, 0, "Timed Game ", "Keep records of the quickest times"
dAddI 4, 3, 55, 148, 1, 3, 0, "Clear things when found (easy) ", "Things disappear when found - VERY EASY"
dAddI 0, 7, 240, 138, 77, 1, 1, "   Start|   Game!", "Start game using settings above"
dAddI 5, 5, 36, 74, 0, 1, 0, "Select game difficulty:", ""
I% = DoDialog%(dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
IF I% = -1 THEN GOTO mnuMain 'Cancel Game Launch

GameType% = 1
BoardMax% = 1 'Always 1 board for Quick Game
RemoveOnFind% = dVal%(4) 'Clear if found?
UseTimer&(0) = dVal%(3) 'Use Timer?
SELECT CASE dVal%(2) 'Apply Rotate, Style, Difficulty Preset
	CASE 0: UseOrientations% = 1: UseDispVar% = 2: GamePreset% = 0
	CASE 1: UseOrientations% = 2: UseDispVar% = 4: GamePreset% = 1
	CASE 2: UseOrientations% = 3: UseDispVar% = 6: GamePreset% = 2
	CASE 3: UseOrientations% = 4: UseDispVar% = 9: GamePreset% = 3
END SELECT

SELECT CASE dVal%(1) 'Choose Board Size & Apply Difficulty (replace later with formula)
	CASE 0: PuzMax% = 15: SELECT CASE dVal%(2): CASE 0: MixBagSize% = 6: CASE 1: MixBagSize% = 8: CASE 2: MixBagSize% = 11: CASE 3: MixBagSize% = 13: END SELECT
	CASE 1: PuzMax% = 24: SELECT CASE dVal%(2): CASE 0: MixBagSize% = 10: CASE 1: MixBagSize% = 14: CASE 2: MixBagSize% = 18: CASE 3: MixBagSize% = 22: END SELECT
	CASE 2: PuzMax% = 35: SELECT CASE dVal%(2): CASE 0: MixBagSize% = 15: CASE 1: MixBagSize% = 20: CASE 2: MixBagSize% = 24: CASE 3: MixBagSize% = 30: END SELECT
	CASE 3: PuzMax% = 48: SELECT CASE dVal%(2): CASE 0: MixBagSize% = 19: CASE 1: MixBagSize% = 25: CASE 2: MixBagSize% = 32: CASE 3: MixBagSize% = 42: END SELECT
END SELECT

QuickGame
GOTO DrawMainScreen 'Return to main menu

mnu99: LastMenu% = 2 '99Things Game Menu
dTitle$ = "- 99THINGS GAME -": dCount% = 5: REDIM dItem%(dCount%), dStartX%(dCount%), dStartY%(dCount%), dInitVal%(dCount%), dMinVal%(dCount%), dMaxVal%(dCount%), dText$(dCount%), dHover$(dCount%), dEndX%(dCount%), dEndY%(dCount%)
dAddI 0, 7, 196, 154, 44, 3, 2, "Start Game!", "Start game using the settings above"
SELECT CASE LowMem% 'For low memory only allow 2 boards
CASE 0: dAddI 1, 0, 36, 88, 0, 0, 0, "SINGLE BOARD|2 BOARDS|3 BOARDS (LARGE!)|4 BOARDS (!HUGE!)|BOARD COUNT", "Play with 2 or more boards for a challenge!"
CASE 1: dAddI 1, 0, 36, 88, 0, 0, 0, "SINGLE BOARD|2 BOARDS|PUZZLE SIZE (99 THINGS MODE ONLY)", "Play with 1 or 2 boards."
END SELECT
dAddI 2, 0, 36, 106, 1, 0, 0, "EASY (15) 1*ROTATE 2*STYLE|NORMAL (30) 2*ROTATE 4*STYLE|TRICKY (45) 3*ROTATE 6*STYLE|TOUGH (65) 4*ROTATE 7*STYLE|INSANE! (90) 4*ROTATE 9*STYLE|DIFFICULTY", "These will increase difficulty"
dAddI 3, 3, 36, 124, 1, 1, 0, "Play a timed game", "Timed game for records keeping"
dAddI 4, 3, 36, 142, 0, 1, 0, "Clear things when found (easier)", "If checked things will disappear when found"
dAddI 5, 5, 28, 70, 0, 3, 0, "Choose game settings", ""
I% = DoDialog%(dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
IF I% = -1 THEN GOTO mnuMain 'Cancel Game Launch
RemoveOnFind% = dVal%(4) 'Clear if found?
UseTimer&(0) = dVal%(3) 'Use Timer?
BoardMax% = dVal%(1) + 1 'Set Boards
GameType% = 2: IF BoardMax% >= 2 THEN GameType% = 3
PuzMax% = (BoardMax% * 99) - 1
SELECT CASE dVal%(2) 'Apply Rotate, Style and Difficulty Preset
	CASE 0: UseOrientations% = 1: UseDispVar% = 2: MixBagSize% = 15: GamePreset% = 0
	CASE 1: UseOrientations% = 2: UseDispVar% = 4: MixBagSize% = 30: GamePreset% = 1
	CASE 2: UseOrientations% = 3: UseDispVar% = 6: MixBagSize% = 45: GamePreset% = 2
	CASE 3: UseOrientations% = 4: UseDispVar% = 7: MixBagSize% = 65: GamePreset% = 3
	CASE 4: UseOrientations% = 4: UseDispVar% = 9: MixBagSize% = 90: GamePreset% = 4
END SELECT
QuickGame
GOTO DrawMainScreen 'Return to main menu

mnuCG: LastMenu% = 3 'Custom Game Menu
dTitle$ = "- CUSTOM GAME -": dCount% = 7: REDIM dItem%(dCount%), dStartX%(dCount%), dStartY%(dCount%), dInitVal%(dCount%), dMinVal%(dCount%), dMaxVal%(dCount%), dText$(dCount%), dHover$(dCount%), dEndX%(dCount%), dEndY%(dCount%)
dAddI 0, 0, 36, 88, 1, 0, 0, "16 (4x4) - 1 BOARD|25 (5x5) - 1 BOARD|36 (6x6) - 1 BOARD|49 (7x7)  - 1 BOARD|64 (8x8) - 1 BOARD|99 THINGS - 1 TO 4 BOARDS|Board Size / Game Mode", "Choose your board size and game mode"
dAddI 1, 1, 38, 106, 12, 5, 97, "DIFFERENT THINGS TO FIND", "Cannot exceed board size"
SELECT CASE LowMem%
CASE 0: dAddI 2, 0, 36, 120, 0, 0, 0, "SINGLE BOARD|2 BOARDS|3 BOARDS (LARGE)|4 BOARDS (HUGE!)|PUZZLE SIZE (99 THINGS MODE ONLY)", "Play with 2 or more boards for a challenge!"
CASE 1: dAddI 2, 0, 36, 120, 0, 0, 0, "SINGLE BOARD|2 BOARDS|PUZZLE SIZE (99 THINGS MODE ONLY)", "Play with 1 or 2 boards."
END SELECT
dAddI 3, 0, 36, 136, 1, 0, 0, "UP (EASY)|UP+LEFT (NORMAL)|UP+LEFT+DOWN (TRICKY)|UP+LEFT+DOWN+RIGHT (HARD)|THING ROTATIONS", "Rotate some things for more of a challenge"
dAddI 4, 1, 36, 152, 6, 2, 9, "THING STYLE VARIATIONS", "Mix up thing colors to make it tricky"
dAddI 5, 3, 36, 164, 1, 1, 0, "Clear things when found (easier)", "If checked things will disappear when found"
dAddI 6, 7, 196, 154, 60, 2, 2, "Start Game!", "Start game using the settings above"
dAddI 7, 5, 28, 70, 0, 3, 0, "Choose the custom game setup", ""
I% = DoDialog%(dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
IF I% = -1 THEN GOTO mnuMain 'Cancel Game Launch
GameType% = 4

IF dVal%(0) = 5 THEN 'Enforce 1 board for non-99 things games
	BoardMax% = dVal%(2) + 1 'Set Boards for 99things
	IF LowMem% = 1 AND BoardMax% > 2 THEN BoardMax% = 2 'Limit
ELSE
	BoardMax% = 1
END IF

RemoveOnFind% = dVal%(5)
UseDispVar% = dVal%(4)
UseOrientations% = dVal%(3) + 1
MixBagSize% = dVal%(1)
SELECT CASE dVal%(0)
CASE 0: PuzMax% = 15
CASE 1: PuzMax% = 24
CASE 2: PuzMax% = 35
CASE 3: PuzMax% = 48
CASE 4: PuzMax% = 63
CASE 5: PuzMax% = (BoardMax * 99) - 1
END SELECT
QuickGame
GOTO DrawMainScreen 'Return to main menu

REM $STATIC
DEFSNG A-Z
SUB CGAPal (UPal%, UCol%)
'CGAPal - Set a CGA Palette
'uPal% = 1-6 - Number of Palette to use
'uCol% = 0-15 - Set a background color to use
'If CGAMode% = 1 then it will use EGA Palette swap to match the colors, CGAMode=2 limits to CGA 4-Pal only
'If NoBlank% = 1 don't CLS - good for background change but might break things
'Credit: YT @MontieMongoose for idea around using the OUT codes to change palette

IF CGAMode% <> 1 AND NoBlank% = 0 THEN : SCREEN 0: SCREEN 1'Reset the CGA Mono/HI Bit

SELECT CASE CGAMode%

CASE 1 'Replicate CGA Pals 1-6 on EGA/VGA
	IF UCol% > -1 THEN PALETTE 0, UCol% 'override with uCol% call
	'Unpack and set
	UseK% = StrSplit%("|", PalX$(UPal%))
	Flag% = 0
	IF UseK% = 3 THEN 'Assuming Valid
		FOR J% = 0 TO 3: PALETTE J%, VAL(SplitWords$(J%)): NEXT J%
	ELSE 'Default
		PALETTE 0, 0: PALETTE 1, 3: PALETTE 2, 5: PALETTE 3, 7
	END IF

CASE 0 'CGA Pals 1-6
	SELECT CASE UPal% 'Use CGA Defined Pals
		CASE 1, 2, 3, 4: OUT 985, ((UPal% - 1) * 16) + UCol%
		CASE 5, 6: OUT 985, ((7 - UPal%) * 16) + UCol%: OUT 984, 46
	END SELECT

CASE 2 'CGA Pals 1-4 only (compat mode)
	SELECT CASE UPal% 'Use CGA Defined Pals
		CASE 1, 2, 3, 4: OUT 985, ((UPal% - 1) * 16) + UCol%
		CASE 5, 6: OUT 985, ((UPal% - 3) * 16) + UCol%
	END SELECT
END SELECT

END SUB

REM $DYNAMIC
DEFINT A-Z
SUB cPrint (UseText$, UseRow%, UseCol%, UseFG%, UseBG%)
'Coloured print routine for standard 8x8 text (UseBG% not implemented yet)
LOCATE UseRow%, UseCol%: PRINT UseText$; : L% = LEN(UseText$): REDIM TempImage%(L% * 22)
GET ((UseCol% - 1) * 8, (UseRow% - 1) * 8)-((UseCol% + L% - 1) * 8, (UseRow% * 8) - 1), TempImage%: LINE ((UseCol% - 1) * 8, (UseRow% - 1) * 8)-((UseCol% + L% - 1) * 8, (UseRow% * 8) - 1), UseFG%, BF
PUT ((UseCol% - 1) * 8, (UseRow% - 1) * 8), TempImage%, AND: GET ((UseCol% - 1) * 8, (UseRow% - 1) * 8)-((UseCol% + L% - 1) * 8, (UseRow% * 8) - 1), TempImage%
END SUB

SUB dAddI (uItem%, udItem%, udStartX%, udStartY%, udInitVal%, udMinVal%, udMaxVal%, udText$, udHover$)
'Dialog Add Item
Item% = uItem%
dItem%(uItem%) = udItem%
dStartX%(uItem%) = udStartX%
dStartY%(uItem%) = udStartY%
dInitVal%(uItem%) = udInitVal%
dMinVal%(uItem%) = udMinVal%
dMaxVal%(uItem%) = udMaxVal%
dText$(uItem%) = udText$
dHover$(uItem%) = udHover$
END SUB

FUNCTION DoDialog% (dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
DoDialog% = -1 'Otherwise return the dItem%(number%) executed

'Simple repeatable dialog with fixed viewport

'Returns: 0 if a button is pressed
'Results are stored in dVal%()
'SelOrder is based on position in dCount%
'1=Slider,2=Slider+-,3=Check,4=iPrint,5=mPrint,6=Button,7=Thing Button,8=Option,9=Thing,10=Input

HideMouse

'Init Menu Window Title Area
LINE (OffSetX% + 2, OffSetY% + 2)-(319 - OffSetX% - 2, OffSetY% + 10), 3, BF
iPrint dTitle$, OffSetX% + 4, OffSetY% + 4, 4, 0

'Clear Viewport
LINE (OffSetX% + 3, OffSetY% + 11)-(319 - OffSetX% - 3, 212 - (OffSetY% / 3) - 14), 0, BF

'Init dVal%() and one-off draws
FOR I% = 0 TO dCount%: IF dItem%(I%) <> 9 THEN dVal%(I%) = dInitVal%(I%)
SELECT CASE dItem%(I%)

	CASE 0 'Chooser
	cCount% = StrSplit%("|", dText$(I%)): cBigLen% = 0 'Perform string split
	FOR UseA% = 0 TO cCount% - 1 'Find biggest choice string
		IF LEN(SplitWords$(UseA%)) > cBigLen% THEN cBigLen% = LEN(SplitWords$(UseA%))
	NEXT UseA%
	       
	'Make surround related to cBigLen%
	AltX% = dStartX%(I%) + (cBigLen% * 4 + 2) + 15 'Calculate Border X
	LINE (dStartX%(I%) + 13, dStartY%(I%) + 1)-(AltX%, dStartY%(I%) + 9), 1, B 'Border Around
	PUT (AltX% + 3, dStartY%(I%)), OtherAsset%(88), PSET: PUT (dStartX%(I%), dStartY%(I%)), OtherAsset%(68), PSET'+- buttons
	iPrint SplitWords$(cCount%), AltX% + 16, dStartY%(I%) + 3, 3, 0 'Caption Text
	dEndX%(I%) = AltX% + 16 + (LEN(SplitWords$(cCount%)) * 4): dEndY%(I%) = dStartY%(I%) + 10
	dMinVal%(I%) = cBigLen%: dMaxVal%(I%) = cCount% - 1: dVal%(I%) = dInitVal%(I%): UseItem% = I%: GOSUB UpdateChoice

	CASE 1 'Slider(s) init
	LINE (dStartX%(I%), dStartY%(I%))-(dStartX%(I%) + 42, dStartY%(I%) + 6), 3, B 'Outside border
	dEndY%(I%) = dStartY%(I%) + 6
	UseItem% = I%: GOSUB UpdateSlider 'dEndX set after text update

	CASE 2 'Slider w +/-
	PUT (dStartX%(I%), dStartY%(I%)), OtherAsset%(68), PSET
	PUT (dStartX%(I%) + 56, dStartY%(I%)), OtherAsset%(88), PSET
	LINE (dStartX%(I%) + 12, dStartY%(I%) + 2)-(dStartX%(I%) + 54, dStartY%(I%) + 8), 3, B'Outside border
	dEndY%(I%) = dStartY%(I%) + 10
	UseItem% = I%: GOSUB UpdateSlider 'dEndX set after text update
       
	CASE 3, 8'Checkbox or Option
	dVal%(I%) = dInitVal%(I%)
	iPrint dText$(I%), dStartX%(I%) + 13, dStartY%(I%) + 3, dMinVal%(I%), dMaxVal%(I%)
	dEndX%(I%) = dStartX%(I%) + 11 + (LEN(dText$(I%)) * 4): dEndY%(I%) = dStartY%(I%) + 10
	UseItem% = I%: GOSUB UpdateRadioCheck
      
	CASE 4: iPrint dText$(I%), dStartX%(I%), dStartY%(I%), dMinVal%(I%), dMaxVal%(I%)  'Text Output
       
	CASE 5: mPrint dText$(I%), dStartX%(I%), dStartY%(I%), dMinVal%(I%), dMaxVal%(I%)  'Big Text Output

	CASE 6 'Button
	LenX% = (LEN(dText$(I%)) * 4) + 2: LINE (dStartX%(I%) - 2, dStartY%(I%) - 2)-(dStartX%(I%) + LenX% + 2, dStartY%(I%) + 10), 3, B
	LINE (dStartX%(I%), dStartY%(I%))-(dStartX%(I%) + LenX%, dStartY%(I%) + 8), 3, BF
	iPrint dText$(I%), dStartX%(I%) + 2, dStartY%(I%) + 2, 1, 1
	dEndX%(I%) = dStartX%(I%) + LenX%: dEndY%(I%) = dStartY%(I%) + 8

	CASE 7 'Thing Button [dMaxVal%()=1|2 mFont below|right]
	IF dInitVal%(I%) > -1 THEN 'Put/Decorate Button based on dMinVal%()
		LINE (dStartX%(I%) + 2, dStartY%(I%) + 2)-(dStartX%(I%) + 17, dStartY%(I%) + 17), dMinVal%(I%), BF
		PPUT dStartX%(I%) + 1, dStartY%(I%) + 1, dInitVal%(I%), 3
	END IF
	SELECT CASE dMaxVal%(I%)
		CASE 1 'mFont Below Centre Justify
		tStartX% = dStartX%(I%): dEndX%(I%) = dStartX%(I%) + 22
		wCount% = StrSplit%("|", dText$(I%)): dEndY%(I%) = dStartY%(I%) + 22 + (wCount% * 16)
		FOR UseZ% = 0 TO wCount% 'Do 1 or 2 lines centre justified with expanded selection areas
			L% = LEN(SplitWords$(UseZ%)): tPos% = tStartX% + 3 - (L% * 2.75)
			mPrint SplitWords$(UseZ%), tPos%, dStartY%(I%) + 22 + (UseZ% * 8), 3, 0
			IF tPos% < dStartX%(I%) THEN dStartX%(I%) = tPos%  'Re-adj Sel StartX
			IF tPos% + (L% * 6) > dEndX%(I%) THEN dEndX%(I%) = tPos% + (L% * 6) + 8
		NEXT UseZ%

		CASE 2 'mFont Right Justify
		mPrint dText$(I%), dStartX%(I%) + 19, dStartY%(I%) + 7, 3, 0
		dEndY%(I%) = dStartY%(I%) + 19: dEndX%(I%) = dStartX%(I%) + 19 + (LEN(dText$(I%)) * 6.5)
	END SELECT
		dEndY%(I%) = dEndY%(I%) - 2: dStartY%(I%) = dStartY%(I%) + 2 'Little Adjustment here

	CASE 9 'Thing Image
	IF dMinVal%(I%) > -1 THEN LINE (dStartX%(I%), dStartY%(I%))-(dStartX%(I%) + 18, dStartY%(I%) + 18), dMinVal%(I%), B
	IF dMaxVal%(I%) > -1 THEN LINE (dStartX%(I%) + 1, dStartY%(I%) + 1)-(dStartX%(I%) + 17, dStartY%(I%) + 17), dMaxVal%(I%), BF
	IF dInitVal%(I%) > -1 THEN PPUT dStartX%(I%) + 1, dStartY%(I%) + 1, dInitVal%(I%), VAL(dHover$(I%))

	CASE 10 'InputBox [dInitVal%() = 1=A-Z,2=0-9,3=A-9,4=A-Z+SPC, 5=A-9+SPC]

	CASE 99 'Garnish
		iPrint "A FIND A THING GAME", OffSetX% + 192, OffSetY% + 13, 1, 0
		iPrint "(2025)", OffSetX% + 182, OffSetY% + 19, 2, 0
		iPrint "4am Programming", OffSetX% + 208, OffSetY% + 19, 3, 0
		iPrint "4am.org/99", OffSetX% + 228, OffSetY% + 25, 3, 0
		FOR X% = 1 TO 2: PUT (OffSetX% + 190 + (X% * 19), OffSetY% + 5 + (X% * 33)), OtherAsset%(188), PSET: NEXT X%

END SELECT


NEXT I%

PrvSel%(4) = -1: CurSel%(4) = 0: dSelCount% = -1'Reset Cur/Prev Sel

'Create List of Selectable Itemns
REDIM dSelList%(dCount%)
FOR UseA% = 0 TO dCount%
SELECT CASE dItem%(UseA%)
CASE 0, 1, 2, 3, 6, 7, 8, 10: dSelCount% = dSelCount% + 1: dSelList%(dSelCount%) = UseA%: END SELECT: NEXT UseA%
IF dSelCount% = -1 THEN EXIT FUNCTION 'Fail out in case dialog has no selectable items

'End of dialog setup

IF UseMouse% = 1 THEN Mouse 0
GOSUB dUpdateSel 'Make first selection

DialogKey:
IF UseMouse% = 1 THEN Mouse 1
'Wait for key or mouse press
DO: uKey$ = INKEY$
IF UseMouse% = 1 THEN 'Capture Mouse Input
    Mouse 3: IF B% = 0 THEN mButtonUP% = 1 'React to button press
    IF B% = 1 AND mButtonUP% > 0 THEN 'Capture Click Event
	mButtonUP% = 0 'Reset to stop hold-down clicking events
	UseH% = H% / 2 'Halve the mouseX
	FOR I% = 0 TO dCount% 'Did we click a selectable item?
		IF UseH% >= dStartX%(I%) AND UseH% <= dEndX%(I%) AND V% >= dStartY%(I%) AND V% <= dEndY%(I%) THEN
		FOR UseA% = 0 TO dSelCount% 'Hunt & Select Item
			IF dSelList%(UseA%) = I% THEN : PrvSel%(4) = CurSel%(4): CurSel%(4) = UseA%: GOSUB dUpdateSel: EXIT FOR
		NEXT UseA%
		SELECT CASE dItem%(I%)
			CASE 6, 7: DoDialog% = I%: EXIT FUNCTION 'Buttons execute dialog
			CASE 0 'Update Chooser
			PlusX% = 19 + (dMinVal%(I%) * 4)
		       
			SELECT CASE UseH% - dStartX%(I%) '- or + ?
				CASE IS <= 10
				IF dVal%(I%) > 0 THEN
					dVal%(I%) = dVal%(I%) - 1
					UseItem% = I%
					GOSUB UpdateChoice
				END IF
				CASE PlusX% TO PlusX% + 11
				IF dVal%(I%) < dMaxVal%(I%) THEN
					dVal%(I%) = dVal%(I%) + 1
					UseItem% = I%
					GOSUB UpdateChoice
				END IF
			END SELECT

			CASE 1 'Update Slider1
			mButtonUP% = 1 'Enable repeat button hold down
			ClickX% = UseH% - dStartX%(I%)
			SELECT CASE ClickX%
				CASE 1 TO 40 'Use Floating poin
				dd! = dMaxVal%(I%) / 40: dVal%(I%) = INT(ClickX% * dd!) + 1: IF dVal%(I%) > dMaxVal%(I%) THEN dVal%(I%) = dMaxVal%(I%)
				IF dVal%(I%) < dMinVal%(I%) THEN dVal%(I%) = dMinVal%(I%)
				GOSUB UpdateSlider
			END SELECT
			uSleep .05 'small delay for effect

			CASE 2 'Update Slider2
			mButtonUP% = 1 'Enable repeat button hold down
			ClickX% = UseH% - dStartX%(I%)
			SELECT CASE ClickX%
				CASE 0 TO 12 'Minus
					IF dVal%(I%) > dMinVal%(I%) THEN dVal%(I%) = dVal%(I%) - 1: GOSUB UpdateSlider
				CASE 13 TO 54
					dd! = dMaxVal%(I%) / 40: dVal%(I%) = INT((ClickX% - 13) * dd!) + 1: IF dVal%(I%) > dMaxVal%(I%) THEN dVal%(I%) = dMaxVal%(I%)
					GOSUB UpdateSlider
				CASE 56 TO 66 'Plus
					IF dVal%(I%) < dMaxVal%(I%) THEN dVal%(I%) = dVal%(I%) + 1: GOSUB UpdateSlider
			END SELECT
			uSleep .05 'small delay for effect

			CASE 3 'Update Checkbox
			SELECT CASE dVal%(I%)
			CASE 0: dVal%(I%) = 1: GOSUB UpdateRadioCheck
			CASE 1: dVal%(I%) = 0: GOSUB UpdateRadioCheck
			END SELECT
			
			CASE 8: GOSUB SelRadio 'Update Radio
		END SELECT
		END IF
	NEXT I%
    END IF
END IF: LOOP WHILE uKey$ = ""

SELECT CASE uKey$  'Process Keyboard Navigation
CASE CHR$(27), CHR$(0) + CHR$(68): DoDialog% = -1: EXIT FUNCTION 'ESC or F10

CASE CHR$(0) + CHR$(72), "W", "w" 'UP
PrvSel%(4) = CurSel%(4)
CurSel%(4) = CurSel%(4) - 1
IF CurSel%(4) < 0 THEN CurSel%(4) = dSelCount%
GOSUB dUpdateSel

CASE CHR$(0) + CHR$(80), "S", "s", CHR$(9)'DOWN (TAB)
PrvSel%(4) = CurSel%(4)
CurSel%(4) = CurSel%(4) + 1
IF CurSel%(4) > dSelCount% THEN CurSel%(4) = 0
GOSUB dUpdateSel

CASE CHR$(0) + CHR$(75), "A", "a", "-"'LEFT
	I% = dSelList%(CurSel%(4)) 'For updater GOSUBs
	SELECT CASE dItem%(dSelList%(CurSel%(4)))
		CASE 0: IF dVal%(I%) > 0 THEN dVal%(I%) = dVal%(I%) - 1: UseItem% = I%: GOSUB UpdateChoice
		CASE 1, 2: IF dVal%(I%) > dMinVal%(I%) THEN dVal%(I%) = dVal%(I%) - 1: UseItem% = I%: GOSUB UpdateSlider
	END SELECT

CASE CHR$(0) + CHR$(77), "D", "d", "+"'RIGHT
	I% = dSelList%(CurSel%(4)) 'For updater GOSUBs
	SELECT CASE dItem%(dSelList%(CurSel%(4)))
		CASE 0, 1, 2:
		IF dVal%(I%) < dMaxVal%(I%) THEN
			dVal%(I%) = dVal%(I%) + 1: UseItem% = I%
			SELECT CASE dItem%(dSelList%(CurSel%(4)))
			CASE 0: GOSUB UpdateChoice
			CASE 1, 2: GOSUB UpdateSlider
			END SELECT
		END IF
	END SELECT

CASE CHR$(13), CHR$(32)'ENTER or SPACE 'Duplicate some of the click routines here..
	I% = dSelList%(CurSel%(4)) 'For updater GOSUBs
	SELECT CASE dItem%(dSelList%(CurSel%(4)))
	CASE 6, 7: DoDialog% = I%: EXIT FUNCTION
	CASE 8: GOSUB SelRadio
	CASE 3: SELECT CASE dVal%(I%): CASE 0: dVal%(I%) = 1: GOSUB UpdateRadioCheck: CASE 1: dVal%(I%) = 0: GOSUB UpdateRadioCheck: END SELECT
	END SELECT

'CASE "p", "P"
'LOCATE 1, 1: PRINT FRE(" "); FRE(-2); FRE(-1); FRE(0);

END SELECT

GOTO DialogKey 'Loop around

'-----Internal GOSUBs
SelRadio:
FOR UseC% = 0 TO dCount% 'Deselect other options
	SELECT CASE dItem%(UseC%)
	CASE 8 'Scope Option Items
	IF UseC% <> I% AND dVal%(UseC%) <> 0 THEN
		dVal%(UseC%) = 0: OldI% = I%: I% = UseC% 'Swap and Deselect
		GOSUB UpdateRadioCheck
		I% = OldI% 'Swap back for select
	END IF
	END SELECT
NEXT UseC%
dVal%(I%) = 1: GOSUB UpdateRadioCheck 'Select
RETURN

dUpdateSel: 'Update Selected Items + Hover
HideMouse
FOR UseA% = 0 TO dSelCount% 'Check all selectable items
IF PrvSel%(4) <> CurSel%(4) THEN
	IF PrvSel%(4) > -1 THEN 'Try to deselect something
		UseC% = 0: SELECT CASE dItem%(dSelList%(PrvSel%(4))): CASE 6: UseC% = 3: END SELECT 'BG for all but buttons which get a white background
		LINE (dStartX%(dSelList%(PrvSel%(4))) - 2, dStartY%(dSelList%(PrvSel%(4))) - 2)-(dEndX%(dSelList%(PrvSel%(4))) + 2, dEndY%(dSelList%(PrvSel%(4))) + 2), UseC%, B
	END IF
	LINE (dStartX%(dSelList%(CurSel%(4))) - 2, dStartY%(dSelList%(CurSel%(4))) - 2)-(dEndX%(dSelList%(CurSel%(4))) + 2, dEndY%(dSelList%(CurSel%(4))) + 2), 2, B
END IF
NEXT UseA%

'Update Hover
IF PrvSel%(4) <> CurSel%(4) THEN
	IF dHover$(dSelList%(CurSel%(4))) <> "" THEN
	UseY% = 209 - (OffSetY% / 4) - 16
	LINE (OffSetX% + 3, UseY%)-(319 - OffSetX% - 3, UseY% + 9), 2, BF
	mPrint dHover$(dSelList%(CurSel%(4))), OffSetX% + 3, UseY% + 1, 3, 0
	END IF
END IF

IF UseMouse% = 1 THEN   'Cursor Mouse
	Mouse 1: Regs.AX = 4: Regs.CX = (dEndX%(dSelList%(CurSel%(4))) - 2) * 2: Regs.DX = dEndY%(dSelList%(CurSel%(4))) - 2
	IF B% = 0 THEN INTERRUPT &H33, Regs, Regs 'Only if initiated by key
END IF
RETURN

UpdateChoice: 'Update dItem%(0) Chooser
HideMouse
LINE (dStartX%(UseItem%) + 16, dStartY%(UseItem%) + 3)-(dStartX%(UseItem%) + 16 + (dMinVal%(UseItem%) * 4), dStartY%(UseItem%) + 8), 0, BF 'Clear
UseK% = StrSplit%("|", dText$(UseItem%))
iPrint SplitWords$(dVal%(UseItem%)), dStartX%(UseItem%) + 16, dStartY%(UseItem%) + 3, 1, 0
IF dVal%(UseItem%) <= dMaxVal%(UseItem%) THEN
	uSeg! = (2 + (dMinVal%(UseItem%) * 4)) / (dMaxVal%(UseItem%) + 1)
	LINE (13 + dStartX%(UseItem%), dStartY%(UseItem%) + 1)-(13 + dStartX%(UseItem%) + (4 + (dMinVal%(UseItem%) * 4)), dStartY%(UseItem%) + 1), 1
	LINE (14 + dStartX%(UseItem%) + (uSeg! * (dVal(UseItem%))), dStartY%(UseItem%) + 1)-(13 + dStartX%(UseItem%) + (uSeg! * (dVal%(UseItem%) + 1)), dStartY%(UseItem%) + 1), 2
	LINE (13 + dStartX%(UseItem%), dStartY%(UseItem%) + 9)-(13 + dStartX%(UseItem%) + (4 + (dMinVal%(UseItem%) * 4)), dStartY%(UseItem%) + 9), 1
	LINE (14 + dStartX%(UseItem%) + (uSeg! * (dVal(UseItem%))), dStartY%(UseItem%) + 9)-(13 + dStartX%(UseItem%) + (uSeg! * (dVal%(UseItem%) + 1)), dStartY%(UseItem%) + 9), 2
END IF
ShowMouse
'TODO: Make a choice indicator ->  cCount% - 1; cBigLen%; dVal%(UseItem%);
RETURN

UpdateSlider: 'Update dItem%() 1 and 2 sliders
HideMouse
UseItem% = I%
SELECT CASE dItem%(UseItem%): CASE 1: AddLX% = 48: CASE 2: AddLX% = 70: END SELECT
uText$ = LTRIM$(STR$(dVal%(UseItem%))): IF LEN(uText$) = 1 THEN uText$ = " " + uText$
uText$ = uText$ + " " + dText$(UseItem%)
dEndX%(UseItem%) = dStartX%(UseItem%) + AddLX% + (LEN(uText$) * 4) - 1: tPosX% = AddLX%
SELECT CASE dItem%(UseItem%): CASE 1: AddLX% = 0: AddlY% = 0: CASE 2: AddlY% = 2: AddLX% = 12: END SELECT
iPrint uText$, tPosX% + dStartX%(UseItem%), AddlY% + dStartY%(UseItem%) + 1, 1, 0'Display Text
LINE (dStartX%(UseItem%) + AddLX% + (dVal%(UseItem%) * (40 / dMaxVal%(UseItem%)) + 1), AddlY% + dStartY%(UseItem%) + 1)-(AddLX% + dStartX%(UseItem%) + 41, AddlY% + dStartY%(UseItem%) + 5), 0, BF
LINE (dStartX%(UseItem%) + 1 + AddLX%, AddlY% + dStartY%(UseItem%) + 1)-(AddLX% + dStartX%(UseItem%) + (dVal%(UseItem%) * (40 / dMaxVal%(UseItem%)) + 1), AddlY% + dStartY%(UseItem%) + 5), 1, BF'Fill

ShowMouse
RETURN

UpdateRadioCheck: 'Update checked/unchecked or selected
	UseItem% = I%
	SELECT CASE dItem%(UseItem%) 'Select Image
		CASE 3: SELECT CASE dVal%(UseItem%): CASE 0: UseA% = 48: CASE 1: UseA% = 28: END SELECT'Default Setting
		CASE 8: SELECT CASE dVal%(UseItem%): CASE 0: UseA% = 108: CASE 1: UseA% = 128: END SELECT'Default Setting
	END SELECT
	HideMouse
	PUT (dStartX%(UseItem%), dStartY%(UseItem%)), OtherAsset%(UseA%), PSET
	ShowMouse
RETURN


END FUNCTION

SUB DrawPattern (UsePattern%, StartX%, StartY%, EndX%, EndY%, DrawStyle%)
'UsePattern% - Number for inbuilt pattern
'Ignore StartX%,StartY%,EndX%,EndY% for now
'DrawStyle% - 1=PSET, 2=PRESET [later 3+=FG/BG combo]
UseU% = UsePattern% * 45 'Reduce Calculations 12042025
SELECT CASE DrawStyle% 'Fill First Row then GET/PUT
	CASE 1: FOR UseX% = 0 TO 18: PUT (UseX% * 16, 0), Pattern%(UseU%), PSET: NEXT UseX%
	CASE 2: FOR UseX% = 0 TO 18: PUT (UseX% * 16, 0), Pattern%(UseU%), PRESET: NEXT UseX%
END SELECT
REDIM Screener%(128): GET (0, 0)-(15, 16), Screener%: PUT (304, 0), Screener%, PSET'trim the last one from top row
REDIM Screener%(1200): GET (0, 0)-(319, 15), Screener%
FOR UseY% = 1 TO 11: PUT (0, (UseY% * 16)), Screener%, PSET: NEXT UseY%'Fill rows
GET (0, 0)-(319, 7), Screener%: PUT (0, 192), Screener%, PSET 'last row
ERASE Screener% 'Added 12042025

END SUB

SUB HideMouse
IF UseMouse% = 1 THEN Mouse 2
END SUB

SUB iPrint (uText$, StartX%, StartY%, UseFG%, UseBG%)
'Image based print using SmallFont%
'UseBG% not fully supported yet - just does a PRESET
uText$ = UCASE$(uText$): LText% = LEN(uText$)
SELECT CASE UseFG%
CASE 4 'Faster Preset
	FOR UChar% = 1 TO LText%
		UseX% = StartX% + ((UChar% - 1) * 4): PUT (UseX%, StartY%), SmallFont%((ASC(MID$(uText$, UChar%, 1)) - 32) * 9), XOR
	NEXT UChar%
CASE IS < 3
	FOR UChar% = 1 TO LText% 'Do LINE then PUT to eliminate blank line draw on slower PCs
		UseX% = StartX% + ((UChar% - 1) * 4): LINE (UseX%, StartY%)-(UseX% + 3, StartY% + 4), UseFG%, BF'Use w/ PUT AND to set FG
		PUT (UseX%, StartY%), SmallFont%((ASC(MID$(uText$, UChar%, 1)) - 32) * 9), AND
	NEXT UChar%
CASE 3  'Just use 3,0 for speed
	FOR UChar% = 1 TO LText%: PUT (StartX% + ((UChar% - 1) * 4), StartY%), SmallFont%((ASC(MID$(uText$, UChar%, 1)) - 32) * 9), PSET: NEXT UChar%
END SELECT

SELECT CASE UseBG%
CASE 1 TO 5
	REDIM TempImage%(128)
	GET (StartX%, StartY%)-(StartX% + (LText% * 4) - 1, StartY% + 4), TempImage%
	SELECT CASE UseBG%
	CASE 1: PUT (StartX%, StartY%), TempImage%, PRESET
	CASE 2: PUT (StartX%, StartY%), TempImage%, AND
	CASE 3: PUT (StartX%, StartY%), TempImage%, XOR
	END SELECT
END SELECT

END SUB

SUB LimitMouseXY (StartX%, StartY%, EndX%, EndY%)
	'Limit mouse to movement (x and y pixels)
	Regs.AX = 7: Regs.CX = StartX * 2: Regs.DX = EndX% * 2: INTERRUPT &H33, Regs, Regs 'Restrict Mouse X
	Regs.AX = 8: Regs.CX = StartY%: Regs.DX = EndY%: INTERRUPT &H33, Regs, Regs   'Restrict Mouse X
END SUB

FUNCTION LoadFX (FileName$)

'Routine to load a SND file created in SOUNDLAB
'Credit: LoadFX from SOUNDLAB play app
F = FREEFILE
OPEN FileName$ FOR BINARY AS #F
IF LOF(1) = 0 THEN LoadFX = 0: CLOSE #1: EXIT FUNCTION
DIM ID AS STRING * 4
GET #F, , ID
IF MID$(ID, 1, 2) <> "SL" THEN LoadFX = 1: CLOSE #F: EXIT FUNCTION
IF MID$(ID, 3, 2) <> "10" THEN LoadFX = 2: CLOSE #F: EXIT FUNCTION
GET #F, , NumSound
REDIM Snd(1 TO NumSound) AS STRING * 30
FOR I% = 1 TO NumSound: GET #F, , Snd(I%): Temp$ = SPACE$(20): GET #F, , Temp$: NEXT I%
CLOSE #F: LoadFX = -1

END FUNCTION

SUB LoadThingDef
'Load thing definitions file
F% = FREEFILE: OPEN "THINGS.DEF" FOR INPUT AS #F
UseC% = 0
DO: LINE INPUT #F, ThingDef$(UseC%): UseC% = UseC% + 1: IF EOF(F) THEN EXIT DO
LOOP
CLOSE #F
END SUB

SUB Mouse (IState%)
'Credit: https://stanislavs.org/helppc/int_33.html
'IState%; 0 = Reset Mouse, 1 = Show, Mouse 2 = Hide , Mouse 3 = Read
Regs.AX = IState%: INTERRUPT &H33, Regs, Regs
B% = Regs.BX: H% = Regs.CX: V% = Regs.DX
END SUB

SUB mPrint (uText$, StartX%, StartY%, UseFG%, UseBG%)
LText% = LEN(uText$)
'Image print with medium font
FOR UChar% = 1 TO LText%
	UseSpace% = ASC(MID$(uText$, UChar%, 1)) - 32
	SELECT CASE UseSpace%
	CASE 0: CurX% = CurX% + 3: PUT (StartX% + CurX% + 2, StartY%), mFont%(0), OR
	CASE IS > 0:  CurX% = CurX% + 6: PUT (StartX% + CurX%, StartY%), mFont%(UseSpace% * 10), OR
	END SELECT
NEXT UChar%
IF UseBG% = 0 AND UseFG% = 3 THEN EXIT SUB 'Post Processing for everything after 3 over 0

CurX% = CurX% - 2 'Trim space at end
UseU% = StartX% + 6: UseT% = StartY% + 7 'Calc once 12042025
REDIM TempImage%(400): GET (UseU%, StartY%)-(UseU% + CurX%, StartY% + 7), TempImage%(0)
SELECT CASE UseBG%
	CASE 0: LINE (UseU%, StartY%)-(UseU% + CurX%, StartY% + 7), UseFG%, BF: PUT (UseU%, StartY%), TempImage%, AND    'Use Background 0
	CASE 1 'Background 1
	SELECT CASE UseFG%
		CASE 0
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 1, BF: PUT (UseU%, StartY%), TempImage%, AND
			GET (UseU%, StartY%)-(UseU% + CurX%, UseT%), TempImage%(0)
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 1, BF: PUT (UseU%, StartY%), TempImage%, XOR
		CASE 2: LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 1, BF: PUT (UseU%, StartY%), TempImage%, XOR
		CASE 3: LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 1, BF: PUT (UseU%, StartY%), TempImage%, OR
       
	END SELECT
	CASE 2
	SELECT CASE UseFG%
		CASE 0
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 2, BF: PUT (UseU%, StartY%), TempImage%, AND
			GET (UseU%, StartY%)-(UseU% + CurX%, UseT%), TempImage%(0)
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 2, BF: PUT (UseU%, StartY%), TempImage%, XOR
		CASE 1: LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 2, BF: PUT (UseU%, StartY%), TempImage%, XOR
		CASE 3: LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 2, BF: PUT (UseU%, StartY%), TempImage%, OR
	END SELECT

	CASE 3
	SELECT CASE UseFG%
		CASE 0: PUT (UseU%, StartY%), TempImage%, PRESET
	      
		CASE 1, 2
		IF UseFG% = 1 THEN 'Invert based on colour choice
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 2, BF
		ELSE
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 1, BF
		END IF
		PUT (UseU%, StartY%), TempImage%, AND: GET (UseU%, StartY%)-(UseU% + CurX%, UseT%), TempImage%(0)
		LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 3, BF: PUT (UseU%, StartY%), TempImage%, XOR
	      
		CASE 3
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 1, BF: PUT (UseU%, StartY%), TempImage%, AND
			GET (UseU%, StartY%)-(UseU% + CurX%, UseT%), TempImage%(0)
			LINE (UseU%, StartY%)-(UseU% + CurX%, UseT%), 3, BF: PUT (UseU%, StartY%), TempImage%, PRESET
	END SELECT
END SELECT
END SUB

SUB PlayFX (Num%)
IF UseAdlib% = 0 THEN EXIT SUB 'dont try to play if adlib's disabled
'Play previously loaded SOUNDLAB Adlib FX (ignoring delays)
FOR XI% = 1 TO 15
	OUT &H388, ASC(MID$(Snd(Num%), (XI% * 2) - 1, 1))
	OUT &H389, ASC(MID$(Snd(Num%), (XI% * 2)))
NEXT XI%
END SUB

SUB PPUT (UseX%, UseY%, UseThing%, Style%)
'Thing put
SELECT CASE Style
CASE 1: PUT (UseX%, UseY%), Thing%(UseThing% * 45), PSET
CASE 2: PUT (UseX%, UseY%), Thing%(UseThing% * 45), XOR
CASE 3: PUT (UseX%, UseY%), Thing%(UseThing% * 45), AND
CASE 4: PUT (UseX%, UseY%), Thing%(UseThing% * 45), PRESET
CASE 5: PUT (UseX%, UseY%), Thing%(UseThing% * 45), OR
END SELECT
END SUB

SUB RandomPal

PalSels% = 0 'Only first choice pals
SELECT CASE CGAMode%
CASE 0, 2: Flag% = 1
CASE 1
	IF UseExtendedPal% = 1 THEN
		Flag% = 2 'EGA w/ Extended Pals
	ELSE
		Flag% = 1 'Stick to Standard Pals
	END IF
END SELECT

RANDOMIZE TIMER
REDIM CPal%(7): REDIM CCol%(7)
CPal%(0) = 2: CCol%(0) = 9: CPal%(1) = 2: CCol%(1) = 5
CPal%(2) = 2: CCol%(2) = 8: CPal%(3) = 5: CCol%(3) = 1
CPal%(4) = 6: CCol%(4) = 1: CPal%(5) = 6: CCol%(5) = 5
CPal%(6) = 6: CCol%(6) = 8: CPal%(7) = 6: CCol%(7) = 9
SELECT CASE Flag%

'NoHiPals% - 0-Default, 1-Only use 1,3,[5] and if CGAMode% = 1 dont use anything with >9 as a color

CASE 1 'Standard Pals
	SELECT CASE NoHiPals%
		CASE 0
			UseA% = INT(RND * 7): CGAPal CPal%(UseA%), CCol%(UseA%) 'Standard Randomness..
		CASE 1  'Choose only low pals 1,3 or 5
			SELECT CASE CGAMode%: CASE 0: MaxPal% = 4: CASE 2: MaxPal% = 3: END SELECT'3 Pals for Extended CGA, 2 Pals for Compat
			UseA% = INT(RND * MaxPal%)
			SELECT CASE UseA%: CASE 1: UseP% = 1: CASE 2: UseP% = 3: CASE 4: UseP% = 5: END SELECT
			CGAPal UseP%, CCol%(UseP%)
	END SELECT
CASE 2 'Extended Pals 'NoHiPals% to be implemeted here later. For now just edit PALX.CGA
	UseA% = INT(RND * PalXCount%): CGAPal UseA%, -1 'Extended Mode
END SELECT


END SUB

SUB ShowMouse
IF UseMouse% = 1 THEN Mouse 1
END SUB

FUNCTION StrSplit% (uSplitBy$, uText$) 'Split uText$ by uSplitBy$ return count to StrSplit%
REDIM SplitWords$(64)
UseZ% = -1: UseL% = LEN(uText$)
UseQ% = INSTR(1, uText$, uSplitBy$)
IF UseQ% = 0 THEN EXIT FUNCTION
UseZ% = UseZ% + 1: SplitWords$(UseZ%) = LEFT$(uText$, UseQ% - 1) 'Get First value
DO
	CurPos% = UseQ% + 1: UseQ% = INSTR(CurPos%, uText$, uSplitBy$)
	UseZ% = UseZ% + 1: IF UseQ% = 0 THEN : SplitWords$(UseZ%) = RIGHT$(uText$, UseL% - CurPos% + 1): EXIT DO
	SplitWords$(UseZ%) = MID$(uText$, CurPos%, UseQ% - CurPos%)
LOOP UNTIL UseQ% = 0
StrSplit% = UseZ%
END FUNCTION

SUB uSleep (Waiter!)
	TIMER ON
	Start! = TIMER + Waiter!: DO: LOOP UNTIL TIMER > Start!
	TIMER OFF
END SUB

