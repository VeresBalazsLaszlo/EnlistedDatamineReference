import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/components/faComp.nut" as faComp
import "%ui/components/modalPopupWnd.nut" as modalPopupWnd
from "%ui/components/textButton.nut" import Secondary
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import midPadding, defSlotBgColor, hoverSlotBgColor,
  smallPadding, darkTxtColor, defTxtColor, inactiveFilterTxtColor, smallBtnHeight
from "%ui/components/squadsUiComps.nut" import squadTypeIcon
from "%ui/soldiers/model/config/squadsConfig.nut" import allSquadTypes, squadsCfgById
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM, SIGN_EVENT
from "%ui/soldiers/armySquadTier.nut" import getSquadBR
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/currency/premiumComp.nut" import premiumGreyImage
from "%ui/soldiers/model/state.nut" import curArmy
from "string" import startswith
from "%ui/ui_library.nut" import *

const MAX_SQUAD_BR = 5

const WND_UID = "squadsFilter"
const iSize = hdpxi(22)
let faFontSize = (iSize * 0.9).tointeger()
const btnWidth = hdpx(350)
const checkFontSize = hdpx(14)
const selectorHeight = hdpx(36)
let textColor = @(sf, isSelected = false, isDisabled = false) isDisabled ? inactiveFilterTxtColor
  : isSelected || (sf & S_HOVER) ? darkTxtColor
  : defTxtColor
let fillColor = @(sf, isSelected = false, isDisabled = false) isDisabled ? defSlotBgColor
  : isSelected || (sf & S_HOVER) ? hoverSlotBgColor
  : defSlotBgColor

function getCountSquadTypes(squadsList, favoritesVal) {
  let squadTypes = { total = squadsList.len() }
  let curArmySquads = squadsCfgById.get()[curArmy.get()]
  foreach (squad in squadsList) {
    let { squadId, squadType } = squad
    squadTypes[squadType] <- (squadTypes?[squadType] ?? 0) + 1

    let { sign = SIGN_NONE } = curArmySquads?[squadId]
    if (squadId in favoritesVal)
      squadTypes.favorite <- (squadTypes?.favorite ?? 0) + 1

    let brId = $"br{getSquadBR(squadId)}"
    squadTypes[brId] <- (squadTypes?[brId] ?? 0) + 1

    if (sign == SIGN_EVENT)
      squadTypes.event <- (squadTypes?.event ?? 0) + 1
    else if (sign == SIGN_PREMIUM)
      squadTypes.premium <- (squadTypes?.premium ?? 0) + 1
    else
      squadTypes.regular <- (squadTypes?.regular ?? 0) + 1
  }
  return squadTypes
}

function updateSquadTypes(res, squadsList, defValue = null) {
  foreach(squad in squadsList)
    if (squad.squadType not in res)
      res[squad.squadType] <- defValue
  return res
}

let listDivider = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, hdpx(1)]
  color = hoverSlotBgColor
}

let mkFaIcon = @(faId, color) faComp(faId, { color, fontSize = faFontSize })

let mkBRIcon = @(br, color) {
  rendObj = ROBJ_TEXT
  size = const [iSize, SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  text = getRomanNumeral(br)
  color
}.__update(fontBody)

let mkIconStatus = @(squadStatus, color) squadStatus == "total" ? mkFaIcon("filter", color)
  : squadStatus == "premium" ? premiumGreyImage(iSize, color)
  : squadStatus == "event" ? mkFaIcon("trophy", color)
  : squadStatus == "regular" ? mkFaIcon("group", color)
  : squadStatus == "favorite" ? mkFaIcon("bookmark", color)
  : startswith(squadStatus, "br") ? mkBRIcon(squadStatus.slice(-1).tointeger(), color)
  : null

let mkIconBtnFilter = @(squadType, sf) function() {
  let color = textColor(sf)
  let squadStatus = squadType.get()
  return {
    watch = squadType
    minWidth = iSize + smallPadding
    halign = ALIGN_CENTER
    children = !squadStatus
      ? mkFaIcon("filter", color)
      : mkIconStatus(squadStatus, color) ?? squadTypeIcon(squadStatus, iSize, { color })
  }
}

let mkIconCheck = @(isSelected, color) !isSelected ? null
  : faComp("check", {color, fontSize = checkFontSize})

function close() {
  modalPopupWnd.remove(WND_UID)
}

let resetFilter = @(watchFilter) watchFilter.set({})
let setFilter = @(watchFilter, squadType) watchFilter.set({ [squadType] = true })
let clearFilter = @(watchFilter, squadType) watchFilter.mutate(@(f) f.$rawdelete(squadType))

let styleSelector = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, selectorHeight]
  minWidth = btnWidth
  behavior = Behaviors.Button
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = [0, midPadding]
}

let mkTextWithAmount = @(text, color, amount) {
  size = FLEX_H
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  color
  text = amount == 0 ? text : $"{text} ({amount})"
  behavior = Behaviors.Marquee
}

