from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, unseenColor
from "%ui/usermail/usermailState.nut" import isUsermailWndOpened, unseenLettersCount
from "%ui/featureFlags.nut" import hasUsermail
from "%ui/components/textButton.nut" import FASecondary
from "%ui/mainMenu/mainmenu.style.nut" import navBottomBarHeight
from "%ui/ui_library.nut" import *

let numUnseenCmp = @(count) count == 0 ? null : {
  rendObj = ROBJ_TEXT
  text = count
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  pos = const [-hdpx(3), hdpx(4)]
  fontFx = FFT_GLOW
  fontFxColor = Color(0, 0, 0, 255)
  color = unseenColor
}.__update(fontSub)

let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("mail/mailTab")
}.__update(hintTxtStyle)


return @() {
  watch = [hasUsermail, unseenLettersCount]
  children = !hasUsermail.get() ? null
    : [
        FASecondary("envelope", @() isUsermailWndOpened.set(true), {
          hint = hoverHint
          btnWidth = navBottomBarHeight
          btnHeight = navBottomBarHeight
        })
        numUnseenCmp(unseenLettersCount.get())
      ]
}