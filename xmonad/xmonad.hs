import Data.List
import Data.Monoid
import Data.Ratio ((%))
import System.Exit
import System.IO
import XMonad
import XMonad.Actions.GridSelect
import XMonad.Actions.SpawnOn
import XMonad.Actions.UpdatePointer
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.Grid
import XMonad.Layout.IM
import XMonad.Layout.Spiral
import XMonad.Layout.NoBorders
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Util.Run

import qualified Data.Map as M
import qualified XMonad.Actions.Search as S
import qualified XMonad.StackSet as W

myTerminal = "urxvt +ls"

myIconDir = "~/.xmonad/icons"

myFocusFollowsMouse = True -- Whether focus follows the mouse pointer.

-- Width of the window border in pixels.
myBorderWidth = 1

-- modMask lets you specify which modkey you want to use. 
-- The default is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. 
-- The "windows key" is usually mod4Mask.
myModMask = mod1Mask

-- The default number of workspaces (virtual screens) and their names.
myWorkspaces = ["1:code","2:","3","4","5:media","6","7:Gimp","8:Chat","9:Monitor"]

-- Border colors for unfocused and focused windows, respectively.
myNormalBorderColor  = "#123456"
myFocusedBorderColor = "#ff0000"

-- Colors for text and backgrounds of each tab when in "Tabbed" layout.
--
tabConfig = defaultTheme {
  activeBorderColor = "#7C7C7C",
  activeTextColor = "#CEFFAC",
  activeColor = "#000000",
  inactiveBorderColor = "#7C7C7C",
  inactiveTextColor = "#EEEEEE",
  inactiveColor = "#000000"
}

-- Prompt style.
myXPConfig :: XPConfig
myXPConfig = defaultXPConfig {
  font = "xft:Terminus-12"
    , position = Bottom
    , bgColor = "#000000"
    , bgHLight = "#000000"
    , fgHLight = "#ffffff"
    , promptBorderWidth = 0
    , height = 40
}

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $

    [
     -- launch a terminal
    ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)

    -- close focused window
    , ((modm .|. shiftMask, xK_c     ), kill)

     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)

    -- Move focus to the next window
    , ((modm,               xK_Tab   ), windows W.focusDown)

    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm,               xK_Return), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )

    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)

    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modm,               xK_t     ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

    -- Toggle the status bar gap
    -- Use this binding with avoidStruts from Hooks.ManageDocks.
    -- See also the statusBar function from Hooks.DynamicLog.
    --
    , ((modm              , xK_b     ), sendMessage ToggleStruts)

    -- Quit xmonad
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))

    -- Restart xmonad
    , ((modm              , xK_q     ), spawn "xmonad --recompile; xmonad --restart")

    -- Search with Google
    , ((modm             , xK_s     ), S.promptSearch myXPConfig S.google)

    -- Open GridSelect
    , ((modm, xK_g), goToSelected defaultGSConfig)

    -- Run a shell command
    , ((modm              , xK_p     ), shellPrompt myXPConfig)

    -- Run a pomodoro command
    , ((modm              , xK_n     ), spawn "touch ~/.pomodoro_session")

    ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

------------------------------------------------------------------------
-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
myLayout = onWorkspace "7:Gimp" gimpLayout $
           onWorkspace "8:Chat" chatLayout $
           standardLayouts
  where
    chatLayout = avoidStruts $ smartBorders $ withIM skypeRatio skypeRoster (tiled ||| reflectTiled ||| Grid) where
    gimpLayout = withIM (0.11) (Role "gimp-toolbox") $ reflectHoriz $ withIM (0.15) (Role "gimp-dock") Full

    -- Percent of screen to increment by when resizing panes
    delta = 3/100

    -- The default number of windows in the master pane
    nmaster = 1

    -- Default proportion of screen occupied by master pane
    ratio = 1/2

    reflectTiled = (reflectHoriz tiled)

    skypeRatio = (1%4)
    skypeRoster = (ClassName "Skype") `And` (Not (Title "Options")) `And` (Not (Role "Chats")) `And` (Not (Role "CallWindowForm"))

    standardLayouts = avoidStruts  $ (tiled ||| spiral (6/7) ||| tabbed shrinkText tabConfig ||| Full)

    -- default tiling algorithm partitions the screen into two panes
    tiled = Tall nmaster delta ratio

------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook = composeAll . concat $
   [ [isFullscreen --> doFullFloat]
   , [isDialog --> doCenterFloat]
   , [ className =? "Emacs" --> doShift "1:Emacs"]
   , [ className =? "Chromium" --> doShift "2:Web"]
   , [ className =? "Gimp" --> doShift "7:Gimp"]
   , [ className =? "Skype" --> doShift "8:Chat" ]
   , [(className =? "Chromium" <&&> stringProperty "WM_WINDOW_ROLE" =? "pop-up") --> doCenterFloat]
     -- using list comprehensions and partial matches
   , [ className =?  c --> doCenterFloat | c <- myCenterFloats ]
   , [ className =?  c --> doFloat | c <- myFloats ]
   , [ fmap ( c `isInfixOf`) className --> doFloat | c <- myMatchAnywhereFloatsC ]
   , [ fmap ( c `isInfixOf`) title     --> doFloat | c <- myMatchAnywhereFloatsT ]
   ]
   -- in a composeAll hook, you'd use: fmap ("VLC" `isInfixOf`) title --> doFloat
  where myFloats = ["Gajim.py", "Xmessage"]
        myCenterFloats = ["Gnome-volume-control", "Gcalctool", "Gnome-screenshot", "Gnome-system-monitor"]
        myMatchAnywhereFloatsC = ["Google","Pidgin"]
        myMatchAnywhereFloatsT = ["VLC"] -- this one is silly for only one string!

------------------------------------------------------------------------
-- Event handling

-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
--
myEventHook = mempty

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
--
myLogHook = fadeInactiveLogHook fadeAmount
          >> updatePointer (Relative 0.5 0.5)
          where fadeAmount = 0.8

myPP = xmobarPP {
  ppCurrent = xmobarColor "#93a1a1" "",
  ppTitle = xmobarColor "green" "" . shorten 50,
  ppHiddenNoWindows = xmobarColor "#073642" "",
  ppHidden = xmobarColor "#586e75" "",
  ppLayout = xmobarColor "#586e75" ""
}

myBar = "~/.cabal/bin/xmobar"

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
--
--
myStartupHook = do
              setWMName "LG3D"
              spawn "xcompmgr -C"
              -- spawnOn "9:Monitor" "urxvt -e 'htop'"

------------------------------------------------------------------------
-- Keybinding to toggle the gap for the status bar.
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

main = do
  xmonad =<< statusBar myBar myPP toggleStrutsKey defaults

-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
defaults = defaultConfig {
  terminal           = myTerminal,
  focusFollowsMouse  = myFocusFollowsMouse,
  borderWidth        = myBorderWidth,
  modMask            = myModMask,
  workspaces         = myWorkspaces,
  normalBorderColor  = myNormalBorderColor,
  focusedBorderColor = myFocusedBorderColor,
  keys               = myKeys,
  layoutHook         = myLayout,
  manageHook         = myManageHook <+> manageDocks <+> manageSpawn,
  handleEventHook    = myEventHook,
  startupHook        = myStartupHook,
  logHook            = myLogHook <+> dynamicLogWithPP xmobarPP { 
    ppTitle = xmobarColor "blue" "" . shorten 50,
    ppLayout = const "" -- to disable the layout info on xmobar
  }
}
