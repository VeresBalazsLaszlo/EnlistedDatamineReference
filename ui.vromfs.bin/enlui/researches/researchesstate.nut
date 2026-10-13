import "%ui/components/researchSquadsPresentation.nut" as squadsResearchPresentation
import "%ui/researches/researchesPresentation.nut" as prepareResearch
import "%ui/researches/recalcMultiResearchPos.nut" as recalcMultiResearchPos
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
from "%ui/meta/clientApi.nut" import do_research, change_research, buy_change_research,
  buy_squad_exp, buy_squad_max_exp, add_army_squad_exp_by_id, get_squad_point,
  research_army_unlock, set_research_points
from "%ui/meta/servProfile.nut" import researchProgress, squadProgress
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%sqstd/string.nut" import toIntegerSafe
from "%sqstd/frp.nut" import subscribeList
from "%ui/meta/profile.nut" import curArmiesList, curCampItems
from "%ui/soldiers/model/state.nut" import armySquadsById, curSquadId, curArmy, armyItemCountByTpl
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/ui_library.nut" import *

const CHANGE_RESEARCH_TPL = "research_change_order"

let isBuyLevelInProgress = Watched(false)
let isResearchInProgress = Watched(false)
let viewSquadId = Watched(curSquadId.get())
curSquadId.subscribe(@(squadId) viewSquadId.set(squadId))


let changeResearchBalance = Computed(@() armyItemCountByTpl.get()?[CHANGE_RESEARCH_TPL] ?? 0)
let changeResearchGoldCost = mkComputedConfigGet(["gameProfile","changeResearchGoldCost"], 0)
let researchesToSquads = mkComputedConfigGet("researchesToSquads", {} )
let researchesCfg = mkComputedConfigGet("researches", {})

let configResearches = Computed(function() {
  let src = researchesCfg.get()
  let res = {}
  foreach (armyId, armyConfig in src) {
    let presentList = squadsResearchPresentation?[armyId]
    let armyPages = {}
    res[armyId] <- {
      squads = armyConfig?.squads
      pages = armyPages
    }
    foreach (squadId, pageList in armyConfig?.pages ?? {})
      armyPages[squadId] <- pageList.map(function(page, idx) {
        page = (page ?? {}).__merge(presentList?[idx] ?? {})
        page.tables <- (page?.tables ?? {})
        return page
      })
  }
  return res
})

let armiesResearches = Computed(function() {
  let res = {}
  foreach (armyId, armyConfig in configResearches.get()) {
    let researchesMap = {}
    foreach (squadPages in armyConfig.pages)
      foreach (page in squadPages)
        foreach (research in page.tables)
          researchesMap[research.research_id] <- research

    res[armyId] <- {
      squads = armyConfig.squads
      pages = armyConfig.pages 
      researches = researchesMap
    }
  }
  return res
})

function getAvailableResearches(researches) {
  let existingResearches = {}
  return researches.reduce(function(count, research) {
    let { multiresearchGroup = 0 } = research
    if (multiresearchGroup == 0)
      return count + 1

    if (multiresearchGroup in existingResearches)
      return count

    existingResearches[multiresearchGroup] <- true
    return count + 1
  }, 0)
}

let squadsResearchAvailable = Computed(function() {
  let res = {}
  let curResearches = armiesResearches.get()?[curArmy.get()] ?? {}
  let { pages = {} } = curResearches
  if (pages.len() == 0)
    return res
  foreach (squadId, squadPages in pages)
    res[squadId] <- squadPages.map(@(page) getAvailableResearches(page?.tables ?? {}))
  return res
})

let selectedResearch = Watched(null)
let selectedTable = mkWatched(persist,"selectedTable", 0)

const LOCKED = 1
const DEPENDENT = 2
const NOT_ENOUGH_EXP = 3
const GROUP_RESEARCHED = 4
const CAN_RESEARCH = 5
const RESEARCHED = 6

let squadResearchPages = Computed(function() {
  let armyId = curArmy.get()
  let squadId = viewSquadId.get()
  let squadTables = armiesResearches.get()?[armyId].pages?[squadId]
  if (!squadTables)
    return null

  let pageContext = {
    armyId
    squadId
    squadsCfg = squadsCfgById.get()
    alltemplates = allItemTemplates.get()
  }

  return squadTables.map(function(config) {
    let researchList = config.tables.values()
      .sort(@(a, b) a.line <=> b.line || a.tier <=> b.tier) 
      .map(@(research) prepareResearch(research, pageContext))
      .reduce(function(res, r) {
        res[r.research_id] <- r
        return res
      }, {})
    recalcMultiResearchPos(researchList)
    return researchList
  })
})

