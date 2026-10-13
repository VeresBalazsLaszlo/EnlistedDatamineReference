import "%dngscripts/platform.nut" as platform
import "%enlSqGlob/userInfo.nut" as userInfo
from "%enlSqGlob/crossnetwork_state.nut" import canCrossnetworkChatWithAll,
  canCrossnetworkChatWithFriends, crossnetworkPlay
from "%ui/squad/squadManager.nut" import inviteToSquad, dismissSquadMember, transferSquad,
  revokeSquadInvite, leaveSquad, isInSquad, isSquadLeader,
  squadMembers, isInvitedToSquad, enabledSquad, canInviteToSquad
from "%ui/state/roomState.nut" import canInviteToRoom, isInMyRoom, inviteToRoom,
  playersWaitingResponseFor, joinFriendRoom
from "%ui/state/queueState.nut" import availableSquadMaxMembers
from "%ui/components/openUrl.nut" import openUrl
from "%ui/state/clientState.nut" import appId
from "%ui/contacts/contactsWatchLists.nut" import approvedUids, myRequestsUids, requestsToMeUids,
  rejectedByMeUids, myBlacklistUids, meInBlacklistUids, psnApprovedUids,
  steamApprovedUids, isInternalContactsAllowed, psnBlockedUids, xboxBlockedUids, friendsUids, blockedUids
from "%ui/contacts/contactsState.nut" import execContactsCharAction, getContactsInviteId
from "%ui/helpers/platformUtils.nut" import canInterractCrossPlatform, canInterractCrossPlatformByCrossplay
from "%ui/contacts/contact.nut" import getContactRealnick
from "app" import get_circuit
from "settings" import get_setting_by_blk_path
from "%ui/contacts/contactPresence.nut" import presences
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/contacts/consoleUidsRemap.nut" import uid2console
from "%ui/contacts/showUserInfo.nut" import showUserInfo, canShowUserInfo
from "%ui/mainScene/invitationsLogState.nut" import removeNotifyById
from "%ui/contacts/contactBlock.nut" import mkJoinToFriendTooltip
from "%ui/gameModes/eventRoomsListState.nut" import roomsList, selectRoom
from "%ui/gameModes/eventModesState.nut" import openCustomGameMode
from "%ui/mpRoom/enlRoomState.nut" import roomMembers
from "%ui/mpRoom/myRoomMemberParams.nut" import setMyTeam
from "%ui/ui_library.nut" import *

let { consoleCompare } = require("%ui/helpers/platformUtils.nut")
let { open_player_profile = @(...) null, PlayerAction = null
} = platform.is_sony? require("sony.social") : null




let myUserId = Computed(@() userInfo.get()?.userIdStr ?? "")
let isInMySquad = @(userId, members) members.get()?[userId.tointeger()] != null

const achievementTestUrl = "http://achievement-test.gaijin.ops/achievement/?app={0}&nick={1}"
let achievementUrl = get_setting_by_blk_path("achievementsUrl") ?? "https://achievements.gaijin.net/?app={0}&nick={1}"

