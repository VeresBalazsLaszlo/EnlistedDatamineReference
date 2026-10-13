import "%ui/control/gui_buttons.nut" as JB
import "%ui/currency/premiumWnd.nut" as premiumWnd
import "%ui/helpers/obsceneFilter.nut" as obsceneFilter
import "%ui/components/spinner.nut" as spinner
import "%ui/components/modalPopupWnd.nut" as modalPopupWnd
import "%ui/components/textInput.nut" as textInput
import "%ui/popup/popupsState.nut" as popupsState
from "%ui/style/designConst.nut" import defTxtColor, selectedTxtColor, disabledTxtColor,
  squadElemsBgColor, squadElemsBgHoverColor, commonBtnHeight, midPadding, titleTxtColor,
  darkPanelBgColor
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/squadPresets/squadPresetsState.nut" import availablePresetsCount, MAX_PRESETS_COUNT,
  squadsPresetWatch
from "%ui/squadPresets/squadPresetsUtils.nut" import createSquadsPreset, updateSquadsPreset,
  deleteSquadsPreset, renameSquadsPreset, applySquadsPreset
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/components/textButton.nut" import FAPrimary
from "%ui/style/sounds.nut" import stateChangeSounds, buttonSound
from "%ui/soldiers/model/chooseSquadsState.nut" import chosenSquads, getUnlockedSquadsBySquadIds,
  maxSquadsInBattle, squadsArmy, previewSquads
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/ui_library.nut" import *


let ROW_HEIGHT = commonBtnHeight
let ADDITIONAL_ICON_SIZE = ROW_HEIGHT * 0.6
const MAX_NAME_LEN = 30

let waitingSpinner = {
  rendObj = ROBJ_SOLID
  size = [FLEX, ROW_HEIGHT]
  vplace = ALIGN_CENTER
  color = squadElemsBgColor
  children = spinner(commonBtnHeight/2)
}

let selectedRenameSlot = Watched(-1)
let renameTextWatch = Watched("")
let isWaitingObsceneFilterForIdx = Watched(-1)


let presetsListWatch = Computed(function() {
  if (!squadsArmy.get())
    return null

  let totalSlots = availablePresetsCount.get()
  let presets = clone squadsPresetWatch.get()?[squadsArmy.get()] ?? []

  let presetsList = presets
    .resize(max(MAX_PRESETS_COUNT, presets.len()), null) 
    .map(@(val, idx) idx >= totalSlots && idx < MAX_PRESETS_COUNT
      ? val == null
        ? { isPremium = true } 
        : val.__merge({ isPremium = true }) 
      : clone val
    )

  return presetsList
})

let getSlotTextColor = @(sf, isDisabled = false) sf & S_HOVER ? selectedTxtColor
  : isDisabled ? disabledTxtColor
  : defTxtColor

let getSlotBGColor = @(sf) sf & S_HOVER ? squadElemsBgHoverColor : squadElemsBgColor
let getInputColor = @(sf) sf & S_HOVER
  ? {
      backGroundColor = squadElemsBgHoverColor
      textColor = selectedTxtColor
    }
  : {
      backGroundColor = squadElemsBgColor
      textColor = defTxtColor
    }


let buttonsList = [
  {
    locId = "squads/presets/apply"
    fontIcon = "check"
    showPreset = true
    isVisible = @(_idx, presetInfo) presetInfo != null
    action = @(idx, _presetInfo) applySquadsPreset(squadsArmy.get(), idx)
  }
  {
    locId = "squads/presets/save"
    fontIcon = "floppy-o"
    action = function(idx, presetInfo) {
      let squadIds = chosenSquads.get()
        .map(@(squadBlock) squadBlock?.squadId)
        .filter(@(v) v != null)
      if (presetInfo == null)
        createSquadsPreset(squadsArmy.get(), idx, squadIds)
      else
        updateSquadsPreset(squadsArmy.get(), idx, squadIds)
    }
    skipForOldPresets = true
  }
  {
    locId = "squads/presets/rename"
    fontIcon = "pencil"
    isVisible = @(_idx, presetInfo) presetInfo != null
    action = function(idx, _presetInfo) {
      if (selectedRenameSlot.get() == idx)
        selectedRenameSlot.set(-1)
      else
        selectedRenameSlot.set(idx)
    }
    skipForOldPresets = true
  }
  {
    locId = "squads/presets/delete"
    fontIcon = "remove"
    isVisible = @(_idx, presetInfo) presetInfo != null
    action = @(idx, _presetInfo) deleteSquadsPreset(squadsArmy.get(), idx)
  }
]

