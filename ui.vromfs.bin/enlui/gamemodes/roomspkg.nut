import "%ui/components/faComp.nut" as faComp
from "%ui/style/designConst.nut" import defTxtColor
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/gameModes/eventModeStyle.nut" import lockIconSize
from "%ui/ui_library.nut" import *

let txt = @(text, width = FLEX, color = defTxtColor) {
    size = [width, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXT
    color
    text
  }.__update(fontSub)

let textArea = @(text, params = {}) {
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = defTxtColor
    text
  }.__update(fontSub, params)

let lockIcon = faComp("lock", {
    fontSize = lockIconSize
    valign = ALIGN_CENTER
  })

let mkIcon = @(icon, size){
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture($"{icon}:{size}:{size}")
  color = defTxtColor
}


let iconInBattle = mkIcon("!ui/uiskin/status/in_battle_status.svg", lockIconSize)
let iconPreparingBattle = mkIcon("!ui/uiskin/status/not_ready_status.svg", lockIconSize)
let iconMod = mkIcon("!ui/uiskin/mod_icon.svg", lockIconSize)


return {
  txt
  textArea
  lockIcon
  iconInBattle
  iconPreparingBattle
  iconMod
}