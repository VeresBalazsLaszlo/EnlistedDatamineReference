import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/style/colors.nut" as colors
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import bigGap, gap
from "%ui/components/textButton.nut" import Regular, FARegular
from "%ui/mainScene/invitationsLogState.nut" import inbox, clearAll, markReadAll, hasUnread, isMailboxVisible, onNotifyRemove, onNotifyShow
from "%ui/style/buttonsStyle.nut" import purchaseButtonStyle, primaryFlatButtonStyle
from "%ui/ui_library.nut" import *

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")

const MAILBOX_MODAL_UID = "mailbox_modal_wnd"
const wndWidth = hdpx(450)
const maxListHeight = hdpx(300)
let padding = gap










let mkRemoveBtn = @(notify) {
  size = SIZE_TO_CONTENT
  padding = [0, gap]
  children = fontIconButton("trash-o",
    { onClick = @() onNotifyRemove(notify),
      color = Color(200,200,200)
    })
}

let btnParams = {
  size = const [FLEX, hdpx(30)]
  halign = ALIGN_LEFT
}.__update({ textParams = fontSub })

let defaultStyle = btnParams
let buttonStyles = {
  toBattle = purchaseButtonStyle.__merge(btnParams)
  primary = primaryFlatButtonStyle.__merge(btnParams)
}

let item = @(notify) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap
  children = [
    Regular(notify.text, @() onNotifyShow(notify), (buttonStyles?[notify.styleId] ?? defaultStyle))
    mkRemoveBtn(notify)
  ]
}

let mailsPlaceHolder = {
  size = FLEX_H
  rendObj = ROBJ_SOLID
  padding = padding
  color = colors.ControlBg
  children = {
    rendObj = ROBJ_TEXT
    color = colors.TextHighlight
    text = loc("no notifications")
  }
}

let mkHeader = @(total) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER

  children = [
    {
      rendObj = ROBJ_TEXT
      text="{0} {1}".subst(loc("Notifications:"), total > 0 ? total : "")
      color =colors.Inactive
      margin = [0, 0, 0, gap]
    }
    {size=const [FLEX,0]}
    {
      vplace = ALIGN_CENTER
      children = fontIconButton("times", { onClick = @() modalPopupWnd.remove(MAILBOX_MODAL_UID) })
    }
  ]
}

let clearAllBtn = FARegular("trash-o", clearAll, {hplace=ALIGN_RIGHT})

function mailboxBlock() {
  let elems = inbox.get().map(item)
  if (elems.len() == 0)
    elems.append(mailsPlaceHolder)
  elems.reverse()

  return {
    size = const [wndWidth, SIZE_TO_CONTENT]
    watch = [hasUnread, inbox]
    flow = FLOW_VERTICAL
    gap = bigGap

    children = [
      mkHeader(inbox.get().len())
      scrollbar.makeVertScroll({
        size = FLEX_H
        gap = gap
        flow = FLOW_VERTICAL
        children = elems
      },
      {
        size = FLEX_H
        maxHeight = maxListHeight
        needReservePlace = false
      })
      clearAllBtn
    ]
  }
}

inbox.subscribe(function(v) { if (v.len() == 0) modalPopupWnd.remove(MAILBOX_MODAL_UID) })

return @(event) modalPopupWnd.add(event.targetRect,
  {
    watch = inbox 
    uid = MAILBOX_MODAL_UID
    onAttach = function() {
      markReadAll()
      isMailboxVisible.set(true)
    }
    onDetach = function() {
      markReadAll()
      isMailboxVisible.set(false)
    }

    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    fillColor = colors.WindowBlurredColor
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = colors.ModalBgTint }

    children = mailboxBlock
  })