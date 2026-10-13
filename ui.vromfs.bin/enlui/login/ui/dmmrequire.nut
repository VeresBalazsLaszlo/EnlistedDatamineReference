import "%ui/components/centeredText.nut" as centeredText
from "%ui/components/textButton.nut" import Regular
from "app" import exit_game
from "%ui/ui_library.nut" import *

return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      centeredText(loc("error/shouldRunFromDMMLauncher"))
      Regular(loc("gamemenu/btnQuit"), exit_game)
    ]
}
