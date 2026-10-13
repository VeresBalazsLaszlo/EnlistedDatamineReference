import "%ui/gameModes/components/mkOptionRow.nut" as mkOptionRow
import "%ui/components/faComp.nut" as faComp
from "%ui/gameModes/eventRoomsListFilter.nut" import OPT_MULTISELECT, OPT_RADIO
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/style/designConst.nut" import midPadding, smallPadding, defTxtColor
from "%ui/gameModes/eventModeStyle.nut" import localGap
from "%ui/gameModes/sandbox/customMissionState.nut" import isModAvailable
from "%ui/ui_library.nut" import *

let { optModRooms, optFullRooms, optPasswordRooms, optMode, optDifficulty, optArmiesA, optArmiesB, optCluster, optCrossplay } = require("%ui/gameModes/eventRoomsListFilter.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")

const WND_UID = "eventFiltersPopup"
let isRoomFilterOpened = Watched(false)
const columnWidth = hdpx(440)
const rowHeight = hdpx(38)
let circleSize = [hdpxi(18), hdpxi(18)]
let locOn = loc($"option/on")
let locOff = loc($"option/off")

const OPTS_LIST = "opts_list"

let optFullFilter = {
  locId = "rooms/Rooms"
  optType = OPTS_LIST
  innerOption = optFullRooms
}

let optPasswordFilter = {
  optType = OPTS_LIST
  innerOption = optPasswordRooms
}

let optModsFilter = {
  optType = OPTS_LIST
  innerOption = optModRooms
}

function getColumnsData(isShowModsFilter) {
  return [
    [ optMode, optDifficulty, optFullFilter, optPasswordFilter ]
      .append(isShowModsFilter ? optModsFilter : null),
    [ optArmiesA, optArmiesB ],
    [ optCluster, optCrossplay ]
  ]
}

let bTxt = @(text) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(fontBody)

let mkBlock = @(headerText, children) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = [
    headerText == null ? null :{
      size = const [FLEX, rowHeight]
      valign = ALIGN_BOTTOM
      padding = [0, midPadding, smallPadding, midPadding]
      rendObj = ROBJ_TEXT
      color = 0xFF808080
      text = headerText
    }.__update(fontSub)
    children
  ]
}

let mkCheckIcon = @(watched) @() {
  watch = watched
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = watched.get() ? faComp("check", {valign = ALIGN_CENTER}) : null
}


let checkCircleIconOn = Picture($"ui/skin#on_radiobutton.svg:{circleSize[0]}:{circleSize[1]}")
let checkCircleIconOff = Picture($"ui/skin#off_radiobutton.svg:{circleSize[0]}:{circleSize[1]}")

let mkCheckCircleIcon = @(v) {
  size = circleSize
  rendObj = ROBJ_IMAGE
  image = v ? checkCircleIconOn : checkCircleIconOff
}

let mkCircleCheck = @(watched) @() {
  watch = watched
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  padding = [midPadding, 0]
  gap = hdpx(5)
  children = [
    bTxt(locOn)
    mkCheckCircleIcon(watched.get())
    { size = [midPadding, FLEX]}
    bTxt(locOff)
    mkCheckCircleIcon(!watched.get())
  ]
}

function mkCheckbox(opt) {
  let { locId, curValue, setValue } = opt
  return mkOptionRow(
    loc(locId),
    mkCircleCheck(curValue),
    {
      onClick = @() setValue(!curValue.get())
      size = const [FLEX, rowHeight]
    }
  )
}

let mkSelectOption = @(opt) function () {
  let { locId, curValues, allValues, valToString = @(v) v, action } = opt
  let res = { watch = allValues }
  if (allValues.get() == null || allValues.get().len() <= 1)
    return res

  let children = allValues.get().map(function (value) {
    let isChecked = Computed(@() curValues.get().contains(value))
    return mkOptionRow(
      loc(valToString(value)),
      mkCheckIcon(isChecked),
      {
        onClick = @() action(value)
        gap = null
        size = const [FLEX, rowHeight]
      }
    )
  })

  return res.__update({
    watch = allValues
    size = FLEX_H
    children = mkBlock(loc(locId),
      {
        flow = FLOW_VERTICAL
        size = FLEX_H
        children = children
      }
    )
  })
}

let mkSelectSingle = @(opt) mkSelectOption(opt.__merge({
  action = @(value) opt?.setValue([value])
}))

let mkSelectMultiple = @(opt) mkSelectOption(opt.__merge({
  action = function (value) {
    let { toggleValue, curValues } = opt
    toggleValue(value, !curValues.get().contains(value))
  }
}))

function mkOptsList(opt) {
  return mkBlock(
    loc(opt?.locId),
    {
      size = FLEX_H
      children = mkCheckbox(opt.innerOption)
    }
  )
}

function mkRow(option) {
  let { optType = null } = option
  if (optType == null)
    return null

  let ctor = {
    [OPTS_LIST] = mkOptsList,
    [OPT_RADIO] = mkSelectSingle,
    [OPT_MULTISELECT] = mkSelectMultiple
  }?[optType]
  return ctor?(option)
}


let mkColumn = @(rows) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = rows.map(mkRow)
}

function filtersContent() {
  let columns = getColumnsData(isModAvailable.get())
  return {
    watch = isModAvailable
    size = [columnWidth * columns.len(), SIZE_TO_CONTENT]
    padding = [0, midPadding, midPadding, midPadding]
    stopMouse = true
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = columns.map(mkColumn)
  }
}

let openEventFiltersPopup = @(event)
  modalPopupWnd.add(event.targetRect, {
    uid = WND_UID
    children = filtersContent
    popupOffset = localGap
    popupHalign = ALIGN_LEFT
    onAttach = @() isRoomFilterOpened.set(true)
    onDetach = @() isRoomFilterOpened.set(false)
  })

let closeEventFiltersPopup = @() modalPopupWnd.remove(WND_UID)

function toggleEventFiltersPopup(event) {
  if (isRoomFilterOpened.get())
    closeEventFiltersPopup()
  else
    openEventFiltersPopup(event)
}

return {
  toggleEventFiltersPopup
  isRoomFilterOpened
}