function resetRenameState() {
  renameTextWatch.set("")
  selectedRenameSlot.set(-1)
}

async function filterAndRenamePreset(newName, idx) {
  let filteredPresetName = await obsceneFilter(newName)
  isWaitingObsceneFilterForIdx.set(-1)
  if (filteredPresetName != newName) {
    popupsState.addPopup({
      id = "prohibited_presetName"
      text = loc("prohibitedPresetname")
      styleName = "error"
    })
    return
  }

  renameSquadsPreset(squadsArmy.get(), idx, newName)
}

function applyPresetRename(idx) {
  if (isWaitingObsceneFilterForIdx.get() >= 0)
    return

  isWaitingObsceneFilterForIdx.set(idx)
  filterAndRenamePreset(renameTextWatch.get(), idx)
  resetRenameState()
}

let renameButtonsList = [{
  locId = "squads/presets/apply"
  fontIcon = "check"
  action = @(idx, _presetInfo) applyPresetRename(idx)
}]


function switchPresetOnHover(on, presetInfo) {
  if (!on || presetInfo?.preset == null) {
    previewSquads.set(null)
    return
  }

  let squads = getUnlockedSquadsBySquadIds(presetInfo.preset)
  if (squads.len() < maxSquadsInBattle.get())
    squads.resize(maxSquadsInBattle.get(), null)
  previewSquads.set(squads)
}

let actionButton = @(action, idx, presetInfo) (action?.isVisible(idx, presetInfo) ?? true)
  ? FAPrimary(action.fontIcon, @() action.action(idx, presetInfo), {
      size = [ROW_HEIGHT, ROW_HEIGHT]
      hplace = ALIGN_CENTER
      onHover = function(on) {
        setTooltip(on ? loc(action.locId) : null)
        if (action?.showPreset)
          switchPresetOnHover(on, presetInfo)
      }
      hint = {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(action.locId)
      }.__update(fontBody)
    })
  : null


let getDefaultPresetSlotName = @(presetInfo) !presetInfo?.name
  ? loc("squads/presets/empty")
  : presetInfo?.campaign ? loc("squads/presets/united",
      { campaign = loc($"{presetInfo.campaign}/full"), name = presetInfo.name })
  : presetInfo.name

