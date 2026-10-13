from "%ui/meta/configs.nut" import mkComputedConfigView
from "%enlSqGlob/vehDecorUtils.nut" import readSkinFromTemplate
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN


let vehCustomizationCfg = mkComputedConfigView(function(config) {
  return (config?.vehCustomizationCfg ?? {})
    .map(@(cTypeData) cTypeData.map(@(cfg, id) { id }.__update(cfg)))
})

let unsuitableSkinsById = mkComputedConfigView(@(config)
  (config?.unsuitableSkinsById ?? {}).map(@(skinVehicles)
    skinVehicles.reduce(@(res, val) res.rawset(val, true), {})
  )
)

let vehCamouflageCfg = mkComputedConfigView(function(config) {
  return (config?.camouflageCfg ?? {})
    .map(@(byTemplate) byTemplate.map(@(cfg, id) { id }.__update(cfg)))
})

function getCurSkinFromTemplate(ownedCamo, vehicle, squadCampaign) {
  let { guid = null, gametemplate = null, skin = null } = vehicle
  if (guid == null )
    return null

  if (skin != null) 
    return readSkinFromTemplate(gametemplate, skin)

  let { isCommon = true, active = {} } = ownedCamo?[guid]
  let campaign = isCommon || squadCampaign == null ? COMMON_CAMPAIGN : squadCampaign

  return (campaign in active) ? readSkinFromTemplate(gametemplate, active[campaign]) : null
}

function getCamoList(viewVehicle, vehDecorCfg, skinList, ownCamoList,
    rewardsPresentation, curSeasonIdx) {
  let { basetpl } = viewVehicle
  let result = []

  foreach (camoId, cfg in vehDecorCfg?[trimUpgradeSuffix(basetpl)] ?? {}) {
    let skinData = skinList.findvalue(@(skin) skin.id == camoId)
    if (skinData == null)
      continue

    let hasOwned = ownCamoList.contains(camoId)
    let bpSeason = rewardsPresentation?[camoId].bpSeason
    if (hasOwned || (cfg?.buyData.price ?? 0) > 0
      || (bpSeason != null && bpSeason <= curSeasonIdx))
        result.append(skinData.__merge(cfg, { hasOwned }))
  }

  return result
}

return {
  vehCustomizationCfg
  vehCamouflageCfg
  unsuitableSkinsById
  getCamoList
  getCurSkinFromTemplate
}
