import "%ui/components/fontawesome.map.nut" as fa
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/spinner.nut" as spinner
import "%ui/components/textInput.nut" as textInput
import "%ui/helpers/obsceneFilter.nut" as obsceneFilter
import "%ui/popup/popupsState.nut" as popupsState
from "%ui/style/fontsStyle.nut" import fontawesome
from "%ui/preset/equipDesign.nut" import rowHeight, defInputStyle, hoverInputStyle, textState,
  bgState, innerBtnStyle, closeBtnStyle
from "%ui/style/designConst.nut" import defSlotBgColor, commonBtnHeight, panelBgColor
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/textButton.nut" import FARegular, Regular
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/style/sounds.nut" import stateChangeSounds
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/ui_library.nut" import *


enum InlineButtons {
  VISIBLE_HOVER = 0
  VISIBLE_ALWAYS = 1
  HIDE_COMMON = 2
}

const MAX_NAME_LEN = 20

let presetWidgetOpened = Watched(false)
let isWaitingObsceneFilterForIdx = Watched(-1)

let waitingSpinner = {
  rendObj = ROBJ_SOLID
  size = [FLEX, rowHeight]
  vplace = ALIGN_CENTER
  color = panelBgColor
  children = spinner(commonBtnHeight/2)
}

let actionBtn = @(icon, action, hint, onHover = null) FARegular(icon, action, {
  btnWidth = rowHeight
  btnHeight = rowHeight
  onHover = function(on) {
    onHover?(on)
    setTooltip(!on ? null : hint)
  }
}.__update(innerBtnStyle))

let btnSavePreset = @(actions, presetCfg) presetCfg?.fnSave == null ? null
  : actionBtn("save",
      @() actions.save(presetCfg),
      loc("squads/presets/save"))

let genApplyBtn = @(presetCfg)
  (presetCfg?.isLockedPrem ?? false) || presetCfg?.fnApply == null
    ? []
    : [{ tooltip = loc("squads/presets/apply"), icon = "check" }]


function mkPresetButtons(actions, presetCfg) {
  let generateFn = presetCfg?.genButtons ?? genApplyBtn
  let btnsConfig = generateFn(presetCfg)

  let buttons = []
  foreach (btnConfig in btnsConfig) {
    let { tooltip, args = {}, name = null, icon = null } = btnConfig
    let config = presetCfg.__merge(args)

    let action = @() actions.apply(config)
    let button = icon != null
      ? actionBtn(icon, action, tooltip, @(on) actions.hover(on ? config : null))
      : Regular(name, action, {
          btnWidth = rowHeight
          btnHeight = rowHeight
          onHover = function(on) {
            actions.hover(on ? config : null)
            setTooltip(on ? tooltip : null)
          }
        }.__update(innerBtnStyle))

    buttons.append(button)
  }
  return buttons
}

let selectedRenameSlot = Watched(-1)
let renameTextWatch = Watched("")

let btnRenamePreset = @(presetCfg, idx, textWatch) presetCfg?.fnRename == null ? null
  : actionBtn("pencil",
      function() {
        textWatch.set(presetCfg.locId)
        selectedRenameSlot.set(idx)
      },
      loc("squads/presets/rename"))

let btnDeletePreset = @(actions, presetCfg, _idx) presetCfg?.fnDelete == null ? null
  : actionBtn("remove",
      @() actions.remove(presetCfg),
      loc("squads/presets/delete"))

function stopRenameAction() {
  renameTextWatch.set("")
  selectedRenameSlot.set(-1)
}

async function filterAndRenamePreset(presetCfg, newName, idx, actions) {
  if (isWaitingObsceneFilterForIdx.get() >= 0)
    return
  isWaitingObsceneFilterForIdx.set(idx)
  let filteredPresetName = await obsceneFilter(newName)
  isWaitingObsceneFilterForIdx.set(-1)
  if (filteredPresetName != newName) {
    return popupsState.addPopup({
      id = "prohibited_presetName"
      text = loc("prohibitedPresetname")
      styleName = "error"
    })
  }
  actions.rename(presetCfg, newName)
}


