from "%ui/meta/configs.nut" import mkComputedConfigGet, mkComputedConfigView
from "%ui/ui_library.nut" import *

let soldierResideTpl = mkComputedConfigGet(["gameProfile", "soldierResideTpl"])
let soldierResideGoldCost = mkComputedConfigGet(["gameProfile", "soldierResideGoldCost"])
let resideCustomization = mkComputedConfigGet(["soldierResideCfg", "customization"])
let soldierResideCountry = mkComputedConfigGet(["soldierResideCfg", "country"])

let soldierReside = mkComputedConfigView(function(cfg) {
  let { resides = [], country = {} } = cfg?.soldierResideCfg
  let resideData = {}
  foreach (resideList in resides)
    foreach (fromTemplate in resideList) {
      let dataList = []
      let fromCountry = country?[fromTemplate] ?? ""
      if (fromCountry == "")
        log($"[RESIDE CONFIG] absent country for template {fromTemplate}")
      resideData[fromTemplate] <- dataList
      foreach (toTemplate in resideList) {
        if (fromTemplate == toTemplate)
          continue

        let toCountry = country?[toTemplate] ?? ""
        if (toCountry == "")
          log($"[RESIDE CONFIG] absent country for template {toTemplate}")
        dataList.append({
          toTemplate
          toCountry
          fromTemplate
          fromCountry
        })
      }
    }
  return resideData
})

function canResideSoldier(soldier, classesConfig) {
  if (soldier == null)
    return false
  let { isHero = false, heroTpl = null, sClass = null } = soldier
  let { isTransferLocked = false } = classesConfig?[sClass]
  return !isHero && (heroTpl ?? "") == "" && !isTransferLocked
}

return {
  soldierResideTpl
  soldierResideGoldCost
  soldierReside
  resideCustomization
  soldierResideCountry
  canResideSoldier
}
