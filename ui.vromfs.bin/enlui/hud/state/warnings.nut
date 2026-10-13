import "%dngscripts/ecs.nut" as ecs
from "net" import get_sync_time
from "dasevents" import CmdNarratorAboutLocalTeam
from "%ui/ui_library.nut" import *

let warningsList = mkWatched(persist, "warningsList", [])

let WARNING_PRIORITIES = {
  HIGH = 0
  MEDIUM = 1
  LOW = 2
  ULTRALOW = 3
}

let possibleWarningsList = {}

assert(possibleWarningsList.len()==0, "should be added only where it used")

function addWarnings(wList) {
  possibleWarningsList.__update(wList)
}

local updateWarinigsTime = @() null 
function setWarningsList(list) {
  let curTime = get_sync_time()
  list = list.filter(@(v) v.showEndTime <= 0 || v.showEndTime > curTime)
    .sort(@(a, b) a.priority <=> b.priority || a.showEndTime <=> b.showEndTime || a.id <=> b.id)
  warningsList.set(list)

  let closestWarningTime = list
    .reduce(@(res, w) w.showEndTime > 0 && (res <= 0 || res > w.showEndTime) ? w.showEndTime : res, 0)
  if (closestWarningTime > 0)
    gui_scene.resetTimeout(closestWarningTime - curTime, updateWarinigsTime)
}
warningsList.whiteListMutatorClosure(setWarningsList)

updateWarinigsTime = @() setWarningsList(warningsList.get())


function warningShow(warningId) {
  let wparams = possibleWarningsList?[warningId]
  if (wparams == null) {
    log($"Failed to add warning {warningId} it does not exist in possibleWarningsList")
    return
  }

  let list = warningsList.get()
  let curWarning = list.findvalue(@(w) w.id == warningId)
  let newWarning = {
    id = warningId
    locId = wparams?.locId ?? warningId
    priority = wparams.priority
    showEndTime = "timeToShow" in wparams ? get_sync_time() + wparams.timeToShow : -1
    color = wparams?.color
  }
  if (curWarning)
    curWarning.__update(newWarning)
  else
    list.append(newWarning)
  setWarningsList(list)

  let snd = wparams?.getSound()
  if (snd != null)
    ecs.g_entity_mgr.broadcastEvent(CmdNarratorAboutLocalTeam({phrase=snd, replace=false}))
}

function warningHide(warningId) {
  let idx = warningsList.get().findindex( @(v) v.id == warningId )
  if (idx == null)
    return
  warningsList.get().remove(idx)
  setWarningsList(warningsList.get())
}

let warningUpdate = @(warningId, shouldShow)
  shouldShow ? warningShow(warningId) : warningHide(warningId)


console_register_command(function(idx=0) {
  let id = idx in possibleWarningsList ? idx
    : (possibleWarningsList.keys()?[idx] ?? possibleWarningsList.keys()?[0])
  let isVisible = warningsList.get().findindex(@(w) w.id == id) != null
  warningUpdate(id, !isVisible)
}, "ui.warning_debug")

return {
  warningsList
  addWarnings
  warningUpdate
  WARNING_PRIORITIES
}