function mkRenameSlot(actions, presetCfg, textWatch, idx) {
  function applyRename() {
    filterAndRenamePreset(presetCfg, textWatch.get(), idx, actions)
    stopRenameAction()
  }
  return watchElemState(@(sf) {
    size = [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    rendObj = ROBJ_WORLD_BLUR_PANEL
    behavior = Behaviors.Button
    onHover = @(on) actions.hover(on ? presetCfg : null)
    children = [
      textInput.Underlined(textWatch, {
        size = [FLEX, rowHeight]
        margin = 0
        textmargin = 0
        placeholderTextMargin = 0
        valignText = ALIGN_CENTER
        placeholder = presetCfg.locId
        maxChars = MAX_NAME_LEN
        onEscape = stopRenameAction
        onReturn = applyRename
        onChange = @(val) textWatch.set(val)
        onAttach = @(elem) set_kb_focus(elem)
        onImeFinish = function(applied) {
          if (!applied)
            return
          applyRename()
        }
      }.__update(sf & S_HOVER ? hoverInputStyle : defInputStyle))
      actionBtn("check", applyRename, loc("squads/presets/apply"))
    ]
  }.__update(bgState(sf, false)))
}

function mkPresetSlot(actions, presetCfg, idx) {
  let { inlineBtns = InlineButtons.VISIBLE_HOVER } = presetCfg

  let presetButtons = mkPresetButtons(actions, presetCfg)
  let commonButtons = inlineBtns & InlineButtons.HIDE_COMMON
    ? []
    : [
        btnRenamePreset(presetCfg, idx, renameTextWatch)
        btnDeletePreset(actions, presetCfg, idx)
        btnSavePreset(actions, presetCfg)
      ]

  let isAlwaysVisible = inlineBtns & InlineButtons.VISIBLE_ALWAYS

  return watchElemState(@(sf) {
    size = [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_WORLD_BLUR_PANEL
    behavior = Behaviors.Button
    key = $"preset{idx}"
    children = [
      {
        size = FLEX
        behavior = Behaviors.Button
        onHover = @(on) actions.hover(on ? presetCfg : null)
        onClick = @() actions.apply(presetCfg)
        sound = stateChangeSounds
        flow = FLOW_HORIZONTAL
        children = [
          {
            rendObj = ROBJ_TEXT
            size = FLEX
            valign = ALIGN_CENTER
            behavior = Behaviors.Marquee
            text = presetCfg.locId
            scrollOnHover = true
          }.__update(textState(sf, presetCfg?.isLockedPrem ?? false))
          presetCfg?.isLockedPrem ? premiumImage(rowHeight * 0.7, { pos = const [0, hdpx(7)]}) : null
        ]
      }
      isAlwaysVisible || (sf & S_HOVER)
        ? {
            flow = FLOW_HORIZONTAL
            children = [].extend(presetButtons, commonButtons)
          }
        : null
    ]
  }.__update(bgState(sf, presetCfg?.isLockedPrem ?? false)))
}

function makePresetList(actions, presetCfgList) {
  let presetList = presetCfgList.map(function(presetCfg, idx) {
    let isRenaming = Computed(@() selectedRenameSlot.get() == idx)
    let isWaiting = Computed(@() isWaitingObsceneFilterForIdx.get() == idx)
    return @() {
      watch = [isRenaming, isWaiting]
      size = FLEX_H
      children = isWaiting.get() ? waitingSpinner
        : isRenaming.get() ? mkRenameSlot(actions, presetCfg, renameTextWatch, idx)
        : mkPresetSlot(actions, presetCfg, idx)
    }
  })
  return presetList
}

let closePanel = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = FLEX_H
  fillColor = defSlotBgColor
  children = {
    rendObj = ROBJ_TEXT
    vplace = ALIGN_TOP
    hplace = ALIGN_RIGHT
    behavior = Behaviors.Button
    text = fa["close"]
    font = fontawesome.font
    hotkeys = [[ $"^{JB.B} | Esc" ]]
    onClick = @() presetWidgetOpened.set(false)
  }.__update(closeBtnStyle)
}

let mkPresetBlock = @(actions, dataWatch, width, animation = null, hasClose = true) {
  flow = FLOW_VERTICAL
  size = [width, FLEX]
  children = [
    hasClose ? closePanel : null
    {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      size = FLEX
      children = makeVertScroll(@() {
        watch = dataWatch
        flow = FLOW_VERTICAL
        size = FLEX_H
        children = makePresetList(actions, dataWatch.get())
      })
      onAttach = function() {
        if (isGamepad.get())
          move_mouse_cursor("preset0")
      }
    }
  ]
  key = "__anim_preset"
}.__update(animation?(0) ?? {})

let togglePresetBlock = @() presetWidgetOpened.set(!presetWidgetOpened.get())

return {
  mkPresetBlock = kwarg(mkPresetBlock)
  togglePresetBlock
  closePresetBlock = @() presetWidgetOpened.set(false)
  presetWidgetOpened
  InlineButtons
}
