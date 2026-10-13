import "steam" as steam
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/userInfoState.nut" import userInfo
from "eventbus" import eventbus_subscribe_onehit
from "app" import get_circuit_conf, get_app_id
from "settings" import get_setting_by_blk_path
from "%ui/options/onlineSettings.nut" import settings, save
from "%ui/state/login_state.nut" import isSteamRunning
from "%ui/components/openUrl.nut" import openUrl
from "dasevents" import EventTimelineEvent
from "%ui/ui_library.nut" import *

let { get_steam_link_token = @(...) null} = require_optional("auth.steam")
let logS = with_prefix("[Steam Url] ")

let isLinked = keepref(Computed(@() !steam.is_running()
  || !userInfo.get()?.tags.contains("steamlogin")))

let isPureSteamAccount = Computed(@() steam.is_running()
  && !userInfo.get()?.tags.contains("steam_el"))

let isOpenLinkUrlInProgress = Watched(false)

let circuitConf = get_circuit_conf()
let { steamBindUrl = null, steamRebindUrl = "" } = circuitConf
let isLinkToEmailEnabled = get_setting_by_blk_path("linkToEmailEnabled") ?? false
let isLinkToSteamEnabled = get_setting_by_blk_path("linkToSteamEnabled") ?? false

let hasDropLinkButton = Computed(@() isLinkToSteamEnabled
  && isSteamRunning.get()
  && !userInfo.get()?.tags.contains("steam_el"))

const STEAM_LINK_SEEN_ID = "ui/steamAccountMsgBoxSeen"

function goToSteamUrl(res, url) {
  let token = res?.token ?? ""
  if (token == "")
    logS("empty token")
  else
    openUrl(url.subst({ token = token, langAbbreviation = loc("langAbbreviation"), appId = get_app_id() }))
  isOpenLinkUrlInProgress.set(false)
}

function openLinkUrl(url) {
  if (!url || url == "")
    return logS("empty url in network.blk")

  isOpenLinkUrlInProgress.set(true)

  eventbus_subscribe_onehit("get_steam_link_token", @(res) goToSteamUrl(res, url))
  get_steam_link_token("get_steam_link_token")
}


let isLinkEmailAvailable = Computed(@() isLinkToEmailEnabled
  && !isLinked.get()
  && isSteamRunning.get())


function clearSteamLinkSeen() {
  settings.mutate(@(set) set.$rawdelete(STEAM_LINK_SEEN_ID))
  save()
}

console_register_command(clearSteamLinkSeen, "steam.reset_seen_link_msgbox")


ecs.register_es("video_clip_timeline_events", {
    [EventTimelineEvent] = @(evt, _, __) steam.steam_add_instantaneous_timeline_event(loc(evt.title), loc(evt.desc), evt.icon, evt.priority, evt.startTime, evt.clipMode)
})

return {
  openSteamLinkUrl = @() openLinkUrl(steamBindUrl)
  openSteamRelinkUrl = @() openUrl(steamRebindUrl.subst({langAbbreviation = loc("langAbbreviation"), appId = steam.get_app_id()}))
  isPureSteamAccount
  isLinkEmailAvailable
  isLinkToSteamEnabled
  hasDropLinkButton
  STEAM_LINK_SEEN_ID
  clearSteamLinkSeen
}
