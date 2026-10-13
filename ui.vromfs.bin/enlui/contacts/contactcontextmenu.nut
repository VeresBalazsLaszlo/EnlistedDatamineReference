import "%ui/helpers/locByPlatform.nut" as locByPlatform
from "%ui/components/contextMenu.nut" import addContextMenu
from "%ui/contacts/consoleUidsRemap.nut" import uid2console
from "%ui/contacts/externalIdsManager.nut" import searchContactByInternalId
from "%ui/ui_library.nut" import *

let { consoleCompare } = require("%ui/helpers/platformUtils.nut")

function openContextMenu(userId, event, actions) {
  let actionsButtons = (actions ?? []).map(@(action) {
    isVisible = action.mkIsVisible(userId)
    text = locByPlatform(action.locId)
    action = @() action.action(userId)
  })
  if (actionsButtons.len())
    addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), actionsButtons)
}

function open(contactValue, event, actions) {
  if (contactValue.userId in uid2console.get()) {
    openContextMenu(contactValue.userId, event, actions)
    return
  }

  foreach (data in consoleCompare)
    if (data.isPlatform && data.isFromPlatform(contactValue.realnick)) {
      searchContactByInternalId(contactValue.userId, function() {
        openContextMenu(contactValue.userId, event, actions)
      })
      return
    }

  openContextMenu(contactValue.userId, event, actions)
}



return {
  open = open
}