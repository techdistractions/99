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
COMMON SHARED PrevPuzMajor%, PrevTarMajor%, PalXCount%, UseExtendedPal%
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
'NoBlank% - Don't attempt to reset CGA Mono/HI bit [0 Disable, 1 Enable]
'UseAdlib% - Flag to use or not use adlib for sound effects [0-1]. Port hardcoded to &H388/&H389 for now.
'UseMouse% - Enable Mouse Polling/Input [0 Disable, 1 Enable]
'UsePCSpk% - Play music and sound effects through PC Speaker [0-1] (if UseAdlib% = 0)
'ConfigFlag% - 0 None 1 Loaded
'LowMem% - Flag for <64KB free memory after assets loaded. Limit to 2 boards

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

SUB ApplySetting (useInput$)
'Simple read and apply setting usually read from CONFIG.DAT

useInput$ = UCASE$(RTRIM$(LTRIM$(useInput$))) 'Get rid of trails and case
L% = LEN(useInput$)

'Fail rules
IF L% < 9 THEN EXIT SUB'Ignore - too small of a string
IF LEFT$(useInput$, 1) = ";" THEN EXIT SUB
UseK% = INSTR(1, useInput$, "=")
IF UseK% = 0 THEN EXIT SUB 'Not a parm
useParm$ = LEFT$(useInput$, UseK% - 1)
useVal% = VAL(RIGHT$(useInput$, (L% - (UseK%))))

SELECT CASE useParm$  'Apply the setting (no validation)
	CASE "USEMOUSE%": UseMouse% = useVal%
	CASE "CGAMODE%": CGAMode% = useVal%
	CASE "USEADLIB%": UseAdlib% = useVal%
	CASE "USEPCSPK%": UsePCSpk% = useVal%
	CASE "NOBLANK%": NoBlank% = useVal%
	CASE "LOWMEM%": LowMem% = useVal%
	CASE "USEEXTENDEDPAL%": UseExtendedPal% = useVal%
END SELECT


END SUB

SUB DoRecords
'Display Records saved in RECORDS.DAT

HideMouse

'Init Menu Window Title Area
dTitle$ = "- Best Timed Records -"
LINE (OffSetX% + 2, OffSetY% + 2)-(319 - OffSetX% - 2, OffSetY% + 10), 3, BF
iPrint dTitle$, OffSetX% + 4, OffSetY% + 4, 4, 0

'Clear Viewport

LINE (OffSetX% + 3, OffSetY% + 11)-(319 - OffSetX% - 3, 220 - (OffSetY% / 3) - 14), 0, BF
UseP% = 0

'Loading message
cPrint "Loading Records...", 9, 10, 1, 0
REDIM uRecs$(180)
F = FREEFILE: OPEN "RECORDS.DAT" FOR INPUT AS #F
UseC% = 0
DO
LINE INPUT #F, uRecs$(UseC%): UseC% = UseC% + 1
IF EOF(F) THEN EXIT DO
LOOP
CLOSE #F

cPrint "LT/RT Change Game - ESC Quits", 23, 5, 2, 0

ChangeID:
Text$ = "<" + GetGameID$(UseP%) + ">"
L% = LEN(Text$): Text$ = Text$ + STRING$(27 - L%, " ")
cPrint Text$, 9, 10, 1, 0
cPrint "Game", 9, 5, 2, 0

FOR X% = UseP% TO UseP% + 4
	LOCATE 12 + ((X% - UseP%) * 2), 5: PRINT LTRIM$(STR$((X% - UseP%) + 1)); " ";

GetSplit% = StrSplit%("|", uRecs$(X%))
Text$ = "NO RECORD"
IF GetSplit% = 5 THEN
IF SplitWords$(1) <> "!99THINGS!" THEN Text$ = SplitWords$(1) + STRING$(10 - LEN(SplitWords$(1)), " ") + " " + SecsToTime$(VAL(SplitWords$(2)), 1) + " S:" + SplitWords$(4) + " E:" + SplitWords$(5)
END IF
L% = LEN(Text$): IF L% < 29 THEN Text$ = Text$ + STRING$(29 - L%, " ")
PRINT Text$;
NEXT X%

DoRecordsKey:
UKey$ = "": DO: UKey$ = INKEY$: LOOP WHILE UKey$ = ""
SELECT CASE UKey$
	CASE CHR$(27): ERASE uRecs$: EXIT SUB
	CASE CHR$(0) + CHR$(75), "a", "A": IF UseP% >= 5 THEN : UseP% = UseP% - 5: GOTO ChangeID
	CASE CHR$(0) + CHR$(77), "d", "D": IF UseP% <= 170 THEN : UseP% = UseP% + 5: GOTO ChangeID
END SELECT
GOTO DoRecordsKey

END SUB

SUB DoSetup
'Setup program

SELECT CASE CGAMode% 'Select current mode
	CASE 0: ModeB% = 1
	CASE 2: ModeA% = 1
	CASE 1: ModeC% = 1
END SELECT

'Check Audio
Audio% = 1 'Default to PC Speaker
IF UseAdlib% = 1 THEN
	Audio% = 2
ELSE
    IF UsePCSpk% = 0 THEN Audio% = 0
END IF


dTitle$ = "- SETTINGS -": dCount% = 12: REDIM dItem%(dCount%), dStartX%(dCount%), dStartY%(dCount%), dInitVal%(dCount%), dMinVal%(dCount%), dMaxVal%(dCount%), dText$(dCount%), dHover$(dCount%), dEndX%(dCount%), dEndY%(dCount%)
dAddI 0, 3, 36, 65, UseMouse%, 3, 0, "Enable Mouse Input", "Use mouse for menu and game"
dAddI 1, 8, 76, 81, ModeA%, 3, 0, "CGA (Compatible) - 4 PALETTES", "For CGA compatible, composite or mono"
dAddI 2, 8, 76, 95, ModeB%, 3, 0, "CGA (Real) - 6 PALETTES", "For real CGA supporting Mode 5h"
dAddI 3, 8, 76, 109, ModeC%, 3, 0, "EGA/VGA 4-Color PALETTES", "Use this if you have an EGA/VGA graphics"
dAddI 9, 9, 41, 85, 78, 0, 1, "", "3"
dAddI 10, 4, 42, 106, 0, 2, 0, "Video", ""
dAddI 11, 4, 44, 113, 0, 2, 0, "Mode", ""
dAddI 4, 3, 96, 123, UseExtendedPal%, 3, 0, "EGA Custom Palettes", "If EGA/VGA use custom palettes"
dAddI 5, 0, 36, 137, Audio%, 0, 0, "No Sound (SILENT)|PC Speaker|Adlib|Sound Effects", "Select the preferred sound device"
dAddI 6, 3, 36, 152, 0, 3, 0, "Disable CGA HI-Intensity Blank (be careful)", "Only useful for CGA Graphics"

'Key Help
dAddI 12, 4, 100, 54, 0, 1, 1, "(TAB/UP/DN:MOVE  LT/RT:CHANGE  ENT:SELECT)", ""

'Quick memory check for LowMem%
FreeMem% = INT(FRE(-1) / 1024): Temp$ = LTRIM$(RTRIM$(STR$(FreeMem%))) + "KB FREE"
SELECT CASE FreeMem%
	CASE IS <= 64: Temp$ = "!Recommended! - " + Temp$
	CASE IS >= 65: Temp$ = "Not Needed - " + Temp$
END SELECT

dAddI 7, 3, 36, 166, LowMem%, 2, 0, "Low Memory Mode: " + Temp$, "Limit to 2 boards"
dAddI 8, 7, 256, 134, 25, 1, 1, "Save|Changes", "Save Settings and Play!"

I% = DoDialog%(dTitle$, dCount%, dItem%(), dStartX%(), dStartY%(), dInitVal%(), dMinVal%(), dMaxVal%(), dText$(), dHover$())
IF I% = -1 THEN
	IF ConfigFlag% = 1 THEN ConfigFlag% = 2
	EXIT SUB 'Don't save
END IF
'Otherwise apply and save
UseExtendedPal% = dVal%(4)
LowMem% = dVal%(7)
UseMouse% = dVal%(0)
NoBlank% = dVal%(6)
SELECT CASE dVal%(5) 'Audio Chooser
	CASE 0: UseAdlib% = 0: UsePCSpk% = 0 'None
	CASE 1: UseAdlib% = 0: UsePCSpk% = 1 'PC Speaker
	CASE 2: UseAdlib% = 1: UsePCSpk% = 0 'Adlib
