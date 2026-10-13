from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/ui_library.nut" import *

let itemsTemplatesCfg = mkComputedConfigGet("items_templates", {})
let equipSchemesCfg = mkComputedConfigGet("equip_schemes", {})



let equipSchemesByArmy = Computed(function() {
  const tblDisabled = { isDisabled = true }
  let emptyArray = freeze([])
  let schemesAll = {}
  let equip_schemes = equipSchemesCfg.get()
  let items_templates = itemsTemplatesCfg.get()
  foreach (armyId, armyTemplates in items_templates) {
    let templatesTypes = {}
    foreach(tpl in armyTemplates)
      templatesTypes[tpl.itemtype] <- true

    schemesAll[armyId] <- equip_schemes.map(@(scheme) scheme.map(function(slot) {
      let { items = emptyArray, itemTypes = emptyArray } = slot
      local availItemOrType = items.findvalue(@(itemTpl) itemTpl in armyTemplates)
        ?? itemTypes.findvalue(@(it) it in templatesTypes) 
      return availItemOrType == null ? slot.__merge(tblDisabled) : slot
    }))
  }
  return schemesAll
})

let allItemTemplates = Computed(function() {
  let all = {}
  let items_templates = itemsTemplatesCfg.get()
  foreach (armyId, armyTemplates in items_templates) {
    let equipSchemes = equipSchemesByArmy.get()?[armyId] ?? {}
    if (armyId not in all)
      all[armyId] <- {}

    foreach (key, tmpl in armyTemplates) {
      let { equipSchemeId = null } = tmpl
      if (equipSchemeId in equipSchemes) {
        let item = clone tmpl
        item.equipScheme <- equipSchemes[equipSchemeId] 
        all[armyId][key] <- item
      } else
        all[armyId][key] <- tmpl
    }
  }
  return all
})

function findItemTemplate(templates, army, tpl) {
  return templates?[army][tpl]
}

function findTemplateInArmies(templates, armies, tpl) {
  foreach (armyId in armies)
    if (tpl in (templates?[armyId] ?? {}))
      return { armyId, template = templates[armyId][tpl] }

  return null
}

let singleSlotItemTypes = @(subSchemeGetter) function(scheme, resTypes) {
  let { itemTypes = [] } = subSchemeGetter(scheme)
  foreach (iType in itemTypes)
    resTypes[iType] <- true
}

let slotTypesConfig = {
  function mainWeapon(scheme, resTypes) {
    foreach (key, slotData in scheme)
      if (["primary", "secondary"].contains(slotData?.ingameWeaponSlot) && key != "medbox") {
        let { itemTypes = [] } = slotData
        foreach (iType in itemTypes)
          resTypes[iType] <- true
      }
  }
  primary = singleSlotItemTypes(@(scheme) scheme?.primary)
  secondary = singleSlotItemTypes(@(scheme) scheme?.secondary)
  melee = singleSlotItemTypes(@(scheme) scheme?.melee)
}

let itemTypesInSlots = Computed(function() {
  let equipSchemes = equipSchemesCfg.get()
  return slotTypesConfig.map(function(handler) {
    let resTypes = {}
    equipSchemes.each(@(s) handler(s, resTypes))
    return resTypes
  })
})

function getTierInterval(items, templates) {
  local minTier = -1
  local maxTier = -1
  foreach (tpl, _ in items ?? {}) {
    let template = templates?[tpl]
    if (!template)
      continue

    let { upgradeIdx = 0 } = template
    if (minTier < 0 || upgradeIdx < minTier)
      minTier = upgradeIdx
    if (maxTier < upgradeIdx)
      maxTier = upgradeIdx
  }
  return { minTier, maxTier }
}

function getArmyByTemplateId(templateId) {
  if ((templateId ?? "") == "")
    return null

  foreach (armyId, templates in allItemTemplates.get())
    if (templateId in templates)
      return armyId

  return null
}


return {
  itemsTemplatesCfg
  equipSchemesByArmy
  allItemTemplates
  findItemTemplate
  findTemplateInArmies
  itemTypesInSlots
  getTierInterval
  getArmyByTemplateId
}
