from "%dngscripts/sound_system.nut" import sound_play
from "%sqstd/table.nut" import getValInTblPath as getByPath
from "dagor.time" import get_time_msec
from "%ui/ui_library.nut" import *
from "types" import Table, Array

const MAX_EVENTS_DEFAULT = 10

let equalIgnore = { ttl = true, key = true, num = true }
let countNotIgnoreKeys = @(event) event.keys().reduce(@(res, key) equalIgnore?[key] ? res + 1 : res, 0)

function isEventSame(event1, event2) {
  if (countNotIgnoreKeys(event1) != countNotIgnoreKeys(event2))
    return false
  foreach (key, value in event1)
    if (!equalIgnore?[key] && event2?[key] != value)
      return false
  return true
}

function speedUpRemoveSame(eventList, event, maxTime) {
  for (local i = eventList.len() - 1; i >= 0; i--) {
    let eventToRemove = eventList[i]
    if (isEventSame(eventToRemove, event)) {
      eventToRemove.ttl = min(eventToRemove.ttl, maxTime)
      break;
    }
  }
}

function playEventSound(event){
  if ("sound" in event)
    sound_play(event?.sound ?? "", event?.volume ?? 1)
}

let EventLogState = class {
  data = null
  idCounter = null
  events = null
  clearTime = -1
  defTtl = null
  maxEvents = MAX_EVENTS_DEFAULT
  checkCollapseByFunc = null

  constructor(persistId, clearSameTime = -1, maxActiveEvents = MAX_EVENTS_DEFAULT, ttl = 5.0, collapseByFunc=null) {
    if (persistId instanceof Table){
      clearSameTime = persistId?.clearSameTime ?? clearSameTime
      maxActiveEvents = persistId?.maxActiveEvents ?? maxActiveEvents
      ttl = persistId?.ttl ?? ttl
      collapseByFunc = persistId?.collapseByFunc ?? collapseByFunc
      persistId = persistId.id
    }
    this.events = Watched([])
    this.idCounter = 0
    this.clearTime = clearSameTime
    this.maxEvents = maxActiveEvents
    this.defTtl = ttl
    this.checkCollapseByFunc = collapseByFunc
  }

  function clearEvents(){
    this.events?.mutate(@(v) v.clear())
    this.idCounter = 0
  }

  function pushEvent(eventExt, collapseBy=null) {
    let key = ++this.idCounter
    let ev = this.events?.get() ?? []
    let lastev  = ev?[ev.len()-1]
    let event = clone eventExt
    local funcCollapseBy = null
    if (collapseBy instanceof Array){
      funcCollapseBy = @(lastevt, evt) getByPath(lastevt,collapseBy) == getByPath(evt,collapseBy)
    }
    let funcToCheck = funcCollapseBy ?? this.checkCollapseByFunc
    this.events.mutate(function(_) {
      let unique = event?.unique
      if (unique != null)
        for (local idx = ev.len() - 1; idx >= 0; --idx) {
          if (ev[idx]?.unique == unique)
            ev.remove(idx)
        }
      event.ttl <- (event?.ttl != null && event.ttl >= 0) ? event.ttl : this.defTtl
      event.ctime <- get_time_msec()
      if (funcToCheck == null || !funcToCheck(lastev, event) || ev.len() == 0) {
        event.key <- key
        if (this.clearTime >= 0)
          speedUpRemoveSame(ev, event, this.clearTime)
        ev.append(event)
        playEventSound(event)
      }
      else {
        let num = (lastev?.num != null) ? lastev.num+1 : 2
        event.num <- num
        event.key <- lastev?.key ?? key
        ev[ev.len()-1] = event
      }
      if (ev.len() > this.maxEvents)
        ev.remove(0)
    }.bindenv(this))
  }

  function update(dt) {
    foreach (e in this.events.get())
      e.ttl -= dt
    let newEvents = this.events.get().filter(@(e) e.ttl > 0)
    if (newEvents.len() != this.events.get().len())
      this.events.set(newEvents)
  }
}

return {EventLogState, MAX_EVENTS_DEFAULT}
