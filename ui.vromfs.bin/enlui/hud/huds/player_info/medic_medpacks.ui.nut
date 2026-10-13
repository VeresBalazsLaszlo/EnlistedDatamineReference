from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/medic_state.nut" import heroMedicMedpacks
from "%ui/hud/state/soldier_class_state.nut" import heroSoldierKind
from "%ui/ui_library.nut" import *

let medpackIconSize = [hdpxi(26), hdpxi(26)]
let medpackIcon = {
  rendObj = ROBJ_IMAGE
  size = medpackIconSize
  image = Picture($"ui/skin#syringe.svg:{medpackIconSize[0]}:{medpackIconSize[1]}")
}

let medpackCount = @() {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  watch = heroMedicMedpacks
  text = heroMedicMedpacks.get()
}.__update(fontSub)

let medicMedpacks = @() {
  watch = heroSoldierKind
  children = heroSoldierKind.get() == "medic" ? {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      medpackIcon
      medpackCount
    ]
  } : null
}

return {
  medicMedpacks
}