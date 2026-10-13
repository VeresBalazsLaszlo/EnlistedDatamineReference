import "%ui/contacts/contactsListWnd.nut" as showContactsListWnd
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, gap, miniPadding
from "%ui/mainMenu/mainmenu.style.nut" import navBottomBarHeight
from "%ui/squad/squadManager.nut" import squadLen, squadMembers, isInvitedToSquad, enabledSquad, canInviteToSquad, leaveSquad, squadSelfMember
  , isSquadLeader, tryResolveLiveCrossplayPrivilege
from "%ui/gameModes/gameModeState.nut" import currentGameMode
from "%ui/contacts/contact.nut" import getContact, contactsGen
from "%ui/contacts/contactBlock.nut" import mkContactBlock
from "%ui/components/textButton.nut" import Regular, Accented, FASecondary
from "%ui/state/roomState.nut" import roomIsLobby
from "%ui/soldiers/model/notReadySquadsState.nut" import showCurNotReadySquadsMsg
from "%ui/soldiers/armySquadTier.nut" import updateBROnMatchStart
from "%ui/quickMatchQueue.nut" import isInQueue
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/contacts/contactPresence.nut" import presences
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/ui_library.nut" import *

let { myExtSquadData } = require("%ui/squad/squadManager.nut")
let { INVITE_TO_FRIENDS, REMOVE_FROM_SQUAD, PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE, INVITE_TO_PSN_FRIENDS } = require("%ui/contacts/contactActions.nut")


let maxMembers = Computed(@() currentGameMode.get()?.maxGroupSize ?? 1)

let contextMenuActions = [INVITE_TO_FRIENDS, INVITE_TO_PSN_FRIENDS, REMOVE_FROM_SQUAD,
  PROMOTE_TO_LEADER, REVOKE_INVITE, SHOW_USER_LIVE_PROFILE]

let hintTxtStyle = { color = defTxtColor }.__update(fontSub)


let mkHint = @(text) {
  rendObj = ROBJ_TEXT
  text
}.__update(hintTxtStyle)


let addUserButton = FASecondary("user-plus", showContactsListWnd, {
  hint = mkHint(loc("tooltips/addUser"))
  btnWidth = navBottomBarHeight
  btnHeight = navBottomBarHeight
})

let leaveButton = FASecondary("close", @() leaveSquad(), {
  hint = mkHint(loc("tooltips/disbandSquad"))
  btnWidth = navBottomBarHeight
  btnHeight = navBottomBarHeight
})

let squadControls = @() {
  watch = squadLen
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  children = squadLen.get() > 0 ? leaveButton : null
}

let horizontalContact = @(contact, curPresences) {
  size = [SIZE_TO_CONTENT, navBottomBarHeight]
  children = mkContactBlock(contact, contextMenuActions, [],
    curPresences?[contact.userId] ?? {}, false)
}

let squadReadyButton = @(ready) (ready.get() ? Regular : Accented)(
  ready.get() ? loc("Set not ready") : loc("Press when ready"),
  function() {
    if (isInQueue.get()) {
      showMsgbox(loc("msg/cantReadyStatus"))
      return
    }
    if (ready.get())
      ready.set(false)
    else
      tryResolveLiveCrossplayPrivilege(function(resolved) {
        if (resolved)
          showCurNotReadySquadsMsg(function() {
          updateBROnMatchStart()
          ready.set(true)
        })
      })
  },
  { size = FLEX_V
    margin = const [0, 0, 0, hdpx(5)]
    textParams = { validateStaticText = false, vplace = ALIGN_CENTER }.__update(fontSub)
  })

function squadReadyButtonPlace() {
  let res = { watch = [squadSelfMember, isSquadLeader, roomIsLobby, myExtSquadData.ready] }
  if (squadSelfMember.get() && !isSquadLeader.get()) {
    res.__update({
      size = [SIZE_TO_CONTENT, navBottomBarHeight]
       children = roomIsLobby.get()
         ? null
         : squadReadyButton(myExtSquadData.ready)
    })
  }
  return res
}

function squadMembersUi() {
  let curPresences = presences.get()
  let squadList = []
  foreach (member in squadMembers.get())
    if (member.isLeader)
      squadList.insert(0, horizontalContact(getContact(member.userId.tostring()),
        curPresences))
    else
      squadList.append(horizontalContact(getContact(member.userId.tostring()),
        curPresences))

  foreach (uid, _ in isInvitedToSquad.get())
    squadList.append(horizontalContact(getContact(uid.tostring()), curPresences))

  if (maxMembers.get() > 1 && canInviteToSquad.get())
    for(local i = squadList.len(); i < maxMembers.get(); i++)
      squadList.append(addUserButton)

  return {
    watch = [squadMembers, isInvitedToSquad, canInviteToSquad, maxMembers, presences, contactsGen]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children = squadList
  }
}


const armyIconSize = hdpxi(32)
const iconHeight = hdpxi(26)

let mkChildrenIcon = @(arr) arr.map(@(armyId) {
  size = const [iconHeight, SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = mkArmyIcon(armyId, hdpxi(20), { margin = 0 })
})

function armyInfoUi() {
  let watch = [enabledSquad, squadMembers, roomIsLobby, curArmiesList]
  if (roomIsLobby.get())
    return { watch }

  let members = squadMembers.get()
  let leader = !enabledSquad.get() ? null : members.findvalue(@(m) m?.isLeader ?? false)
  if (leader == null)
    return { watch }

  let { isTeamRandom = false, curArmy = null } = leader.state
  if (!isTeamRandom && curArmy != null)
    return {
      watch
      size = const [hdpx(70), FLEX]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = mkArmyIcon(curArmy, armyIconSize, { margin = 0 })
    }

  let armiesList = curArmiesList.get()
  let children = []
  for(local i = 0; i < armiesList.len(); i += 2)
    children.append({
      flow = FLOW_HORIZONTAL
      children = mkChildrenIcon(armiesList.slice(i, i + 2))
    })

  return {
    watch
    size = const [hdpx(70), FLEX]
    flow = FLOW_VERTICAL
    gap = miniPadding
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children
  }
}


return @() {
  stopMouse = true
  watch = enabledSquad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap
  children = enabledSquad.get()
    ? [
        squadControls
        squadReadyButtonPlace
        armyInfoUi
        squadMembersUi
      ]
    : null
}
