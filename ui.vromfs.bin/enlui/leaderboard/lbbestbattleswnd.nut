import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/style/designConst.nut" import bigGap
from "%ui/leaderboard/lbState.nut" import bestBattlesByMode, ratingBattlesCountByMode, getCategoriesByGroup
from "%ui/style/colors.nut" import TextActive, WindowHeader, TextDefault, UserNameColor
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/ui_library.nut" import *

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let lbCategory = require("%ui/leaderboard/lbCategory.nut")


const WND_UID = "lb_best_battles_wnd"

const headerHeight = hdpx(45)
const rowHeight = hdpx(24)

let close = @() modalPopupWnd.remove(WND_UID)

let header = {
  size = FLEX_H
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("lb/bestBattles")
    }.__update(fontHeading2)
    { size = FLEX }
    fontIconButton("times", { onClick = close })
  ]
}

let mkBattlesComputed = @(baseData, mode) Computed(@() (baseData.get()?[mode] ?? [])
  .map(function(battle) {
    let modeBattle = battle?[mode] ?? {}
    let res = { timestamp = battle?["$timestamp"] ?? 0 }
    foreach (category in lbCategory) {
      let value = modeBattle?[category.field] ?? -1
      if (value > 0 || (category.field not in res))
        res[category.field] <- value
    }
    return res
  })
  .reverse())


let mkRows = @(lbCols, battles, lastBattleTimestamp, color) @() {
  watch = [battles, lastBattleTimestamp]
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = battles.get().map(@(battle) {
    size = const [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = lbCols.map(@(cat, idx) {
      size = [flex(cat.relWidth), FLEX]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = battle.timestamp == lastBattleTimestamp.get() ? UserNameColor : color
      halign = idx == 0 ? ALIGN_LEFT : ALIGN_CENTER
      indent = idx == 0 ? bigGap : 0
      valign = ALIGN_CENTER
      text = cat.getText(battle)
    }.__update(fontSub))
  })
}

let mkOtherRowsHeader = @(isVisible) @() {
  watch = isVisible
  children = isVisible.get()
    ? {
        margin = [bigGap, 0, 0, 0]
        rendObj = ROBJ_TEXT
        text = loc("lb/battlesOutOfCount")
      }.__update(fontSub)
    : null
}

let mkColumnsHeader = @(lbCols) {
  size = const [FLEX, headerHeight]
  margin = const [0, 0, hdpx(10), 0]
  children = [
    {
      rendObj = ROBJ_SOLID
      size = FLEX
      color = WindowHeader
    }
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      children = lbCols.map(@(cat, idx) {
        size = [flex(cat.relWidth), FLEX]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = TextDefault
        halign = idx == 0 ? ALIGN_LEFT : ALIGN_CENTER
        indent = idx == 0 ? bigGap : 0
        valign = ALIGN_CENTER
        text = loc(cat.locId)
      }.__update(fontSub))
    }
  ]
}

let findMinTime = @(list, prevVal = 0)
  list.reduce(@(res, b) res == 0 ? b.timestamp : max(res, b.timestamp), prevVal)

function mkLbTable(mode) {
  let lbCols = getCategoriesByGroup(mode).best
  let bestBattles = mkBattlesComputed(bestBattlesByMode, mode)
  let ratedCount = Computed(@() ratingBattlesCountByMode.get()?[mode] ?? 0)
  let ratedBattles = Computed(@() bestBattles.get().slice(0, ratedCount.get()))
  let otherBattles = Computed(@() bestBattles.get().slice(ratedCount.get()))
  let lastBattleTimestamp = Computed(@() findMinTime(bestBattles.get()))
  let hasOtherBattles = Computed(@() otherBattles.get().len() > 0)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      mkColumnsHeader(lbCols)
      mkRows(lbCols, ratedBattles, lastBattleTimestamp, Color(255, 245, 180))
      mkOtherRowsHeader(hasOtherBattles)
      mkRows(lbCols, otherBattles, lastBattleTimestamp, TextActive)
    ]
  }
}

let mkBestBattlesWnd = @(mode) {
  size = const [fsh(110), sh(70)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR_PANEL
  padding = bigGap
  flow = FLOW_VERTICAL
  gap = bigGap
  stopMouse = true
  children = [
    header
    makeVertScroll(mkLbTable(mode), { styling = thinStyle })
  ]
}

return @(mode) modalPopupWnd.add([sw(50), sh(20)], {
  uid = WND_UID
  valign = ALIGN_CENTER
  children = mkBestBattlesWnd(mode)
  popupBg = { rendObj = ROBJ_SOLID, color = Color(0, 0, 0, 140) }
  hotkeys = [[$"^{JB.B} | Esc", { action = close, description = loc("Close") }]]
})