let tableStructure = Computed(function() {
  let armyId = curArmy.get()
  let squadId = viewSquadId.get()
  let curResearches = armiesResearches.get()?[armyId]
  let ret = {
    armyId
    squadId = squadId
    researches = {}
    pages = []
  }

  if (!curResearches)
    return ret

  let pages = curResearches.pages?[squadId]
  if (pages == null)
    return ret

  ret.pages = pages
  ret.researches = squadResearchPages.get()?[selectedTable.get()] ?? {}
  return ret
})

let isResearched = @(research, researched) research.research_id in researched

let getSquadListFromConfig = @(researchId, researchesToSquadsVal)
  researchesToSquadsVal?[researchId ?? ""] ?? []

let getSquadIdList = @(researchId)
  getSquadListFromConfig(researchId, researchesToSquads.get())

function calcResearchedGroups(researches, researchesToSquadsVal, researched) {
  let res = {}
  foreach (researchId, val in researched) {
    if (!val)
      continue
    let { multiresearchGroup = 0 } = researches?[researchId]
    if (multiresearchGroup <= 0)
      continue

    let researchSquads = researchesToSquadsVal?[researchId] ?? []
    foreach (squadId in researchSquads) {
      if (squadId not in res)
        res[squadId] <- {}
      res[squadId][multiresearchGroup] <- true
    }
  }
  return res
}

function researchStatusArmy(armyResearches, researched, progress, squads,
    researchesToSquadsVal) {
  let groups = calcResearchedGroups(armyResearches, researchesToSquadsVal, researched)
  return armyResearches.map(function(research) {
    if (isResearched(research, researched))
      return RESEARCHED

    let researchSquads = researchesToSquadsVal?[research?.research_id ?? ""] ?? []
    let [ squad_id  = "" ] = researchSquads
    if (squad_id == "")
      return LOCKED

    let { multiresearchGroup = 0 } = research
    if (multiresearchGroup > 0 && (groups?[squad_id][multiresearchGroup] ?? false))
      return GROUP_RESEARCHED

    let { requirements = [] } = research
    if (requirements.findindex(@(id) !researched?[id]) != null
        || researchSquads.findvalue(@(squadId) squadId in squads) == null) 
      return DEPENDENT

    let { price = 0 } = research
    if (researchSquads.findvalue(@(squadId) price <= (progress?[squadId].points ?? 0)) != null)
      return CAN_RESEARCH

    return NOT_ENOUGH_EXP
  })
}

let allResearchStatus = Computed(function() {
  let res = {}
  let allArmiesResearches = armiesResearches.get()
  let progress = squadProgress.get()
  let researchesToSquadsVal = researchesToSquads.get()
  let researched = researchProgress.get()
  foreach (armyId in curArmiesList.get()) {
    let armyResearches = allArmiesResearches?[armyId].researches ?? {}
    let squads = armySquadsById.get()?[armyId] ?? {}
    res[armyId] <- researchStatusArmy(armyResearches, researched, progress,
      squads, researchesToSquadsVal)
  }
  return res
})

let researchStatuses = Computed(function() {
  
  let armyId = curArmy.get()
  let statusTbl = allResearchStatus.get()?[armyId] ?? {}
  let { researches = {} } = armiesResearches.get()?[armyId]
  let { points = 0 } = squadProgress.get()?[viewSquadId.get()]
  return statusTbl.map(function(status, researchId) {
    if (status != CAN_RESEARCH)
      return status
    let { price = 0 } = researches?[researchId]
    return price <= points ? CAN_RESEARCH : NOT_ENOUGH_EXP
  })
})

let allSquadsPoints = Computed(@() squadProgress.get().map(@(p) p.points))
let allSquadsLevels = Computed(@() squadProgress.get().map(@(p) p.level))

