import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/items/itemsPresentationUtils.nut" import mkReward
from "%ui/items/itemsPresentation.nut" import rewardsPresentation
from "%ui/ui_library.nut" import *

let addItemMappingCfg = mkComputedConfigGet("addItemMapping")

let itemMapping = Computed(function() {
  let addItemMapping = addItemMappingCfg.get()
  let res = clone rewardsPresentation
  if (addItemMapping == null)
    return res

  let { nameorig = "" } = userInfo.get()
  foreach (key, reward in addItemMapping)
    res[key] <- reward.__merge(res?[key] ?? {}, mkReward(reward, nameorig) ?? {})
  return res
})

return itemMapping
