import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/hud/state/mkBlockedTimeout.nut" as mkBlockedTimeout
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/meta/servProfile.nut" import decorators
from "%ui/meta/clientApi.nut" import add_decorator, add_all_decorators, choose_decorator,
  buy_decorator, remove_decorator
from "%ui/ui_library.nut" import *

let { portraits, nickFrames } = require("%ui/components/decoratorsPresentation.nut")


const EXPIRED_TEXT_TIME = 3

let decoratorInPurchase = Watched(null)

let ownDecorators = Watched({})
let decoratorsCfg = mkComputedConfigGet("decoratorsCfg", {})
let blockedDecorators = mkBlockedTimeout(decoratorsCfg)

let nextExpireTime = keepref(Computed(function() {
  local time = 0
  foreach (decorator in ownDecorators.get()) {
    let { expireTime = 0 } = decorator
    if (expireTime > 0)
      time = time == 0 ? expireTime : min(time, expireTime)
  }
  return time
}))

function recalcActiveDecorators() {
  let time = serverTime.get()
  let res = decorators.get().filter(@(d) d.expireTime == 0 || (d.expireTime - time) > 0)
  ownDecorators.set(freeze(res))
}

nextExpireTime.subscribe(function(v) {
  let timeLeft = v - serverTime.get()
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft + EXPIRED_TEXT_TIME, recalcActiveDecorators)
})

decorators.subscribe(@(_) recalcActiveDecorators())

serverTime.subscribe(function(time) {
  if (time <= 0)
    return
  serverTime.unsubscribe(callee())
  recalcActiveDecorators()
})

let decoratorsCfgByType = Computed(function() {
  let res = {}
  let blocked = blockedDecorators.get()
  foreach (guid, decoratorCfg in decoratorsCfg.get()) {
    if (guid in blocked)
      continue

    let { cType, weight = 0, isNotOwnedHidden = false, buyData = null } = decoratorCfg
    if (cType not in res)
      res[cType] <- {}
    res[cType][guid] <- { guid, weight, isNotOwnedHidden, buyData }

    
    if (cType == "portrait")
      res[cType][guid].__update(portraits?[guid] ?? {})
    else
      res[cType][guid].viewCb <- nickFrames?[guid]
  }
  return res
})

let decoratorsListByType = Computed(@()
  decoratorsCfgByType.get().map(@(v) v.values()))

let availDecoratorsByType = Computed(function() {
  let decorsCfg = decoratorsCfg.get()
  let res = {}
  foreach (guid, decorator in ownDecorators.get()) {
    let { cType = null } = decorsCfg?[guid]
    if (cType == null)
      continue

    if (cType not in res)
      res[cType] <- {}
    res[cType][guid] <- decorator
  }
  return res
})

let portraitsConfig = Computed(@() decoratorsListByType.get()?.portrait ?? [])
let nickFramesConfig = Computed(@() decoratorsListByType.get()?.nickFrame ?? [])

let availPortraits = Computed(@() availDecoratorsByType.get()?.portrait ?? {})
let availNickFrames = Computed(@() availDecoratorsByType.get()?.nickFrame ?? {})

let sortDecorators = @(a, b, avail)
  b.guid in avail <=> a.guid in avail
    || a.weight <=> b.weight
    || b.guid <=> a.guid

let portraitCfgAvailable = Computed(function() {
  let avail = availPortraits.get()
  return portraitsConfig.get()
    .filter(@(p) !p.isNotOwnedHidden || p.guid in avail)
    .sort(@(a, b) sortDecorators(a, b, avail))
})

let nickFramesCfgAvailable = Computed(function() {
  let avail = availNickFrames.get()
  return nickFramesConfig.get()
    .filter(@(p) !p.isNotOwnedHidden || p.guid in avail)
    .sort(@(a, b) sortDecorators(a, b, avail))
})

let chosenPortrait = Computed(@() availPortraits.get().findvalue(@(v) v.hasChosen))
let chosenNickFrame = Computed(@() availNickFrames.get().findvalue(@(v) v.hasChosen))

function chooseDecorator(cType, guid) {
  choose_decorator(cType, guid)
}

function buyDecorator(guid, cost) {
  if (decoratorInPurchase.get() != null)
    return

  decoratorInPurchase.set(guid)
  buy_decorator(guid, cost, function(_) {
    decoratorInPurchase.set(null)
  })
}

console_register_command(add_decorator, "meta.addDecorator")
console_register_command(add_all_decorators, "meta.addAllDecorators")
console_register_command(remove_decorator, "meta.removeDecorator")

return {
  decoratorsCfgByType
  portraitsConfig
  nickFramesConfig
  availPortraits
  availNickFrames
  portraitCfgAvailable
  nickFramesCfgAvailable
  chosenPortrait
  chosenNickFrame
  chooseDecorator
  buyDecorator
  decoratorInPurchase
}
