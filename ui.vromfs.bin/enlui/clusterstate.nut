import "dagor.system" as dagor_sys
from "%ui/geo.nut" import getClusterByCode
from "auth" import get_country_code
from "matching.api" import matching_listen_notify
from "%ui/matchingClient.nut" import matchingCall
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated, settings
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/featureFlags.nut" import hasAutoCluster
from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *
from "%ui/connectHolderR.nut" import isMatchingConnected

let logC = with_prefix("[CLUSTERS] ")

const CLUSTERS_KEY = "selectedClusters"
const AUTO_CLUSTER_KEY = "autoCluster"
let availableClustersDef = ["EU", "RU", "US", "JP"]
let debugClusters = dagor_sys.DBGLEVEL != 0 ? ["debug"] : []


let clustersViewMap = { RU = "EEU" }
let clusterLoc = @(cluster) loc(clustersViewMap?[cluster] ?? cluster)
let countryLoc = @(country) loc($"country/{country}", country.toupper())

let ownCluster = nestWatched("ownCluster", null)
let ownCountry = nestWatched("ownCountry", null)


let matchingClusters = nestWatched("matchingClusters", [])
function fetchClustersFromMatching() {
  let self = callee()
  if (!isMatchingConnected.get()) {
    return
  }

  matchingCall("hmanager.fetch_clusters_list",
    function (response) {
      if (response.error != 0) {
        gui_scene.resetTimeout(5, self) 
      }
      else {
        logC("clusters from matching server", response.clusters)
        matchingClusters.set(response.clusters)
      }
    }
  )
}

matchingClusters.subscribe(function(v) {
  if (v.len() == 0)
    gui_scene.resetTimeout(5, fetchClustersFromMatching)
  logC("matchingClusters:", v)
})

eventbus_subscribe("matching.connectHolder.ready", @(...) fetchClustersFromMatching())
fetchClustersFromMatching()

matching_listen_notify("hmanager.notify_clusters_changed")
eventbus_subscribe("hmanager.notify_clusters_changed", function(...) { fetchClustersFromMatching() })

let availableClusters = Computed(function() {
  local available = matchingClusters.get().filter(@(v) v!="debug")
  if (available.len()==0)
    available = clone availableClustersDef
  return available.extend(debugClusters)
})

function setOwnCluster() {
  local country_code = get_country_code()
  ownCountry.set(country_code.tolower())
  country_code = country_code.toupper()
  let localData = getClusterByCode({ code = country_code })
  let cluster = localData.cluster
  logC("country code:", country_code, "localData:", localData)
  ownCluster.set(cluster)
}

function validateClusters(clusters, available) {
  logC("validate clusters:", clusters, "available:", available)
  clusters = clusters.filter(@(has, cluster) has && available.contains(cluster))
  if (clusters.len() == 0 && available.contains(ownCluster.get()))
    clusters[ownCluster.get()] <- true
  if (clusters.len() == 0 && available.len() > 0)
    clusters[available[0]] <- true
  logC("result clusters:", clusters)
  return clusters
}

let clusters = nestWatched("clusters", validateClusters({}, availableClusters.get()))
let rawAutoCluster = nestWatched("autocluster", true)
let isAutoCluster = Computed(@() hasAutoCluster.get() && rawAutoCluster.get())

onlineSettingUpdated.subscribe(function(v) {
  if (!v)
    return
  setOwnCluster()
  logC("onlineSettings auto:", settings.get()?[AUTO_CLUSTER_KEY],"selectedClusters:", settings.get()?[CLUSTERS_KEY])
  rawAutoCluster.set(settings.get()?[AUTO_CLUSTER_KEY] ?? (clusters.get().len() <= 1))
  clusters.set(validateClusters(settings.get()?[CLUSTERS_KEY] ?? {}, availableClusters.get()))
})
setOwnCluster()
availableClusters.subscribe(function(available) {
  clusters.set(validateClusters(clusters.get(), available))
})

let selectedClusters = Computed(function() {
  if (!isAutoCluster.get())
    return clone clusters.get()
  let available = availableClusters.get()
  let ownId = ownCluster.get()
  if (available.contains(ownId))
    return { [ownCluster.get()] = true }
  return { [available[0]] = true }
})

selectedClusters.subscribe(@(v)
  logC("auto:", isAutoCluster.get(), "own:", ownCluster.get(), "selectedClusters:", v))

let oneOfSelectedClusters = Computed(function() {
  foreach (c, has in selectedClusters.get())
    if (has)
      return c
  return matchingClusters.get()?[0] ?? availableClustersDef[0]
})

clusters.subscribe(function(clustersVal) {
  let needSave = isEqual(settings.get()?[CLUSTERS_KEY], clustersVal)
  logC("onlineSettingsUpdated:", onlineSettingUpdated.get(), "isEqual to current:", needSave, "toSave:", clustersVal)
  if (!onlineSettingUpdated.get() || needSave)
    return
  settings.mutate(@(s) s[CLUSTERS_KEY] <- clustersVal.filter(@(has) has))
})

isAutoCluster.subscribe(function(isAuto) {
  if (!onlineSettingUpdated.get() || isAuto == settings.get()?[AUTO_CLUSTER_KEY])
    return
  settings.mutate(@(s) s[AUTO_CLUSTER_KEY] <- isAuto)
})

return {
  ownCountry
  availableClusters
  clusters
  selectedClusters
  isAutoCluster
  oneOfSelectedClusters
  clusterLoc
  countryLoc
}
