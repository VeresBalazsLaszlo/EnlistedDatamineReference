from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let fireTip = tipCmp({
  inputId = "Human.Shoot"
  text = loc("controls/Human.Shoot")
  style={rendObj=null}.__update(fontSub)
})

let exitTip = tipCmp({
  inputId = "Mortar.Cancel"
  text = loc("controls/cancelMortarAiming")
  style={rendObj=null}.__update(fontSub)
})

let mapTip = tipCmp({
  inputId = "HUD.BigMap"
  text = loc("controls/HUD.BigMap")
  style={rendObj=null}.__update(fontSub)
})

return {
  flow = FLOW_VERTICAL
  gap = hdpx(5)
  children = [fireTip, exitTip, mapTip]
}