let curSquadProgress = Computed(function() {
  let squadCfg = armiesResearches.get()?[curArmy.get()].squads[viewSquadId.get()]
  let { levels  = [] } = squadCfg
  let res = {
    level = 0
    exp = 0
    points = 0
    nextLevelExp = 0
    levelCost = 0
    maxLevel = levels.len()
    maxLevelCost = 0
  }.__update(squadProgress.get()?[viewSquadId.get()] ?? {})

  let { level } = res

  let levelExp = levels?[level].exp ?? 0
  let levelCost = levels?[level].levelCost ?? 0
  let needExp = levelExp - res.exp

  res.nextLevelExp = levelExp
  if (levelExp > 0 && needExp > 0 && levelCost > 0)
    res.levelCost = max(levelCost * needExp / levelExp, 1)

  res.maxLevelCost = res.levelCost
  for (local i = res.level + 1; i < levels.len(); i++)
    res.maxLevelCost += levels[i]?.levelCost ?? 0

  return res
})

function researchAction(researchId) {
  if (isResearchInProgress.get() || researchStatuses.get()?[researchId] != CAN_RESEARCH)
    return
  isResearchInProgress.set(true)
  do_research(tableStructure.get().armyId, researchId, @(_) isResearchInProgress.set(false))
}

function changeResearch(researchFrom, researchTo) {
  if (isResearchInProgress.get()
      || researchStatuses.get()?[researchTo] != GROUP_RESEARCHED
      || researchStatuses.get()?[researchFrom] != RESEARCHED)
    return
  let payData = getPayItemsData({ [CHANGE_RESEARCH_TPL] = 1 }, curCampItems.get())
  if (payData == null)
    return
  isResearchInProgress.set(true)
  change_research(tableStructure.get().armyId, researchFrom, researchTo, payData,
    @(_) isResearchInProgress.set(false))
}

function buyChangeResearch(researchFrom, researchTo) {
  if (isResearchInProgress.get()
      || researchStatuses.get()?[researchTo] != GROUP_RESEARCHED
      || researchStatuses.get()?[researchFrom] != RESEARCHED)
    isResearchInProgress.set(true)
  buy_change_research(tableStructure.get().armyId, researchFrom, researchTo, changeResearchGoldCost.get(),
    @(_) isResearchInProgress.set(false))
}

let closestTargets = Computed(function() {
  let list = squadResearchPages.get()
  if (!list)
    return null

  return list.map(function(researches) {
    local pageTop = null
    foreach (r in researches) {
      let status = researchStatuses.get()?[r.research_id]
      if (status != CAN_RESEARCH && status != NOT_ENOUGH_EXP)
        continue

      let { line, tier } = r
      if (pageTop == null || line < pageTop.line || (line == pageTop.line && tier < pageTop.tier))
        pageTop = r
    }
    return pageTop
  })
})

let mkBuyLevelCb = @(cb) function(res) {
  isBuyLevelInProgress.set(false)
  cb?(res?.error == null)
}

function buySquadLevel(cb = null) {
  if (isBuyLevelInProgress.get())
    return

  let action = mkBuyLevelCb(cb)
  let { nextLevelExp = 0, exp = 0, levelCost = 0 } = curSquadProgress.get()
  let canGetLevel = exp > 0 && exp >= nextLevelExp
  if (canGetLevel) {
    isBuyLevelInProgress.set(true)
    get_squad_point(curArmy.get(), viewSquadId.get(), action)
    return
  }

  let needExp = nextLevelExp - exp
  if (needExp <= 0 || levelCost <= 0)
    return

  isBuyLevelInProgress.set(true)
  buy_squad_exp(curArmy.get(), viewSquadId.get(), needExp, levelCost, action)
}

function buySquadMaxLevel(cb = null) {
  if (isBuyLevelInProgress.get())
    return

  let { level = 0, maxLevel = 0, maxLevelCost = 0 } = curSquadProgress.get()
  if (level == maxLevel)
    return

  isBuyLevelInProgress.set(true)
  buy_squad_max_exp(viewSquadId.get(), maxLevelCost, mkBuyLevelCb(cb))
}

function setCompletedResearches() {
  selectedResearch.set({
    isLockedByCampaignLvl = false
    research_id = ""
    name = "researches/allResearchesResearchedName"
    description = "researches/allResearchesResearchedDescription"
  })
}