function mkSquadSelector(watchFilter, squadTypeInfo, squadsCount) {
  let { squadType, nameText } = squadTypeInfo
  let isSelected = Computed(@() squadType in watchFilter.get())
  let typeCount = Computed(@() squadsCount.get()?[squadType] ?? 0)
  let isDisabled = Computed(@() squadType not in squadsCount.get())
  return watchElemState(function(sf) {
    let color = textColor(sf, isSelected.get(), isDisabled.get())
    return {
      watch = [isSelected, isDisabled, typeCount]
      gap = midPadding
      color = fillColor(sf, isSelected.get(), isDisabled.get())
      onClick = isDisabled.get() ? null
        : function() {
            close()
            if (!isSelected.get()) {
              setFilter(watchFilter, squadType)
              return
            }
            if (squadType in watchFilter.get())
              clearFilter(watchFilter, squadType)
          }
      children = [
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = midPadding
          children = [
            squadTypeIcon(squadType, iSize, { color })
            mkTextWithAmount(nameText, color, typeCount.get())
          ]
        }
        mkIconCheck(isSelected.get(), color)
      ]
    }.__update(styleSelector)
  })
}

let mkStatusSelector = @(text, onClick, isEmptyFilter, typeCount, squadStatus) watchElemState(function(sf) {
  let color = textColor(sf, isEmptyFilter.get())
  return {
    color = fillColor(sf, isEmptyFilter.get())
    watch = isEmptyFilter
    onClick
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          mkIconStatus(squadStatus, color)
          mkTextWithAmount(text, color, typeCount.get())
        ]
      }
      mkIconCheck(isEmptyFilter.get(), color)
    ]
  }.__update(styleSelector)
})

let mkSelectorShowAll = @(watchFilter, squadTypesCount, text, id) mkStatusSelector(text,
  function() {
    resetFilter(watchFilter)
    close()
  },
  Computed(@() watchFilter.get().len() == 0),
  Computed(@() squadTypesCount.get()?.total ?? 0),
  id)

function mkFilterCb(watchFilter, id) {
  return function() {
    setFilter(watchFilter, id)
    close()
  }
}

let mkIsSelectedComputed = @(watchFilter, id) Computed(@() watchFilter.get()?[id])

let mkAmountComputed = @(squadTypesCount, id) Computed(@() squadTypesCount.get()?[id] ?? 0)

let mkSelectorSpecial = @(watchFilter, squadTypesCount, text, id) mkStatusSelector(text,
  mkFilterCb(watchFilter, id),
  mkIsSelectedComputed(watchFilter, id),
  mkAmountComputed(squadTypesCount, id),
  id)

function openFilter(event, watchFilter, squadTypesCount, offset) {
  let children = [
    mkSelectorShowAll(watchFilter, squadTypesCount, loc("ShowAll"), "total")
    listDivider
    mkSelectorSpecial(watchFilter, squadTypesCount, loc("squadsFilter/premium"), "premium")
    mkSelectorSpecial(watchFilter, squadTypesCount, loc("squadsFilter/event"), "event")
    mkSelectorSpecial(watchFilter, squadTypesCount, loc("squadsFilter/regular"), "regular")
    mkSelectorSpecial(watchFilter, squadTypesCount, loc("squadsFilter/favorite"), "favorite")
    listDivider]
  .extend(array(MAX_SQUAD_BR).map(@(_, idx) mkSelectorSpecial(watchFilter, squadTypesCount,
    loc("squadsFilter/br", { br = getRomanNumeral(idx + 1) }), $"br{idx + 1}")))
  .append(listDivider)
  .extend(allSquadTypes.get().map(@(squadType)
    mkSquadSelector(watchFilter, squadType, squadTypesCount)))

  modalPopupWnd.add([event.targetRect.r + offset[1], event.targetRect.t + offset[0]], {
    uid = WND_UID
    popupHalign = ALIGN_LEFT
    popupValign = ALIGN_TOP
    popupFlow = FLOW_VERTICAL
    popupBg = { rendObj = null }
    padding = 0
    valign = ALIGN_TOP
    children = @() {
      flow = FLOW_VERTICAL
      children
    }
    hotkeys = [[$"^{JB.B} | Esc | J:RS", { action = close }]]
  })
}

function getFilterSquads(squadsList, filter, curArmySquads, favoritesVal = null) {
  if (filter.len() == 0)
    return squadsList

  return squadsList.filter(function(s) {
    let { sign = SIGN_NONE } = curArmySquads?[s.squadId]
    if (filter?.event)
      return sign == SIGN_EVENT

    if (filter?.premium)
      return sign == SIGN_PREMIUM

    if (filter?.regular)
      return sign != SIGN_EVENT && sign != SIGN_PREMIUM

    if (filter?.favorite)
      return s.squadId in favoritesVal

    if (s.squadType in filter)
      return true

    let br = $"br{getSquadBR(s.squadId)}"
    return br in filter
  })
}

let mkTextBtnFilter = @(color) {
  rendObj = ROBJ_TEXT
  color
  text = loc("Filters")
}

let squadsFilterUi = kwarg(function(watchFilter, squadTypesCount, offset = [0, 0], override = {}) {
  let squadType = Computed(@() watchFilter.get().keys()?[0])
  let filterBtn = @(sf) {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = midPadding
    padding = midPadding
    children = [
      mkTextBtnFilter(textColor(sf))
      mkIconBtnFilter(squadType, sf)
    ]
  }

  return Secondary(@(_textComp, params, handler, group, sf)
    textButtonTextCtor(filterBtn(sf), params, handler, group, sf),
    @(event) openFilter(event, watchFilter, squadTypesCount, offset), {
      key = "openSquadsFilter"
      size = [SIZE_TO_CONTENT, smallBtnHeight]
      hotkeys = [["^J:RS"]]
    }.__update(override))
})

return {
  getCountSquadTypes
  updateSquadTypes
  squadsFilterUi
  getFilterSquads
  resetFilter
}
