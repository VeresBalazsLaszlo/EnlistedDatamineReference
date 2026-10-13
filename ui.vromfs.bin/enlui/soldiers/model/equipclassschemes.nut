from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/soldiers/model/all_items_templates.nut" import equipSchemesByArmy
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/ui_library.nut" import *

let equipSchemesByClass = mkComputedConfigGet("equip_classes", {})

function getEquipClasses(armyId, basetpl, itemType) {
  basetpl = trimUpgradeSuffix(basetpl)
  let classList = {}
  let classSchemes = equipSchemesByClass.get()?[armyId] ?? {}
  foreach (sClass, schemeId in classSchemes) {
    let schemeList = equipSchemesByArmy.get()?[armyId][schemeId] ?? {}
    foreach (scheme in schemeList) {
      let { items = [], itemTypes = [] } = scheme
      if ((itemTypes.len() == 0 && items.len() == 0)
          || itemTypes.contains(itemType)
          || items.contains(basetpl)) {
        classList[sClass] <- true
        break;
      }
    }
  }
  return classList.keys()
}

return getEquipClasses