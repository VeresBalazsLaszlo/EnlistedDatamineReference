from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/config/equipIncreaseConfig.nut" import equipSlotIncreaseCfg, equipAmmoIncreaseCfg
from "%ui/ui_library.nut" import *

let itemTypesWithEquivalents = {
  medkits = true
  repair_kit = true
  melee = true
  shovel = true
  axe = true
  grenade = true
  explosion_pack = true
  impact_grenade = true
  smoke_grenade = true
  incendiary_grenade = true
  antipersonnel_mine = true
  antitank_mine = true
  flask_usable = true
  binoculars_usable = true
}

let armiesWithEquivalents = [ "ger", "usa" ]

function collectSameTemplates(result, tplsList, allItemTemplatesV) {
  let sameItems = {}
  foreach (tpl, _ in tplsList)
    foreach (armyTemplates in allItemTemplatesV) {
      if (tpl not in armyTemplates)
        continue
      let { itemtype } = armyTemplates[tpl]
      let itemsList = sameItems?[itemtype] ?? []
      itemsList.append(tpl)
      sameItems[itemtype] <- itemsList
    }
  foreach (itemtype, itemsList in sameItems)
    result[itemtype] <- (result?[itemtype] ?? []).extend(itemsList)
}

let equivalentItemsList = Computed(function() {
  let equivalentsByType = {}
  let allItemTemplatesV = allItemTemplates.get()
  foreach (armyId, armyTemplates in allItemTemplatesV) {
    if (!armiesWithEquivalents.contains(armyId))
      continue
    foreach (basetpl, template in armyTemplates) {
      let { itemtype } = template
      if (itemtype not in itemTypesWithEquivalents)
        continue
      let listByType = equivalentsByType?[itemtype] ?? []
      listByType.append(basetpl)
      equivalentsByType[itemtype] <- listByType
    }
  }

  collectSameTemplates(equivalentsByType,
    equipAmmoIncreaseCfg.get(),
    allItemTemplatesV)

  foreach (templatesTbl in equipSlotIncreaseCfg.get())
    collectSameTemplates(equivalentsByType, templatesTbl, allItemTemplatesV)

  return equivalentsByType
})

return equivalentItemsList
