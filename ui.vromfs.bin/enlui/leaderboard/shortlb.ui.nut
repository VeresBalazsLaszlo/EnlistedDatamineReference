import "%ui/components/exclamation.nut" as exclamation
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor
from "%ui/style/colors.nut" import UserNameColor
from "%ui/leaderboard/lbState.nut" import refreshLbData, curLbRequestData, curLbData, curLbErrName, curLbSelfRow, lbSelCategories, isRefreshLbEnabled
from "%ui/ui_library.nut" import *

let { RANK, NAME } = require("%ui/leaderboard/lbCategory.nut")


const MAX_LB_ROWS = 10
const rowHeight = hdpx(25)
const fullHeight = (MAX_LB_ROWS + 3) * rowHeight
let waitingSpinner = spinner()

let styleByCategory = {
  [RANK] = { halign = ALIGN_LEFT },
  [NAME] = { color = 0xFFFFFFFF, halign = ALIGN_LEFT },
}

let refreshLbOnChange = @(_) refreshLbData()

let mkLbCell = @(category, rowData) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  halign = ALIGN_RIGHT
  text = category.getText(rowData)
}.__update(
  fontSub,
  styleByCategory?[category] ?? {},
  rowData?.self ? { color = UserNameColor } : {})

let mkLbRow = @(rowData, categories) {
  size = const [FLEX, rowHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = categories.map(@(c) mkLbCell(c, rowData))
}

let lbHeaderRow = @(categories) {
  size = const [FLEX, rowHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = categories.map(@(category) {
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    halign = styleByCategory?[category].halign ?? ALIGN_RIGHT
    children = {
      rendObj = ROBJ_TEXT
      text = loc(category.locId)
      color = defTxtColor
    }.__update(fontSub)
  })
}

let dotsRow = {
  size = const [FLEX, rowHeight]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = "..."
}

function shortEventLb() {
  let lbCategories = lbSelCategories.get().short
  local children = null
  local valign = ALIGN_CENTER
  if (curLbData.get() == null)
    children = waitingSpinner
  else if (curLbData.get().len() == 0)
    children = exclamation(
      loc(curLbErrName.get() != null ? $"error/{curLbErrName.get()}" : "leaderboard/noLbData"))
  else {
    children = [lbHeaderRow(lbCategories)]
      .extend(curLbData.get()
        .slice(0, MAX_LB_ROWS)
        .map(@(rowData) mkLbRow(rowData, lbCategories)))
    valign = ALIGN_TOP
    if (curLbSelfRow.get()) {
      let selfRow = mkLbRow(curLbSelfRow.get(), lbCategories)
      let { idx = -1 } = curLbSelfRow.get()
      if (idx < 0 || idx > MAX_LB_ROWS){
        children.append(dotsRow)
        children.append(selfRow)
      }
    }
  }

  return {
    watch = [lbSelCategories, curLbData, curLbErrName, curLbSelfRow]
    size = const [FLEX, fullHeight]
    onAttach = function() {
      isRefreshLbEnabled.set(true)
      curLbRequestData.subscribe(refreshLbOnChange)
    }
    onDetach = function() {
      isRefreshLbEnabled.set(false)
      curLbRequestData.unsubscribe(refreshLbOnChange)
    }
    halign = ALIGN_CENTER
    valign
    flow = FLOW_VERTICAL
    children
  }
}

return shortEventLb