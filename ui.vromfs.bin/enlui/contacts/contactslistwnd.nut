import "%ui/control/gui_buttons.nut" as JB
import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/contacts/onlineNotifications.nut" as hasFriendOnlineNotification
import "%ui/components/fontIconButton.nut" as fontIconButton
import "%ui/contacts/buildContactsButton.nut" as buildContactsButton
import "%ui/contacts/buildCounter.nut" as buildCounter
import "%ui/helpers/locByPlatform.nut" as locByPlatform
import "%ui/components/checkbox.nut" as checkbox
import "%ui/components/textInput.nut" as textInput
import "%ui/components/modalPopupWnd.nut" as modalPopupWnd
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, smallPadding, panelBgColor,
  bigPadding, defItemBlur, darkPanelBgColor, disabledTxtColor, fullTransparentBgColor
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/text.nut" import dtext as txt
from "%ui/popup/popupBlock.nut" import popupBlockStyle
from "%ui/contacts/contactBlock.nut" import mkContactBlock
from "%ui/contacts/contact.nut" import contacts, getContact, getContactNick, contactsGen
from "%ui/contacts/contactsWatchLists.nut" import approvedUids, psnApprovedUids, xboxApprovedUids,
  friendsOnlineUids, requestsToMeUids, myRequestsUids, rejectedByMeUids, blockedUids,
  isInternalContactsAllowed, steamApprovedUids
from "%ui/contacts/contactsState.nut" import searchContacts, isContactsManagementEnabled,
  isContactsEnabled, isOnlineContactsSearchEnabled, searchContactsResults
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%dngscripts/platform.nut" import is_sony
from "%ui/contacts/contactPresence.nut" import presences, onlineStatus, isContactOnline
from "%ui/state/appState.nut" import isInBattleState
from "%ui/gameModes/eventRoomsListState.nut" import isRefreshEnabled
from "%ui/state/incognitoState.nut" import incognitoState, incognitoStateUpdate, isIncognitoAvailable
from "%ui/ui_library.nut" import *
from "%ui/hud/menus/options/incognito_options.nut" import incognitoOption
from "%ui/popup/popupBlock.nut" import defPopupBlockPos
from "%ui/contacts/contactActions.nut" import INVITE_TO_PSN_FRIENDS, CANCEL_INVITE, APPROVE_INVITE,
  ADD_TO_BLACKLIST, INVITE_TO_FRIENDS, INVITE_TO_SQUAD,
  REMOVE_FROM_BLACKLIST, COMPARE_ACHIEVEMENTS, INVITE_TO_ROOM,
  REVOKE_INVITE, REJECT_INVITE, REMOVE_FROM_SQUAD,
  REMOVE_FROM_FRIENDS, PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE,
  REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX,
  JOIN_BATTLE, BATTLE_INFO


const CONTACTLIST_MODAL_UID = "contactsListWnd_modalUid"
const contactListWidth = hdpx(400)
let defTxtStyle = freeze({ color = defTxtColor }.__update(fontSub))
let headerTxtStyle = freeze({ color = titleTxtColor }.__update(fontBody))


const APPROVED_TAB = "approved"
const SEARCH_RESULT_TAB = "search_results"
const INVITES_TAB = "invites"
const BLACKLIST_TAB = "myBlacklist"

let display = Watched(APPROVED_TAB)
const windowPadding = fsh(2)
let searchPlayer = Watched("")


let headerTxt = @(text) txt(text, {
  padding = const [hdpx(2), fsh(1)]
  behavior = [Behaviors.Marquee, Behaviors.Button]
  skipDirPadNav = true
  size = FLEX_H
  speed = hdpx(100)
  scrollOnHover = true
}.__update(defTxtStyle))


let closeWnd = @() modalPopupWnd.remove(CONTACTLIST_MODAL_UID)

isInBattleState.subscribe(function(v) {
  if (v)
    closeWnd()
})

function resetSearch() {
  display.set(APPROVED_TAB)
  searchPlayer.set("")
  searchContactsResults.set({})
}

let closeButton = fontIconButton("close", {
  skipDirPadNav = true
  onClick = function() {
    resetSearch()
    closeWnd()
  }
})


