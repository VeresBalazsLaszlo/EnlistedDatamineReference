from "dagor.debug" import logerr
from "%ui/ui_library.nut" import *
from "modules" import on_module_unload

let { is_app_terminating = @() false } = require("app")















let fadeState = mkWatched(persist, "fadeState", [])
let allActions = {}
const black = Color(0,0,0)
local counter = 0

let doFadeBlack = kwarg(function(fadein, fadeout=null, color = black, action = null, params = null, id = null) {
  counter++
  fadeState.mutate(@(value) value.append(
    { fadein, fadeout = fadeout ?? fadein, color, action, params, id = id ?? counter }))
})

function registerFadeBlackActions(actions) {
  foreach (name, act in actions)
    if (name in allActions)
      logerr($"fadeToBlack: Try to register already exist action /*{name}*/")
    else
      allActions[name] <- act
}

function removeFade(id) {
  let idx = fadeState.get().findindex(@(v) v.id==id)
  if (idx!=null)
    fadeState.mutate(@(fs) fs.remove(idx))
}

local isExiting = false
on_module_unload(@(...) isExiting=true) 

function doAction(fs) {
  if (isExiting || is_app_terminating())
    return
  let { action = null, params = null } = fs
  let handler = allActions?[action]
  if (handler == null) {
    if (action != null)
      logerr($"fadeToBlack: Unknown action /*{action}*/")
    return
  }

  let {parameters, defparams} = handler.getfuncinfos()
  let paramCount = parameters.len()
  let defargsCount = defparams.len()
  if (paramCount == 1)
    handler()
  else if (paramCount == 2)
    handler(params)
  else if (paramCount > 2 && (paramCount-defargsCount) <= 2)
    handler(params)
  else {
    log($"fadeToBlack: paramCount: {paramCount}, defargsCount: {defargsCount}")
    logerr($"fadeToBlack: Try to do action /*{action}*/ but it has wrong arguments count /*{paramCount}*/")
  }
}

function doActionAndRemove(fs) {
  doAction(fs)
  removeFade(fs.id)
}

function mkFs(fs) {
  local isComplete = false
  function completeFn() {
    if (isComplete)
      return
    isComplete = true
    doActionAndRemove(fs)
  }
  return {
    size = FLEX
    key = fs.id
    color = fs?.color ?? black
    rendObj = ROBJ_SOLID
    onDetach = completeFn
    onAttach = @() gui_scene.resetTimeout(fs?.fadein ?? 0.5, completeFn, fs.id)
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = fs?.fadein ?? 0.5, play = true }
      { prop = AnimProp.opacity, from = 1, to = 0, duration = fs?.fadeout ?? 0.5, playFadeOut = true }
    ]
  }
}

let fadeBlackUi = @() {
  watch = fadeState
  children = fadeState.get().map(mkFs)
  size = FLEX
}

return {
  registerFadeBlackActions
  doFadeBlack
  fadeBlackUi
}