END SELECT

'Video
IF dVal%(1) = 1 THEN CGAMode% = 2'compat
IF dVal%(2) = 1 THEN CGAMode% = 0'real
IF dVal%(3) = 1 THEN CGAMode% = 1'Attempt to change to EGA first

ConfigFlag% = 1 'Success! - Dump Settings
F = FREEFILE: OPEN "CONFIG.DAT" FOR OUTPUT AS F
PRINT #F, ";99Things Config - Refer to README.TXT"
PRINT #F, "UseMouse%="; LTRIM$(STR$(UseMouse%))
PRINT #F, "CGAMode%="; LTRIM$(STR$(CGAMode%))
PRINT #F, "UseAdlib%="; LTRIM$(STR$(UseAdlib%))
PRINT #F, "UsePCSpk%="; LTRIM$(STR$(UsePCSpk%))
PRINT #F, "NoBlank%="; LTRIM$(STR$(NoBlank%))
PRINT #F, "LowMem%="; LTRIM$(STR$(LowMem%))
PRINT #F, "UseExtendedPal%="; LTRIM$((STR$(UseExtendedPal%)));
CLOSE F

END SUB

REM $STATIC
FUNCTION GetGameID$ (InRecord%)
'Uses InRecord% to figure out which game mode (record) it is
REDIM uSize$(3), uBoards$(3), uDiff$(4)

uSize$(0) = "Smallest": uSize$(1) = "Smaller": uSize$(2) = "Bigger": uSize$(3) = "Largest"
uBoards$(0) = "Single": uBoards$(1) = "Double": uBoards$(2) = "Triple": uBoards$(3) = "Quad"
uDiff$(0) = "Easy": uDiff$(1) = "Normal": uDiff$(2) = "Tricky": uDiff$(3) = "Tough": uDiff$(4) = "Insane"

useI% = InRecord% \ 5
IF InRecord% < 80 THEN
    GetGameID$ = "QuickGame/" + uSize$(useI% \ 4) + "/" + uDiff$(useI% MOD 4)
ELSE
    GetGameID$ = "99Things/" + uBoards$((useI% - 16) \ 5) + "/" + uDiff$((useI% - 16) MOD 5)
END IF



END FUNCTION

SUB PalXInit
'Load Custom Palettes from PALX.CGA and store in PalX$() report value in PalXCount%
F = FREEFILE: OPEN "PALX.CGA" FOR INPUT AS #F
REDIM PalX$(30) 'Support 6 standard and up to 24 custom palettes
PalXCount% = 0 'Start at 1
DO
	PalXCount% = PalXCount% + 1
	LINE INPUT #F, Temp$
	S% = StrSplit%("|", Temp$)
	IF S% = 3 THEN '0|1|2|3
		PalX$(PalXCount%) = Temp$
	ELSE  'Ignore
		PalXCount% = PalXCount% - 1
	END IF
	IF EOF(F) THEN EXIT DO
	IF PalXCount% > 19 THEN EXIT DO 'Ignore afterwards
LOOP
CLOSE #F
END SUB

REM $DYNAMIC
SUB PuzzleUI (UType%)
'Put all of the PuzzleUI Routines here
'1 - Initialise / Draw
'2 - Info Panel Update
'3 - Update Timer
'4 - Update Puzzle Progress
'5 - Update Target Progress
'6 - Update Board Navigation

SUIX% = 216: SUIY% = 2 'Ref Top-Left of the Status UI
IF (H% / 2) > 216 THEN HideMouse

SELECT CASE UType%
CASE 1 'Initialise/Draw - expects pattern BG

HideMouse 'Hide Mouse

'Panel(0) = Game Mode Panel
'Panel(1) = Thing Countdown Panel or Things VS Mode Panel
'Panel(2) = Thing Target Panel
'Panel(3) = Timer Panel; No timer iPrint, Countdown, Co-Op or VS Mode Panel
'Panel(4) = Board Panel; Board Switcher or "X% Square Board" iPrint
'Panel(5) = Info Panel; F2 to show puzzle parms, F1 for help and F7 for stats

'Game Mode Panel
LINE (SUIX%, SUIY%)-(SUIX% + 99, SUIY% + 10), 0, BF: LINE (SUIX%, SUIY%)-(SUIX% + 99, SUIY% + 10), 2, B
SELECT CASE GameType% 'Show Game Header
	CASE 1: Text$ = "Quick Game"
	CASE 2: Text$ = "99Things!"
	CASE 3: Text$ = "Multi Board"
	CASE 4: Text$ = "Custom Game"
	CASE 5: Text$ = "Co-Op Game"
	CASE 6: Text$ = "VS Game"
END SELECT
L% = LEN(Text$) * 3: mPrint Text$, SUIX% + 47 - L%, SUIY% + 2, 2, 0

'Remmed difficulty at this stage
'LINE (SUIX% + 94, SUIY% + 2)-(SUIX% + 96, SUIY% + 8), 3, B: LINE (SUIX% + 90, SUIY% + 4)-(SUIX% + 92, SUIY% + 8), 3, B: LINE (SUIX% + 86, SUIY% + 6)-(SUIX% + 88, SUIY% + 8), 3, B
'IF UseDifficulty% > -1 THEN LINE (SUIX% + 82, SUIY% + 8)-(SUIX% + 84, SUIY% + 8), 2, B
'TODO: Add Paint commands for UseDifficulty%

'Thing Panel [Things Countdown]
LINE (SUIX%, SUIY% + 14)-(SUIX% + 99, SUIY% + 47), 0, BF: LINE (SUIX%, SUIY% + 14)-(SUIX% + 99, SUIY% + 47), 2, B
'Text$ = STR$(PuzPos%) + " of " + STR$(PuzListCount%)
iPrint "THINGS", SUIX% + 37, SUIY% + 17, 3, 0
PrevPuzMajor% = 0 'Reset >9 flag for UI update
PuzzleUI 4

'Target Panel
LINE (SUIX%, SUIY% + 51)-(SUIX% + 99, SUIY% + 86), 0, BF: LINE (SUIX%, SUIY% + 51)-(SUIX% + 99, SUIY% + 86), 2, B
PrevTarMajor% = 0 'Reset >9 flag for UI update
PuzzleUI 5

'Timer Panel
LINE (SUIX%, SUIY% + 90)-(SUIX% + 99, SUIY% + 125), 0, BF: LINE (SUIX%, SUIY% + 90)-(SUIX% + 99, SUIY% + 125), 2, B
IF UseTimer&(0) = 1 THEN 'TimerUI
	iPrint "ELAPSED TIME", SUIX% + 25, SUIY% + 92, 3, 0
	'PUT (SUIX% + 52, SUIY% + 101), BigFont%(11 * 32), PSET
ELSE  'No Timer - check game style
iPrint "NO TIMER", SUIX% + 46, SUIY% + 106, 3, 0
	PUT (SUIX% + 12, SUIY% + 100), Thing%(71 * 45), PRESET
	LINE (SUIX% + 12, SUIY% + 100)-(SUIX% + 28, SUIY% + 116), 2
	LINE (SUIX% + 12, SUIY% + 116)-(SUIX% + 28, SUIY% + 100), 2
END IF

'Board Panel
LINE (SUIX%, SUIY% + 129)-(SUIX% + 99, SUIY% + 145), 0, BF: LINE (SUIX%, SUIY% + 129)-(SUIX% + 99, SUIY% + 145), 2, B
'Display text for 1 board, Display buttons for Board switcher
IF BoardMax% = 1 THEN
	Text$ = STR$(PuzMax% + 1) + " * SQUARE BOARD"
	iPrint Text$, SUIX% + 49 - ((LEN(Text$) + 1) * 2), SUIY% + 135, 1, 0
	ELSE FOR UseA% = 2 TO BoardMax% + 1
		LINE (2 + SUIX% + ((UseA% - 2) * 16), SUIY% + 131)-(2 + SUIX% + ((UseA% - 1) * 16), SUIY% + 143), 1, B
		iPrint LTRIM$(STR$(UseA% - 1)), 5 + SUIX% + (((UseA% - 2) * 16)), SUIY% + 134, 1, 0
	NEXT UseA%
	PAINT (8 + SUIX%, SUIY% + 139), 2, 1
	iPrint "BOARDS", SUIX% + 72, SUIY% + 135, 1, 0
