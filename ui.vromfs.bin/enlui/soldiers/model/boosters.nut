import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/meta/servProfile.nut" import activeBoosters
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/meta/clientApi.nut" import activate_booster, deactivate_booster
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let boostersConfig = mkComputedConfigGet("boosters", {})

let isBooster = @(item) item?.itemtype == "booster"

const HOUR_SEC = 60 * 60
const DAY_SEC = HOUR_SEC * 24
let holdActions = {}

let allBoostersBase = Computed(function() {
  let boosters = boostersConfig.get()
  let res = {}
  foreach (guid, booster in activeBoosters.get()) {
    let template = boosters?[booster.boosterId]
    if (template != null)
      res[guid] <- { booster, template }
  }
  return res
})

let allBoosters = Watched([])
let nextExpireTime = Watched(0)

let showHintActivateBoosters = nestWatched("showHintActivateBoosters", false)
let showHintExpiringBoosters = nestWatched("showHintExpiringBoosters", false)
let expiringBoostersTs = nestWatched({})

let needBoosterCapWarning = Watched(true)

function collectExpiringBoostersInfo(...) {
  let boosters = allBoosters.get() 
  if (boosters.len() == 0) {
    showHintActivateBoosters.set(false)
    expiringBoostersTs.set({})
    return
  }

  let hasActive = boosters.findvalue(@(booster) (booster?.booster.activeTs ?? 0) > 0) != null
  showHintActivateBoosters.set(!hasActive)

  let time = serverTime.get()
  let clearTsAfter = time - HOUR_SEC
  let expirationTs = expiringBoostersTs.get()?.filter(@(_, ts) ts > clearTsAfter) ?? {}
  local closestUpdateTs = time + DAY_SEC
  foreach (boosterObj in boosters) {
    let { booster } = boosterObj
    if (booster.activeTs > 0 || booster.expireTs < time)
      continue

    let dayWarning = booster.expireTs - DAY_SEC
    if (dayWarning > time)
      closestUpdateTs = min(closestUpdateTs, dayWarning)
    else if (dayWarning not in expirationTs)
      expirationTs[dayWarning] <- true

    let hourWarning = booster.expireTs - HOUR_SEC
    if (hourWarning > time)
      closestUpdateTs = min(closestUpdateTs, hourWarning)
    else if (hourWarning not in expirationTs)
      expirationTs[hourWarning] <- true
  }
  if (closestUpdateTs > time) 
    gui_scene.resetTimeout(closestUpdateTs - time, collectExpiringBoostersInfo)

  expiringBoostersTs.set(expirationTs)
}

allBoosters.subscribe(collectExpiringBoostersInfo)
expiringBoostersTs.subscribe(@(ts) showHintExpiringBoosters.set(ts.findvalue(@(v) v) != null))

let countNextExpire = @(boosters) boosters
  .reduce(@(res, b)
    b.booster.expireTs <= 0 || (res > 0 && b.booster.expireTs > res)
      ? res
      : b.booster.expireTs, 0)

function recalcActiveBosters(_ = null) {
  let time = serverTime.get()
  let boosters = allBoostersBase.get().filter(@(b)
      b.booster.expireTs <= 0 || b.booster.expireTs > time)
  let nextExpire = countNextExpire(boosters)
  let timeLeft = nextExpire - time
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft, recalcActiveBosters)
  allBoosters.set(boosters)
  nextExpireTime.set(nextExpire)
}
allBoosters.whiteListMutatorClosure(recalcActiveBosters)
nextExpireTime.whiteListMutatorClosure(recalcActiveBosters)

subscribeAndInit(recalcActiveBosters, allBoostersBase)

let battleLeftCount = @(boosterObj)
  (boosterObj?.template.battles ?? 0) - (boosterObj.booster?.battles ?? 0)

function setActivateBooster(boosterGuid) {
  if (boosterGuid in holdActions)
    return

  holdActions[boosterGuid] <- true
  activate_booster(boosterGuid, @(_) holdActions.$rawdelete(boosterGuid))
}

function setDeactivateBooster(boosterGuid) {
  if (boosterGuid in holdActions)
    return

  holdActions[boosterGuid] <- true
  deactivate_booster(boosterGuid, @(_) holdActions.$rawdelete(boosterGuid))
}

let curExpBonus = @(boosters) boosters.reduce(function(res, booster) {
  if ((booster?.booster.activeTs ?? 0) > 0 && (booster?.template.expMul ?? 0.0) > 0.0)
    return res + booster.template.expMul
  return res
}, 0.0)


console_register_command(@()
  log($"needBoosterCapWarning = {needBoosterCapWarning.get()}"), "meta.needBoosterCapWarning")

return {
  setActivateBooster
  setDeactivateBooster
  boostersConfig
  allBoosters
  battleLeftCount
  curExpBonus
  needBoosterCapWarning
  nextExpireTime
  isBooster
  showHintActivateBoosters
  showHintExpiringBoosters
  recalcActiveBosters
}
