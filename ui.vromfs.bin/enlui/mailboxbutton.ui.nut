import "%ui/mailboxBlock.nut" as mailboxWndOpen
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor
from "%ui/mainScene/invitationsLogState.nut" import isMailboxVisible, unreadNum, hasUnread
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/textButton.nut" import FASecondary
from "%ui/state/appState.nut" import isInMainMenuState
from "%ui/mainMenu/mainmenu.style.nut" import navBottomBarHeight
from "%ui/ui_library.nut" import *

let animsCounter = [
  {prop = AnimProp.scale from =[3.0, 3.0] to = [1.0,1.0]  duration = 0.5 trigger="new_mail" easing = OutCubic}
]
const soundNewMail = "ui/enlist/notification"
let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

function readNumCounter(){
  let num = unreadNum.get()
  return {
    watch = unreadNum
    rendObj = ROBJ_TEXT
    text = num < 1 ? "" : num
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    pos = const [-hdpx(3), hdpx(4)]
    fontFx = FFT_GLOW
    transform = { pivot = [0.5,0.5] }
    fontFxColor = Color(0, 0, 0, 255)
    animations = animsCounter
  }.__update(fontSub)
}

local prevUnread = unreadNum.get()
unreadNum.subscribe(function(v) {
  if (isInMainMenuState.get())
    if (v > prevUnread) {
        sound_play(soundNewMail)
        anim_start("new_mail")
    } else
      anim_request_stop("new_mail")
  prevUnread = v
})

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("tooltips/invites")
}.__update(hintTxtStyle)

return @() {
  watch = [hasUnread, isMailboxVisible]
  children = [
    FASecondary("flag", mailboxWndOpen, {
      hint = hoverHint
      selected = isMailboxVisible
      btnWidth = navBottomBarHeight
      btnHeight = navBottomBarHeight
      key = hasUnread.get()
      animations = hasUnread.get()
        ? [{prop = AnimProp.scale, from =[1.0, 1.0], to = [1.1, 1.1], duration = 1.3, loop = true, play = true, easing = CosineFull }]
        : null
    })
    readNumCounter
  ]
}
