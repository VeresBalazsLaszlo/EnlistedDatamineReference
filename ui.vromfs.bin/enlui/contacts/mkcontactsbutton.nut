import "%ui/contacts/buildCounter.nut" as buildCounter
from "%ui/style/fontsStyle.nut" import fontawesome, fontSub
from "%ui/style/designConst.nut" import defTxtColor, brightAccentColor, warningColor
from "%ui/contacts/contactsWatchLists.nut" import friendsOnlineUids, requestsToMeUids
from "%ui/contacts/contactsState.nut" import isContactsVisible
from "%ui/components/textButton.nut" import FASecondary
from "%ui/mainMenu/mainmenu.style.nut" import navBottomBarHeight
from "%ui/state/incognitoState.nut" import incognitoState, isIncognitoAvailable
from "%ui/ui_library.nut" import *

let counterText = @(count) count > 0 ? count : null
let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

let onlineFriendsCounter = buildCounter(
  Computed(@() counterText(friendsOnlineUids.get().len())),
  { pos = const [-hdpx(3), hdpx(4)] })

let invitationsCounter = buildCounter(
  Computed(@() counterText(requestsToMeUids.get().len())),
  {
    pos = const [-hdpx(3), -hdpx(4)]
    vplace = ALIGN_BOTTOM
    color = brightAccentColor
  })

enum IncognitoState {
  ONLINE = "Online"
  INVISIBLE = "Incognito"
}

let hoverHint = @(state) {
  rendObj = ROBJ_TEXT
  text = loc("tooltips/contactsButton", { state = loc($"contact/{state}") })
}.__update(hintTxtStyle)


let contactsIconParams = {
  hint = hoverHint(IncognitoState.ONLINE)
  btnWidth = navBottomBarHeight
  btnHeight = navBottomBarHeight
}

let incognitoIconParams = {
  hint = hoverHint(IncognitoState.INVISIBLE)
  btnWidth = navBottomBarHeight
  btnHeight = navBottomBarHeight
  textParams = fontawesome.__merge({ color =  warningColor })
}

let contactsButton = @(onClick) @() {
  watch = [isContactsVisible, incognitoState]
  children = [
    FASecondary("users", onClick,
      isIncognitoAvailable && incognitoState.get() ? incognitoIconParams : contactsIconParams)
    onlineFriendsCounter
    invitationsCounter
  ]
}

return contactsButton
