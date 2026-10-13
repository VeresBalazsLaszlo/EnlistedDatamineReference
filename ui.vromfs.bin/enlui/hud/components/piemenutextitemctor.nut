import "%ui/components/fontawesome.map.nut" as fa
from "%ui/style/fontsStyle.nut" import fontawesome
from "%ui/ui_library.nut" import *

const curTextColor = Color(250,250,200,200)
const defTextColor = Color(150,150,150,50)
const disabledTextColor = Color(50, 50, 50, 50)
const blockedColor = 0xFFFF6060


let mkDisableIcon = @(isBlocked) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_INSCRIPTION
  font = fontawesome.font
  text = fa["times-circle-o"]
  pos = const [-hdpx(30), 0]
  color = isBlocked ? blockedColor : disabledTextColor
  fontSize = hdpx(20)
}

let pieMenuTextItemCtor = @(text, available = Watched(true), isBlocked = Watched(false)) function(curIdx, idx) {
  if (!(isObservable(text)))
    text = Watched(text)
  let isActive = Computed(@() curIdx.get() == idx)
  return watchElemState(@(sf) {
      watch = [text, available, isBlocked, isActive]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text.get()
      color = !available.get() ? disabledTextColor
        : (sf & S_HOVER) || isActive.get() ? curTextColor
        : defTextColor
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      maxWidth = hdpx(140)
      valign = ALIGN_CENTER

      children = available.get() ? null : mkDisableIcon(isBlocked.get())
    })
}

return kwarg(pieMenuTextItemCtor)