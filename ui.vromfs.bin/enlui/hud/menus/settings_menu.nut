import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/settingsMenu.nut" as settingsMenuCtor
from "eventbus" import eventbus_send
from "videomode" import apply_video_settings
from "%ui/hud/menus/options/options_lib.nut" import isOption
from "%ui/components/textButton.nut" import Regular
from "%ui/components/msgbox.nut" import showMsgbox
from "settings" import save_changed_settings, get_setting_by_blk_path, set_setting_by_blk_path, save_settings, remove_setting_by_blk_path
from "%ui/benchmark/benchmarkWnd.nut" import runBenchmarkBtn
from "%dngscripts/platform.nut" import is_pc
from "app" import reload_ui_scripts, reload_overlay_ui_scripts
from "%ui/state/login_state.nut" import isLoggedIn
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *


let {apply_audio_settings=@(_fields) null} = require_optional("dngsound")
let logMenu = with_prefix("[SettingsMenu] ")
let onlineSettingUpdated = require_optional("onlineStorage")
  ? require("%ui/options/onlineSettings.nut").onlineSettingUpdated : null

let showSettingsMenu = mkWatched(persist, "showSettingsMenu", false)
let settingsForRestart = mkWatched(persist, "settingsForRestart", {})

let closeMenu = @() showSettingsMenu.set(false)

let menuOptionsGen = WatchedImmediate(0)
let menuOptionsContainer = []
let getMenuOptions = @() menuOptionsContainer
let menuTabsOrder = Watched([])

let foundTabsByOptionsGen = Watched(0)
let foundTabsByOptionsContainer = []
let getFoundTabsByOptions = @(...) foundTabsByOptionsContainer
function setFoundTabsByOptions(v){
  foundTabsByOptionsContainer.replace(v)
  foundTabsByOptionsGen.modify(@(i) i+1)
}

let resultOptionsGen = Watched(0)
let resultOptionsContainer = []

function resultOptions(v){
  resultOptionsContainer.replace(v)
  resultOptionsGen.modify(@(i) i+1)
}

function setResultOptions(...){
  local optionsValue = getMenuOptions()
  let tabsInOptions = {}

  optionsValue = optionsValue.filter(@(opt) isOption(opt) && (
    (opt?.isAvailable == null && opt?.isAvailableWatched == null)
    || (opt?.isAvailableWatched.get() ?? opt?.isAvailable() ?? false)
  ))
  let res = []
  local lastSeparator = null
  let optionsStack = []

  foreach (opt in optionsValue) {
    if (opt?.tab != null ) {
      if (tabsInOptions?[opt.tab] == null)
        tabsInOptions[opt.tab] <- true
    }
    else {
      tabsInOptions["__unknown__"] <- true
    }

    if (opt?.isSeparator) {
      if (lastSeparator != null) {
        optionsStack.insert(0, lastSeparator)
        lastSeparator = null
      }
      res.extend(optionsStack)

      optionsStack.clear()
      lastSeparator = opt
    }
    else {
      optionsStack.append(opt)

      if (opt == optionsValue.top()) { 
        if (lastSeparator != null)
          res.append(lastSeparator)
        res.extend(optionsStack)
      }
    }
  }
  resultOptions(res)
  setFoundTabsByOptions(tabsInOptions.keys())
}

let lastSubscribers = []

function onOptionsChanged(...) {
  foreach (sub in lastSubscribers)
    sub.unsubscribe(setResultOptions)

  lastSubscribers.clear()
  foreach (opt in getMenuOptions()) {
    let { isAvailableWatched = null } = opt
    if (isAvailableWatched) {
      lastSubscribers.append(isAvailableWatched)
      isAvailableWatched.subscribe(setResultOptions)
    }
  }

  setResultOptions()
}

subscribeAndInit(onOptionsChanged, menuOptionsGen)

