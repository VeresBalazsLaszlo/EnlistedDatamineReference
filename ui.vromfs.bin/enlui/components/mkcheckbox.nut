import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import accentColor, commonBorderRadius, panelBgColor, disabledBdColor, disabledBgColor, disabledTxtColor, midPadding
from "%ui/ui_library.nut" import *

let mkLabel = @(label, size, textParams, isActive, isLeftOrientation = true) {
  rendObj = ROBJ_TEXTAREA
  size
  behavior = Behaviors.TextArea
  text = label
  halign = isLeftOrientation ? ALIGN_RIGHT : ALIGN_LEFT
}.__update(textParams, !isActive ? { color = disabledTxtColor } : {})


let checkBox = @(isChecked, isActive, isHovered) {
  size = hdpxi(18)
  rendObj = ROBJ_BOX
  borderWidth = isHovered ? hdpx(2) : hdpx(1)
  borderRadius = commonBorderRadius * 2
  borderColor = isActive ? accentColor : disabledBdColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = isActive ? panelBgColor : disabledBgColor
  children = !isChecked ? null : faComp("check", {
    color = accentColor
    fontSize = hdpxi(12)
  })
}


function mkCheckbox(isChecked, label, params = {}) {
  let { canBeModified = true, isActive = true, size = FLEX_H,
    isLeftOrientation = true, onClick = null, textParams = fontSub, blockParams = {}
  } = params

  let defAction = @() isChecked.set(!isChecked.get())
  return watchElemState(@(sf) {
    watch = isChecked
    size
    behavior = Behaviors.Button
    onClick = !isActive ? null
      : canBeModified ? onClick ?? defAction
      : !canBeModified && onClick != null ? onClick
      : defAction
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      isLeftOrientation ? null : mkLabel(label, size, textParams, isActive)
      checkBox(isChecked.get(), isActive, sf & S_HOVER)
      !isLeftOrientation ? null : mkLabel(label, size, textParams, isActive, !isLeftOrientation)
    ]
  }.__update(blockParams))
}


return mkCheckbox