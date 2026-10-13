import "%ui/hud/state/battle_area_warnings.nut" as displayOutsideBattleAreaWarning
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/ui_library.nut" import *

return function () {
  let watch = displayOutsideBattleAreaWarning
  if (!displayOutsideBattleAreaWarning.get())
    return { watch = watch }

  return {
    watch = watch
    behavior = Behaviors.TextArea
    color = Color(255,180,180,200)
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    margin = fsh(20)
    text = loc("leftBattleArea")
  }.__update(fontHeading2)
}