from "console" import register_command
from "%ui/squadPresets/squadPresetsState.nut" import setSquadsPreset, squadsPresetWatch, MAX_PRESETS_COUNT
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/soldiers/model/chooseSquadsState.nut" import unlockedSquads, reserveSquads, chosenSquads, previewSquads, slotsCount, getCantTakeSquadReasonData
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/options/onlineSettings.nut" import settings
from "%ui/quickMatchQueue.nut" import isChangesBlocked, showBlockedChangesMessage
from "%ui/ui_library.nut" import *

let logP = with_prefix("[Soldiers Presets] ")

function savePresets(armyId, idx, preset) {
  let squadsPreset = clone squadsPresetWatch.get()
  local newPresetsList = clone squadsPreset?[armyId] ?? []
  if (newPresetsList.len() <= idx)
    newPresetsList.resize(idx + 1, null)

  if (preset == null)
    if (idx >= MAX_PRESETS_COUNT)
      newPresetsList.remove(idx)
    else
      newPresetsList[idx] = null
  else {
    let currentPreset = newPresetsList?[idx] ?? {}
    newPresetsList[idx] = currentPreset.__merge(preset)
  }

  local lastPresetIndex = null
  for (local i = newPresetsList.len() - 1; i >= 0; i--) {
    if (newPresetsList[i] != null) {
      lastPresetIndex = i
      break
    }
  }

  if (lastPresetIndex != null) { 
    newPresetsList.resize(lastPresetIndex + 1)
    squadsPreset[armyId] <- newPresetsList
  }
  else if (armyId in squadsPreset) 
    squadsPreset.$rawdelete(armyId)

  setSquadsPreset(squadsPreset)
}

function getPreset(armyId, idx) {
  let armyPresets = squadsPresetWatch.get()?[armyId] ?? []
  if (idx >= armyPresets.len()) {
    logP($"try to accept not existing preset index {idx}", armyPresets)
    return null
  }

  return armyPresets[idx]
}

function createSquadsPreset(armyId, idx, squadIds) {
  if (squadIds.len() == 0) {
    logP("Create: empty squad data.")
    return
  }

  savePresets(armyId, idx, {
    name = loc("squads/presets/new", { name = getRomanNumeral(idx) })
    preset = squadIds
  })
}

function changePresetInfo(armyId, idx, updateInfo) {
  let preset = getPreset(armyId, idx)
  if (!preset)
    return

  if (("name" in updateInfo) && ("campaign" in preset))
    preset.$rawdelete("campaign")

  savePresets(armyId, idx, preset.__merge(updateInfo))
}

let updateSquadsPreset = @(armyId, idx, preset) changePresetInfo(armyId, idx, { preset })
let renameSquadsPreset = @(armyId, idx, name) changePresetInfo(armyId, idx, { name })
let deleteSquadsPreset = @(armyId, idx) savePresets(armyId, idx, null)

function applySquadsPreset(armyId, idx) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  let preset = clone getPreset(armyId, idx)?.preset
  if (!preset || !previewSquads.get())
    return

  let squadPlaceErrors = {}
  let newChosenSquads = []

  
  previewSquads.get().each(function(squad) {
    if (!squad?.squadId) 
      return

    let reasonData = getCantTakeSquadReasonData(squad, newChosenSquads, newChosenSquads.len())
    if (reasonData != null) {
      if (reasonData.type not in squadPlaceErrors)
        squadPlaceErrors[reasonData.type] <- reasonData.getErrorText()
      return
    }

    newChosenSquads.append(squad)
  })

  if (squadPlaceErrors.len())
    foreach (errorType, errorText in squadPlaceErrors)
      addPopup({
        id = $"{errorType}_squad_preset_error"
        text = errorText
        needPopup = true
        styleName = "error"
      })

  if (newChosenSquads.len() == 0)
    return

  
  newChosenSquads.resize(slotsCount.get(), null)

  
  let previewSquadIds = {}
  newChosenSquads.each(function(squad) {
    if (squad?.squadId)
      previewSquadIds[squad.squadId] <- true
  })

  
  let newReserveSquads = unlockedSquads.get().filter(@(squad) squad != null && squad.squadId not in previewSquadIds)

  chosenSquads.set(newChosenSquads)
  reserveSquads.set(newReserveSquads)
}

register_command(createSquadsPreset, "debug.preset.squads.create")
register_command(updateSquadsPreset, "debug.preset.squads.update")
register_command(deleteSquadsPreset, "debug.preset.squads.delete")
register_command(renameSquadsPreset, "debug.preset.squads.rename")
register_command(applySquadsPreset, "debug.preset.squads.accept")

register_command(@() console_print("Squad presets: ", squadsPresetWatch.get()),
  "presets.squads.list")
register_command(@() setSquadsPreset(null), "presets.squads.clear")
register_command(@() settings.mutate(@(v) v.wereSquadPresetsGenerated <- false),
  "presets.squads.reset_generation_flag")


return {
  createSquadsPreset
  updateSquadsPreset
  deleteSquadsPreset
  renameSquadsPreset
  applySquadsPreset
}