import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/exclamation.nut" as exclamation
import "%ui/components/spinner.nut" as spinner
import "%ui/components/closeBtn.nut" as closeBtn
import "%ui/leaderboard/lbBestBattlesWnd.nut" as lbBestBattlesWnd
from "dagor.localize" import doesLocTextExist
from "%ui/style/fontsStyle.nut" import fontTitle, fontSub
from "%ui/style/cursors.nut" import withTooltip
from "%ui/style/designConst.nut" import defTxtColor, blurBgColor, bigPadding, defInsideBgColor, rowBg
from "%ui/style/colors.nut" import UserNameColor
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/leaderboard/lbState.nut" import refreshLbData, curLbRequestData, curLbData, curLbSelfRow, curLbErrName, isLbWndOpened, isRefreshLbEnabled
  , lbSelCategories, LB_PAGE_ROWS, bestBattlesByMode, ratingBattlesCountByMode
from "%ui/gameModes/eventModesState.nut" import selLbMode, selEvent
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *

let { RANK, NAME } = require("%ui/leaderboard/lbCategory.nut")



const WND_UID = "leaderboard"
const rowHeight = hdpx(28)
const contentHeaderHeight = rowHeight * 1.5
let fullHeight = (LB_PAGE_ROWS + 2) * rowHeight + 2 * bigPadding + contentHeaderHeight
const firstPlaceColor = 0xFFFFFFFF
const top3Color = Color(255, 245, 180)
let localGap = bigPadding * 2
const wreathSize = hdpx(24)
const headerImgHeight = hdpx(150)
const iconHeaderSize = hdpxi(30)
let waitingSpinner = spinner()


let styleByCategory = {
  [RANK] = { halign = ALIGN_LEFT },
  [NAME] = { halign = ALIGN_LEFT, size = const [hdpx(240), SIZE_TO_CONTENT] },
}

let close = @() isLbWndOpened.set(false)
let refreshLbOnChange = @(_) refreshLbData()

