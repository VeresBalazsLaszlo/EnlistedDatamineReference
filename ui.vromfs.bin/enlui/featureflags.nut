from "settings" import get_setting_by_blk_path
from "dagor.system" import DBGLEVEL
from "%dngscripts/globalState.nut" import nestWatched
from "%dngscripts/platform.nut" import is_gdk, is_pc
from "%ui/ui_library.nut" import *

let SHOW_MODS_DEFAULT = !(is_pc && is_gdk)

let hasProfileCard = nestWatched("hasProfileCard", true)
let hasCustomGames = nestWatched("hasCustomGames", true)
let showEventsWidget = nestWatched("showEventsWidget", true)
let hasUserLogs = nestWatched("hasUserLogs", DBGLEVEL > 0)
let showModsInCustomRoomCreateWnd = nestWatched("showMods", SHOW_MODS_DEFAULT)
let hasVehicleCustomization = nestWatched( "hasVehicleCustomization", true)
let isOffersVisible = nestWatched("isOffersVisible", true)
let hasUsermail = nestWatched("hasUsermail", DBGLEVEL > 0)
let showReplayTabInProfile = nestWatched("showReplayTabInProfile", true)
let showUserProfile = nestWatched("showUserProfile", DBGLEVEL > 0)
let PSNAllowShowQRCodeStore = nestWatched("PSNAllowShowQRCodeStore", false)
let canRentSquad = nestWatched("canRentSquad", false)
let hasAutoCluster = nestWatched("hasAutoCluster", false)
let allowReconnect = nestWatched("allowReconnect", true)
let hasHitCamera = nestWatched("hasHitCamera", DBGLEVEL > 0)
let hasGpuBenchmark = nestWatched("hasGpuBenchmark", false)
let hasMissionLikes = nestWatched("hasMissionLikes", true)
let hasMissionTutorial = nestWatched("hasMissionTutorial", false)
let hasControlTutorial = nestWatched("hasControlTutorial", false)
let canTestDriveItems = nestWatched("canTestDriveItems", true)
let hasSkinCustomizer = nestWatched("hasSkinCustomizer", true)


let features = {
  hasProfileCard
  hasUserLogs
  hasCustomGames
  showEventsWidget
  showModsInCustomRoomCreateWnd
  hasVehicleCustomization
  isOffersVisible
  hasUsermail
  showReplayTabInProfile
  showUserProfile
  PSNAllowShowQRCodeStore
  canRentSquad
  hasAutoCluster
  allowReconnect
  hasHitCamera
  hasGpuBenchmark
  hasMissionLikes
  hasMissionTutorial
  hasControlTutorial
  canTestDriveItems
  hasSkinCustomizer
}

foreach (featureId, featureFlag in features)
  featureFlag.set(get_setting_by_blk_path($"features/{featureId}") ?? featureFlag.get())

console_register_command(
  @(name) name in features ? console_print($"{name} = {features[name].get()}") : console_print($"FEATURE NOT EXIST {name}"),
  "feature.has")

console_register_command(
  function(name) {
    if (name not in features)
      return console_print($"FEATURE NOT EXIST {name}")
    let feature = features[name]
    feature.set(!feature.get())
    console_print($"Feature {name} changed to {feature.get()}")
  }
  "feature.toggle")

return freeze(features)