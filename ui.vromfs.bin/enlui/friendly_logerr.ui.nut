import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/components/fontawesome.map.nut" as fa
import "%ui/style/colors.nut" as colors
import "dagor.system" as dagorSys
from "dagor.debug" import logerr, register_logerr_interceptor
from "%ui/style/fontsStyle.nut" import fontawesome
from "%dngscripts/platform.nut" import platformId, is_pc
from "%ui/ui_library.nut" import *

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")


let errors = mkWatched(persist, "errors", [])
let haveUnseenErrors = mkWatched(persist, "haveUnseenErrors", false)

const maxErrorsToShow = 8

function addError(tag, logstring, timestamp, text){
  local curErrors = clone errors.get()

  if (curErrors.len() >= maxErrorsToShow)
    curErrors = curErrors.slice(-(maxErrorsToShow-1))
  curErrors.append({timestamp = timestamp, logstring = logstring, tag=tag, text=text})
  errors.set(curErrors)
  haveUnseenErrors.set(true)
}

function mkSimpleCb(locid) {
  return function(tag, logstring, timestamp){
    addError(tag, logstring, timestamp, "logerr/{0}{1}".subst(is_pc ? "" : $"{platformId}/", locid))
  }
}

let tagsForPopup = ["web-vromfs:", "[disk]", "[network]"]
tagsForPopup.map(@(tag) register_logerr_interceptor([tag], mkSimpleCb(tag)))

if (dagorSys.DBGLEVEL <= 0) {
  let clientlog = require("clientlog")
  function sendErrorInRelease(_tag, logstring, _timestamp) {
    clientlog.send_error_log(logstring, {
      attach_game_log = false,
      meta = {}
    })
  }
  register_logerr_interceptor(["[frp:error]"], sendErrorInRelease)
}

local counter = 0
function test_log_errors(){
  counter++
  errors.set(clone errors.get())
  logerr($"web-vromfs: [network] {counter}")
}
console_register_command(@()gui_scene.setInterval(2.0, test_log_errors), "ui.test_logerrs")

function textarea(text, logstring) {
  local onClick

  if (dagorSys.DBGLEVEL > 0) {
    onClick = function onClickImpl() {
      modalPopupWnd.add([sw(50),sh(0)], {
        size = const [sw(100), sh(100)]
        uid = "LOGGER_ERROR_DETAILS"
        padding = 0
        popupOffset = 0
        margin = 0
        children = {
          size = FLEX
          rendObj = ROBJ_TEXTAREA
          behavior = [Behaviors.TextArea]
          text = logstring
          color = Color(220,220,220,220)
          textColor = Color(220,220,220,220)
        }
        popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, color = Color(220,220,220,220) fillColor = Color(0,0,0,180)}
      })
    }
  }

  return watchElemState(@(sf) {
    rendObj = ROBJ_TEXTAREA
    behavior = [Behaviors.TextArea, Behaviors.Button]
    text = loc(text,loc("unknown error"))
    color = sf & S_HOVER ? Color(220,220,220) : Color(128,128,128)
    size = FLEX_H
    onClick = onClick
    skipDirPadNav = true
  })
}


let header = @(text) {
  rendObj = ROBJ_SOLID
  size = FLEX_H
  padding = hdpx(10)
  color = colors.WindowHeader
  children = {rendObj = ROBJ_TEXT text = text color = Color(128,128,128) size = FLEX_H}
}






function errors_list(){
  return {
    watch = errors
    flow = FLOW_VERTICAL
    size = FLEX_H
    padding = hdpx(20)
    children = errors.get().map(@(v) textarea(v.text, v.logstring))
    gap = hdpx(20)
  }
}
function onClick(event){
  modalPopupWnd.add(event.targetRect,
  {
    size = const [sw(45), sh(40)]
    uid = "MODAL_LOGERR"
    padding = 0
    popupFlow = FLOW_VERTICAL
    popupValign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow= FLOW_VERTICAL
    popupOffset = 0
    margin = 0
    onDetach = @() haveUnseenErrors.set(false)
    onAttach = @() haveUnseenErrors.set(false)
    children = [
      header(loc("logerrWnd_hdr", "Warnings"))
      {
        size = FLEX
        clipChildren = true
        children = scrollbar.makeVertScroll(errors_list)
      }
    ]
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, color = Color(220,220,220,220) fillColor = Color(0,0,0,180)}
  })
}
function mkBtn(){
  let stateFlags = Watched(0)
  let onElemState = @(sf) stateFlags.set(sf)
  return function(){
    let sf = stateFlags.get()
    return {
      behavior = Behaviors.Button
      onClick = onClick
      watch = stateFlags
      rendObj = ROBJ_INSCRIPTION
      validateStaticText = false
      onElemState = onElemState
      text = fa["exclamation-triangle"]
      fontSize = hdpx(12)
      font = fontawesome.font
      color = sf & S_HOVER ? Color(255,255,255) : Color(245, 100, 30, 100)
    }
  }
}

let errBtn = mkBtn()
function errorBtn(){
  return {
    watch = [haveUnseenErrors,errors]
    size = SIZE_TO_CONTENT
    children = haveUnseenErrors.get() ? errBtn : null
    padding = hdpx(5)
  }
}

return errorBtn
