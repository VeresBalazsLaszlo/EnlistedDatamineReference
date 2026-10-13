from "%ui/squad/squadState.nut" import isInSquad, isSquadLeader
from "%ui/clusterState.nut" import isAutoCluster, selectedClusters
from "%ui/matchingQueues.nut" import matchingQueues
from "%dngscripts/globalState.nut" import nestWatched
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let { squadSharedData } = require("%ui/squad/squadState.nut")
let squadClusters = squadSharedData.clusters
let squadAutoCluster = squadSharedData.isAutoCluster


let STATUS = {
  NOT_IN_QUEUE = 0
  JOINING = 1
  IN_QUEUE = 2
}

let curGameMode = nestWatched("curGameMode", null)
let queueStatus = nestWatched("queueStatus", STATUS.NOT_IN_QUEUE)

let debugShowQueue = Watched(false)

let isInQueue = Computed(@() queueStatus.get() != STATUS.NOT_IN_QUEUE || debugShowQueue.get())

let timeInQueue = Watched(0)
let queueClusters = Computed(@()
  isInSquad.get() && !isSquadLeader.get() && squadClusters.get() != null
    ? clone squadClusters.get()
    : clone selectedClusters.get()) 

let canChangeQueueParams = Computed(@() !isInQueue.get() && (!isInSquad.get() || isSquadLeader.get()))

let availableSquadMaxMembers = Computed(@() matchingQueues.get().reduce(@(res, gt) max(res, (gt?.maxGroupSize ?? 1)), 1))

function recalcSquadClusters() {
  if (!isSquadLeader.get())
    return
  squadClusters.set(clone selectedClusters.get())
  squadAutoCluster.set(isAutoCluster.get())
}

subscribeList(recalcSquadClusters, isSquadLeader, selectedClusters, isAutoCluster)

console_register_command(@() debugShowQueue.set(!debugShowQueue.get()), "ui.showQueueInfo")

return {
  STATUS
  curGameMode
  queueStatus
  isInQueue

  timeInQueue
  queueClusters
  canChangeQueueParams

  availableSquadMaxMembers
}