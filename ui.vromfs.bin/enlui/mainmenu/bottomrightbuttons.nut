import "%ui/mailboxButton.ui.nut" as mailboxButton
import "%ui/contacts/contactsListWnd.nut" as showContactsListWnd
import "%ui/contacts/mkContactsButton.nut" as mkContactsButton
import "%ui/squad/squadWidget.ui.nut" as squadWidget
import "%ui/userLog/userLogButton.nut" as userLogButton
import "%ui/usermail/usermailButton.nut" as usermailButton
from "%ui/style/colors.nut" import Inactive
from "%ui/style/designConst.nut" import bigGap, gap
from "%ui/mainMenu/mainmenu.style.nut" import navBottomBarHeight
from "%ui/contacts/contactsState.nut" import isContactsEnabled
from "%ui/squad/squadState.nut" import enabledSquad
from "%ui/mainMenu/sectionsState.nut" import hasMainSectionOpened
from "%ui/ui_library.nut" import *

let buttons = [mailboxButton]
if (isContactsEnabled)
  buttons.append(mkContactsButton(showContactsListWnd))

buttons.append(userLogButton)
buttons.append(usermailButton)


let buttonsBlock = freeze({
  size = [SIZE_TO_CONTENT, navBottomBarHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap
  children = buttons
})

function bottomBar() {
  let res = { watch = [hasMainSectionOpened, enabledSquad] }
  let children = []
  if (hasMainSectionOpened.get()) {
    if (enabledSquad.get())
      children.append(squadWidget)
    if (buttons.len() > 0)
      children.append(buttonsBlock)
  }
  if (children.len() <= 0)
    return res

  return res.__update({
    size = FLEX_H
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = {
      size = const [hdpx(1), ph(65)]
      rendObj = ROBJ_SOLID
      color = Inactive
      margin = [0, bigGap, 0, bigGap]
    }
    children
  })
}

return bottomBar