let actions = {
  INVITE_TO_SQUAD = {
    locId = "Invite to squad"
    icon = "handshake-o"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get()
      && canInviteToSquad.get()
      && !isInMySquad(userId, squadMembers)
      && availableSquadMaxMembers.get() > 1
      && !isInvitedToSquad.get()?[userId.tointeger()]
      && canInterractCrossPlatformByCrossplay(
        getContactRealnick(userId),
        crossnetworkPlay.get()
      )
      && userId not in meInBlacklistUids.get()
      && userId not in blockedUids.get()
    )
    action = @(userId) inviteToSquad(userId.tointeger())
  }

  INVITE_TO_ROOM = {
    locId = "Invite to room"
    icon = "handshake-o"
    mkIsVisible = @(userId) Computed(@() canInviteToRoom.get()
      && userId.tointeger() not in playersWaitingResponseFor.get()
      && !isInMyRoom(userId.tointeger())
      && canInterractCrossPlatformByCrossplay(
        getContactRealnick(userId),
        crossnetworkPlay.get()
      ))
    action = @(userId) inviteToRoom(userId.tointeger())
  }

  INVITE_TO_FRIENDS = {
    locId = "Invite to friends"
    icon = "user-plus"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get()
      && isInternalContactsAllowed
      && userId not in blockedUids.get()
      && userId not in friendsUids.get()
      && userId not in myRequestsUids.get()
      && userId not in rejectedByMeUids.get()
      && userId not in requestsToMeUids.get()
    )
    function action(userId) {
      if (platform.is_gdk && canShowUserInfo(userId.tointeger(), getContactRealnick(userId)))
        showUserInfo(userId) 
      else
        execContactsCharAction(userId, "contacts_request_for_contact")
    }
  }

  INVITE_TO_PSN_FRIENDS = {
    locId = "contacts/psn/friends/request"
    icon = "user-plus"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get()
      && (platform.is_sony && consoleCompare.psn.isFromPlatform(getContactRealnick(userId)))
      && userId not in psnApprovedUids.get()
      && userId not in blockedUids.get()
      && userId not in meInBlacklistUids.get()
    )
    action = @(userId) open_player_profile(
      (uid2console.get()?[userId] ?? "-1").tointeger(),
      PlayerAction?.REQUEST_FRIENDSHIP,
      "PlayerProfileDialogClosed",
      {}
    )
  }

  CANCEL_INVITE = {
    locId = "Cancel Invite"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get() && userId in myRequestsUids.get())
    action      = @(userId) execContactsCharAction(userId, "contacts_cancel_request")
  }

  APPROVE_INVITE = {
    locId = "Approve Invite"
    icon = "user-plus"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get()
      && (userId in requestsToMeUids.get() || userId in rejectedByMeUids.get())
      && canInterractCrossPlatformByCrossplay(
        getContactRealnick(userId),
        crossnetworkPlay.get()
      )
    )
    action      = function(userId) {
      removeNotifyById(getContactsInviteId(userId))
      execContactsCharAction(userId, "contacts_approve_request")
    }
  }

  REJECT_INVITE = {
    locId = "Reject Invite"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get()
      && userId in requestsToMeUids.get())
    action      = function(userId) {
      removeNotifyById(getContactsInviteId(userId))
      execContactsCharAction(userId, "contacts_reject_request")
    }
  }

  REMOVE_FROM_FRIENDS = {
    locId = "Break approval"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@()
      canInterractCrossPlatform(
        getContactRealnick(userId),
        canCrossnetworkChatWithFriends.get()
      )
      && userId != myUserId.get()
      && userId in friendsUids.get()
      && userId not in psnApprovedUids.get()
      && userId not in steamApprovedUids.get()
    )
    function action(userId) {
      if (platform.is_gdk && canShowUserInfo(userId.tointeger(), getContactRealnick(userId)))
        showUserInfo(userId) 
      else
        execContactsCharAction(userId, "contacts_break_approval_request")
    }
  }

  ADD_TO_BLACKLIST = {
    locId = "Add to blacklist"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@()
      canInterractCrossPlatform(
        getContactRealnick(userId),
        userId in friendsUids.get()
          ? canCrossnetworkChatWithFriends.get()
          : canCrossnetworkChatWithAll.get()
      )
      && userId != myUserId.get()
      && userId not in blockedUids.get()
      && userId not in approvedUids.get())
    function action(userId) {
      if (platform.is_sony && consoleCompare.psn.isFromPlatform(getContactRealnick(userId)))
        open_player_profile(
          (uid2console.get()?[userId] ?? "-1").tointeger(),
          PlayerAction?.BLOCK_PLAYER,
          "PlayerProfileDialogClosed",
          {}
        )
      else if (platform.is_gdk && canShowUserInfo(userId.tointeger(), getContactRealnick(userId)))
        showUserInfo(userId) 
      else
        execContactsCharAction(userId, "contacts_add_to_blacklist")
    }
  }


  REMOVE_FROM_BLACKLIST = {
    locId = "Remove from blacklist"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get() && userId in myBlacklistUids.get())
    action      = @(userId) execContactsCharAction(userId, "contacts_remove_from_blacklist")
  }

  REMOVE_FROM_BLACKLIST_XBOX = {
    locId = "Remove from blacklist"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get()
      && userId in xboxBlockedUids.get()
      && canShowUserInfo(userId.tointeger(), getContactRealnick(userId))
    )
    action      = showUserInfo
  }

  REMOVE_FROM_BLACKLIST_PSN = {
    locId = "Remove from blacklist"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserId.get() && userId in psnBlockedUids.get())
    action      = @(userId) open_player_profile(
      (uid2console.get()?[userId] ?? "-1").tointeger(),
      PlayerAction?.DISPLAY,
      "PlayerProfileDialogClosed",
      {}
    )
  }

  REMOVE_FROM_SQUAD = {
    locId = "Remove from squad"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() enabledSquad.get()
      && userId != myUserId.get() && isSquadLeader.get() && isInMySquad(userId, squadMembers))
    action      = @(userId) dismissSquadMember(userId.tointeger())
  }

  PROMOTE_TO_LEADER = {
    locId = "Promote to squad chief"
    icon = "flag"
    mkIsVisible = @(userId) Computed(@() enabledSquad.get()
      && userId != myUserId.get() && isSquadLeader.get() && isInMySquad(userId, squadMembers))
    action      = @(userId) transferSquad(userId.tointeger())
  }

  REVOKE_INVITE = {
    locId = "Revoke invite"
    icon = "remove"
    mkIsVisible = @(userId) Computed(@() isSquadLeader.get()
      && !isInMySquad(userId, squadMembers) && (isInvitedToSquad.get()?[userId.tointeger()] ?? false))
    action      = @(userId) revokeSquadInvite(userId.tointeger())
  }

  LEAVE_SQUAD = {
    locId = "Leave squad"
    icon = "child"
    mkIsVisible = @(userId) Computed(@() enabledSquad.get() && userId == myUserId.get() && isInSquad.get())
    action      = @(_userId) leaveSquad()
  }

  COMPARE_ACHIEVEMENTS = {
    locId = "Compare achievements"
    icon = "line-chart"
    mkIsVisible = @(userId) Computed(@() platform.is_pc && achievementUrl != "" && userId != myUserId.get())
    action      = @(userId)
      openUrl(
        ["moon", "internal"].contains(get_circuit())
          ? achievementTestUrl.subst(appId, getContactRealnick(userId))
          : achievementUrl.subst(appId, getContactRealnick(userId))
      )
  }

  SHOW_USER_LIVE_PROFILE = {
    locId = "show_user_live_profile"
    icon = "id-card"
    mkIsVisible = @(userId) WatchedRo(canShowUserInfo(userId.tointeger(), getContactRealnick(userId)))
    action      = showUserInfo
  }

  BATTLE_INFO = {
    mkTooltip = @(userId) mkJoinToFriendTooltip(presences.get()?[userId])
    icon = "question-circle-o"
    mkIsVisible = @(userId) Computed(function() {
      let { online = false, inBattle = false, lobby = false } = presences.get()?[userId]
      return online && inBattle && !lobby
    })
  }

  JOIN_BATTLE = {
    locId = "contacts/join_battle"
    mkTooltip = @(userId) mkJoinToFriendTooltip(presences.get()?[userId])
    icon = "star-o"
    mkIsVisible = @(userId) Computed(function() {
      let { online = false, roomId = null, lobby = false } = presences.get()?[userId]
      return online && lobby && roomId != null
        && canInterractCrossPlatformByCrossplay(
          getContactRealnick(userId),
          crossnetworkPlay.get()
        )
    })
    action = function(userId) {
      let { lobby = false } = presences.get()?[userId]
      if (!lobby)
        return

      let { roomId } = presences.get()[userId]
      let roomIdStr = roomId.tostring()
      let room = roomsList.get().findvalue(@(r) r.roomId == roomIdStr)

      joinFriendRoom(roomId, room, {
        open = function() {
          openCustomGameMode()
          selectRoom(roomId)
        }

        join = function() {
          let member = roomMembers.get().findvalue(@(m) m.userId.tostring() == userId)
          openCustomGameMode()
          if (member == null)
            showMsgbox(loc("msgbox/friendLeftLobby"))
          else {
            let { team = 0 } = member?.public
            setMyTeam(team)
          }
        }
      })
    }
  }
}

return actions