function getResultTabs(foundTabsByOptionsValue, tabsOrder){
  let selectedTabs = []
  let ret = []
  foreach (tab in tabsOrder) {
    if (foundTabsByOptionsValue.contains(tab?.id) && !selectedTabs.contains(tab?.id)) {
      ret.append(tab)
      selectedTabs.append(tab.id)
    }
  }
  foreach (id in foundTabsByOptionsValue)
    if (tabsOrder.findindex(@(tab) tab?.id == id) == null)
      ret.append({id=id, text=loc(id)})
  return ret
}

let curTab = mkWatched(persist, "curTab")
let currentTab = mkWatched(persist, "currentTab", menuTabsOrder.get()?[0].id)
menuTabsOrder.subscribe(function(v) {
  if (currentTab.get() == null && v.len()>0)
    currentTab.set(menuTabsOrder.get()?[0].id)
})

function checkAndApply(available, val, defVal, blkPath) {
  if (available == null)
    return val

  if (isObservable(available))
    available = available.get()
  if (typeof available != "array")
    available = [available]
  if (available.contains(val))
    return val

  logMenu($"{blkPath} absent value:", val, "default:", defVal, "available:", available)
  if (defVal != null)
    return defVal
  if (available.len() > 0)
    return available[0]

  logMenu($"{blkPath} absent value:", val, "no default values")
  return val
}


function backupRestartRequiredSettings() {
  
  remove_setting_by_blk_path("onReloadChanges")

  if (settingsForRestart.get().len() != 0) {
    
    foreach (blkPath, val in settingsForRestart.get())
      set_setting_by_blk_path($"onReloadChanges/{blkPath}", val)

    settingsForRestart.set({})
  }
  save_settings(true)
}


let convertForBlkByType = {
  float = @(v) v.tofloat()
  integer = @(v) v.tointeger()
  string = @(v) v.tostring()
  bool = @(v) !!v
}
function applyGameSettingsChanges(optionsValue, silentApply = false) {
  let onCloseActions = {
    needNotifyRestart = false
    needReload = false
  }

  let changedFields = []
  foreach (opt in optionsValue) {
    let { blkPath = null } = opt
    if (blkPath) {
      let defaultVal = opt?.defVal
      let isEq = opt.isEqual
      local hasChanges = false
      local val = opt.var.get()
      local defVal = defaultVal
      if ("convertForBlk" in opt) {
        let convertForBlk = opt.convertForBlk
        val = convertForBlk(val)
        defVal = isObservable(defaultVal) ? Computed(@() convertForBlk(defaultVal.get())) : convertForBlk(defaultVal)
      }
      else if ("typ" in opt && opt.typ in convertForBlkByType) {
        try {
          let cval = convertForBlkByType[opt.typ](val)
          let { available = null } = opt
          let res = checkAndApply(available, cval, defVal, blkPath)
          if (!isEq(res, cval)) {
            val = res
            changedFields.append(blkPath)
          } else
            val = cval
        }
        catch(e) {
          logMenu("error in loading ", opt, e)
          val = defVal
          changedFields.append(blkPath)
        }
      }

      if (opt?.restart) {
        let optSavedValue = get_setting_by_blk_path(blkPath) ?? defVal
        if (!isEq(optSavedValue, val) && val != null) {
          settingsForRestart.mutate(function(v) {
            
            v[blkPath] <- val

            
            foreach (moreSetting in opt?.getMoreBlkSettings(val) ?? [])
              v[moreSetting.blkPath] <- moreSetting.val
          })
          logMenu($"{blkPath}, {val} marked as 'restart required'. Saved until restart game")
        }
        else if (blkPath in settingsForRestart.get()) {
          settingsForRestart.mutate(function(v) {
            
            v.$rawdelete(blkPath)

            
            foreach (moreSetting in opt?.getMoreBlkSettings(val) ?? [])
              v.$rawdelete(moreSetting.blkPath)
          })

          logMenu($"{blkPath} marked as 'restart required'. Restored last saved value. Remove from save queue.")
        }
        continue
      }

      let blksettings = [{ blkPath, val, defVal }]
      if ("getMoreBlkSettings" in opt)
        blksettings.extend(opt.getMoreBlkSettings(val))

      foreach (setting in blksettings) {
        logMenu(setting.blkPath, get_setting_by_blk_path(setting.blkPath), setting?.defVal, setting.val)
        let savedValue = get_setting_by_blk_path(setting.blkPath) ?? setting?.defVal
        if (!isEq(savedValue, setting.val) && setting.val != null) {
          
          if (type(get_setting_by_blk_path(setting.blkPath)) != type(setting.val))
            remove_setting_by_blk_path(setting.blkPath)
          set_setting_by_blk_path(setting.blkPath, setting.val)
          changedFields.append(setting.blkPath)
          hasChanges = true
        }
      }

      if (hasChanges && opt?.reload)
        onCloseActions.needReload = true
    }
  }

  if (!silentApply && settingsForRestart.get().len())
    onCloseActions.needNotifyRestart = true

  backupRestartRequiredSettings()

  if (changedFields.len() != 0) {
    logMenu("apply changes", changedFields)
    save_changed_settings(changedFields)
    apply_video_settings(changedFields)
    apply_audio_settings(changedFields)
  }
  return onCloseActions
}

