import "%enlSqGlob/userInfo.nut" as userInfo
from "dagor.time" import get_time_msec
from "%ui/state/windowState.nut" import windowActive, steamOverlayActive
from "%ui/state/clientState.nut" import appId
from "%ui/state/appState.nut" import isInBattleState
from "%ui/components/browserWidget.nut" import isBrowserClosed
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

let needOnBrowserCloseCb = get_setting_by_blk_path("updatePurchasesOnBrowserClose") ?? false



function mkExtAutoRefreshTimer(
  refresh, 
  refreshDelaySec = 30 
) {
  local readyRefreshTime = 0
  local timeLeftToUpdate = 0
  local refreshPeriod = 10.0
  local startAutoRefreshTimer = null
  local isAutorefreshTimerStarted = false

  function autoRefreshImpl() {
    if (userInfo.get()?.userId == null || appId < 0)
      return

    readyRefreshTime = get_time_msec() + (1000 * refreshDelaySec).tointeger()
    if (!isInBattleState.get())
      refresh()

    timeLeftToUpdate = max(0, timeLeftToUpdate - 1)
    if (timeLeftToUpdate > 0)
      startAutoRefreshTimer()
  }

  function onRefresh() {
    isAutorefreshTimerStarted = false
    readyRefreshTime = 0
    if (windowActive.get() && !steamOverlayActive.get())
      autoRefreshImpl()
  }

  startAutoRefreshTimer = function() {
    if (isAutorefreshTimerStarted)
      return
    isAutorefreshTimerStarted = true
    gui_scene.resetTimeout(refreshPeriod, onRefresh)
  }

  function windowStateHandler(isActive) {
    if (isActive && (readyRefreshTime <= get_time_msec()))
      autoRefreshImpl()
  }

  isBrowserClosed.subscribe(function(v){
    if (v && needOnBrowserCloseCb)
      autoRefreshImpl()
  })

  windowActive.subscribe(windowStateHandler)
  steamOverlayActive.subscribe(@(overlayActive) windowStateHandler(!overlayActive))

  function refreshOnWindowActivate(repeatAmount = 1, refreshPeriodSec = 10.0) {
    readyRefreshTime = 0
    timeLeftToUpdate = repeatAmount
    refreshPeriod = refreshPeriodSec
  }

  return refreshOnWindowActivate
}

return mkExtAutoRefreshTimer