let mkInputBlock = @(idx, presetInfo) watchElemState(@(sf) {
  size = [FLEX, ROW_HEIGHT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  rendObj = ROBJ_BOX
  behavior = Behaviors.Button
  fillColor = getSlotBGColor(sf)
  onHover = @(on) switchPresetOnHover(on, presetInfo)
  children = [textInput.Underlined(renameTextWatch, {
      size = [FLEX, ROW_HEIGHT]
      padding = [0, 0, 0, midPadding]
      margin = 0
      textmargin = 0
      placeholderTextMargin = 0
      valignText = ALIGN_CENTER
      placeholder = getDefaultPresetSlotName(presetInfo)
      maxChars = MAX_NAME_LEN
      colors = getInputColor(sf)
      onHover = @(on) switchPresetOnHover(on, presetInfo)
      onEscape = resetRenameState
      onReturn = @() applyPresetRename(idx)
      onChange = @(val) renameTextWatch.set(val)
      onAttach = @() renameTextWatch.set(getDefaultPresetSlotName(presetInfo))
      onImeFinish = function(applied) {
        if (!applied)
          return

        applyPresetRename(idx)
      }
      xmbNode = XmbNode()
    }.__update(fontBody))
  ].extend(renameButtonsList.map(@(action) actionButton(action, idx, presetInfo)))
})

function mkPresetSlot(idx, presetInfo = null) {
  let isRenaming = Computed(@() selectedRenameSlot.get() == idx)
  let isWaiting = Computed(@() isWaitingObsceneFilterForIdx.get() == idx)
  return @() {
    watch = [isRenaming, isWaiting]
    size = FLEX_H
    flow = FLOW_VERTICAL
    rendObj = ROBJ_BOX
    behavior = Behaviors.Button
    children = isWaiting.get() ? waitingSpinner
      : isRenaming.get() ? mkInputBlock(idx, presetInfo)
      : watchElemState(@(sf) {
          size = [FLEX, ROW_HEIGHT]
          flow = FLOW_HORIZONTAL
          rendObj = ROBJ_BOX
          behavior = Behaviors.Button
          fillColor = getSlotBGColor(sf)
          children = [
            {
              size = FLEX
              padding = [0, 0, 0, midPadding]
              behavior = [Behaviors.Button, Behaviors.Marquee]
              onHover = @(on) switchPresetOnHover(on, presetInfo)
              onDoubleClick = @() applySquadsPreset(squadsArmy.get(), idx)
              sound = stateChangeSounds
              valign = ALIGN_CENTER
              rendObj = ROBJ_TEXT
              text = getDefaultPresetSlotName(presetInfo)
              color = getSlotTextColor(sf)
              scrollOnHover = true
            }.__update(fontBody)
          ].extend(sf & S_HOVER
            ? buttonsList.map(@(action) idx >= MAX_PRESETS_COUNT && action?.skipForOldPresets ? null
                : actionButton(action, idx, presetInfo))
            : [])
        })
  }
}


let mkPremiumPresetSlot = @(presetInfo) watchElemState(@(sf) {
  behavior = Behaviors.Button
  rendObj = ROBJ_BOX
  fillColor = getSlotBGColor(sf)
  onClick = premiumWnd
  size = [FLEX, ROW_HEIGHT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  sound = buttonSound
  onHover = @(on) switchPresetOnHover(on, presetInfo)
  children = [
    {
      size = FLEX_V
      padding = [0, midPadding, 0, midPadding]
      valign = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = getDefaultPresetSlotName(presetInfo)
      color = getSlotTextColor(sf, true)
    }.__update(fontBody)
    premiumImage(ADDITIONAL_ICON_SIZE, { color = sf & S_HOVER ? titleTxtColor : defTxtColor  })
  ]
})

const WND_UID = "squadsPresetsViewOld"
function close() {
  if (selectedRenameSlot.get() >= 0)
    selectedRenameSlot.set(-1)
  else
    modalPopupWnd.remove(WND_UID)
}

let presetsListContent = @() {
  watch = presetsListWatch
  rendObj = ROBJ_BOX
  size = FLEX_H
  flow = FLOW_VERTICAL
  fillColor = darkPanelBgColor
  children = presetsListWatch.get().map(function(item, idx) {
    if (item?.isPremium)
      return mkPremiumPresetSlot(item)

    return mkPresetSlot(idx, item)
  })
}

return {
  open = function(event) {
    let presetsAmount = Computed(@() presetsListWatch.get()?.len())
    return modalPopupWnd.add([event.targetRect.r + midPadding, 0], {
      uid = WND_UID
      popupHalign = ALIGN_LEFT
      popupValign = ALIGN_TOP
      popupFlow = FLOW_VERTICAL
      moveDuration = min(0.12 + 0.03 * MAX_PRESETS_COUNT, 0.3)
      padding = 0
      rendObj = null
      size = const [hdpx(600), sh(85)]
      valign = ALIGN_BOTTOM
      children = @() {
        watch = presetsAmount
        size = [hdpx(600), min(calc_comp_size(presetsListContent)[1], sh(80))]
        children = makeVertScroll(presetsListContent, {
          maxHeight = sh(80)
        })
      }
      hotkeys = [[$"^{JB.B} | Esc", { action = close }]]
    })
  }
}