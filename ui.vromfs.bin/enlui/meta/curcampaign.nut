from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile, gameProfileLookCfg
from "%ui/ui_library.nut" import *

const COMMON_CAMPAIGN = "common"

const USSR    = "ussr"
const GERMANY = "ger"
const USA     = "usa"
const JAPAN   = "jap"

let sidesArmies = {
  moscow_allies     = USSR
  moscow_axis       = GERMANY
  berlin_allies     = USSR
  berlin_axis       = GERMANY
  normandy_allies   = USA
  normandy_axis     = GERMANY
  tunisia_allies    = USA
  tunisia_axis      = GERMANY
  stalingrad_allies = USSR
  stalingrad_axis   = GERMANY
  pacific_allies    = USA
  pacific_axis      = JAPAN
}

let allCampaigns = WatchedRo([
  "common",
  "normandy",
  "moscow",
  "berlin",
  "tunisia",
  "stalingrad",
  "pacific",
])

let allArmies = WatchedRo({
  common = ["ussr", "usa", "ger", "jap"]
  normandy = ["normandy_allies", "normandy_axis"]
  moscow = ["moscow_allies", "moscow_axis"]
  berlin = ["berlin_allies", "berlin_axis"]
  tunisia = ["tunisia_allies", "tunisia_axis"]
  stalingrad = ["stalingrad_allies", "stalingrad_axis"]
  pacific = ["pacific_allies", "pacific_axis"]
})

let allArmiesList = Computed(@() allArmies.get()
  .reduce(function(res, armies) {
    armies.each(@(armyId) res[armyId] <- true)
    return res
  }, {})
  .keys())

let curCampaignConfig = Computed(@() gameProfile.get()?.campaigns[COMMON_CAMPAIGN])

function armiesToCampaigns(config, field) {
  let result = {}
  foreach (campaignId, lookCfgList in config)
    foreach (look in lookCfgList) {
      let name = look?[field] ?? campaignId

      foreach (armyId in look.armies) {
        let armyData = result?[armyId] ?? {}
        armyData[name] <- (armyData?[name] ?? []).append(campaignId)
        result[armyId] <- armyData
      }
    }

  foreach (armyId, armyData in result)
    result[armyId] <- armyData.map(@(v) "_".join(v.sort()))

  return result
}

let camoCampaignsByArmies = Computed(@()
  armiesToCampaigns(gameProfileLookCfg.get(), "camouflage"))

let outfitCampaignsByArmies = Computed(@()
  armiesToCampaigns(gameProfileLookCfg.get(), "outfit"))


let looksByArmy = Computed(function() {
  let baseByArmy = {}
  let uniqueByArmy = {}

  foreach (campaignId, looks in gameProfileLookCfg.get())
    foreach (lookData in looks) {

      let { outfit = null, camouflage = null } = lookData
      let isBasic = outfit == null && camouflage == null

      let look = [
        outfit ?? campaignId,
        camouflage ?? campaignId
      ]

      foreach (armyId in lookData.armies) {
        local unique = uniqueByArmy?[armyId]
        if (unique == null) {
          unique = []
          uniqueByArmy[armyId] <- unique
        }

        let existing = unique.findvalue(@(v) isEqual(v.look, look))
        if (existing == null)
          unique.append({ look, campaigns = [campaignId] })
        else
          existing.campaigns.append(campaignId)

        if (isBasic) {
          let basic = baseByArmy?[armyId] ?? []
          baseByArmy[armyId] <- basic.append(campaignId)
        }
      }
    }

  foreach (armyId, sameSetupList in uniqueByArmy) {
    let basic = baseByArmy?[armyId] ?? []
    foreach (setup in sameSetupList) {
      if (setup.campaigns.len() == 1) {
        let campaign = setup.campaigns.top()
        if (!basic.contains(campaign))
          basic.append(campaign)
      }
    }
    baseByArmy[armyId] <- basic
  }

  return uniqueByArmy.map(@(unique, armyId) unique.reduce(function(res, v) {
    let name = "_".join(v.campaigns.sort())
    foreach (campaign in v.campaigns) {
      if (baseByArmy?[armyId].contains(campaign))
        res[campaign] <- name
    }
    return res
  }, {}))
})

return {
  COMMON_CAMPAIGN
  sidesArmies
  curCampaignConfig
  allCampaigns
  allArmies
  allArmiesList

  camoCampaignsByArmies
  outfitCampaignsByArmies
  looksByArmy
}
