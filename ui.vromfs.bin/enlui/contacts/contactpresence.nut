from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *
from "types" import Integer

const PRESENCES_ID = "presences"
const SQUAD_STATUS_ID = "squad_status"

let presences = nestWatched(PRESENCES_ID, {})
let squadStatus = nestWatched(SQUAD_STATUS_ID, {})

let calcStatus = @(presence) presence?.unknown ? null : presence?.online
let onlineStatusBase = Computed(@() presences.get().map(calcStatus))

let onlineStatus = Computed(@() onlineStatusBase.get().__merge(squadStatus.get()))

let mkUpdatePresences = @(watch) function(newPresences) {
  watch.mutate(function(v) {
    v.__update(newPresences)
    
    foreach (userId, presence in newPresences)
      if (presence == null)
        v.$rawdelete(userId)
  })
}

let updatePresences = mkUpdatePresences(presences)
let updateSquadPresences = mkUpdatePresences(squadStatus)

function isContactOnline(userId, onlineStatusVal) {
  let uid = userId instanceof Integer ? userId.tostring() : userId
  return onlineStatusVal?[uid] == true
}

return {
  presences
  onlineStatus
  updatePresences
  updateSquadPresences

  isContactOnline
}