function findAndSelectClosestTarget(...) {
  local minLine = 1000, minTier = 1000, found = null
  foreach (research in tableStructure.get().researches) {
    let status = researchStatuses.get()?[research.research_id]
    if (status != CAN_RESEARCH && status != NOT_ENOUGH_EXP)
      continue

    let { line, tier } = research
    if (line < minLine || (line == minLine && tier < minTier)) {
      minLine = line
      minTier = tier
      found = research
    }
  }

  if (found == null)
    setCompletedResearches()
  else
    selectedResearch.set(found)
}

function computeRequirements(researches) {
  let res = {}
  foreach (research in researches) {
    let { research_id, requirements = [] } = research
    if (requirements.len() > 0)
      foreach (requirementId in requirements)
        res[research_id] <- (res?[research_id] ?? []).append(requirementId)
  }
  return res
}

function computeWeights(requirements) {
  let weights = {}
  let nodeQueue = requirements.keys()

  while (nodeQueue.len() > 0) {
    let research_id = nodeQueue.pop()
    weights[research_id] <- (weights?[research_id] ?? 0) + 1
    if (research_id in requirements)
      nodeQueue.extend(requirements[research_id])
  }
  return weights
}

function isNamesSimilar(nameA, nameB) {
  let nameArrA = nameA.split("_")
  let nameArrB = nameB.split("_")
  if (nameArrA.len() != nameArrB.len() || nameArrA.len() < 2)
    return false
  if (toIntegerSafe(nameArrA.top(), -1, false) < 0 || toIntegerSafe(nameArrB.top(), -1, false) < 0)
    return false
  nameArrA.resize(nameArrA.len() - 1)
  nameArrB.resize(nameArrB.len() - 1)
  return "_".join(nameArrA) == "_".join(nameArrB)
}

let getDependentResearches = @(requirementsTbl, resId) requirementsTbl
  .filter(@(v) v.contains(resId))
  .keys()

