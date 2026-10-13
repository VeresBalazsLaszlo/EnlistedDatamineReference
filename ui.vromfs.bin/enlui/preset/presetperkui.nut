import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/preset/presetPerkStorage.nut" import perkPresetWatch, SLOT_COUNT_MAX, SLOT_COUNT,
  savePreset, renamePreset, deletePreset
import "%ui/meta/perks/perksList.nut" as perksList
from "%ui/currency/premium.nut" import hasPremium
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/preset/presetWidget.nut" import mkPresetBlock
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/style/designConst.nut" import unitSize
from "%ui/preset/perksSolver.nut" import computePerks
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/soldiers/model/soldierActions.nut" import setPerks
from "%ui/meta/servProfile.nut" import soldierPerks
from "%ui/meta/configs.nut" import serverConfigs
from "%ui/meta/perks/perksSchemesConfig.nut" import perkSchemes
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/ui_library.nut" import *


const BLOCK_WIDTH = (unitSize * 8).tointeger()
const POPUP_ID = "preset_perks"

let presetWidgetOpened = Watched(false)
let previewPerkPreset = Watched(null)
let slotCount = Computed(@() hasPremium.get() ? SLOT_COUNT_MAX : SLOT_COUNT)


function getAutoPerkScheme(soldier, perksCfg, schemes, configs, perksListVal) {
  let { sKind = null, sClass = null } = soldier
  let { isPremium = false, isEvent = false } = getClassCfg(sClass)

  let { perkSchemeId } = perksCfg
  let premiumStartPerks = schemes?[perkSchemeId]
  let { perk_groups = {} } = configs

  let perks = (isPremium || isEvent) && premiumStartPerks
    ? premiumStartPerks.reduce(@(result, perk) result.extend(perk.perks), [])
    : perk_groups?[$"weight_recommended_{sKind}"] ?? []

  let result = {}
  foreach (perkId in perks)
    result[perkId] <- max(1, perksListVal[perkId]?.available ?? 0)

  return result
}

function getPresetWithStarter(preset, perksCfg, schemes) {
  let { perkSchemeId } = perksCfg
  let scheme = schemes?[perkSchemeId].findvalue(@(v) v?.isDefault ?? false)
  let { perks = [] } = scheme

  let result = {}
  perks.each(@(perkId) result[perkId] <- 1)

  let { items = {} } = preset?.data
  return result.__update(items)
}

function getPerksAvailableToBuy(soldier, needReset, newPerks, perksCfg, perksListVal) {
  let availablePoints = clone perksCfg.points
  let { perks = {} } = perksCfg

  local tier1UsedPoints = 0
  if (!needReset) {
    foreach (perkId, amount in perks) {
      let { cost = {}, tier = 0 } = perksListVal[perkId]
      foreach (stat, val in cost) {
        let points = val * amount
        availablePoints[stat] -= points
        if (tier == 1)
          tier1UsedPoints += points
      }
    }

    newPerks = newPerks
      .map(@(amount, perkId) amount - (perks?[perkId] ?? 0))
      .filter(@(v) v > 0)
  }

  let selectedPerks = []
  foreach (perkId, newAmount in newPerks) {
    let perk = perksListVal[perkId]
    let cost = perk?.cost.reduce(@(res, val) val + res, 0)
    selectedPerks.append({
      newAmount
      perk
      cost
      totalCost = newAmount * (cost ?? 0)
    })
  }

  selectedPerks.sort(@(a, b)
    (b.perk?.tier ?? 0) <=> (a.perk?.tier ?? 0)
      || a.totalCost <=> b.totalCost)

  let { level } = soldier
  let result = computePerks(level, selectedPerks, availablePoints, tier1UsedPoints)

  if (!needReset)
    foreach (perkId, amount in perks)
      result[perkId] <- amount + (result?[perkId] ?? 0)

  return result
}

let applyAutoPerks = @(_preset, soldier, perksCfg, schemes, configs, perksListVal)
  getPerksAvailableToBuy(soldier,
    false,
    getAutoPerkScheme(soldier, perksCfg, schemes, configs, perksListVal),
    perksCfg,
    perksListVal)

let autoPreset = { locId = loc("perks/autofillBtn"), fnApply = applyAutoPerks }

let presetSlotName = @(preset, index) preset?.campaign
  ? loc("squads/presets/united", { campaign = loc($"{preset.campaign}/full"),
      name = preset.name })
  : (preset?.name ?? loc("btn/preset/name", { count = getRomanNumeral(index + 1) }))

let showPopup = @(text) addPopup({ id = POPUP_ID, text })

