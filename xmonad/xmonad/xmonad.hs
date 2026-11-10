import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.EwmhDesktops
import XMonad.Layout.BinarySpacePartition
import XMonad.Layout.IndependentScreens
import XMonad.Layout.Magnifier
import XMonad.Layout.ThreeColumns
import XMonad.Layout.Spacing
import XMonad.Layout.Gaps
import XMonad.ManageHook
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.NamedScratchpad
import XMonad.Util.SpawnOnce
import qualified XMonad.StackSet as W

main :: IO ()
main = xmonad
     . ewmhFullscreen
     . ewmh
     . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
     $ myConfig

myConfig = def
    { terminal   = "st"      -- Rebind Mod to the Super key
    , layoutHook = myLayout      -- Use custom layouts
    , manageHook = myManageHook  -- Match on certain windows
    , startupHook = myStartupHook -- Autostart apps
    , focusedBorderColor = "#ff79c6"
    , normalBorderColor  = "#bd93f9"
    , borderWidth = 3
    }
  `additionalKeysP`
    [ ("M-d", spawn "rofi -show drun")
    , ("M-x", spawn "power_menu")
    , ("M-C-p", unGrab *> spawn "scrot -s")
    , ("M-S-b"  , spawn "qutebrowser")
    , ("M-C-t"  , spawn "slock")
    , ("M-S-r", spawn "xmonad --recompile")
    , ("M-s", namedScratchpadAction myScratchPads "terminal")
    , ("M-h", namedScratchpadAction myScratchPads "htop")
    , ("M-a", namedScratchpadAction myScratchPads "alsamixer")
    , ("M-n", namedScratchpadAction myScratchPads "nmtui") ]

myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "terminal" "xterm -name scratchpad" (title =? "scratchpad") (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3))
		, NS "htop" "xterm -e htop" (title =? "htop") (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3))
                , NS "alsamixer" "xterm -e alsamixer" (title =? "alsamixer") (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3))
                , NS "nmtui" "xterm -e nmtui" (title =? "nmtui") (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3))
		]

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Gimp" --> doFloat
    , isDialog            --> doFloat
    , title =? "scratchpad" --> doCenterFloat
    , title =? "alsamixer" --> doCenterFloat
    , title =? "nmtui" --> doCenterFloat
    , title =? "htop" --> doCenterFloat
    ]

myLayout = spacingWithEdge 3 $ gaps [(U, 3)] $ emptyBSP ||| tiled ||| Mirror tiled ||| Full ||| threeCol
  where
    threeCol = magnifiercz' 1.3 $ ThreeColMid nmaster delta ratio
    tiled    = Tall nmaster delta ratio
    nmaster  = 1      -- Default number of windows in the master pane
    ratio    = 1/2    -- Default proportion of screen occupied by master pane
    delta    = 3/100  -- Percent of screen to increment by when resizing panes

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "feh --bg-fill ~/Wallpaper/Haskell2.png"
  spawnOnce "synclient TapButton1=1"
  spawnOnce "synclient TapButton2=3"
  spawnOnce "synclient TapButton3=2"
  spawnOnce "xcompmgr -c -f -n"
  spawnOnce "dunst"
  spawnOnce "udiskie -a"
  spawnOnce "redshift -P -l 41.16:-8.62 -t 5700:3500 -g 0.8"
  spawnOnce "xautolock -time 5 -locker slock"

myXmobarPP :: PP
myXmobarPP = def
    { ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip
    , ppCurrent         = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    , ppHidden          = white . wrap " " ""
    , ppHiddenNoWindows = lowWhite . wrap " " ""
    , ppUrgent          = red . wrap (yellow "!") (yellow "!")
    , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
    , ppExtras          = [logTitles formatFocused formatUnfocused]
    }
  where
    formatFocused   = wrap (white    "[") (white    "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue    . ppWindow

    -- | Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#ff79c6" ""
    blue     = xmobarColor "#bd93f9" ""
    white    = xmobarColor "#f8f8f2" ""
    yellow   = xmobarColor "#f1fa8c" ""
    red      = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""
