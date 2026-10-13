from "math" import rand
from "%ui/matchingClient.nut" import matchingCall
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/gameModes/eventModesState.nut" import openEventModes, checkEventModesAccess
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "matching.errors" import error_string
from "settings" import save_settings, get_setting_by_blk_path, set_setting_by_blk_path
from "%ui/ui_library.nut" import *

let { chooseRandom } = require("%sqstd/rand.nut")
let baseRoomState = require("%ui/state/roomState.nut")
let { room, startSessionWithLocalDedicated, canStartWithLocalDedicated, joinedRoomWithInvite,
  isHostInGame
} = baseRoomState
let roomMembersBase = baseRoomState.roomMembers
let { portraits, nickFrames } = require("%ui/components/decoratorsPresentation.nut")
let memberStatuses = require("%ui/mpRoom/roomMemberStatuses.nut")


const IS_LOCAL_DEDICATED = "startWithLocalDedicated"

let roomScene = Computed(@() room.get()?.public.scene)
let isEventRoom = Computed(@() room.get()?.public.digestGroup == "events-lobby")
let debugMembers = mkWatched(persist, "debugMembers", [])
let roomMembers = Computed(@() (clone roomMembersBase.get()).extend(debugMembers.get()))
let isLocalDedicated = Watched(get_setting_by_blk_path(IS_LOCAL_DEDICATED) ?? false)
isLocalDedicated.subscribe(function(v) {
  set_setting_by_blk_path(IS_LOCAL_DEDICATED, v)
  save_settings()
})


let roomTeamArmies = Computed(function() {
  let { armiesTeamA = [], armiesTeamB = [] } = room.get()?.public
  return [armiesTeamA, armiesTeamB]
})

let roomTeamsNumber = Computed(@() room.get()?.public.numTeams ?? 2)

function onStartSessionResult(res) {
  if (res.error == 0)
    return

  log("Error on start session: ", res)
  showMsgbox({
    text = loc("msgbox/failedJoinRoom",
      { error = res?.accept == false ? loc(res?.reason ?? "") 
        : loc($"error/{error_string(res.error)}")
      })
  })
}

function startSession() {
  isHostInGame.set(true)
  if (isLocalDedicated.get() && canStartWithLocalDedicated.get())
    startSessionWithLocalDedicated(onStartSessionResult)
  else
    matchingCall("mrooms.start_session",
      onStartSessionResult,
      { cluster = room.get()?.public.cluster })
}

function cancelSessionStart() {
  matchingCall("mrooms.cancel_session_start")
}

let mkDebugMembers = @(count) array(count).map(function(_, idx) {
  let campaign = chooseRandom((gameProfile.get()?.campaigns ?? {}).keys())
  let rnd = rand()
  return {
    userId = rnd
    memberId = 1000 - idx
    name = $"WWWWWWWWWWWWWWW{rnd % 10}"
    nameText = $"WWWWWWWWWWWWWWW{rnd % 10}"
    squadNum = max(0, rnd % 10 - 4)
    public = {
      team = rnd % 2
      campaign
      army = chooseRandom(gameProfile.get()?.campaigns[campaign].armies ?? [])?.id ?? ""
      isReady = (rnd % 2) == 1
      portrait = chooseRandom(portraits.keys())
      nickFrame = chooseRandom(nickFrames.keys())
      status = chooseRandom(memberStatuses.keys())
    }
  }
})


joinedRoomWithInvite.subscribe(function(v) {
  if (v)
    openEventModes()
  else
    checkEventModesAccess()
})

console_register_command(
  @() debugMembers.modify(@(v) v.len() > 0 ? [] : mkDebugMembers(rand() % 64)),
  "eventRooms.toggleDebugMembersMode")
console_register_command(@() debugMembers.set(mkDebugMembers(rand() % 64)),
  "eventRooms.regenerateDebugMembers")

return baseRoomState.__merge({
  roomScene
  roomTeamArmies
  roomTeamsNumber
  isEventRoom
  roomMembers
  isLocalDedicated

  startSession
  cancelSessionStart
})
