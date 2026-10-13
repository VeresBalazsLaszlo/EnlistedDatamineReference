from "%ui/userLog/userLogState.nut" import battlesUserLogs, extractLogData
from "%ui/style/designConst.nut" import defTxtColor, hoverSlotBgColor, panelBgColor,
  selectedPanelBgColor, miniPadding
from "%ui/userLog/userLogPkg.nut" import mkUserLogHeader, mkRowText, rowStyle, userLogStyle,
  userLogRowStyle
from "%ui/ui_library.nut" import *

let battleResLoc = const {
  DESERTION = "userLog/battleRes/deserter"
  WIN = "userLog/battleRes/victory"
  DEFEAT = "userLog/battleRes/defeat"
  EARLY_DESERTION = "userLog/battleRes/deserter"
}

let selectedIdx = Watched(0)

let mkArmyExpLogRow = @(row) {
  children = mkRowText(loc("listWithDot", {
    text = loc("userLogRow/armyExp", {
      army = loc(row.armyId)
      exp = row.exp
    })
  }), defTxtColor)
}.__update(rowStyle)


function mkBattleLog(uLog, isSelected, sf) {
  let { ts, records = null } = uLog
  let { data } = extractLogData(records?.findvalue(@(_) true))
  let { result = 0, missionId = "" } = data
  return {
    children = [
      mkUserLogHeader(isSelected, ts,
        loc("userLog/battle", {
          result = loc(battleResLoc[result])
          missionName = loc(missionId, { mission_type = "" }).replace(" ()","")
        }), sf)
      isSelected && data != null
        ? { children = mkArmyExpLogRow(data) }.__update(userLogRowStyle)
        : null
    ]
  }.__update(userLogStyle)
}

function mkLog(uLog, idx) {
  let isSelected = Computed(@() idx == selectedIdx.get())
  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    watch = isSelected
    size = FLEX_H
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    onClick = @() selectedIdx.set(idx)
    fillColor = sf & S_HOVER ? hoverSlotBgColor
      : isSelected.get() ? selectedPanelBgColor
      : panelBgColor
    children = mkBattleLog(uLog, isSelected.get(), sf)
  })
}

return @() {
  watch = battlesUserLogs
  size = FLEX_H
  flow = FLOW_VERTICAL
  xmbNode = XmbContainer({
    canFocus = false
    wrap = false
    scrollSpeed = 10.0
    isViewport = true
  })
  gap = miniPadding
  children = battlesUserLogs.get().map(mkLog)
}