let mkLbCell = @(category, rowData, override) {
  size = [flex(category.relWidth), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  halign = ALIGN_CENTER
  text = category.getText(rowData)
}.__update(
  fontSub,
  styleByCategory?[category] ?? {},
  override)

function mkLbRankCell(category, rowData, override) {
  let { idx = -1 } = rowData

  return {
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    children = {
      size = const [wreathSize, SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [ idx >= 0 && idx < 3
        ? {
            rendObj = ROBJ_IMAGE
            size = const [wreathSize, wreathSize]
            image = Picture("ui/uiskin/scanner_range.avif")
          }
        : null
        {
            rendObj = ROBJ_TEXT
            color = defTxtColor
            text = category.getText(rowData)
        }.__update(fontSub)
      ]
    }
  }.__update(override, styleByCategory)
}

let renderByCategory = {
  [RANK] = mkLbRankCell
}

function mkLbRow(rowData, categories) {
  let { self = false, idx = -1 } = rowData
  let color = self ? UserNameColor
    : idx == 0 ? firstPlaceColor
    : idx == 1 || idx == 2 ? top3Color
    : null

  let override = color != null ? { color } : {}
  return {
    rendObj = ROBJ_SOLID
    size = const [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    padding = localGap
    color = rowBg(0, idx)
    valign = ALIGN_CENTER
    children = categories.map(@(c) (renderByCategory?[c] ?? mkLbCell)(c, rowData, override))
  }
}

let dotsRow = {
  size = const [FLEX, rowHeight]
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = "..."
}

let lbHeaderFlag = {
  vplace = ALIGN_CENTER
  children = mkHeaderFlag(
    {
      padding = [localGap, bigPadding * 3]
      rendObj = ROBJ_TEXT
      text = loc("Leaderboard")
    }.__update(fontTitle),
    casualFlagStyle.__merge({ offset = hdpx(15) })
  )
}

let lbHeaderImgPath = Computed(@() selEvent.get()?.image ?? "ui/pacific_usa_login_screen")

let lbHeaderImg = @() {
  watch = lbHeaderImgPath
  size = const [FLEX, headerImgHeight]
  rendObj = ROBJ_IMAGE
  image = Picture(lbHeaderImgPath.get())
  keepAspect = KEEP_ASPECT_FILL
}

let lbWindowHeader = {
  size = FLEX_H
  children = [
    lbHeaderImg
    lbHeaderFlag
    closeBtn({ onClick = close }).__update({ margin = bigPadding })
    function() {
      let res = { watch = [selLbMode, bestBattlesByMode] }
      let battles = bestBattlesByMode.get()?[selLbMode.get()] ?? []
      return battles.len() == 0 ? res
        : res.__update({
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            children = Regular(loc("lb/bestBattles"),
              @() lbBestBattlesWnd(selLbMode.get()), { margin = bigPadding })
          })
    }
  ]
}


function getColumnDescription(locId, textParams = null) {
  let descLocId = $"{locId}/desc"
  let description = doesLocTextExist(descLocId) ? loc(descLocId, textParams) : ""

  return description
}

let categoryTooltip = Computed(function() {
  let count = ratingBattlesCountByMode.get()?[selLbMode.get()] ?? 20

  return {
    common = @(category) "\n\n".join([loc(category.locId),
      getColumnDescription(category.locId)]),
    BATTLE_RATING = @(category) "\n\n".join([loc(category.locId),
      getColumnDescription(category.locId, { count })])
    TOURNAMENT_BATTLE_RATING = @(category) "\n\n".join([loc(category.locId),
      getColumnDescription(category.locId, { count })])
  }
})

let mkCategoryTooltip = @(category, categoryTooltipVal)
  (categoryTooltipVal?[category.id] ?? categoryTooltipVal.common)(category)

let mkHeaderName = @(category) {
    size = [flex(category.relWidth), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    xmbNode = XmbNode()
    children = category?.icon == null
      ? {
          rendObj = ROBJ_TEXT
          text = loc(category.locId)
          color = defTxtColor
        }.__update(fontSub)
      : withTooltip({
            rendObj = ROBJ_IMAGE
            color = defTxtColor
            size = const [iconHeaderSize, iconHeaderSize]
            image = Picture(category.icon)
          },
          @() tooltipCtor(@() {
              watch = categoryTooltip
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              maxWidth = hdpx(500)
              text = mkCategoryTooltip(category, categoryTooltip.get())
              color = Color(180, 180, 180, 120)
            })
          )
  }.__update(styleByCategory?[category] ?? {})

let lbHeaderRow = @(categories) {
  rendObj = ROBJ_SOLID
  size = const [FLEX, contentHeaderHeight]
  xmbNode = XmbContainer({
    isViewport = true
  })
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = localGap
  color = Color(0,0,0)
  children = categories.map(mkHeaderName)
}

function lbContent() {
  let lbCategories = lbSelCategories.get().full
  local children = null
  local valign = ALIGN_CENTER
  if (curLbData.get() == null)
    children = waitingSpinner
  else if (curLbData.get().len() == 0)
    children = exclamation(
      loc(curLbErrName.get() != null ? $"error/{curLbErrName.get()}" : "leaderboard/noLbData"))
  else {
    children = curLbData.get().map(@(rowData) mkLbRow(rowData, lbCategories))
    if (curLbSelfRow.get() && curLbData.get().findvalue(@(r) r?.self ?? false) == null) {
      let selfRow = mkLbRow(curLbSelfRow.get(), lbCategories)
      let { idx = -1 } = curLbSelfRow.get()
      if (idx > 0 && idx < (curLbData.get()[0]?.idx ?? -1)) {
        children.insert(0, selfRow)
        children.insert(1, dotsRow)
      }
      else if (idx > (curLbData.get().top()?.idx ?? -1) + 1) {
        children.append(dotsRow)
        children.append(selfRow)
      }
    }
    children.insert(0, lbHeaderRow(lbCategories))
    valign = ALIGN_TOP
  }

  return {
    watch = [lbSelCategories, curLbData, curLbSelfRow, curLbErrName]
    size = [FLEX, fullHeight]
    rendObj = ROBJ_SOLID
    color = Color(10,10,10,10)
    halign = ALIGN_CENTER
    valign
    flow = FLOW_VERTICAL
    children
  }
}

let lbWindow = {
  size = const [hdpx(1300), SIZE_TO_CONTENT]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  flow = FLOW_VERTICAL
  onAttach = function() {
    refreshLbData()
    curLbRequestData.subscribe(refreshLbOnChange)
  }
  onDetach = @() curLbRequestData.unsubscribe(refreshLbOnChange)
  children = [
    lbWindowHeader
    lbContent
  ]
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = FLEX
  onAttach = @() isRefreshLbEnabled.set(true)
  onDetach = @() isRefreshLbEnabled.set(false)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  onClick = @() null
  children = lbWindow
})

if (isLbWndOpened.get())
  open()
isLbWndOpened.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))