END IF

'Info Panel init
LINE (SUIX%, SUIY% + 149)-(SUIX + 99, SUIY% + 194), 0, BF: LINE (SUIX%, SUIY% + 149)-(SUIX% + 99, SUIY% + 194), 2, B
LINE (SUIX% + 1, SUIY% + 157)-(SUIX + 98, SUIY% + 157), 3

'Draw and Grab Keys then blank
PUT (SUIX% + 4, SUIY% + 162), OtherAsset%(0): iPrint "MOVE SQUARE", SUIX% + 22, SUIY% + 163, 1, 0

iPrint "ENT", SUIX% + 5, SUIY% + 173, 1, 1: LINE (SUIX% + 4, SUIY% + 172)-(SUIX% + 16, SUIY% + 178), 3, B
iPrint "TRY SQUARE", SUIX% + 22, SUIY% + 173, 1, 0

iPrint "ESC", SUIX% + 5, SUIY% + 183, 1, 1: LINE (SUIX% + 4, SUIY% + 182)-(SUIX% + 16, SUIY% + 188), 3, B
iPrint "EXIT", SUIX% + 22, SUIY% + 183, 1, 0

iPrint "F9", SUIX% + 55, SUIY% + 183, 1, 1: LINE (SUIX% + 54, SUIY% + 182)-(SUIX% + 62, SUIY% + 188), 3, B
iPrint "UN/MUTE", SUIX% + 66, SUIY% + 183, 1, 0

iPrint "MOUSE", SUIX% + 76, SUIY% + 166, 3, 0
IF UseMouse% = 1 THEN 'show mouse toggle
	iPrint "YES", SUIX% + 80, SUIY% + 172, 1, 0
	ELSE
	iPrint "NO", SUIX% + 82, SUIY% + 172, 2, 0
END IF

GET (SUIX%, SUIY% + 157)-(SUIX + 99, SUIY% + 194), SUIArea%(500)
LINE (SUIX% + 1, SUIY% + 159)-(SUIX + 98, SUIY% + 193), 0, BF

'Draw Info Panel
'Clear on Find?
iPrint "CLEAR", SUIX% + 6, SUIY% + 160, 3, 0: PUT (SUIX% + 7, SUIY% + 167), Thing%(36 * 45), PSET: LINE (SUIX% + 7, SUIY% + 168)-(SUIX% + 23, SUIY% + 183), 3, B
SELECT CASE RemoveOnFind%
	CASE 1: iPrint "YES", SUIX% + 10, SUIY% + 186, 1, 0: LINE (SUIX% + 10, SUIY% + 170)-(SUIX% + 20, SUIY% + 180), 2: LINE (SUIX% + 10, SUIY% + 180)-(SUIX% + 20, SUIY% + 170), 2
	CASE 0: iPrint "NO", SUIX% + 12, SUIY% + 186, 2, 0
END SELECT

'Orientations?
UseC% = 3: SELECT CASE UseOrientations%: CASE 2, 3: UseC% = 1: CASE 4: UseC% = 2: END SELECT
iPrint "ROTATE", SUIX% + 34, SUIY% + 160, 3, 0
PUT (SUIX% + 32, SUIY% + 168), Thing%(264 * 45), PSET
PUT (SUIX% + 43, SUIY% + 168), Thing%(66 * 45), OR
LINE (SUIX% + 34, SUIY% + 169)-(SUIX% + 56, SUIY% + 183), UseC%, B
Text$ = "NO": SELECT CASE UseOrientations%: CASE 2, 3, 4: Text$ = "*" + LTRIM$(STR$(UseOrientations%)): END SELECT
iPrint Text$, SUIX% + 42, SUIY% + 186, UseC%, 0

'Style?
iPrint "STYLE", SUIX% + 69, SUIY% + 160, 3, 0
UseC% = 3: SELECT CASE UseDispVar%: CASE 2, 3: UseC% = 1: CASE 4: UseC% = 2: END SELECT
Text$ = "NO": SELECT CASE UseDispVar%: CASE IS > 1: Text$ = "*" + LTRIM$(STR$(UseDispVar%)): END SELECT
iPrint Text$, SUIX% + 76, SUIY% + 186, UseC%, 0

LINE (SUIX% + 64, SUIY% + 168)-(SUIX% + 77, SUIY% + 182), 1, BF: PUT (SUIX% + 64, SUIY% + 167), Thing%(3 * 45), AND
LINE (SUIX% + 80, SUIY% + 168)-(SUIX% + 90, SUIY% + 182), 2, BF: PUT (SUIX% + 77, SUIY% + 167), Thing%(3 * 45), OR
LINE (SUIX% + 65, SUIY% + 167)-(SUIX% + 92, SUIY% + 183), 1, B

'Get for later
GET (SUIX%, SUIY% + 157)-(SUIX + 99, SUIY% + 194), SUIArea%(0)

PuzzleUI 2'Update Info Panel

CASE 2 'Info Panel Update
LINE (SUIX% + 1, SUIY% + 150)-(SUIX% + 97, SUIY% + 156), 0, BF'Clear
IF SUITabVis% <> 1 THEN iPrint "F1=INFO", SUIX% + 3, SUIY% + 151, 3, 0
IF SUITabVis% <> 2 THEN iPrint "F2=KEYS", SUIX% + 33, SUIY% + 151, 3, 0
IF SUITabVis% <> 3 THEN iPrint "F7=STATS", SUIX% + 65, SUIY% + 151, 3, 0
SELECT CASE SUITabVis%
	CASE 1: PUT (SUIX%, SUIY% + 157), SUIArea%(0), PSET: LINE (SUIX% + 1, SUIY% + 150)-(SUIX% + 30, SUIY% + 156), 3, BF: iPrint "F1=INFO", SUIX% + 3, SUIY% + 151, 3, 1
	CASE 2: PUT (SUIX%, SUIY% + 157), SUIArea%(500), PSET: LINE (SUIX% + 31, SUIY% + 150)-(SUIX% + 62, SUIY% + 156), 3, BF: iPrint "F2=KEYS", SUIX% + 33, SUIY% + 151, 3, 1
	CASE 3
	LINE (SUIX% + 1, SUIY% + 158)-(SUIX + 98, SUIY% + 193), 0, BF: LINE (SUIX% + 63, SUIY% + 150)-(SUIX% + 97, SUIY% + 156), 3, BF: iPrint "F7=STATS", SUIX% + 65, SUIY% + 151, 3, 1
	iPrint "STREAK:" + STR$(GameCurrentStreak%), SUIX% + 8, SUIY + 164, 1, 0
	SELECT CASE UseTimer&(0)
		CASE 1: iPrint "FINDS /MIN: ", SUIX% + 8, SUIY + 174, 3, 0
		CASE 0: iPrint "UNTIMED", SUIX% + 8, SUIY + 174, 3, 0
	END SELECT
	iPrint "MISSES:" + STR$(GameErrorCount%), SUIX% + 8, SUIY + 184, 2, 0
END SELECT

CASE 21 'Update Streak and Finds/Min for correct guesses
IF SUITabVis% = 3 THEN
	iPrint STR$(GameCurrentStreak%) + "  ", SUIX% + 36, SUIY + 164, 1, 0
	IF UseTimer&(0) = 1 THEN
		Speed% = INT(((PuzMax% + 1) / UseTimer&(2)) * 60)
		iPrint LTRIM$(STR$(Speed%)) + "  ", SUIX% + 54, SUIY + 174, 3, 0
	END IF
END IF

CASE 22 'Update Cumulative Errors and reset Streak if needed
IF SUITabVis% = 3 THEN
	iPrint STR$(GameErrorCount%), SUIX% + 36, SUIY + 184, 2, 0
	iPrint "0  ", SUIX% + 40, SUIY + 164, 1, 0 'Reset Streak UI
END IF


CASE 3 'Timer Update using UseTimer&(2)
TimeString$ = SecsToTime$(INT(UseTimer&(2)), 0)
L% = LEN(TimeString$)

UseT% = SUIY% + 101 'Calc Once
FOR UseK% = 1 TO L%
	UChar$ = MID$(TimeString$, UseK%, 1)
	IF UChar$ = ":" THEN
		UseV% = 11 'Seperator
	ELSE
		UseV% = VAL(UChar$)
	END IF


