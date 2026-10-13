from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/ui_library.nut" import *

let itemsUpgradeConfig = mkComputedConfigGet("items_upgrade_config", [])
let itemsDisposeConfig = mkComputedConfigGet("items_dispose_config", [])

function rebuildConfig(modifyConfigList) {
    let res = {}
    foreach (modifyConfig in modifyConfigList) {
      
      let { tier = 0, prices = {} } = modifyConfig
      foreach (itemType, modifyPrice in prices) {
        let tiersList = res?[itemType] ?? []
        let pricesTbl = tiersList?[tier] ?? {}
        pricesTbl[modifyPrice.itemTpl] <- modifyPrice
        if (tiersList.len() <= tier)
          tiersList.resize(tier + 1)
        tiersList[tier] = pricesTbl
        res[itemType] <- tiersList
      }
    }
    return res
  }

let itemUpgrades = Computed(@() rebuildConfig(itemsUpgradeConfig.get()))
let itemDisposes = Computed(@() rebuildConfig(itemsDisposeConfig.get()))

let getModifyConfig = @(modifyConfig, tier, itemType)
  modifyConfig?[itemType][tier] ?? modifyConfig?["default"][tier]

let disposableTypes = Computed(function() {
  let res = {}
  foreach (cfg in itemsDisposeConfig.get())
    foreach (itemtype, _ in cfg.prices) {
      if (itemtype != "default")
        res[itemtype] <- true
    }
  return res
})

return {
  itemUpgrades
  itemDisposes
  getModifyConfig
  disposableTypes
}
