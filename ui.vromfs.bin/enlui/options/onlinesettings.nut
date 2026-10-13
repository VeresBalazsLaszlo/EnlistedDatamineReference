import "%enlSqGlob/userInfo.nut" as userInfo
from "eventbus" import eventbus_subscribe
from "onlineStorage" import save_table_to_online_storage, get_table_from_online_storage, send_to_server, load_from_cloud
from "%sqstd/timers.nut" import debounce
from "%dngscripts/globalState.nut" import nestWatched
from "modules" import on_module_unload
from "%sqstd/frp.nut" import Watched
from "daRg" import gui_scene

let logOS = require("%enlSqGlob/library_logs.nut").with_prefix("[ONLINE_SETTINGS] ")
let onlineSettingUpdated = nestWatched("onlineSettingUpdated", false)
let onlineSettingsInited = nestWatched("onlineSettingsInited", false)

const STORAGE_ID = "GBT_GENERAL_SETTINGS"

let cacheForModuleUnload = { value = null }
function getOnlineTbl() {
  let data = get_table_from_online_storage(STORAGE_ID) ?? cacheForModuleUnload.value
  return typeof data != "table" ? {} : data
}
let settings = Watched(getOnlineTbl())

const SEND_PENDING_TIMEOUT_SEC = 600 

function onUpdateSettings(_userId) {
  settings.set(getOnlineTbl())
  onlineSettingUpdated.set(true)
  onlineSettingsInited.set(true)
}

if (userInfo.get()?.chardToken!=null && userInfo.get()?.userId!=null && !onlineSettingsInited.get()){ 
  onUpdateSettings(userInfo.get()?.userId)
}

local isSendToSrvTimerStarted = false

function sendToServer(forced = false) {
  if (!isSendToSrvTimerStarted && !forced)
    return 

  logOS("Send to server")
  gui_scene.clearTimer(callee())
  isSendToSrvTimerStarted = false
  send_to_server()
}

function startSendToSrvTimer() {
  if (isSendToSrvTimerStarted) {
    logOS("Timer to send is already on")
    return
  }

  isSendToSrvTimerStarted = true
  logOS("Start timer to send")
  gui_scene.resetTimeout(SEND_PENDING_TIMEOUT_SEC, sendToServer)
}

userInfo.subscribe(function (new_val) {
  if (new_val != null)
    return
  sendToServer()
  onlineSettingUpdated.set(false)
})

function save() {
  logOS("Save settings")
  let v = settings.get() ?? cacheForModuleUnload.value
  if (v != null)
    save_table_to_online_storage(v, STORAGE_ID)
}

let lazySave = debounce(save, 15)

settings.subscribe(function(new_val) {
  if (new_val != null)
    cacheForModuleUnload.value = new_val

  logOS("Queue setting to save")
  lazySave()
  startSendToSrvTimer()
})

function loadFromCloud(userId, cb) {
  load_from_cloud(userId, cb)
}

local isExiting = false
eventbus_subscribe("app.shutdown", function(_) {
  isExiting = true
})

eventbus_subscribe("onlineSettings.sendToServer", @(_) sendToServer())

on_module_unload(function(...){
  if (!isExiting && cacheForModuleUnload.value != null){
    save_table_to_online_storage(cacheForModuleUnload.value, STORAGE_ID)
    send_to_server()
  }
})

return {
  onUpdateSettings
  onlineSettingUpdated
  settings
  loadFromCloud
  startSendToSrvTimer
  sendToServer
  save
}
