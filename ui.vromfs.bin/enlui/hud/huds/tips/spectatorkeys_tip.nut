from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tipNext = tipCmp({
  inputId = "Spectator.Next"
})

let tipPrev = tipCmp({
  inputId = "Spectator.Prev"
})

let hintChangeSpectator = {
  rendObj = ROBJ_TEXT
  text = loc("hud/spectator_change_target")
}.__update(fontBody)

let spectatorKeys_tip = @() {
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    hintChangeSpectator
    tipPrev
    tipNext
  ]
}

return spectatorKeys_tip
