from "%enlSqGlob/library_logs.nut" import log
from "app" import get_app_id
from "%dngscripts/platform.nut" import isPlatformXbox, isPlatformSony

let appIdsList = [get_app_id()]

function setAppIdsList(list) {
  log("[APP IDS] set list ", list)
  appIdsList.clear()
  appIdsList.extend(list)
}
let getAppIdsList = @() clone appIdsList

let getAppIdByPlatform = @(platformId) isPlatformXbox(platformId) ? 1132
  : isPlatformSony(platformId) ? 1178
  : 1131

return {
  setAppIdsList,
  getAppIdsList,
  getAppIdByPlatform
}