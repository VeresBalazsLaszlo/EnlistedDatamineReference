import "steam" as steam
from "%ui/state/login_state.nut" import isSteamRunning
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()

function getShopUrl() {
  if (!isSteamRunning.get())
    return circuitConf?.shopUrl
  let url = circuitConf?.shopUrlSteam
  return url ? url.subst({ appId = steam.get_app_id(), steamId = steam.get_my_id() }) : null
}

function getUrlByGuid(guid) {
  let url  = isSteamRunning.get()
    ? circuitConf?.shopGuidUrlSteam
    : circuitConf?.shopGuidUrl
  if (!url || !guid.len())
    return null
  let params = { guid = guid }
  if (isSteamRunning.get())
    params.__update({ appId = steam.get_app_id(), steamId = steam.get_my_id() })
  return url.subst(params)
}

function getShopCategoryUrl(category = "") {
  let url = isSteamRunning.get()
    ? circuitConf?.shopCategoryUrlSteam
    : circuitConf?.shopCategoryUrl

  if (!url || category == "")
    return ""

  let params = { category }
  if (isSteamRunning.get())
    params.__update({ appId = steam.get_app_id(), steamId = steam.get_my_id() })

  return url.subst(params)
}

return {
  getShopUrl
  getUrlByGuid
  getShopCategoryUrl
}