let header = @() {
  watch = userInfo
  size = const [FLEX, fsh(4)]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  padding = [bigPadding, bigPadding, bigPadding, windowPadding]
  color = panelBgColor
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXT
      color = disabledTxtColor
      text = userInfo.get()?.nameorig == null
        ? loc("contactsHdr")
        : userInfo.get().nameorig
      clipChildren = true
      behavior = [Behaviors.Marquee, Behaviors.Button]
      skipDirPadNav = true
      scrollOnHover = true
    }.__update(headerTxtStyle)
    closeButton
  ]
}

function searchCallback() {
  if (searchPlayer.get().len() > 0)
    display.set(SEARCH_RESULT_TAB)
}

function doSearch(nick) {
  if (nick.len() == 0)
    resetSearch()
  else
    searchContacts(nick, searchCallback)
}

display.subscribe(function(val) {
  if (val == SEARCH_RESULT_TAB)
    return
  searchPlayer.set("")
  searchContactsResults.set({})
})

let exitSearchButton = fontIconButton("close", {
  onClick = resetSearch
  validateStaticText = false
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  margin = const [0, fsh(0.5)]
})

function clearOrExitWnd() {
  if (searchPlayer.get() == "")
    closeWnd()
  else
    resetSearch()
}

let searchBlock = @() {
  watch = display
  size = FLEX_H
  margin = const [hdpx(2), windowPadding]
  children = [
    textInput(searchPlayer, {
      placeholder = loc(isOnlineContactsSearchEnabled
        ? "contacts/friendSearch"
        : "contacts/mailInvite")
      onChange = doSearch
      onReturn = @() doSearch(searchPlayer.get())
      onEscape = clearOrExitWnd
    }.__update(defTxtStyle))
    display.get() != SEARCH_RESULT_TAB || searchPlayer.get().len() == 0 ? null : exitSearchButton
  ]
}

let counterText = @(count) count > 0 ? count : null
let placeholder = txt(loc("contacts/list_empty"), {
  color = disabledTxtColor,
  margin = const [fsh(1), windowPadding]
}.__update(defTxtStyle))

let friendsButton = buildContactsButton({
  symbol = "users"
  onClick = @() display.set(APPROVED_TAB)
  selected = Computed(@() display.get() == APPROVED_TAB)
  children = buildCounter(Computed(@() counterText(friendsOnlineUids.get().len())))
})

let friendsKeys = []
if (isInternalContactsAllowed) {
  friendsKeys.append({
    name = "friends"
    uidsWatch = [approvedUids, xboxApprovedUids, steamApprovedUids]
    placeholder
    inContactActions = [JOIN_BATTLE, BATTLE_INFO, INVITE_TO_SQUAD]
    contextMenuActions = [
      INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_ROOM,
      INVITE_TO_SQUAD, PROMOTE_TO_LEADER,REMOVE_FROM_FRIENDS, COMPARE_ACHIEVEMENTS,
      SHOW_USER_LIVE_PROFILE, JOIN_BATTLE
    ]
  })
}

if (is_sony)
  friendsKeys.append({
    name = "contacts"
    uidsWatch = psnApprovedUids
    inContactActions = [INVITE_TO_FRIENDS]
    contextMenuActions = [
      INVITE_TO_FRIENDS, ADD_TO_BLACKLIST, REMOVE_FROM_SQUAD, REVOKE_INVITE, INVITE_TO_SQUAD,
      PROMOTE_TO_LEADER, SHOW_USER_LIVE_PROFILE
    ]
  })

let invitationsButton = buildContactsButton({
  symbol = "user-plus"
  onClick = @() display.set(INVITES_TAB)
  selected = Computed(@() display.get() == INVITES_TAB)
  children = buildCounter(Computed(@() counterText(
    requestsToMeUids.get().len() + myRequestsUids.get().len() + rejectedByMeUids.get().len()
  )))
})

let myBlacklist = buildContactsButton({
  symbol = "user-times"
  onClick = @() display.set(BLACKLIST_TAB)
  selected = Computed(@() display.get() ==BLACKLIST_TAB)
  children = buildCounter(Computed(@() counterText( blockedUids.get().len() )))
})


