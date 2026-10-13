import "regexp2" as regexp2
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/ui_library.nut" import *

function dmColor(state){
  if (state == 65535)
    return Color(173, 224, 255, 255)
  let grad = 230 * state / 65535
  return Color(242, grad, 0, 255)
}

let mkText = @(slot) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = dmColor(slot.state)
  indent = hdpx(5)
  transform = true
}.__update(fontSub)

const size = hdpxi(60)

function getIconName(name){
  let reg = regexp2(@"_\d")
  let newName = reg.replace("splitter", name)
  return newName.split("splitter")?[0] ?? "empty"
}

let mkIcon = @(slot) {
  size = const [size, size]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  color = dmColor(slot.state)
  image = Picture($"!ui/uiskin/repair_parts/{getIconName(slot.name)}.svg:{size}:{size}:K")
  fallbackImage = Picture($"!ui/uiskin/repair_parts/empty.svg")
}

let mkPieItemCtor = @(slot) @(...) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  children = [
    mkText(slot)
    mkIcon(slot)
  ]
}

return{
  mkPieItemCtor
  getIconName
}