function doReload() {
  defer(function() {
    reload_overlay_ui_scripts()
    reload_ui_scripts()
  })
}

let saveAndApply = @(onMenuClose, options) function() {
  let onCloseActions = applyGameSettingsChanges(options)
  onMenuClose()
  eventbus_send("onlineSettings.sendToServer", null)

  if (onCloseActions.needNotifyRestart) {
    showMsgbox({
      text = loc("settings/restart_needed")
      buttons = [{ text = loc("Ok"), isCurrent = true
          action = onCloseActions.needReload ? doReload : null }]
    })
  }
  else if (onCloseActions.needReload)
    doReload()
}

if (onlineSettingUpdated)
  onlineSettingUpdated.subscribe(
    @(val) val ? defer(@() applyGameSettingsChanges(resultOptionsContainer)) : null
  )

function setMenuOptions(options){
  menuOptionsContainer.replace(options)
  menuOptionsGen.modify(@(v) v+1)
  applyGameSettingsChanges(resultOptionsContainer, true)
}

function mkSettingsMenuUi(menu_params) {
  function close(){
    menu_params?.onClose()
    closeMenu()
  }
  return function(){
    let tabs = getResultTabs(getFoundTabsByOptions(), menuTabsOrder.get())
    let allLeftButtons = clone (menu_params?.leftButtons ?? [])
    if (is_pc && currentTab.get() == "Graphics")
      allLeftButtons.append(runBenchmarkBtn)
    return {
      size = FLEX
      key = "settings_menu_root"
      onDetach = @() curTab.set(tabs?[0].id ?? "")
      onAttach = function() {
        if ((curTab.get() ?? "") == "")
          curTab.set(tabs?[0].id ?? "")
      }
      watch = [resultOptionsGen, currentTab, menuTabsOrder, foundTabsByOptionsGen]
      children = settingsMenuCtor({
        key = "settings_menu"
        size = const [sw(70), sh(80)]
        options = resultOptionsContainer
        sourceTabs = tabs
        currentTab = currentTab
        onClose = close
        buttons = [
          { size=FLEX, flow = FLOW_HORIZONTAL, children = allLeftButtons }
          Regular(loc("Ok"), saveAndApply(close, resultOptionsContainer), {
            hotkeys = [
              [$"^{JB.B} | J:Start | Esc", {action=saveAndApply(closeMenu, resultOptionsContainer), description={skip=true}}],
            ],
            skipDirPadNav = true
          })
        ]
        cancelHandler = @() null
      })
    }
  }
}

isLoggedIn.subscribe(@(v) v? null : closeMenu())

return {
  setMenuOptions
  mkSettingsMenuUi
  showSettingsMenu
  menuTabsOrder
}
