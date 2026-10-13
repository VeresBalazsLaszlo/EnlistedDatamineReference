import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defBgColor, selectedTxtColor, defTxtColor, activeBgColor,
  hoverBgColor, blockedBgColor, vehicleListCardSize, smallPadding, listCtors
from "%ui/components/itemsInfo.nut" import itemNameFromItem
from "%ui/components/defcomps.nut" import autoscrollText
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon, noBlinkUnseenIcon
from "%ui/vehicles/vehiclesListState.nut" import viewVehicle, curSquad, curSquadArmy, LOCKED, CANT_USE
from "%ui/components/itemPkg.nut" import statusIconLocked, mkNoVehicle, mkVehicleHint
from "%ui/vehicles/unseenVehicles.nut" import unseenSquadsVehicle, markVehicleSeen
from "%ui/components/mkSpecialItemIcon.nut" import mkSpecialItemIcon
from "%ui/meta/servProfile.nut" import vehCamouflages
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/vehicles/customizePkg.nut" import mkVehicleImage
from "%ui/soldiers/model/config/outfitConfig.nut" import getSquadCamoByVehicle
from "%ui/soldiers/model/state.nut" import armySquadsById
from "%ui/meta/profile.nut" import squadsByArmies
from "%ui/soldiers/components/itemDetailsComp.nut" import detailsStatusTier
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/ui_library.nut" import *

let { txtColor } = listCtors

let seenTanksList = Watched({})

let itemStatusIcon = @(vehicle) vehicle.status.flags & LOCKED ? statusIconLocked : null

let listTxtColor = @(flags, selected = false)
  (flags & S_HOVER) || (flags & S_ACTIVE) || selected ? selectedTxtColor : defTxtColor

let blinkIconUnseen = blinkUnseenIcon()
let noBlinkIconUnseen = noBlinkUnseenIcon()

function mkUnseenSign(vehicle) {
  let vehicleTpl = vehicle?.basetpl
  let notifierState = Computed(@() unseenSquadsVehicle.get()?[curSquad.get()?.guid][vehicleTpl] ?? false)
  return function () {
    let res = { watch = [notifierState, seenTanksList] }
    if (!notifierState.get())
      return res

    let unseenIcon = vehicleTpl not in seenTanksList.get() ? blinkIconUnseen : noBlinkIconUnseen
    return res.__update({ children = unseenIcon })
  }
}

let setVehiclesSeen = @(vehicle) vehicle?.basetpl == null ? null
  : seenTanksList.mutate(@(v) v[vehicle.basetpl] <- true)

let mkVehicleName = @(vehicle, color) autoscrollText({
  text = itemNameFromItem(vehicle)
  textParams = { color }
})

let amountText = @(count, sf, isSelected) {
  rendObj = ROBJ_SOLID
  color = isSelected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_TEXT
    color = txtColor(sf, isSelected)
    text = loc("common/amountShort", { count })
  }.__update(fontSub)
}

let itemCountRarity = @(item, sf, isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = [
    detailsStatusTier(item)
    1 >= (item?.count ?? 0) ? null : amountText(item.count, sf, isSelected)
  ]
}


function card(item, onClick = @(_item) null, onDoubleClick = @(_item) null) {
  let isAllowed = item != null && !((item?.status.flags ?? 0) & CANT_USE)
  let isSelected = Computed(function() {
    let { guid = null, basetpl = null } = viewVehicle.get()
    return item?.guid == guid && item?.basetpl == basetpl
  })

  return watchElemState(function(sf) {
    let isSelectedVal = isSelected.get()
    let textColor = listTxtColor(sf, isSelectedVal)
    let res = {
      watch = [isSelected, vehCamouflages, squadsByArmies, armySquadsById, gameProfileLookCfg]
      behavior = Behaviors.Button
      rendObj = ROBJ_SOLID
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
      color = isSelectedVal ? activeBgColor
        : sf & S_HOVER ? hoverBgColor
        : isAllowed ? defBgColor
        : blockedBgColor
      size = vehicleListCardSize
      padding = smallPadding
    }
    if (item == null)
      return res.__update({ children = mkNoVehicle(sf, textColor) })

    let camouflage = getSquadCamoByVehicle(item,
      squadsByArmies.get(), armySquadsById.get(), gameProfileLookCfg.get())
    return res.__update({
      onClick = @() onClick(item)
      onDoubleClick = @() onDoubleClick(item)
      onHover = function(on) {
        setTooltip(on && item != null ? mkVehicleHint(item) : null)
        hoverHoldAction("unseenVehicle", item.basetpl,
          function(tpl) {
            if (unseenSquadsVehicle.get()?[curSquad.get()?.guid][tpl] && curSquadArmy.get())
              markVehicleSeen(curSquadArmy.get(), tpl)
          }
        )(on)
      }
      onAttach = @() setVehiclesSeen(item)
      children = [
        mkVehicleImage(vehCamouflages.get(), item, camouflage)
        {
          children = [
            mkUnseenSign(item)
            itemStatusIcon(item)
          ]
        }
        {
          flow = FLOW_HORIZONTAL
          gap = hdpx(2)
          vplace = ALIGN_BOTTOM
          valign = ALIGN_BOTTOM
          size = FLEX_H
          children = [
            mkSpecialItemIcon(item)
            mkVehicleName(item, textColor)
          ]
        }
        itemCountRarity(item, sf, isSelectedVal)
        {
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_RIGHT
          children = mkBattleRatingShort(item?.growthTier ?? 1)
        }
      ]
    })
  })
}

return kwarg(card)