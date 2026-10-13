import "%ui/components/mkSoldierCard.nut" as mkSoldierCard
import "%ui/helpers/squad_vehicle_seats.nut" as mkVehicleSeats
from "%ui/style/cursors.nut" import setTooltip
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/style/designConst.nut" import slotBaseSize, smallPadding, midPadding, defTxtColor, panelBgColor
from "%ui/components/defcomps.nut" import note
from "%ui/ui_library.nut" import *

let STATUS = require("%ui/soldiers/readyStatus.nut")


let emptySlot = @(cb) {
  behavior = Behaviors.Button
  onClick = cb
  size = slotBaseSize
  rendObj = ROBJ_SOLID
  color = panelBgColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squad/soldierFreeSlot")
      color = defTxtColor
    }.__update(fontSub)
  ]
}

let mkSoldierSlot = kwarg(function(soldier, idx, curSoldierIdxWatch,
  canDeselect = true, addCardChild = null, soldiersReadyWatch = Watched(null),
  defSoldierGuidWatch = Watched(null), seatsOrder = [], expToLevelWatch = Watched([])
) {
  let isSelectedWatch = Computed(function() {
    if (curSoldierIdxWatch.get() == idx)
      return true
    let sGuid = defSoldierGuidWatch.get()
    return sGuid != null && soldier.guid == sGuid
  })

  let group = ElemGroup()
  return watchElemState(function(sf) {
    let soldiersReadyInfo = soldiersReadyWatch.get()
    let soldierStatus = soldiersReadyInfo?[soldier.guid] ?? STATUS.READY
    let hasWeaponWarning = (soldierStatus & STATUS.NOT_READY_BY_EQUIP) != 0
    let isFaded = soldierStatus != STATUS.READY
    let outOfVehicSize = (soldierStatus & STATUS.OUT_OF_VEHICLE) != 0
    let seatInfo = seatsOrder?[idx]
    soldier.idx <- idx

    let chContent = {
      xmbNode = XmbNode()
      vplace = ALIGN_CENTER
      children = mkSoldierCard({
        soldierInfo = soldier
        expToLevel = expToLevelWatch.get()
        size = slotBaseSize
        group = group
        sf = sf
        isSelected = isSelectedWatch.get()
        isFaded = isFaded
        isClassRestricted = (soldierStatus & STATUS.TOO_MUCH_CLASS) != 0
        hasAlertStyle = hasWeaponWarning
        hasWeaponWarning = hasWeaponWarning
        addChild = addCardChild
      })
    }

    return {
      watch = [soldiersReadyWatch, isSelectedWatch, expToLevelWatch]
      group = group
      key = $"slot{soldier?.guid}{idx}"
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      onHover = outOfVehicSize
        ? @(on) setTooltip(on ? loc("soldier/status/outOfVehicleCrewSize") : null)
        : null
      onClick = function() {
        if (soldier?.canSpawn ?? true) {
          defSoldierGuidWatch.set(null)
          curSoldierIdxWatch.set(canDeselect && idx == curSoldierIdxWatch.get() ? null : idx)
        }
      }
      sound = const {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      children = [
        seatInfo ? note(loc(seatInfo.locName)) : null
        chContent
      ]
    }
  })
})

function mkSoldiersBlock(params) {
  let {
    soldiersListWatch, curSoldierIdxWatch, vehicleInfo = Watched(null), addCardChild = null,
    emptySlotsNum = 0, emptySlotHandler = null
  } = params
  return function() {
    let seatsOrder = mkVehicleSeats(vehicleInfo.get())
    let unitsInVehicle = seatsOrder.len()
    let soldiers = soldiersListWatch.get()
    let children = soldiers.slice(0, unitsInVehicle).map(@(soldier, idx)
      mkSoldierSlot(params.__merge({ soldier, idx, addCardChild, seatsOrder }), KWARG_NON_STRICT))

    if (unitsInVehicle < soldiers.len()) {
      children.extend(soldiers.slice(unitsInVehicle).map(@(soldier, idx)
        mkSoldierSlot(params.__merge({
          soldier
          idx = idx + unitsInVehicle
          addCardChild
          seatsOrder }),
        KWARG_NON_STRICT)))
    }

    for (local i = 0; i < emptySlotsNum; i++) {
      children.append(emptySlot(emptySlotHandler))
    }

    return {
      watch = [soldiersListWatch, curSoldierIdxWatch, vehicleInfo]
      size = [slotBaseSize[0], SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      gap = smallPadding
      onClick = function() {
        if (params?.canDeselect ?? false)
          curSoldierIdxWatch.set(null)
      }
      children = children
    }
  }
}

let mkVehicleBlock = @(hasVehicleWatch, curVehicleUi) function() {
  let res = { watch = hasVehicleWatch }
  if (!hasVehicleWatch.get())
    return res

  return res.__update({
    size = FLEX_H
    margin = [0, 0, midPadding, 0]
    children = {
      flow = FLOW_VERTICAL
      gap = smallPadding
      size = FLEX_H
      children = curVehicleUi
    }
  })
}

let mkMainSoldiersBlock = @(params) {
  size = [slotBaseSize[0], FLEX]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    params?.headerBlock
    params?.outfitBlock
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        "hasVehicleWatch" not in params ? null
          : mkVehicleBlock(params.hasVehicleWatch, params.curVehicleUi)
        makeVertScroll(mkSoldiersBlock(params), {
          size = FLEX_V, styling = thinStyle
        })
      ]
    }
    params?.bottomObj
  ]
}

return mkMainSoldiersBlock
