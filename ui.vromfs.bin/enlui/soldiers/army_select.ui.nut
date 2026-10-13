import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/style/designConst.nut" import bigPadding, hoverSlotBgColor, miniPadding,
  panelBgColor, accentColor, selectedPanelBgColor, defTxtColor, smallPadding
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon, mkArmySimpleIcon
from "%ui/soldiers/armySquadTier.nut" import getLiveArmyBR, BRByArmies
from "%ui/components/battleRatingPkg.nut" import mkBattleRating, mkBattleRatingShort
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy, selectArmy, canSwitchArmy
from "%ui/style/fontsStyle.nut" import fontSub
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/cursors.nut" import setTooltip
from "%ui/ui_library.nut" import *

const colorGray = Color(30, 44, 52)
const sizeIcon = hdpx(26)
let showNameArmy =  Computed(@() curArmiesList.get().len() > 2)

const sound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
}

function selectArmyCb(army) {
  if (!canSwitchArmy.get()) {
    addPopup({ text = loc("army/disabled"), id = "ArmyNotification" })
  }
  selectArmy(army)
}

let hoverPredefined = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(650)
  color = defTxtColor
  text = loc("army/predefined")
}.__update(fontSub)

let hoverArmyBR = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(650)
  color = defTxtColor
  text = loc("battleRating/desc")
}.__update(fontSub)

function mkArmyBtn(armyId, isSelected = WatchedRo(false), action = selectArmyCb, isCustomProfile = false) {
  let icon = mkArmyIcon(armyId, sizeIcon, {margin = 0})
  let onHover = @(on) setTooltip(!on ? null
    : tooltipCtor({
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = isCustomProfile
          ? hoverPredefined
          : [
              mkBattleRating(getLiveArmyBR(BRByArmies.get(), armyId))
              hoverArmyBR
            ]
      })
  )
  function builder(sf) {
    let isEnabled = canSwitchArmy.get()
    let colorIcon = !isEnabled || ((sf & S_HOVER) && !isSelected.get())
      ? colorGray
      : hoverSlotBgColor

    return {
      watch = [isSelected, showNameArmy, BRByArmies, canSwitchArmy]
      rendObj = ROBJ_BOX
      borderWidth = isSelected.get() ? [0, 0, hdpx(2), 0] : 0
      borderColor = accentColor
      fillColor = isEnabled && (sf & S_HOVER) ? hoverSlotBgColor
        : isSelected.get() ? selectedPanelBgColor
        : panelBgColor
      behavior = Behaviors.Button
      skipDirPadNav = true
      sound
      onClick = @() action(armyId)
      onHover
      children = {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        padding = showNameArmy.get() ? [hdpx(8), hdpx(14)] : [hdpx(8), hdpx(23)]
        vplace = ALIGN_BOTTOM
        children = isSelected.get()
          ? icon
          : mkArmySimpleIcon(armyId, sizeIcon, {
              color = colorIcon
              margin = 0
            })
      }
    }
  }
  return watchElemState(builder)
}

function switchArmy(delta) {
  let armies = curArmiesList.get() ?? []
  let curArmyIdx = armies.indexof(curArmy.get()) ?? 0
  let newArmyId = armies?[curArmyIdx + delta]
  if (newArmyId != null)
    selectArmy(newArmyId)
}

let tb = @(key, val, params) @() {
  watch = [isGamepad, canSwitchArmy]
  isHidden = !isGamepad.get() || !canSwitchArmy.get()
  children = mkHotkey(key, @() switchArmy(val))
}.__update(params)

function armySelectButtons() {
  let watch = [curArmiesList]
  let armies = curArmiesList.get()
  if (armies.len() <= 1)
    return { watch }

  return {
    watch
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        flow = FLOW_HORIZONTAL
        children = armies.map(@(armyId) mkArmyBtn(armyId, Computed(@() armyId == curArmy.get())))
      }
      tb("^J:LT", -1, { pos = const [-hdpx(15), 0] })
      tb("^J:RT", 1, { hplace = ALIGN_RIGHT, pos = const [hdpx(15), 0] })
    ]
  }
}

let mkUpperText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = utf8ToUpper(text)
}.__update(override)

let armySelectText = @() {
  watch = [curArmy, showNameArmy, allArmiesInfo, BRByArmies]
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  halign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  children = [
    showNameArmy.get()
      ? mkUpperText(loc($"country/{allArmiesInfo.get()[curArmy.get()].country}"), fontSub)
      : mkUpperText(loc("select_army"), fontSub)
    mkBattleRatingShort(getLiveArmyBR(BRByArmies.get(), curArmy.get()))
  ]
}

let armySelectUi = {
  flow = FLOW_VERTICAL
  vplace = ALIGN_BOTTOM
  gap = miniPadding
  children = [
    armySelectText
    armySelectButtons
  ]
}

return {
  armySelectUi
  mkArmyBtn
}