let mkViewStructure = @() Computed(function() {
    let { researches, armyId } = tableStructure.get()
    let requirementsTbl = computeRequirements(researches)
    let weights = computeWeights(requirementsTbl)
    let curTemplates = allItemTemplates.get()?[armyId] ?? {}

    local columns = []
    local hasTemplatesLine = false
    let templateCount = {}
    local order = 0
    let dependentResearches = {}
    
    foreach (baseResId, baseRes in researches) {
      if ((baseRes?.requirements.len() ?? 0) > 0)
        continue

      order += 100
      local mainRes = baseResId
      
      while (mainRes != null) {
        let { gametemplate = null, effect = null } = researches[mainRes]
        let [ basetpl = null ] = effect?.weapon_upgrades
        let { growthTier = 0, upgradeIdx = 0 } = curTemplates?[basetpl]

        columns.append({
          main = mainRes
          order = order++
          br = growthTier
          level = upgradeIdx
          children = []
          template = gametemplate
          tplCount = 0
          toChildren = 0
        })

        if (gametemplate != null) {
          hasTemplatesLine = true
          templateCount[gametemplate] <- (templateCount?[gametemplate] ?? 0) + 1
        }

        let childNodes = getDependentResearches(requirementsTbl, mainRes)
        dependentResearches[mainRes] <- childNodes
        let followResearches = childNodes.filter(@(resId)
          (researches?[resId].multiresearchGroup ?? 0) == 0)

        if (followResearches.len() == 0)
          break

        local nextResearch = followResearches[0]
        local maxWeight = weights[nextResearch]
        for (local i = 1; i < followResearches.len(); i++) {
          let curWeight = weights[followResearches[i]]
          if (curWeight > maxWeight) {
            maxWeight = curWeight
            nextResearch = followResearches[i]
          }
        }

        let numChildren = childNodes.len()
        let hasMult = numChildren > followResearches.len()
        if (maxWeight > 2
            || (maxWeight == 2
              && (numChildren == 1 || isNamesSimilar(mainRes, nextResearch) || hasMult))
            || (hasMult && numChildren > 3))
          mainRes = nextResearch
        else
          
          break
      }
    }

    columns.sort(@(a,b) a.br <=> b.br
      || a.template <=> b.template
      || a.level <=> b.level
      || a.order <=> b.order)

    foreach (idx, column in columns) {
      let { main } = column
      let nextMain = columns?[idx + 1].main
      foreach (resId in dependentResearches?[main] ?? []) {
        if (nextMain == resId)
          continue

        let { multiresearchGroup = 0 } = researches[resId]
        if (multiresearchGroup == 0)
          column.children.append({
            multiresearchGroup
            children = getDependentResearches(requirementsTbl, resId).insert(0, resId)
          })
        else {
          let cIdx = column.children
            .findindex(@(r) (r?.multiresearchGroup ?? 0) == multiresearchGroup)
          if (cIdx == null)
            column.children.append({ multiresearchGroup, children = [resId] })
          else
            column.children[cIdx].children.append(resId)
        }
      }
    }
    let maxChildHeight = [0, 0]
    let childCount = []
    foreach (column in columns) {
      let { template } = column
      if (template != "" && template in templateCount) {
        column.tplCount = templateCount[template]
        templateCount.$rawdelete(template)
      }
      if ("children" not in column) {
        childCount.append(0, 0)
        continue
      }
      let prevCountTop = childCount?[childCount.len() - 2] ?? 0
      let prevCountBtm = childCount?[childCount.len() - 1] ?? 0
      let childTop = column?.children[0]
      let childBtm = column?.children[1]
      let countTop = (childTop?.multiresearchGroup ?? 0) == 0
        ? min((childTop?.children.len() ?? 0), 1)
        : childTop.children.len()
      let countBtm = (childBtm?.multiresearchGroup ?? 0) == 0
        ? min((childBtm?.children.len() ?? 0), 1)
        : childBtm.children.len()
      let heightTop = max(maxChildHeight[0],
        (childTop?.multiresearchGroup ?? 0) == 0 ? (childTop?.children.len() ?? 0) : 1)
      let heightBtm = max(maxChildHeight[1],
        (childBtm?.multiresearchGroup ?? 0) == 0 ? (childBtm?.children.len() ?? 0) : 1)
      if (prevCountTop + countTop < 5 && prevCountBtm + countBtm < 5) {
        childCount.append(countTop, countBtm)
        maxChildHeight[0] = heightTop
        maxChildHeight[1] = heightBtm
      }
      else {
        column.children.clear()
        column.children.append(childBtm, childTop)
        childCount.append(countBtm, countTop)
        maxChildHeight[0] = heightBtm
        maxChildHeight[1] = heightTop
      }
    }
    local toChildren = 0
    for (local i = columns.len() - 1; i >= 0 ; i--) {
      let column = columns[i]
      if (column.children.findvalue(@(ch) ch != null) != null)
        toChildren = 0
      else
        toChildren++
      column.toChildren = toChildren
    }
    return { columns, maxChildHeight, hasTemplatesLine }
  })


subscribeList(findAndSelectClosestTarget, researchStatuses, tableStructure)
findAndSelectClosestTarget()

console_register_command(function(exp) {
  if (viewSquadId.get() != null) {
    add_army_squad_exp_by_id(exp, viewSquadId.get())
    log_for_user($"Add exp for {viewSquadId.get()}")
  } else
    log_for_user("Squad is not selected")
}, "meta.addCurSquadExp")

console_register_command(function(points) {
  if (viewSquadId.get() != null) {
    set_research_points(points, viewSquadId.get())
    log_for_user($"Set {points} points for {viewSquadId.get()}")
  } else
    log_for_user("Squad is not selected")
}, "meta.setSquadResearchPoints")

console_register_command(@() research_army_unlock(curArmy.get()), "meta.researchArmyUnlock")

return {
  closestTargets
  configResearches
  getSquadIdList
  armiesResearches
  squadsResearchAvailable
  selectedTable
  tableStructure
  selectedResearch
  viewArmy = curArmy
  viewSquadId

  allResearchStatus
  researchStatuses
  allSquadsLevels
  allSquadsPoints
  squadProgress
  curSquadProgress
  changeResearchBalance
  changeResearchGoldCost
  researchesToSquads

  researchAction
  changeResearch
  buyChangeResearch
  isResearchInProgress
  isBuyLevelInProgress
  buySquadLevel
  buySquadMaxLevel

  mkViewStructure

  getAvailableResearches

  LOCKED
  DEPENDENT
  NOT_ENOUGH_EXP
  GROUP_RESEARCHED
  CAN_RESEARCH
  RESEARCHED

  CHANGE_RESEARCH_TPL
  BALANCE_ATTRACT_TRIGGER = "army_balance_attract"
}