IF UseV% <> PrvTimer%(UseK% - 1) THEN 'Update
       
	IF UseK% < 3 AND UseV% = 1 THEN 'If the minute column has a 1 in it - recentre timer
		LINE (SUIX% + 2, UseT%)-(SUIX% + 96, UseT% + 18), 0, BF 'Clear area
		PrvTimer%(3) = -1 'reset colon for PUT
		SELECT CASE (UseK% - 1) 'Adjust offset
			CASE 0, 2: PrvTimer%(6) = 7
			CASE 1: PrvTimer%(6) = -1
		END SELECT
	END IF

      'Draw the number/colon
      PUT (SUIX% + (((UseK% - 1)) * 15) + PrvTimer%(6), UseT%), BigFont%(UseV% * 32), PSET
      PrvTimer%(UseK% - 1) = UseV%
END IF
NEXT UseK%

CASE 4 'Puzzle Progress Update (Things)
UseR% = PuzListCount% - PuzPos% + 1
UseU% = SUIY% + 25
IF UseR% \ 10 = 0 THEN
	AddX% = 30 'reset and recentre
	IF PrevPuzMajor% = 1 THEN
		PrevPuzMajor% = 0
		LINE (SUIX% + 36, UseU%)-(SUIX% + 60, SUIY% + 44), 0, BF 'Clear Major
	END IF
ELSE '10+
	PrevPuzMajor% = 1: AddX% = 36
	PUT (SUIX% + AddX%, UseU%), BigFont%((UseR% \ 10) * 32), PSET 'Place Major
END IF
PUT (SUIX% + AddX% + 14, UseU%), BigFont%((UseR% MOD 10) * 32), PSET 'Place Minor


CASE 5 'Target Update
UseB% = PuzzleCount(PuzPos%)
IF PuzFlag% = 0 THEN 'Blank and do one-offs
	J% = PuzList%(PuzPos%)
	Text$ = ThingDef$(J%)
	LINE (SUIX% + 2, SUIY% + 54)-(SUIX% + 94, SUIY% + 84), 0, BF
	iPrint Text$, SUIX% + 49 - (LEN(Text$) * 2), SUIY% + 54, 3, 0
	PUT (SUIX% + 14, SUIY% + 63), Thing%(J% * 45), PSET
	PUT (SUIX% + 44, SUIY% + 63), BigFont%(10 * 32), PSET
END IF

UseU% = SUIY% + 63

IF UseB% > 9 THEN
PUT (SUIX% + 63, UseU%), BigFont%((UseB% \ 10) * 32), PSET
PUT (SUIX% + 76, UseU%), BigFont%((UseB% MOD 10) * 32), PSET
PrevTarMajor% = 1
ELSE
IF PrevTarMajor% = 1 THEN
	LINE (SUIX% + 63, UseU%)-(SUIX% + 98, SUIY% + 85), 0, BF'Clear    
	PrevTarMajor% = 0 'reset
END IF
PUT (SUIX% + 70, UseU%), BigFont%(UseB% * 32), PSET
END IF

PuzFlag% = 1 'Reset

CASE 6 'Board Nav Update
	HideMouse
	FOR UseA% = 1 TO BoardMax% 'Unselect
	IF UseA% - 1 <> CurrentBoard% - 1 THEN
	PAINT (10 + (16 * (UseA% - 1)) + SUIX%, SUIY% + 139), 0, 1
	END IF
	NEXT UseA%
	PAINT (10 + (16 * (CurrentBoard% - 1)) + SUIX%, SUIY% + 139), 2, 1
	ShowMouse
END SELECT 'End of the PuzzleUI SELECT CASE

ShowMouse
END SUB

SUB QuickGame 'Game Board 2.0
QuickGameStart:

REDIM TempImage%(128)
IF UsePCSpk% = 1 THEN
MuteFlag% = 2
END IF

IF UseAdlib% = 1 THEN
MuteFlag% = 3 'Figure out what we would mute
END IF

'Set Up Screen
HideMouse
CLS
RandomPal
BoardBG% = 0
SelColor% = 3
Pat% = INT(RND * 16): IF Pat% > 15 THEN Pat% = 15
DrawPattern Pat%, 0, 0, 319, 39, 1
RANDOMIZE TIMER

'Get Puzzle Parms [set by menu]
'BoardMax% = 1'Multiplier x PuzMax% for 99 things tables (1 for everything else)
'PuzMax% = (BoardMax% * 99) - 1
'PuzMax% = 15
'MixBagSize% = 16 'Select from Bag - cannot exceed 97 right now
'UseDispVar% = 9 'Cannot exceed 9
'UseOrientations% = 4 'Cannot exceed 4

PuzFlag% = 0
GameErrorCount% = 0 'Reset
GameStreakCount% = 0 'Reset
GameCurrentStreak% = 0 'Reset

'Some basic corrections
IF MixBagSize% >= PuzMax% - 1 THEN MixBagSize% = PuzMax% - 2

UseC% = 0 'Reset counter
SUITabVis% = 1 'Reset to F1=Info
PuzPos% = 0 'Start PuzList%(0)
SUIX% = 216: SUIY% = 2 'Ref Top-Left of the Status UI
TryX% = -1: TryY% = -1: TryCount% = 0 'Reset Tries

LINE (SUIX%, SUIY% + 149)-(SUIX + 99, SUIY% + 194), 0, BF: LINE (SUIX%, SUIY% + 149)-(SUIX% + 99, SUIY% + 194), 2, B
LINE (SUIX% + 1, SUIY% + 157)-(SUIX + 98, SUIY% + 157), 3
iPrint "Generating Puzzle...", SUIX% + 2, SUIY% + 151, 1, 0

SELECT CASE PuzMax% 'Set up Board Parms
	CASE 98, 197, 296, 395:  BoardRows% = 8: BoardCols% = 10: OffSetX% = 10: OffSetY% = 15: OffSetC% = 0: CellSize% = 18: Text$ = "99Things!"'99 Board - no padding
	CASE 15: BoardRows% = 3: BoardCols% = 3: OffSetX% = 25: OffSetY% = 18: OffSetC% = 11: CellSize% = 40 '4x4 board
	CASE 24: BoardRows% = 4: BoardCols% = 4: OffSetX% = 26: OffSetY% = 18: OffSetC% = 8: CellSize% = 32  '5x5 board
	CASE 35: BoardRows% = 5: BoardCols% = 5: OffSetX% = 15: OffSetY% = 15: OffSetC% = 5: CellSize% = 28  '6x6 board
	CASE 48: BoardRows% = 6: BoardCols% = 6: OffSetX% = 15: OffSetY% = 15: OffSetC% = 3: CellSize% = 24  '7x7 board
	CASE 63: BoardRows% = 7: BoardCols% = 7: OffSetX% = 17: OffSetY% = 10: OffSetC% = 2: CellSize% = 22  '8x8 board
END SELECT

'Set Up Game

'Generate Thing Selection Mix Bag (no dupes)
REDIM Nums%(99): REDIM MixBag%(MixBagSize%)
FOR I% = 0 TO MixBagSize%: DO: Num% = INT(RND * 99): LOOP UNTIL Nums%(Num%) = 0: Nums%(Num%) = 1: MixBag%(I%) = Num%: NEXT I%: ERASE Nums%

'Create Puzzle board and keep a list of the sequence and counts
REDIM Puzzle%(PuzMax%): REDIM PuzList%(PuzMax%): REDIM PuzzleCount%(PuzMax%): PuzListCount% = -1: REDIM PuzzleO%(PuzMax%): REDIM PuzzleD%(PuzMax%): REDIM PuzzleFlag%(PuzMax%)
REDIM TempCount%(128): REDIM PuzDMix%(UseDispVar%)
FOR I% = 1 TO UseDispVar%   'Generate mix bag for PuzzleD
GetDispVar:
	TryI% = INT(RND * 12) + 1
	SELECT CASE BoardBG% 'Stop no-border clashes - maybe replace with alt border?
		CASE 0: SELECT CASE TryI%: CASE 7, 8, 1: GOTO GetDispVar: END SELECT
		CASE 1: SELECT CASE TryI%: CASE 10, 2, 3: GOTO GetDispVar: END SELECT
		CASE 2: SELECT CASE TryI%: CASE 9, 4, 5: GOTO GetDispVar: END SELECT
		CASE 3: SELECT CASE TryI%: CASE 6, 11, 12: GOTO GetDispVar: END SELECT
	END SELECT

	FOR UseC% = 1 TO I%
		IF TryI% = PuzDMix%(UseC%) THEN GOTO GetDispVar 'Dupe - retry
	NEXT UseC%
	PuzDMix%(I%) = TryI%
