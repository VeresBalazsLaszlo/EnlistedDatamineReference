from "%sqstd/timers.nut" import debounce
from "%sqstd/underscore.nut" import deep_clone
from "%ui/state/clientState.nut" import appId
from "%ui/mpRoom/enlRoomState.nut" import roomIsLobby, setMemberAttributes, room, isEventRoom,
  roomTeamArmies, roomMembers, doConnectToHostOnHostNotfy, canOperateRoom, isInRoom, lobbyStatus
from "%ui/soldiers/model/state.nut" import curArmy, setRoomArmy
from "%ui/profile/decoratorState.nut" import chosenPortrait, chosenNickFrame
from "%ui/debriefing/debriefingState.nut" import isInDebriefing
from "%ui/state/appState.nut" import isInBattleState
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *
from "%ui/mpRoom/roomMemberStatuses.nut" import *

let { LobbyStatus } = require("%ui/mpRoom/enlRoomState.nut")


let keysToDropReady = ["mode", "difficulty", "teamArmies", "scenes"]
let savedRoomsTeams = persist("savedRoomsTeams", @() {})

let curTeam = mkWatched(persist, "curTeam", -1) 
let myArmy = mkWatched(persist, "myArmy", "")
let hasBalanceCheckedByEntrance = Watched(false)
let lastPlayedSessionId = mkWatched(persist, "lastPlayedSessionId", -1)
let isReady = doConnectToHostOnHostNotfy 




myArmy.subscribe(@(a) isInRoom.get() ? setRoomArmy(a) : null)
curArmy.subscribe(@(a) !isInRoom.get() ? myArmy.set(a) : null)

let setReadyStatus = @() isReady.set(canOperateRoom.get())
subscribeList(setReadyStatus, canOperateRoom, isInDebriefing)

let myRoomPublic = Computed(@() !isEventRoom.get()
  ? { appId = appId
      team = curTeam.get()
    }
  : { appId = appId
      team = curTeam.get()
      army = myArmy.get()
      isReady = isReady.get()
      portrait = chosenPortrait.get()?.guid
      nickFrame = chosenNickFrame.get()?.guid
      status = isInBattleState.get() ? IN_BATTLE.id
        : isInDebriefing.get() ? IN_DEBRIEFING.id
        : isReady.get() ? IN_LOBBY_READY.id
        : IN_LOBBY_NOT_READY.id
    })

function updateMyPublic() {
  if (roomIsLobby.get())
    setMemberAttributes({ public = myRoomPublic.get() })

  if (myRoomPublic.get()?.status == IN_BATTLE.id && (room.get()?.public.sessionId ?? 0) > 0)
    lastPlayedSessionId.set(room.get()?.public.sessionId)
}
let updateMyPublicDebounced = debounce(updateMyPublic, 0.1)
myRoomPublic.subscribe(@(_) updateMyPublicDebounced())

isInRoom.subscribe(function(is) {
  isReady.set(canOperateRoom.get() || !(roomIsLobby.get() && isEventRoom.get()))
  updateMyPublicDebounced()

  if (!is) {
    setRoomArmy(null)
    curTeam.set(-1)
    myArmy.set(curArmy.get())
  }
})


local lastRoomPublic = deep_clone(room.get()?.public)
let doesTeamContainArmy = @(team, armyId)
  roomTeamArmies.get()?[team].contains(armyId) ?? false

function setMyArmy(armyId) {
  if (armyId == myArmy.get() || !doesTeamContainArmy(curTeam.get(), armyId))
    return
  myArmy.set(armyId)
}

function setReady(ready) {
  if (canOperateRoom.get() || ready == isReady.get()) 
    return
  isReady.set(ready)
  
}

function setMyTeam(team) {
  if (team == curTeam.get())
    return

  setReady(false)
  let armyId = myArmy.get()
  let hasToChangeArmy = !doesTeamContainArmy(team, armyId)
  if (hasToChangeArmy)
    myArmy.set(roomTeamArmies.get()?[team][0])

  savedRoomsTeams[room.get().roomId] <- team
  curTeam.set(team)
}

let hasPlayedCurSession = Computed(function(){
  return (room.get()?.public.sessionId ?? 0) == lastPlayedSessionId.get()
    && (lobbyStatus.get() == LobbyStatus.GameInProgress || lobbyStatus.get() == LobbyStatus.GameInProgressNoLaunched)
  })

isInBattleState.subscribe(function(v){
  if (!v && room.get()?.public.sessionId != null && !canOperateRoom.get())
    isReady.set(false)
})

let canChangeTeam = Computed(function() {
  let maxPlayersByTeam = (room.get()?.public.maxPlayers ?? 0) / 2
  let availableTeamsCount = (room.get()?.public.numTeams ?? 2) - 1
  let currentTeam = curTeam.get()
  let teamToJoin = 1 - currentTeam
  let doesTeamToJoinExists = teamToJoin in roomTeamArmies.get()
  let members = roomMembers.get() ?? []
  let playersInTeam = members.filter(@(player) player.public?.team == teamToJoin)
  let isRoomCreating = lobbyStatus.get() == LobbyStatus.WaitingBeforeLauch
  return doesTeamToJoinExists && playersInTeam.len() < maxPlayersByTeam
    && !hasPlayedCurSession.get() && !isRoomCreating && teamToJoin <= availableTeamsCount
})

function teamSelectAfterEntrance() {
  let members = roomMembers.get() ?? []
  let isOneTeamAvailable = (room.get()?.public.numTeams ?? 2) == 1
  if (isOneTeamAvailable)
    setMyTeam(0)
  else {
    let playersInTeamA = members.reduce(@(sum, player) sum + (player?.public.team == 0 ? 1 : 0), 0)
    let playersInTeamB = members.reduce(@(sum, player) sum + (player?.public.team == 1 ? 1 : 0), 0)
    let teamToSelect = playersInTeamA > playersInTeamB ? 1 : 0

    let teamSaved = savedRoomsTeams?[room.get().roomId]
    if (teamSaved != null && teamSaved != teamToSelect && canChangeTeam.get())
      setMyTeam(teamSaved)
    else
      setMyTeam(teamToSelect)
  }

  hasBalanceCheckedByEntrance.set(true)
}

function onRoomChanged() {
  let needDropReady = null != keysToDropReady.findindex(@(key)
    !isEqual(lastRoomPublic?[key], room.get()?.public[key]))
  lastRoomPublic = deep_clone(room.get()?.public)
  if (!roomIsLobby.get() || room.get() == null)
    return
  if (!isEventRoom.get()) {
    updateMyPublic()
    return
  }

  if (needDropReady)
    isReady.set(canOperateRoom.get())

  let armyId = myArmy.get()

  if(!doesTeamContainArmy(curTeam.get(), armyId))
    setRoomArmy(roomTeamArmies.get()?[curTeam.get()][0])

  if (!hasBalanceCheckedByEntrance.get())
    teamSelectAfterEntrance()
}

let onRoomChangedDebounced = debounce(onRoomChanged, 0.01)
subscribeList(onRoomChangedDebounced, room, roomIsLobby, isEventRoom, roomTeamArmies)

return {
  curTeam
  myArmy
  setMyArmy
  setMyTeam
  canChangeTeam
  isReady = Computed(@() isReady.get())
  setReady
  hasBalanceCheckedByEntrance
}