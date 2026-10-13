import "%ui/userLog/userLogScene.nut" as userLogScene
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor
from "%ui/featureFlags.nut" import hasUserLogs
from "%ui/components/textButton.nut" import FASecondary
from "%ui/mainMenu/mainmenu.style.nut" import navBottomBarHeight
from "%ui/ui_library.nut" import *

let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("tooltips/userLogs")
}.__update(hintTxtStyle)

return @() {
  watch = hasUserLogs
  children = !hasUserLogs.get() ? null
    : FASecondary("bell", @() userLogScene(), {
      hint = hoverHint
      btnWidth = navBottomBarHeight
      btnHeight = navBottomBarHeight
    })
}