NEXT I%

FOR I% = 0 TO PuzMax% 'Fill Puzzle%(I%)
	Puzzle%(I%) = MixBag%(INT(RND * MixBagSize%)): Flag% = 0
	PuzzleO%(I%) = INT(RND * UseOrientations%) + 1
	PuzzleD%(I%) = PuzDMix%(INT(RND * UseDispVar%) + 1)
	PuzzleFlag%(I%) = 0
	'Increment TempCount%(Puzzle%(I%)) [0-MixBagSize%]
	TempCount%(Puzzle%(I%)) = TempCount%(Puzzle%(I%)) + 1
NEXT I%

PuzListCount% = -1 'Get PuzListCount% first
FOR I% = 0 TO 98: IF TempCount%(I%) > 0 THEN PuzListCount% = PuzListCount% + 1
NEXT I%

FOR I% = 0 TO 98 'Now use it to generate random PuzList%
IF TempCount%(I%) > 0 THEN
FindRandomPL: IF INKEY$ = CHR$(27) THEN EXIT FOR
		UseB% = INT(RND * (PuzListCount% + 1))
		IF PuzzleCount%(UseB%) = 0 THEN
			PuzList%(UseB%) = I%
			PuzzleCount%(UseB%) = TempCount%(I%)
			ELSE : GOTO FindRandomPL
		END IF
END IF
NEXT I%

'Clean up puzzle prep variables (if any)
ERASE TempCount%: ERASE PuzDMix%

'Configure Board Parms
UseC% = 0: CurrentBoard% = 1: REDIM Board%(BoardMax% * 4092): REDIM PrvSel%(99 * BoardMax%): REDIM CurSel%(99 * BoardMax%)
iPrint "Generate Board:", SUIX% + 2, SUIY% + 151, 1, 0 'For slower pcs..
FOR UseB% = 0 TO BoardMax% - 1'Draw Board based on BoardSize%

	PrvSel%(UseB%) = 1: CurSel%(UseB%) = 1 'reset selections BASE 1
	iPrint STR$(UseB% + 1) + " OF" + STR$(BoardMax%), SUIX% + 62, SUIY% + 151, 3, 0
	CellX% = OffSetX% + (BoardCols% + 1) * CellSize% - 1: CellY% = OffSetY% + (BoardRows% + 1) * CellSize% - 1
	LINE (OffSetX% - 1, OffSetY% - 1)-(CellX%, CellY%), BoardBG%, BF 'Clear Board
	FOR UseY% = 0 TO BoardRows%: FOR UseX% = 0 TO BoardCols%
		CellX% = OffSetX% + UseX% * CellSize%: CellY% = OffSetY% + UseY% * CellSize%
	      
		
		'Pre-Put LINE to support 1st PUT
	       
		SELECT CASE PuzzleD%(UseC%) 'Cell BG Change
			CASE 7, 8, 1:  LINE (CellX%, CellY%)-(CellX% + CellSize% - 2, CellY% + CellSize% - 2), 0, BF: CellS% = 1
			CASE 10, 2, 3:  LINE (CellX%, CellY%)-(CellX% + CellSize% - 2, CellY% + CellSize% - 2), 1, BF
				CellS% = 2: IF PuzzleD%(UseC%) = 3 THEN CellS% = 5
			CASE 9, 4, 5: LINE (CellX%, CellY%)-(CellX% + CellSize% - 2, CellY% + CellSize% - 2), 2, BF
				CellS% = 2: IF PuzzleD%(UseC%) = 5 THEN CellS% = 5
			CASE 6, 11, 12: CellS% = 4: LINE (CellX%, CellY%)-(CellX% + CellSize% - 2, CellY% + CellSize% - 2), 3, BF
		END SELECT

		'Extra box for 7-12 'Mid Cell BG Change and Style set
		UseU% = 16 + OffSetC%
		SELECT CASE PuzzleD%(UseC%)
			CASE 7, 8: CellS% = 3: LINE (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), PuzzleD%(UseC%) - 6, BF
			CASE 9: CellS% = 4: LINE (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), 1, BF
			CASE 10: CellS% = 5: LINE (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), 2, BF
			CASE 11: CellS% = 3: LINE (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), 2, BF
			CASE 12: CellS% = 3: LINE (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), 1, BF
		END SELECT

		PPUT OffSetC% + CellX%, OffSetC% + CellY%, (99 * (PuzzleO%(UseC%) - 1)) + Puzzle%(UseC%), CellS%
		SELECT CASE PuzzleD%(UseC%) 'Get/PUT2
			CASE 10, 11, 12: GET (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), TempImage%: PUT (OffSetC% + CellX%, OffSetC% + CellY%), TempImage%, PRESET
			CASE 9: GET (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), TempImage%
			LINE (OffSetC% + CellX%, OffSetC% + CellY%)-(UseU% + CellX%, UseU% + CellY%), 2, BF: PUT (OffSetC% + CellX%, OffSetC% + CellY%), TempImage%, AND
		END SELECT
	

	UseC% = UseC% + 1: NEXT UseX%: NEXT UseY%
	IF BoardMax% > 1 THEN GET (OffSetX% - 1, OffSetY% - 1)-(OffSetX% + 197, OffSetY% + 161), Board%(UseB% * 4081) 'Simplified 13042025

NEXT UseB%

IF BoardMax% > 1 THEN 'Re-PUT 1st board if multi-board
 CellX% = OffSetX% + (BoardCols% + 1) * CellSize% - 1: CellY% = OffSetY% + (BoardRows% + 1) * CellSize% - 1
 PUT (OffSetX% - 1, OffSetY% - 1), Board%((CurrentBoard% - 1) * 4081), PSET
END IF

'Draw GameUI & Start Events

PuzzleUI 1 'Init the UI
GOSUB UpdateSel

IF UseTimer&(0) = 1 THEN 'Reset TIMERs
	UseTimer&(2) = -2: UseTimer&(1) = TIMER: LastSec& = 0
	FOR I% = 0 TO 2: PrvTimer%(I%) = 0: NEXT I%
	FOR I% = 3 TO 5: PrvTimer%(I%) = -1: NEXT I%
	PrvTimer%(6) = -8 'Furtherest left
END IF

IF UseMouse% = 1 THEN 'Reset and set cursor to 1,1
	Mouse 0: Mouse 1'Show Reset and Show
	Regs.ax = 4: Regs.cx = ((ColPos% + CellSize%) * 2) - 8: Regs.dx = RowPos% + CellSize% - 3
	INTERRUPT &H33, Regs, Regs
END IF

GameKey: 'Key Manager for QuickGame
	DO: UKey$ = INKEY$:         'Key Manager
			IF UseTimer&(0) = 1 THEN 'Handle Timer
				S& = TIMER MOD 60
				IF S& <> LastSec& THEN 'Handle timer change (dont store over 30k seconds)
					IF UseTimer&(2) < 30000 THEN UseTimer&(2) = UseTimer&(2) + 1 'Increment
					IF UseTimer&(2) < 0 THEN GOTO GameKey'catch first second glitch
					LastSec& = S&:  PuzzleUI 3'Update UI
					END IF
			END IF
		       
			IF UseMouse% = 1 THEN 'Handle Mouse Input
			Mouse 3: IF B% = 0 THEN mButtonUP% = 1: useH! = H% / 2
				IF B% = 1 AND mButtonUP% > 0 THEN 'Capture Click Event
					mButtonUP% = 0 'Reset to stop hold-down clicking events
					TryX% = INT(((useH!) - OffSetX%) / CellSize%)
					TryY% = INT((V% - OffSetY%) / CellSize%)
					IF TryX% > -1 AND TryY% > -1 AND TryX% <= BoardCols% AND TryY% <= BoardRows% THEN
						CurSel%(CurrentBoard%) = (TryY% * (BoardCols% + 1)) + TryX%: GOSUB UpdateSel 'Update Selection based on mouse click
						GOTO PuzzleTry
						ELSE 'Clicked somewhere else in UI
						SELECT CASE V%
							CASE SUIY% + 131 TO SUIY% + 143 'Board Switcher?
								IF BoardMax% > 1 THEN '2 or more
									FOR UseA% = 1 TO BoardMax%
									SELECT CASE useH!
										CASE ((UseA% - 1) * 16) + SUIX% + 2 TO ((UseA% - 1) * 16) + SUIX% + 18
											
										CurrentBoard% = UseA%
										CellX% = OffSetX% + (BoardCols% + 1) * CellSize% - 1: CellY% = OffSetY% + (BoardRows% + 1) * CellSize% - 1
										HideMouse
										PUT (OffSetX% - 1, OffSetY% - 1), Board%((CurrentBoard% - 1) * 4081), PSET
										ShowMouse
										PuzzleUI 6
										EXIT FOR
																					
									END SELECT
									NEXT UseA%
								END IF
						END SELECT
					END IF
				END IF
			END IF
	LOOP WHILE UKey$ = ""

