import "%ui/components/faComp.nut" as faComp
import "%ui/components/checkbox.nut" as checkBox
from "dagor.debug" import logerr
from "%ui/style/designConst.nut" import smallPadding, midPadding
from "%ui/style/colors.nut" import comboboxBorderColor
from "%ui/components/defcomps.nut" import txt, noteTextArea
from "%ui/scene/soldier_overrides.nut" import soldierReset, soldierResetAll, mkSoldierDisarmed,
  setSoldierDisarmed, mkSoldierIdle, setSoldierIdle, allSoldierHeads, mkSoldierHead, setSoldierHead,
  FACE_ID_COUNT, mkSoldierFace, setSoldierFace, mkSoldierSlotsSwap, setSoldierSlotsSwap,
  faceGenOverrides, faceGenRandomize, faceGenAll, faceGenSave
from "%ui/helpers/menu_poses_for_weapons.nut" import allIdleAnims
from "%ui/components/slider.nut" import Horiz
from "%ui/components/textButton.nut" import Regular, FARegular
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/ui_library.nut" import *

let comboBox = require("%ui/components/combobox.nut")

const debugUiColor = 0xFFAA0000

let idleAnims = Watched([null].extend(allIdleAnims))
let soldierHeads = Computed(@() [null].extend(allSoldierHeads.get()))
let hasFaceGenOverrides = Computed(@() faceGenOverrides.get().len() > 0)

let mkWatchableField = @(watchable) {
  rendObj = ROBJ_BOX
  size = const [ph(100), FLEX]
  borderWidth = hdpx(1)
  borderRadius = hdpx(3)
  borderColor = comboboxBorderColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = @() {
    watch = watchable
    rendObj = ROBJ_TEXT
    text = watchable.get()
  }
}

let debugFeatureWarning = {
  rendObj = ROBJ_FRAME
  size = FLEX_H
  valign = ALIGN_CENTER
  color = debugUiColor
  borderWidth = hdpx(4)
  padding = midPadding * 2
  gap = midPadding
  flow = FLOW_HORIZONTAL
  children = [
    faComp("exclamation-triangle", { color = debugUiColor, fontSize = hdpx(24) })
    noteTextArea("This is debug feature, all changes made will be lost on game restart. The changes are applied to the currently selected soldier, so you can individually customize the appearance of the entire squad.")
  ]
}

let optCheckbox = @(label, value, setValue)
  checkBox(value, label, { setValue })

let optCombobox = @(label, value, update, list) {
  size = const [FLEX, fsh(4)]
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    txt(label)
    comboBox({ value, update }, list)
  ]
}

function optSlider(label, value, minVal, maxVal, setValue) {
  let safeValue = Computed(@() value.get() ?? minVal)
  return {
    size = const [FLEX, fsh(4)]
    flow = FLOW_HORIZONTAL
    gap = midPadding
    valign = ALIGN_CENTER
    children = [
      txt(label)
      Horiz(safeValue, {
        min = minVal
        max = maxVal
        pageScroll = 1.0 / (maxVal - minVal)
        setValue
        ignoreWheel = false
      })
      mkWatchableField(value)
    ]
  }
}

let warnResetAll = @() showMsgbox({
  text = "This will clear all soldier override settings. Are you sure?"
  buttons = [
    { text = "Ok", action = soldierResetAll }
    { text = "Cancel", isCancel = true, isCurrent = true }
  ]
})

function saveFaceGenAndWarn() {
  let fileName = faceGenSave()
  showMsgbox($"All soldiers' face generation properties were saved to file {fileName}.\nYou should manually move it to the proper location.")
}

let mkBtnStyle = @(isEnabled) {
  size = FLEX_H
  isEnabled
}

let mkFaceButtons = @(headWatch, faceWatch) @() {
  watch = [hasFaceGenOverrides, headWatch, faceWatch]
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    Regular("Save all", saveFaceGenAndWarn, mkBtnStyle(hasFaceGenOverrides.get()))
    Regular("Fill faces", @() faceGenAll(headWatch.get()), mkBtnStyle(headWatch.get() != null))
    Regular("Reroll face", @() faceGenRandomize(headWatch.get(), faceWatch.get()),
      mkBtnStyle(headWatch.get() != null && faceWatch.get() != null))
  ]
}

let mkResetButtons = @(guid) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    Regular("Reset all soldiers", warnResetAll,
      { borderWidth = hdpx(2), borderColor = debugUiColor })
    { size = FLEX }
    FARegular("exclamation-triangle", @() logerr("Button to check out UI behavior on log error"))
    Regular("Reset", @() soldierReset(guid))
  ]
}

let soldierLook = @(soldier) function() {
  let { guid } = soldier.get()
  let soldierHeadId = mkSoldierHead(guid)
  let soldierFaceId = mkSoldierFace(guid)
  return {
    watch = soldier
    size = FLEX
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      debugFeatureWarning
      optCombobox("Idle animation", mkSoldierIdle(guid),
        @(val) setSoldierIdle(guid, val), idleAnims)
      optCombobox("Custom head", soldierHeadId,
        @(val) setSoldierHead(guid, val), soldierHeads)
      optSlider("Custom face", soldierFaceId, -1, FACE_ID_COUNT - 1,
        @(val) setSoldierFace(guid, val))
      mkFaceButtons(soldierHeadId, soldierFaceId)
      optCheckbox("Remove weapon", mkSoldierDisarmed(guid),
        @(val) setSoldierDisarmed(guid, val))
      optCheckbox("Swap primary and secondary slots", mkSoldierSlotsSwap(guid),
        @(val) setSoldierSlotsSwap(guid, val))
      mkResetButtons(guid)
    ]
  }
}

return kwarg(soldierLook)