let invitesKeys = [
  { name = "requestsToMe",
    uidsWatch = requestsToMeUids,
    inContactActions = [APPROVE_INVITE],
    contextMenuActions = [APPROVE_INVITE, REJECT_INVITE, INVITE_TO_SQUAD,
      ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
  { name = "myRequests",
    uidsWatch = myRequestsUids,
    inContactActions = [CANCEL_INVITE],
    contextMenuActions = [CANCEL_INVITE, INVITE_TO_SQUAD, REVOKE_INVITE, ADD_TO_BLACKLIST,
      COMPARE_ACHIEVEMENTS]
  }
  { name = "rejectedByMe",
    uidsWatch = rejectedByMeUids,
    inContactActions = [],
    contextMenuActions = [APPROVE_INVITE, INVITE_TO_FRIENDS, INVITE_TO_SQUAD,
      ADD_TO_BLACKLIST, COMPARE_ACHIEVEMENTS]
  }
]

let nickToLower = memoize(@(v) getContactNick(v).tolower(), @(v) v.userId,
  persist("stringsLowerCache", @() {}))
let sortContacts = @(contactsArr, onlineStatusVal) contactsArr.sort(@(a, b)
  isContactOnline(b.userId, onlineStatusVal) <=> isContactOnline(a.userId, onlineStatusVal)
  || nickToLower(a) <=> nickToLower(b))

let mkContactsGroupContent = @(groupKeys) function() {
  let children = []
  let watch = [presences, onlineStatus, searchPlayer, contactsGen]
  let curPresences = presences.get()
  let searchPlayerVal = searchPlayer.get().tolower()
  foreach (v in groupKeys) {
    let { name, uidsWatch, inContactActions, contextMenuActions } = v
    let watchesList = typeof uidsWatch == "array" ? uidsWatch : [uidsWatch]

    local contactsArr = []
    foreach (w in watchesList)
      contactsArr.extend(w.get().keys().map(@(userId) getContact(userId)))

    if (searchPlayerVal != "")
      contactsArr = contactsArr.filter(@(c)
        c.realnick.tolower().contains(searchPlayerVal))

    contactsArr = sortContacts(contactsArr, onlineStatus.get())
      .map(@(contact) {
        size = const [FLEX, hdpx(62)]
        children = mkContactBlock(contact, contextMenuActions,
          inContactActions, curPresences?[contact.userId] ?? {})
      })

    children.append(headerTxt(locByPlatform($"contacts/{name}")))
    if (contactsArr.len() == 0)
      children.append(placeholder)
    else
      children.extend(contactsArr)

    watch.extend(watchesList)
  }

  return {
    watch
    xmbNode = XmbContainer({
      canFocus = false
      wrap = false
      scrollToEdge = true
    })
    size = FLEX_H
    flow = FLOW_VERTICAL
    children
  }
}

let modesList = [
  { option = APPROVED_TAB, comp = friendsButton },
  { option = INVITES_TAB, comp = invitationsButton},
  { option =BLACKLIST_TAB, comp = myBlacklist}
]

let modeSwitcher = {
    hplace = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    margin = [bigPadding, windowPadding, 0, windowPadding]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = modesList.map(@(m) m.comp)
  }

let searchTbl = [{
  uidsWatch = searchContactsResults,
  name = "search_results",
  placeholder,
  inContactActions = [INVITE_TO_FRIENDS],
  contextMenuActions = [
    INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_FRIENDS, APPROVE_INVITE,
    INVITE_TO_SQUAD, CANCEL_INVITE, REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN,
    REMOVE_FROM_BLACKLIST_XBOX, ADD_TO_BLACKLIST, SHOW_USER_LIVE_PROFILE,COMPARE_ACHIEVEMENTS
  ]
}]

let myBlackTbl = [{
  uidsWatch = [blockedUids]
  name =BLACKLIST_TAB,
  placeholder,
  inContactActions = [REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN, REMOVE_FROM_BLACKLIST_XBOX],
  contextMenuActions = [REMOVE_FROM_BLACKLIST, REMOVE_FROM_BLACKLIST_PSN,
    REMOVE_FROM_BLACKLIST_XBOX, SHOW_USER_LIVE_PROFILE, COMPARE_ACHIEVEMENTS]
}]

let isContactsWndVisible = Watched(false)
let popupsOffset = [-contactListWidth + defPopupBlockPos[0], defPopupBlockPos[1]]
isContactsWndVisible.subscribe(@(v) popupBlockStyle.mutate(@(style)
  style.pos <- (v ? popupsOffset : defPopupBlockPos)))

let tabsContent = {
  search_results = mkContactsGroupContent(searchTbl)
  myBlacklist    = mkContactsGroupContent(myBlackTbl)
  approved       = mkContactsGroupContent(friendsKeys)
  invites        = mkContactsGroupContent(invitesKeys)
}

let trackFriendsOnline = freeze({
  padding = smallPadding
  size = FLEX_H
  margin = const [0, hdpx(5)]
  halign = ALIGN_CENTER
  children = checkbox(hasFriendOnlineNotification, loc("contacts/friendNotificaion"))
})

let incognitoCmp = {
  size = FLEX_H
  padding = const [0, windowPadding]
  children = checkbox(incognitoState, {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = loc("contact/Incognito")
      margin = 0
    }.__update(fontSub),
    {
      setValue = function(v) {
        incognitoStateUpdate(v)
        incognitoOption?.setValue(v)
      }
    })
}

let contactsBlock = @() {
  watch = display
  size = const [contactListWidth, FLEX]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = defItemBlur
  stopMouse = true
  key = "contactsBlock"
  onAttach = @() isContactsWndVisible.set(true)
  onDetach = @() isContactsWndVisible.set(false)
  hotkeys = [[$"^{JB.B} | Esc", { action = clearOrExitWnd, description = loc("Close") }]]

  children = {
    size = FLEX
    rendObj = ROBJ_SOLID
    color = darkPanelBgColor
    flow = FLOW_VERTICAL
    children = [
      header
      {
        size = const [FLEX, fsh(5)]
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        children = [
          isIncognitoAvailable ? incognitoCmp : null
          isContactsManagementEnabled ? modeSwitcher : null
        ]
      }
      searchBlock
      trackFriendsOnline
      makeVertScroll(tabsContent?[display.get()])
    ]
  }
}


let curModeIdx = Computed(@() modesList.findindex(@(m) m.option == display.get()) ?? -1)
let changeMode = @(delta) display.set(modesList[(curModeIdx.get() + delta + modesList.len())
  % modesList.len()].option)

let btnContactsNav = @() {
  size = SIZE_TO_CONTENT
  children = isContactsManagementEnabled ? {
    hotkeys = [
      ["^J:LB | L.Shift Tab | R.Shift Tab", { action = @() changeMode(-1),
        description = loc("contacts/prev_list")} ],
      ["^J:RB | Tab", {action = @() changeMode(1),
        description = loc("contacts/next_list")} ]
    ]
  } : null
}


let popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = fullTransparentBgColor }
function show(){
  if (!isContactsEnabled)
    return
  let bottomOffset = safeAreaBorders.get()[2] + bigPadding
  let popupHeight = sh(95) - bottomOffset
  modalPopupWnd.add([sw(100), sh(100) - bottomOffset],
  {
    size = [SIZE_TO_CONTENT, popupHeight]
    uid = CONTACTLIST_MODAL_UID
    fillColor = Color(0,0,0)
    padding = 0
    popupFlow = FLOW_HORIZONTAL
    popupValign = ALIGN_BOTTOM
    popupOffset = 0
    margin = 0
    children = [
      contactsBlock
      btnContactsNav
    ]
    popupBg = popupBg
    onAttach = @() isRefreshEnabled.set(true)
    onDetach = @() isRefreshEnabled.set(false)
  })
}

console_register_command(function(num) {
  let syllable = ["am", "ba", "co", "du", "er", "fu", "go", "hi", "in", "je", "ky", "la"]
  let syllableSize = syllable.len()
  let res = {}
  local uid = contacts.get().len()
  for (local i = 0; i < num; ++i) {
    local realnick = ""
    let len = (uid * 3187) % 4 + 3
    for (local j = 0; j < len; ++j) {
      uid = (uid * 7993 + 7027) % 479001599
      realnick = $"{realnick}{syllable[uid % syllableSize]}"
    }
    let userId = uid.tostring()
    realnick = $"{realnick}_{userId}"
    res[userId] <- { userId , uid, realnick }
  }
  contacts.mutate(@(data) data.__update(res))
  approvedUids.mutate(@(data) data.__update(res.map(@(_) true)))
}, "contacts.setRandom")

return show