SELECT CASE UKey$ 'Handle Key Inputs

	CASE CHR$(0) + CHR$(77), "d", "D" 'RIGHT
	CurSel%(CurrentBoard%) = CurSel%(CurrentBoard%) + 1
	IF CurSel%(CurrentBoard%) >= (BoardRows% + 1) * (BoardCols% + 1) THEN CurSel%(CurrentBoard%) = 0
	GOSUB UpdateSel

	CASE CHR$(0) + CHR$(75), "a", "A" 'LEFT
	CurSel%(CurrentBoard%) = CurSel%(CurrentBoard%) - 1
	IF CurSel%(CurrentBoard%) < 0 THEN CurSel%(CurrentBoard%) = (BoardRows% + 1) * (BoardCols% + 1) - 1
	GOSUB UpdateSel

	CASE CHR$(0) + CHR$(80), "S", "s" 'DOWN
	CurSel%(CurrentBoard%) = CurSel%(CurrentBoard%) + (BoardCols% + 1)
	IF CurSel%(CurrentBoard%) >= (BoardRows% + 1) * (BoardCols% + 1) THEN CurSel%(CurrentBoard%) = CurSel%(CurrentBoard%) - ((BoardRows% + 1) * (BoardCols% + 1))
	GOSUB UpdateSel

	CASE CHR$(0) + CHR$(72), "W", "w" 'UP
	CurSel%(CurrentBoard%) = CurSel%(CurrentBoard%) - (BoardCols% + 1)
	IF CurSel%(CurrentBoard%) < 0 THEN CurSel%(CurrentBoard%) = ((BoardRows% + 1) * (BoardCols% + 1)) + CurSel%(CurrentBoard%)
	GOSUB UpdateSel

	CASE CHR$(13), CHR$(32) 'SELECT
	TryY% = CurSel%(CurrentBoard%) \ (BoardCols% + 1)
	TryX% = CurSel%(CurrentBoard%) MOD (BoardCols% + 1)
	GOTO PuzzleTry


	CASE CHR$(27) 'Quit Dialog
		HideMouse
		CellX% = OffSetX% + (BoardCols% + 1) * CellSize% - 1: CellY% = OffSetY% + (BoardRows% + 1) * CellSize% - 1
		IF BoardMax% = 1 THEN REDIM Board%(4082): GET (OffSetX% - 1, OffSetY% - 1)-(CellX%, CellY%), Board%
		LINE (OffSetX% - 1, OffSetY% - 1)-(CellX%, CellY%), 0, BF
		LINE (OffSetX% + 13, OffSetY% + 13)-(CellX% - 12, CellY% - 12), 2, B
		CentreX% = OffSetX% + (((BoardCols% + 1) * CellSize% - 1) / 2)
		Text$ = "! GAME PAUSED !": mPrint Text$, CentreX% - ((LEN(Text$) * 2.9)), OffSetY% + 20, 2, 0
		Text$ = "Press Y to QUIT": mPrint Text$, CentreX% - ((LEN(Text$) * 2.9)), OffSetY% + 53, 1, 0
		Text$ = "Any other key resumes": mPrint Text$, CentreX% - ((LEN(Text$) * 2.9)), OffSetY% + 70, 1, 0
	       
		SubUKey$ = "": DO: SubUKey$ = INKEY$: LOOP WHILE SubUKey$ = ""
		SELECT CASE SubUKey$
		
		CASE "Y", "y":
		SELECT CASE MuteFlag%: CASE 1, 2: UsePCSpk% = 1: UseAdlib% = 0: CASE 3, 4: UseAdlib% = 1: UsePCSpk% = 0: END SELECT
		ERASE Board%: EXIT SUB
		END SELECT
	       
		'Resume game
		PUT (OffSetX% - 1, OffSetY% - 1), Board%((CurrentBoard% - 1) * 4081), PSET
		IF BoardMax% = 1 THEN ERASE Board%
		ShowMouse

	CASE "1", "2", "3", "4" 'Board Switcher
		UseV% = VAL(UKey$)
		IF BoardMax% > 1 AND UseV% <> CurrentBoard% AND UseV% <= BoardMax% THEN
		 IF RemoveOnFind% = 1 THEN GET (OffSetX% - 1, OffSetY% - 1)-(OffSetX% + 197, OffSetY% + 161), Board%((CurrentBoard% - 1) * 4081) 'Update board for CLEAR
		 CurrentBoard% = UseV%
		 CellX% = OffSetX% + (BoardCols% + 1) * CellSize% - 1: CellY% = OffSetY% + (BoardRows% + 1) * CellSize% - 1
		HideMouse
		PUT (OffSetX% - 1, OffSetY% - 1), Board%((CurrentBoard% - 1) * 4081), PSET: ShowMouse
		 PuzzleUI 6
		 GOSUB UpdateSel
		END IF

	CASE CHR$(0) + CHR$(59) 'F1
	IF SUITabVis% <> 1 THEN : SUITabVis% = 1: PUT (SUIX%, SUIY% + 157), SUIArea%(0), PSET: PuzzleUI 2'Update Panel

	CASE CHR$(0) + CHR$(60) 'F2
	IF SUITabVis% <> 2 THEN : SUITabVis% = 2: PuzzleUI 2'Update Panel

	CASE CHR$(0) + CHR$(65) 'F7
	IF SUITabVis% <> 3 THEN : SUITabVis% = 3: PuzzleUI 2'Update Panel

	CASE CHR$(0) + CHR$(67) 'F9 Toggle Mute
	SELECT CASE MuteFlag%
	CASE 2: UsePCSpk% = 0: MuteFlag% = 1'UsePCSpk
	CASE 1: UsePCSpk% = 1: MuteFlag% = 2
	CASE 3: UseAdlib% = 0: MuteFlag% = 4'UseAdlib
	CASE 4: UseAdlib% = 1: MuteFlag% = 3
	END SELECT

	'CASE "P", "p"
	'LOCATE 1, 1: PRINT FRE(" "); FRE(-2); FRE(-1); FRE(0);
       
	CASE "{", "}"'Change Palettes in a non-timed game
	IF CGAMode% = 1 AND UseTimer&(0) = 0 THEN
	Prev% = NoBlank%: RandomPal: NoBlank% = Prev%
	IF UKey$ = "}" THEN 'Do it and show the numbers for debug
		LOCATE 1, 1: FOR J% = 0 TO 3: PRINT SplitWords$(J%); " "; : NEXT J%
		PRINT STRING$(3, " ");
	END IF
	END IF
	
	


     
END SELECT
GOTO GameKey 'Loop back

'Put Post-Key GOSUB's here

PuzzleTry: 'Use; TryX%; Try% and Increment Count
TryCount% = TryCount% + 1
Cell% = (TryY% * (BoardCols% + 1) + TryX%) + ((CurrentBoard% - 1) * (BoardCols% + 1) * (BoardRows% + 1))
'LOCATE 1, 1: PRINT "Cell Try:"; Cell%; STRING$(12, " ");
'LOCATE 2, 2: PRINT TryX%; TryY%; STRING$(12, " ");

