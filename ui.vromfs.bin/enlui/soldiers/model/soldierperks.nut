import "%ui/meta/perks/perksList.nut" as perksList
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import chosenSquadsByArmy, soldiersBySquad
from "%ui/meta/servProfile.nut" import soldierPerks as serverPerks
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/meta/perks/perkTreePkg.nut" import getPerkPointsInfo
from "%ui/meta/perks/perksSchemesConfig.nut" import perkSchemes, perkTrees, perkTreesSpecial,
  perkSlotsByTiers
from "%ui/options/onlineSettings.nut" import settings
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/soldierPerks"
let seenData = Computed(@() settings.get()?[SEEN_ID])

function clearPerkNotifiersArmy(armyId) {
  settings.mutate(function(value) {
    let seen = clone value?[SEEN_ID] ?? {}
    foreach (squad in chosenSquadsByArmy.get()?[armyId] ?? [])
      foreach (soldier in soldiersBySquad.get()?[squad.guid] ?? []) {
        seen[soldier.guid] <- true
      }
    value[SEEN_ID] <- seen
  })
}

function markPerksUnseen(guidsList) {
  if (SEEN_ID not in settings.get())
    return

  settings.mutate(function(value) {
    let seen = clone value[SEEN_ID] ?? {}
    foreach (soldierGuid in guidsList)
      seen.$rawdelete(soldierGuid)
    value[SEEN_ID] <- seen
  })
}

function markPerksSeen(guidsList) {
  settings.mutate(function(value) {
    let seen = clone value?[SEEN_ID] ?? {}
    foreach (soldierGuid in guidsList)
      seen[soldierGuid] <- true
    value[SEEN_ID] <- seen
  })
}

console_register_command(function() {
    settings.mutate(@(v) v.$rawdelete(SEEN_ID))
  }, "meta.resetSeenPerks")

let perksData = Computed(function() {
  let perkSlotsByTiersVal = perkSlotsByTiers.get()
  let perkSchemesVal = perkSchemes.get()
  let maxLevelByTier = perkSlotsByTiersVal.map(@(levels) levels.reduce(@(res, l) res + l, 0))
  return serverPerks.get().map(function(p) {
    let { sTier = 1, perkSchemeId = "" } = p
    let scheme = perkSchemesVal?[perkSchemeId] ?? []
    return p.__merge({
      maxLevel = maxLevelByTier?[sTier] ?? 1
      tiers = scheme.map(@(tierCfg, idx) tierCfg.__merge({
        slots = array(perkSlotsByTiersVal?[sTier][idx] ?? 0, "")
      }))
    })
  })
})

let notChosenPerkSoldiers = Watched({}) 
let notChosenPerkSquads = Watched({}) 

function isKeysEqual(tbl1, tbl2) {
  if (tbl1.len() != tbl2.len())
    return false

  foreach (key, _ in tbl1)
    if (key not in tbl2)
      return false

  return true
}

function isArmiesKeysEqual(tbl1, tbl2) {
  if (tbl1.len() != tbl2.len())
    return false

  foreach (key, list1 in tbl1) {
    let list2 = tbl2?[key]
    if (list2 == null)
      return false

    if (!isKeysEqual(list1, list2))
      return false
  }

  return true
}

function updateNotChosenPerks() {
  let pList = perksList.get()
  let pData = perksData.get()
  let classesCfg = sClassesCfg.get()
  let perkTreesVal = perkTrees.get()
  let perkTreesSpecialVal = perkTreesSpecial.get()

  let soldiersList = {}
  let squadsList = {}

  foreach (armyId in curArmiesList.get()) {
    squadsList[armyId] <- {}
    let chosenSquads = chosenSquadsByArmy.get()?[armyId]
    if (chosenSquads == null)
      continue

    foreach (squad in chosenSquads) {
      let { squadId } = squad
      let squadSoldiers = soldiersBySquad.get()?[squad.guid] ?? []
      local hasUnseenSoldiers = false
      foreach (soldier in squadSoldiers) {
        let { guid, sClass } = soldier
        if (guid in seenData.get())
          continue

        let perks = pData?[guid]
        let ppInfo = getPerkPointsInfo(pList, perks)
        let availPoints = {}
        local hasAvailPoints = false
        foreach (pointId, count in ppInfo.total) {
          let pointsLeft = count - (ppInfo.used?[pointId] ?? 0)
          availPoints[pointId] <- pointsLeft
          hasAvailPoints = hasAvailPoints || pointsLeft > 0
        }

        if (!hasAvailPoints)
          continue

        let tree = perkTreesVal?[perkTreesSpecialVal?[sClass] ?? classesCfg?[sClass].kind] ?? []
        foreach (perkId in tree) {
          let perk = pList[perkId]
          if ((perk.available ?? 1) > (perks?.perks[perkId] ?? 0)) {
            local hasAvailPerk = true
            foreach (pointId, pointReq in perk.cost) {
              let pointHave = availPoints?[pointId] ?? 0
              if (pointHave < pointReq) {
                hasAvailPerk = false
                break
              }
            }
            if (hasAvailPerk) {
              soldiersList[guid] <- true
              hasUnseenSoldiers = true
              break
            }
          }
        }
      }
      if (hasUnseenSoldiers)
        squadsList[armyId][squadId] <- true
    }
  }

  if (!isKeysEqual(soldiersList, notChosenPerkSoldiers.get()))
    notChosenPerkSoldiers.set(soldiersList)
  if (!isArmiesKeysEqual(squadsList, notChosenPerkSquads.get()))
    notChosenPerkSquads.set(squadsList)
}


subscribeList(updateNotChosenPerks, perksList, perksData, chosenSquadsByArmy, seenData)
updateNotChosenPerks()

return {
  notChosenPerkSquads
  notChosenPerkSoldiers
  clearPerkNotifiersArmy
  markPerksUnseen
  markPerksSeen

  perksData
}
