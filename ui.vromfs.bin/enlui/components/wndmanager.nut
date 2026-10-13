from "%ui/components/topoSort.nut" import tSort
from "dagor.debug" import logerr
from "%sqstd/functools.nut" import kwarg
from "%ui/ui_library.nut" import *

enum Wnd {
  NONE = "*",
  ROULETTE = "roulette",
  ITEMS = "items",
  DAILY = "daily"
  BENCHMARK = "benchmark",
  PROFILE_ITEMS = "profileItems",
  SQUADS = "squads",
  BOOSTER_CAP = "boosterCap",
  PREM_EXPIRE = "premExpire",
  SQUAD_TUTORIAL = "squadTutorial",
  WEB_PROMO = "webPromo",
  EVENT = "event"
  CHANGELOG = "changelog"
  RETURNER = "returner"
}

let WndTypes = {}
foreach (_, v in Wnd)
  WndTypes[v] <- true

let priorities = Watched({})
let sortedPrioGraph = Computed(@() tSort(WndTypes, priorities.get()))

enum WndEvents {
  SUPPRESS
}

let commonHandlers = {
  [WndEvents.SUPPRESS] = @(w) w.isCurrent.set(false),
}

let windows = {}
let queued = Watched([])

let curWindow = keepref(Computed(function() {
  let queue = queued.get()
  if (queue.len() == 0)
    return null

  let order = {}
  let sorted = sortedPrioGraph.get()
  foreach (wnd in queue)
    order[wnd] <- sorted.indexof(wnd)

  return queue.reduce(@(res, wnd)
    order[wnd] < order[res] ? wnd : res)
}))

curWindow.subscribe(function(current) {
  foreach (name, wndData in windows) {
    let { isCurrent } = wndData
    isCurrent.set(current == name)
  }
})

function isDefined(name, enumerated) {
  foreach (_, val in enumerated)
    if (val == name)
      return true
  return false
}

function enqueue(name) {
  if (!queued.get().contains(name))
    queued.mutate(@(q) q.append(name))
}

let dequeue = @(name) queued.mutate(
  function(q) {
    let idx = q.indexof(name)
    if (idx != null)
      q.remove(idx)
  })

function registerWnd(dataWatch, showWatch, closeWatch, name, order = null, handlers = {}) {
  if (!isDefined(name, Wnd))
    logerr($"Window name is not defined. Can't register: {name}")

  if (name in windows)
    logerr($"Window already registered: {name}")

  if (order != null)
    priorities.mutate(@(v) v[name] <- order)

  let addWindow = Computed(@() dataWatch.get() && showWatch.get())
  addWindow.subscribe(@(v) v ? enqueue(name) : null)

  let removeWindow = Computed(@() !dataWatch.get() || closeWatch.get())
  removeWindow.subscribe(@(v) v ? dequeue(name) : null)

  let controlWatch = Watched(false)
  windows[name] <- {
    dataWatch
    addWindow
    removeWindow
    isCurrent = controlWatch
    handlers
  }

  if (addWindow.get())
    enqueue(name)

  return controlWatch
}

function sendWndEvent(evt) {
  if (!isDefined(evt, WndEvents))
    logerr($"Window event {evt} is undefined")

  foreach (w in windows) {
    w?.handlers[evt]()
    commonHandlers?[evt](w)
  }
}

console_register_command(@() console_print("queued", queued.get()), "debug.showQueuedWnd")
return {
  registerWnd = kwarg(registerWnd)
  Wnd
  sendWndEvent
  WndEvents
}