IF Puzzle%(Cell%) = PuzList%(PuzPos%) AND PuzzleFlag%(Cell%) = 0 THEN  'Found!
	PuzzleFlag%(Cell%) = 1
	GameCurrentStreak% = GameCurrentStreak% + 1: IF GameCurrentStreak% > GameStreakCount% THEN GameStreakCount% = GameCurrentStreak%
	'TODO: Update Streak PuzzleUI
	PuzzleUI 21

	IF RemoveOnFind% = 1 THEN 'Clear!
		InCellX% = OffSetX% + (TryX% * CellSize%) + OffSetC%
		InCellY% = OffSetY% + (TryY% * CellSize%) + OffSetC%
		SELECT CASE PuzzleD%(Cell%): CASE 7, 8, 1: UseBG% = 0: CASE 10, 2, 3: UseBG% = 1: CASE 9, 4, 5: UseBG% = 2: CASE 6, 11, 12: UseBG% = 3: END SELECT
		HideMouse
		LINE (InCellX%, InCellY%)-(InCellX% + 16, InCellY% + 16), UseBG%, BF
		ShowMouse
		
	END IF
	PuzzleCount%(PuzPos%) = PuzzleCount%(PuzPos%) - 1
	IF PuzzleCount%(PuzPos%) = 0 THEN 'Thing complete
		PuzPos% = PuzPos% + 1
		'Puzzle Complete - Dialog
		IF PuzPos% > PuzListCount% THEN
			PlayFX 9: Speak 1: HideMouse
			ERASE Board%
			OffSetX% = 70: OffSetY% = 30 'Smaller Dialog one-off
			LINE (OffSetX% - 2, OffSetY% - 2)-(319 - OffSetX% + 1, 199 - (OffSetY% / 3) - 11), 3, BF
			LINE (OffSetX% - 2, OffSetY% - 2)-(319 - OffSetX% + 1, 199 - (OffSetY% / 3) - 11), 0, B
			LINE (OffSetX%, OffSetY%)-(319 - OffSetX% - 1, 199 - (OffSetY% / 3) - 13), 0, B
			LINE (OffSetX% + 5, OffSetY% + 5)-(319 - OffSetX% - 6, 193 - (OffSetY% / 3) - 11), 0, BF
			cPrint "Puzzle Complete!", 6, 13, 1, 0
			LOCATE 9, 11: PRINT "Best Streak:"; GameStreakCount%;
		       
			SELECT CASE GameErrorCount% 'Evaluate Error Count
			CASE IS > 0: cPrint "Errors:" + STR$(GameErrorCount%), 12, 11, 2, 0
			CASE 0: 'Celebrate no errors
				SELECT CASE RemoveOnFind%
					CASE 1: cPrint "No Errors", 12, 11, 1, 0
					CASE 0: cPrint "! P E R F E C T !", 12, 12, 3, 0
				END SELECT
			END SELECT

			'Timed game section
			SELECT CASE UseTimer&(2)
			CASE IS > 0
				uTime$ = SecsToTime$(INT(UseTimer&(2)), 1)
				Speed% = INT(((PuzMax% + 1) / UseTimer&(2)) * 60)
				LOCATE 10, 11: PRINT "Find Speed:"; RTRIM$(STR$(Speed%)); "/min";
				LOCATE 8, 11: PRINT "Time Taken: "; uTime$
			CASE 0: LOCATE 10, 11: PRINT "Game was not timed";
			END SELECT

			IF GameType% <= 3 AND UseTimer&(0) = 1 AND RemoveOnFind% = 0 THEN
			'Pass to TryRecord (Rows 14-19)
			TryRecord
			'cPrint "Press a key to close", 21, 11, 2, 0
			'UKey$ = "": DO: UKey$ = INKEY$: LOOP WHILE UKey$ = ""
		      
			SELECT CASE MuteFlag%: CASE 1, 2: UsePCSpk% = 1: UseAdlib% = 0: CASE 3, 4: UseAdlib% = 1: UsePCSpk% = 0: END SELECT
			EXIT SUB

			ELSE
			'Clear Things section
			LOCATE 15, 11: PRINT "Attempt a record?";
			IF RemoveOnFind% = 1 THEN LOCATE 16, 11: PRINT "Untick CLEAR Things";
			IF UseTimer&(0) = 0 THEN LOCATE 17, 11: PRINT "Enable TIMED Game";
			uSleep .75
			cPrint "Press a key to close", 21, 11, 2, 0
			UKey$ = "": DO: UKey$ = INKEY$: LOOP WHILE UKey$ = ""
			EXIT SUB
			END IF
		       
		       
		ELSE 'Next PuzPos%
			PlayFX 7: Speak 2 'Complete Thing
			PuzzleUI 4
			PuzFlag% = 0: PuzzleUI 5
		END IF

	ELSE 'Find next iteration of target thing
	PlayFX 1: Speak 0 'Swish
	PuzFlag% = 1: PuzzleUI 5  'Update Target Thing
	END IF
ELSE 'PuzzleTry failed
GameErrorCount% = GameErrorCount% + 1
GameCurrentStreak% = 0 'Reset
PuzzleUI 22 'Update Streak PuzzleUI

END IF
GOTO GameKey 'Loop back to key handler


UpdateSel:
HideMouse
RowPos% = OffSetY% + (((PrvSel%(CurrentBoard%)) \ (BoardCols% + 1)) * CellSize%)
ColPos% = OffSetX% + (((PrvSel%(CurrentBoard%)) MOD (BoardCols% + 1)) * CellSize%)
LINE (ColPos% - 1, RowPos% - 1)-(ColPos% + CellSize% - 1, RowPos% + CellSize% - 1), BoardBG%, B

RowPos% = OffSetY% + (((CurSel%(CurrentBoard%)) \ (BoardCols% + 1)) * CellSize%)
ColPos% = OffSetX% + (((CurSel%(CurrentBoard%)) MOD (BoardCols% + 1)) * CellSize%)

'Logic for Selection color based on Cell Background
IF BoardMax% = 1 THEN
	UseCell% = CurSel%(CurrentBoard%)
ELSE
	UseCell% = CurSel%(CurrentBoard%) + ((CurrentBoard% - 1) * 99)
END IF

uSelColor% = SelColor% 'Make sure selection border doesnt clash with cell bg
SELECT CASE PuzzleD%(UseCell%)
	CASE 6, 11, 12: uSelColor% = 1 '3
END SELECT
LINE (ColPos% - 1, RowPos% - 1)-(ColPos% + CellSize% - 1, RowPos% + CellSize% - 1), uSelColor%, B

PrvSel%(CurrentBoard%) = CurSel%(CurrentBoard%)

IF UseMouse% = 1 THEN  'Cursor Mouse!
	Mouse 1 'Show
	IF B% = 0 THEN 'Only if we didn't click!
	Regs.ax = 4: Regs.cx = ((ColPos% + CellSize%) * 2) - 8: Regs.dx = RowPos% + CellSize% - 3
	INTERRUPT &H33, Regs, Regs
	END IF
END IF


RETURN


END SUB

REM $STATIC
FUNCTION SecsToTime$ (inSecs%, fFlag%)
'Convert seconds integer into mmM:SS
'Maximum count is 30000 seconds or 8.3hrs

UseSecs$ = LTRIM$(STR$((inSecs% MOD 60)))
IF LEN(UseSecs$) = 1 THEN UseSecs$ = "0" + UseSecs$
IF fFlag% = 0 THEN 'Format Flag
	UseMin$ = LTRIM$(RTRIM$(STR$(inSecs% \ 60)))
	UseMin$ = STRING$(3 - LEN(UseMin$), "0") + UseMin$
	SecsToTime$ = UseMin$ + ":" + UseSecs$
ELSE
	SecsToTime$ = LTRIM$(RTRIM$(STR$(inSecs% \ 60))) + ":" + UseSecs$
END IF
END FUNCTION

REM $DYNAMIC
SUB Speak (SpeakFX%)
'Use the PC Speaker to PLAY sounds

IF UsePCSpk% = 0 THEN EXIT SUB 'Unless it's muted

SELECT CASE SpeakFX%
	CASE 1: PLAY "MBT180O3L8 GGGL2E" 'Startup
	CASE 2: PLAY "MBT180L16O5 CEGO6C" 'Complete Thing
	CASE 3: PLAY "MBT180L16O3 DA" 'Find Thing
	CASE 0: PLAY "MBT255L64O3 C" 'Fail
END SELECT

END SUB

SUB TryRecord
'Simple routine to figure out if the time achieved is in the top 5
REDIM uRecs$(180), rUser$(6), rTime%(6), rDate$(6), rStreak%(6), rErrors%(6)

