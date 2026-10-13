import "%ui/components/mkCheckbox.nut" as mkCheckbox
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, midPadding, smallPadding, panelBgColor, hoverPanelBgColor, darkTxtColor, darkPanelBgColor
  , commonBtnHeight, titleTxtColor
from "%ui/state/queueState.nut" import canChangeQueueParams, isInQueue
from "%ui/clusterState.nut" import availableClusters, clusters, clusterLoc, countryLoc, isAutoCluster, ownCountry
from "%ui/squad/squadState.nut" import isInSquad, isSquadLeader
from "%ui/popup/popupsState.nut" import addPopup, removePopup
from "%ui/components/textButton.nut" import Regular
from "%ui/featureFlags.nut" import hasAutoCluster
from "%ui/ui_library.nut" import *

let { squadSharedData } = require("%ui/squad/squadState.nut")
let squadClustersWatched = squadSharedData.clusters
let squadAutoClusterWatched = squadSharedData.isAutoCluster
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")


const CLUSTER_PANEL_UID = "clustersSelector"
const SELECTION_ERROR_UID = "groupSizePopup"
const NO_SERVER_ERROR = "noServerPopup"


let fillBgColor = @(sf) (sf & S_ACTIVE) || (sf & S_HOVER)
  ? hoverPanelBgColor
  : panelBgColor
let isLocalClusters = Computed(@() !isInSquad.get() || isSquadLeader.get())
let squadClusters = Computed(@() squadClustersWatched.get() ?? {})
let squadAutoCluster = Computed(@() squadAutoClusterWatched.get() ?? false)


function toggleServerSelection(server) {
  if (server in clusters.get()) {
    if (clusters.get().len() <= 1)
      addPopup({
        id = NO_SERVER_ERROR
        text = loc("quickMatch/noServer")
        styleName = "error"
      })
    else
      clusters.mutate(@(v) v.$rawdelete(server))
  }
  else
    clusters.mutate(@(v) v[server] <- true)
}


function mkServerBtn(server, txt, isAutoSelected = false) {
  let isSelected = Computed(@() server in clusters.get())
  return watchElemState(@(sf) {
    watch = isSelected
    rendObj = ROBJ_SOLID
    size = FLEX_H
    padding = [smallPadding, midPadding]
    color = fillBgColor(sf)
    children = mkCheckbox(isSelected, txt,
      {
        isActive = !isAutoSelected
        size = FLEX_H
        onClick = @() toggleServerSelection(server)
      })
  })
}


let optimalServerButton = watchElemState(@(sf) {
  watch = [isAutoCluster, ownCountry]
  rendObj = ROBJ_SOLID
  size = FLEX_H
  color = fillBgColor(sf)
  padding = [smallPadding, midPadding]
  children = mkCheckbox(isAutoCluster,
    loc("quickMatch/Server/Optimal", { code = countryLoc(ownCountry.get()) }),
    {
      size = FLEX_H
      onClick = @() isAutoCluster.set(!isAutoCluster.get())
    })
})

let clusterSelector = @() {
  watch = [availableClusters, isAutoCluster, clusters, hasAutoCluster]
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = hdpx(2)
  children = [
    hasAutoCluster.get() ? optimalServerButton : null
  ].extend(availableClusters.get().map(@(val)
    mkServerBtn(val, clusterLoc(val), isAutoCluster.get())))
}

let showCantChangeInQueue = @() addPopup({
  id = SELECTION_ERROR_UID
  text = loc("quickMatch/paramsInQue")
  styleName = "error"
})

function showCantChangeMessage() {
  if (isInQueue.get()) {
    showCantChangeInQueue()
    return
  }
  addPopup({
    id = SELECTION_ERROR_UID
    text = loc("quickMatch/squadLeaderParams")
    styleName = "error"
  })
}

function openClustersMenu(event) {
  if (isInQueue.get()) {
    showCantChangeInQueue()
    return
  }
  removePopup(SELECTION_ERROR_UID)
  modalPopupWnd.add(event.targetRect, {
    rendObj = ROBJ_SOLID
    color = darkPanelBgColor
    uid = CLUSTER_PANEL_UID
    size = const [fsh(27.5), SIZE_TO_CONTENT]
    popupOffset = 0
    padding = 0
    margin = [0, 0, midPadding, 0]
    popupHalign = ALIGN_CENTER
    popupBg = { rendObj = null }
    children = clusterSelector
  })
}

isInQueue.subscribe(@(_) modalPopupWnd.remove(CLUSTER_PANEL_UID))

let mkServersRow = @(locFn = @(v) v) Computed(function(){
  if (isLocalClusters.get())
    return isAutoCluster.get()
      ? loc("quickMatch/Server/Optimal", { code = countryLoc(ownCountry.get()) })
      : availableClusters.get().len() == clusters.get().len() ? loc("quickMatch/Server/Any")
      : ", ".join(clusters.get().keys().map(locFn))
  return squadAutoCluster.get()
    ? loc("quickMatch/Server/OptimalSquad")
    : ", ".join(squadClusters.get().keys().map(locFn))
})

let mkServerClusterBtn = @(serversRow, params = {}) function() {
  let text = loc("quickMatch/curServers", { server = serversRow.get() })
  let btn = Regular(text, isLocalClusters.get() ? openClustersMenu : showCantChangeMessage,
    {
      size = [SIZE_TO_CONTENT, commonBtnHeight]
      sEnables = canChangeQueueParams.get()
      hotkeys = [["^J:X", { description = loc("server/change") }]]
    }.__update(params))
  return {
    size = [FLEX, commonBtnHeight]
    halign = ALIGN_CENTER
    watch = [isLocalClusters, canChangeQueueParams, serversRow]
    children = btn
  }
}


let txtColor = @(sf) sf & S_ACTIVE
  ? titleTxtColor
  : sf & S_HOVER ? darkTxtColor : defTxtColor

function serversToShow(group = null, onClick = null) {
  let serversRow = mkServersRow()
  return watchElemState(function(sf) {
    return {
      watch = [serversRow]
      size = FLEX_H
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Marquee
      skipDirPadNav = true
      group
      onClick
      margin = const [0, hdpx(15), 0, hdpx(15)]
      scrollOnHover = true
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      text = loc("quickMatch/curServers", { server = serversRow.get() })
      color = txtColor(sf)
    }.__update(fontSub)
  })
}



return {
  serverClusterBtnAbbrev = mkServerClusterBtn(mkServersRow(), {size = FLEX})
  serverClusterBtn = mkServerClusterBtn(mkServersRow(clusterLoc))
  serversToShow
}