function applyPerks(preset, soldier, perksCfg, schemes, _configs, perksListVal) {
  let presetPerks = getPresetWithStarter(preset, perksCfg, schemes)
  return getPerksAvailableToBuy(soldier, true, presetPerks, perksCfg, perksListVal)
}

let inlineButtons = const [
  { icon = "check", tooltip = loc("perks/preset/apply") }
]

let genButtons = @(presetCfg)
  presetCfg?.fnApply == null || presetCfg?.isLockedPrem ? [] : inlineButtons

function mkSlotDesc(data, i) {
  let exists = data != null
  let isSlotActive = i < SLOT_COUNT_MAX
  return {
    slot = i
    data
    locId = presetSlotName(data, i)
    fnApply = exists ? applyPerks : null
    fnRename = exists && isSlotActive ? renamePreset : null
    fnDelete = exists && !isSlotActive ? deletePreset : null
    fnSave = isSlotActive ? savePreset : null
    genButtons
  }
}

function mkSlotPrem(data, i) {
  return {
    slot = i
    data
    locId = data?.name ?? loc("btn/preset/locked")
    fnApply = data == null ? null : applyPerks
    onClick = @() premiumWnd()
    isLockedPrem = true
  }
}

let presetPerksList = Computed(function() {
  let allPresets = [autoPreset]
  let { sKind = null } = curSoldierInfo.get()
  let list = perkPresetWatch.get()?[sKind]
  let presetsCount = list?.len() ?? SLOT_COUNT_MAX
  let slotCountVal = slotCount.get()
  for (local idx = 0; idx < presetsCount; idx++) {
    let slotData = list?[idx]
    allPresets.append(idx < slotCountVal || idx >= SLOT_COUNT_MAX
      ? mkSlotDesc(slotData, idx)
      : mkSlotPrem(slotData, idx))
  }
  return allPresets
})

function isUnlockMaximumList(buyPerks, perksListVal) {

  return null != buyPerks.findvalue(function(amount, perkId) {
    let { available = 0 } = perksListVal[perkId]
    if (available == 0)
      return false

    return amount == available
  })
}

function applyAction(presetCfg, soldier) {
  let { isLockedPrem = false, fnApply = null, onClick = null } = presetCfg

  if (isLockedPrem)
    return premiumWnd()

  if (onClick != null)
    return onClick()

  if (fnApply == null)
    return

  let { guid = null } = soldier
  let perksCfg = soldierPerks.get()?[guid] ?? {}
  let schemes = perkSchemes.get()
  let configs = serverConfigs.get()
  let perksListVal = perksList.get()

  let buyPerks = fnApply(presetCfg, soldier, perksCfg, schemes, configs, perksListVal)
    .filter(@(v) v != 0)

  if (buyPerks.len() > 0) {
    let isMax = isUnlockMaximumList(buyPerks, perksListVal)
    setPerks(guid, buyPerks, @(_) sound_play(isMax ? "ui/perk_max" : "ui/perk_add"))
  }
}

function saveAction(presetCfg, soldier) {
  let { fnSave = null } = presetCfg
  if (fnSave == null)
    return

  let { guid = null } = soldier
  let { perks = {} } = soldierPerks.get()?[guid]

  let perksListVal = perksList.get()
  let starter = perks.findindex(@(_, perkId)
    0 == perksListVal[perkId].cost.reduce(@(res, val) res += val, 0))

  fnSave(presetCfg, soldier, perks.filter(@(_, perkId) perkId != starter))
  showPopup(loc("preset/equip/saved"))
}

let mkActions = @(soldier) {
  save = @(cfg) saveAction(cfg, soldier)
  apply = @(cfg) applyAction(cfg, soldier)
  remove = @(cfg) cfg.fnDelete(cfg, soldier)
  rename = @(cfg, name) cfg.fnRename(cfg, soldier, name)
  hover = @(cfg) previewPerkPreset.set(cfg)
}

let mkPerkPresetBlock = @(soldierWatch) function() {
  let soldier = soldierWatch.get()
  return {
    watch = [presetWidgetOpened, soldierWatch]
    size = FLEX_V
    children = !presetWidgetOpened.get() || soldier == null ? null
      : mkPresetBlock({
          actions = mkActions(soldier)
          dataWatch = presetPerksList
          width = BLOCK_WIDTH
          hasClose = false
        })
  }
}

return {
  presetWidgetOpened
  mkPerkPresetBlock
  closePerkPresets = @() presetWidgetOpened.set(false)
  togglePerkPresetBlock = @() presetWidgetOpened.set(!presetWidgetOpened.get())
  previewPerkPreset
  getPerksAvailableToBuy
}