IF GameType% > 3 OR UseTimer&(0) = 0 OR RemoveOnFind% = 1 THEN 'Fail quit
	GOTO QuitRecord
END IF

'Still alive - Try the score
SELECT CASE GameType% 'Figure out our starting record (0-4) for best time attempt
CASE 1:
	SELECT CASE PuzMax%
		CASE 15: StartRecord% = 0
		CASE 24: StartRecord% = 20
		CASE 35: StartRecord% = 40
		CASE 48: StartRecord% = 60
	END SELECT
CASE 2: StartRecord% = 80
CASE 3: StartRecord% = 105 + ((BoardMax% - 2) * 25)
END SELECT
StartRecord% = StartRecord% + (GamePreset% * 5) 'Starting position for 0-4

iPrint "- CHECKING RECORDS -", 112, 166, 1, 0
F = FREEFILE: OPEN "RECORDS.DAT" FOR INPUT AS #F
UseC% = -1
DO
	UseC% = UseC% + 1: LINE INPUT #F, uRecs$(UseC%)
	IF EOF(F) THEN EXIT DO
LOOP
CLOSE #F
IF UseC% <> 179 THEN GOTO QuitRecord 'Dont Save

FOR X% = StartRecord% TO StartRecord% + 4 'create game table
	UseK% = StrSplit%("|", uRecs$(X%))
	IF SplitWords$(0) <> LTRIM$(RTRIM$(STR$(X%))) THEN GOTO QuitRecord  'Fail out, there's a problem!
	UseT% = X% - StartRecord%
	rUser$(UseT%) = SplitWords$(1): rTime%(UseT%) = VAL(SplitWords$(2))
	rDate$(UseT%) = SplitWords$(3): rStreak%(UseT%) = VAL(SplitWords$(4)): rErrors%(UseT%) = VAL(SplitWords$(5))
NEXT X%

Flag% = -1 'Not yet a record (default)
FOR UseC% = 0 TO 4
	IF UseTimer&(2) < rTime%(UseC%) THEN
		Flag% = UseC%: EXIT FOR
	ELSEIF UseTimer&(2) = rTime%(UseC%) THEN
	'Tie - Compare Errors then Streak
		IF GameErrorCount% < rErrors%(UseC%) THEN
			Flag% = UseC%: EXIT FOR
		ELSEIF GameErrorCount% = rErrors%(UseC%) THEN
		'STILL A TIE!! Can we break it with Streak records?
		'If Streak records are the same this new value will be evaluated against the next lowest value
		IF GameStreakCount% > rStreak%(UseC%) THEN Flag% = UseC%: EXIT FOR
		END IF
	END IF
NEXT UseC%

IF Flag% > -1 THEN 'Yes it's a Record!
LINE (112, 166)-(195, 170), 0, BF'Clear iPrint

SELECT CASE Flag%: CASE 0: Text$ = "1st": UseThing% = 54: CASE 1: Text$ = "2nd": UseThing% = 65: CASE 2: Text$ = "3rd": UseThing% = 54: CASE 3: Text$ = "4th": UseThing% = 36: CASE 4: Text$ = "5th": UseThing% = 5: END SELECT
cPrint Text$ + " best time!", 14, 15, 1, 0

'LINE (108, 86)-(123, 111), 3, B
LINE (85, 101)-(101, 117), 1, BF
PUT (85, 101), Thing%(UseThing% * 45), AND

UName$ = "": LOCATE 17, 11: PRINT "Enter your name:";
LOCATE 18, 11: PRINT ">";
NewRecordKey:
L% = LEN(UName$)
LOCATE 18, 13: PRINT UName$; STRING$(10 - L%, " ");
UKey$ = "": DO: UKey$ = INKEY$: LOOP WHILE UKey$ = ""
SELECT CASE ASC(UKey$)
	CASE ASC("A") TO ASC("Z"), ASC("a") TO ASC("z"), 48 TO 57
	IF L% < 10 THEN UName$ = UName$ + UKey$
	CASE 32: UName$ = LTRIM$(UName$ + " ")
	CASE 13: IF L% > 0 THEN GOTO StoreRecord
	CASE 8: IF L% > 0 THEN UName$ = LEFT$(UName$, L% - 1)
END SELECT
GOTO NewRecordKey
ELSE 'Just show the record table
UseRecord% = -1
GOSUB PrintTable
GOTO QuitRecord
END IF

StoreRecord:
'If Flag% >-1 then we have our new position 0-4
'0: Swap 3->4, 2->3, Swap 1->2, Swap 0->1 and Overwrite 0
'1: Leave 0, Swap 3->4, 2->3, 1->2 and Overwrite 1
'2: Leave 0,1, Swap 3->4, 2->3 and Overwrite 2
'3: Swap 3->4 and Overwrite 3
'4: Overwrite only

FOR UseT% = 3 TO 0 STEP -1
IF UseT% >= Flag% THEN
	UseA% = UseT%: UseB% = UseA% + 1
	SWAP rUser$(UseA%), rUser$(UseB%)
	SWAP rTime%(UseA%), rTime%(UseB%)
	SWAP rDate$(UseA%), rDate$(UseB%)
	SWAP rStreak%(UseA%), rStreak%(UseB%)
	SWAP rErrors%(UseA%), rErrors%(UseB%)
END IF
NEXT UseT%

IF Flag% >= 0 AND Flag% <= 4 THEN 'Perform the update
	UseRecord% = Flag%
	rUser$(UseRecord%) = LTRIM$(RTRIM$(UName$))
	rTime%(UseRecord%) = UseTimer&(2)
	rDate$(UseRecord%) = DATE$
	rStreak%(UseRecord%) = GameStreakCount%
	rErrors%(UseRecord%) = GameErrorCount%
END IF

'Print out the best time table for the segment
GOSUB PrintTable

iPrint "- SAVING RECORD -", 112, 166, 1, 0

IF Flag% >= 0 THEN 'Save Record
'Stage 1 - Overwrite uRecs$(StartRecord%)
FOR J% = StartRecord% TO StartRecord% + 4
X% = J% - StartRecord% '0-4 base
Temp$ = LTRIM$(STR$(J%)) + "|" + rUser$(X%) + "|" + LTRIM$(STR$(rTime%(X%))) + "|" + rDate$(X%) + "|" + LTRIM$(STR$(rStreak%(X%))) + "|" + LTRIM$(STR$(rErrors%(X%)))
uRecs$(J%) = Temp$
NEXT J%

'Stage 2 - Dump the file
F = FREEFILE: OPEN "RECORDS.DAT" FOR OUTPUT AS #F
FOR UseC% = 0 TO 179
	PRINT #F, uRecs$(UseC%)
NEXT UseC%
CLOSE #F
END IF


QuitRecord: 'For fails or terminate
ERASE uRecs$, rUser$, rTime%, rDate$, rStreak%, rErrors%
iPrint "- PRESS A KEY TO CLOSE -", 112, 166, 2, 0
UKey$ = "": DO: UKey$ = INKEY$: LOOP WHILE UKey$ = ""
EXIT SUB

PrintTable: 'Display mini records table
LINE (80, 101)-(236, 162), 0, BF
LINE (80, 110)-(236, 162), 1, B
iPrint "GAME: " + GetGameID$(StartRecord%), 80, 103, 1, 0
FOR X% = 0 TO 4
      
	IF rUser$(X%) <> "!99THINGS!" THEN
		UseC$ = LTRIM$(RTRIM$(STR$(rTime%(X%) MOD 60)))
		IF LEN(UseC$) = 1 THEN UseC$ = "0" + UseC$
		uTime$ = LTRIM$(RTRIM$(STR$(rTime%(X%) \ 60))) + ":" + UseC$
		Text$ = STR$(X% + 1) + ". " + rUser$(X%) + STRING$(10 - LEN(rUser$(X%)), " ") + " " + uTime$ + " S:" + LTRIM$(STR$(rStreak%(X%))) + " E:" + LTRIM$(STR$(rErrors%(X%)))
		UCol% = 3
		IF X% = UseRecord% THEN UCol% = 2
	ELSE
		UCol% = 3: Text$ = STR$(X% + 1) + ". NO RECORD SET"
	END IF
	iPrint Text$, 82, 114 + (10 * (X%)), UCol%, 0
NEXT X%
RETURN

END SUB

