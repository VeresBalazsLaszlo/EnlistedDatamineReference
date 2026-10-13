from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/components/itemPkg.nut" import statusIconLocked, statusIconBlocked, hintText
from "%ui/vehicles/vehiclesListState.nut" import viewVehicle, selectVehicle, selectedVehicle, vehicleClear, squadsWithVehicles, setCurSquadId, CAN_USE
  , CANT_USE, CAN_PURCHASE, AVAILABLE_IN_GROWTH, IS_BUSY_BY_SQUAD
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/mainMenu/sectionsState.nut" import jumpToArmyGrowth
from "%ui/soldiers/components/itemDetailsComp.nut" import mkViewDetailsFull
from "%ui/soldiers/model/itemActions.nut" import isItemActionInProgress
from "%ui/shop/armyShopState.nut" import getShopItemsList, curArmyShopItems, openAndHighlightItems
from "%ui/vehicles/dmViewer.nut" import isDmViewerEnabled
from "%ui/style/designConst.nut" import inventoryItemDetailsWidth, disabledBdColor, defBdColor, commonBorderRadius, midPadding, smallPadding
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/squadsUiComps.nut" import mkSquadIcon
from "%ui/quickMatchQueue.nut" import isChangesBlocked
from "%ui/battleData/testDrive.nut" import mkCommonTestDriveButtonUi
from "%ui/soldiers/components/modifyItemPkg.nut" import mkDisposeBtn, mkUpgradeBtn
from "%ui/ui_library.nut" import *

let { waitingSpinner } = require("%ui/soldiers/components/modifyItemPkg.nut")


let mkStatusRow = @(text, icon) {
  size = FLEX_H
  padding = [smallPadding, 0]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    hintText(text)
    icon
  ]
}

let mkVehOwnersUi = @(owners) owners.len() == 0 ? null
  : function() {
      let vehSquads = squadsWithVehicles.get()
      return {
        watch = squadsWithVehicles
        children = owners.map(function(guid) {
          let squad = vehSquads.findvalue(@(v) v.guid == guid)
          return squad == null ? null
            : watchElemState(@(sf) {
                rendObj = ROBJ_BOX
                borderWidth = hdpx(1)
                borderRadius = commonBorderRadius
                borderColor = sf & S_HOVER ? defBdColor : disabledBdColor
                behavior = Behaviors.Button
                onClick = @() setCurSquadId(squad.squadId)
                children = mkSquadIcon(squad?.icon, {
                  size = hdpxi(50)
                  margin = smallPadding
                })
              })
        })
      }
    }

function vehicleStatusRow(item) {
  let { flags, statusText = "", owners = [] } = item.status
  if (item == null || flags == CAN_USE)
    return null

  if (IS_BUSY_BY_SQUAD & flags) {
    return mkStatusRow(statusText, mkVehOwnersUi(owners))
  }

  return mkStatusRow(statusText, CANT_USE & flags ? statusIconBlocked : statusIconLocked)
}

let backButton = Regular(loc("mainmenu/btnBack"), vehicleClear,
  { margin = [0, 0, 0, midPadding] })

let btnStyle = {
  margin = [0, 0, 0, midPadding]
  hotkeys = [[ "^J:Y" ]]
}

function mkChooseButton(curVehicle, selVehicle, isBlocked = false) {
  if (curVehicle?.basetpl == (selVehicle?.basetpl ?? "") || curVehicle == null)
    return null

  let { flags = 0, growthId = null } = curVehicle.status
  if (flags == CAN_USE)
    return Primary(loc("mainmenu/btnSelect"), @() selectVehicle(curVehicle), btnStyle.__merge({
      isEnabled = !isBlocked
    }))

  else if (flags & AVAILABLE_IN_GROWTH)
    return Regular(loc("GoToGrowth"), @() jumpToArmyGrowth(growthId), btnStyle)

  else if (flags & CAN_PURCHASE) {
    let { basetpl } = curVehicle
    let shopItemsList = getShopItemsList(basetpl)
    return Regular(loc("btn/gotoLogistics"),
      @() openAndHighlightItems(shopItemsList, curArmyShopItems.get()), btnStyle)
  }

  return null
}

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "vehicleDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "vehicleDetailsAnim"}
]

let manageButtons = @() {
  watch = [viewVehicle, selectedVehicle, isGamepad, isChangesBlocked, isItemActionInProgress]
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  children = isItemActionInProgress.get()
    ? waitingSpinner
    : [
        mkCommonTestDriveButtonUi(viewVehicle.get(), {
          margin = [0, 0, 0, midPadding]
          hotkeys = [[ "^J:Start" ]]
        })
        mkUpgradeBtn(viewVehicle.get(), { margin = [0, 0, 0, midPadding] })
        mkDisposeBtn(viewVehicle.get(), { margin = [0, 0, 0, midPadding] })
        mkChooseButton(viewVehicle.get(), selectedVehicle.get(), isChangesBlocked.get())
      ].append(isGamepad.get() ? null : backButton)
}

local lastVehicleTpl = null
return function() {
  let watch = [ viewVehicle, isDmViewerEnabled]
  let vehicle = viewVehicle.get()
  if (vehicle == null)
    return { watch }

  if (lastVehicleTpl != vehicle?.basetpl) {
    lastVehicleTpl = vehicle?.basetpl
    anim_start("vehicleDetailsAnim")
  }

  return {
    watch
    size = [inventoryItemDetailsWidth, FLEX]
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    transform = true
    animations = animations
    children = !isDmViewerEnabled.get()
      ? [
          {
          size = FLEX
          flow = FLOW_VERTICAL
          valign = ALIGN_BOTTOM
          gap = midPadding
          children = [
            mkViewDetailsFull(viewVehicle.get(),
              fsh(75) - safeAreaBorders.get()[0] - safeAreaBorders.get()[2])
            vehicleStatusRow(vehicle)
          ]
        }
        manageButtons
      ]
      : manageButtons
  }
}

