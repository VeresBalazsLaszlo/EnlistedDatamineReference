import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/vehicles/vehiclesListCard.ui.nut" as vehiclesListCard
import "%ui/vehicles/vehicleDetails.ui.nut" as vehicleDetails
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/components/mkToggleHeader.nut" as mkToggleHeader
import "%ui/components/mkSquadsList.nut" as mkCurSquadsList
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/vehicles/vehiclesListState.nut" import vehicles, squadsWithVehicles, viewVehicle,
  selectedVehicle, selectVehicle, selectVehParams, curSquadId, setCurSquadId, CANT_USE, LOCKED,
  vehicleClear, getVehicleSquad
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/style/designConst.nut" import smallPadding, midPadding, blurBgColor, blurBgFillColor,
  vehicleListCardSize, defTxtColor, bigPadding
from "%ui/components/defcomps.nut" import txt
from "%ui/vehicles/dmViewer.nut" import isDmViewerEnabled, onDmViewerMouseMove, dmViewerPanelUi
from "%ui/showState.nut" import changeCameraFov
from "%ui/soldiers/armySquadTier.nut" import getLiveSquadBR, updateSquadsBR, BRInfoBySquads
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkPageButton
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/ui_library.nut" import *

const ADD_CAMERA_FOV_MIN = -25
const ADD_CAMERA_FOV_MAX = 45


let showNotAvailable = Watched(false)
selectVehParams.subscribe(@(_) showNotAvailable.set(false))

let notAvailableHeader = mkToggleHeader(showNotAvailable, loc("header/notAvailableVehicles"))

let sortByStatus = @(a, b) (b != LOCKED) <=> (a != LOCKED) || a <=> b

function mkStatusHeader(status) {
  let { statusTextShort = null, statusText = null, isHiddenInGroup = false } = status
  let text = isHiddenInGroup ? null : (statusTextShort ?? statusText)
  return text == null ? null
    : {
        rendObj = ROBJ_TEXT
        size = FLEX_H
        margin = [smallPadding, 0, 0, 0]
        text
        color = defTxtColor
        behavior = [Behaviors.Marquee, Behaviors.Button]
        scrollOnHover = true
      }.__update(fontSub)
}

function groupByStatus(itemsList) {
  let groupedItems = {}
  foreach (item in itemsList) {
    let { statusText = "" } = item.status
    groupedItems[statusText] <- (groupedItems?[statusText] ?? []).append(item)
  }
  let children = []
  let itemsOrdered = groupedItems.values().sort(@(a, b)
    sortByStatus(a[0].status.flags, b[0].status.flags))
  foreach (items in itemsOrdered) {
    children.append(mkStatusHeader(items[0].status))
    foreach (item in items)
      children.append(vehiclesListCard({
        item
        onClick = @(item_) viewVehicle.set(item_)
        onDoubleClick = @(item_) selectVehicle(item_)
      }))
  }
  return children
}

function vehiclesList() {
  let available = []
  let unavailable = []
  foreach (vehicle in vehicles.get()) {
    
    if (getVehicleSquad(vehicle) != null)
      continue
    if (!(vehicle.status.flags & CANT_USE))
      available.append(vehicle)
    else
      unavailable.append(vehicle)
  }

  let children = groupByStatus(available)
  if (unavailable.len() > 0) {
    children.append(notAvailableHeader)
    if (showNotAvailable.get())
      children.extend(groupByStatus(unavailable))
  }
  return {
    watch = [vehicles, showNotAvailable]
    size = [vehicleListCardSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    children
  }
}

let currentVehicle = @() {
  watch = selectedVehicle
  children = vehiclesListCard({
    item = selectedVehicle.get()
    onClick = @(item) viewVehicle.set(item)
  })
}

let vehiclesBlock = {
  size = FLEX_V
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = midPadding
  flow = FLOW_VERTICAL
  stopMouse = true
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squad/vehicle")
      color = defTxtColor
    }.__update(fontSub)
    currentVehicle
    scrollbar.makeVertScroll(vehiclesList, {
      size = FLEX_V
      needReservePlace = false
    })
  ]
}

function mkSquadName(squadId, armyId) {
  let squadPres = getSquadPresentation(squadId, armyId)
  return squadPres != null
    ? txt(loc(squadPres?.titleLocId ?? "unknown"))
    : null
}

let vehicleListWithBR = Computed(@()
  squadsWithVehicles.get().map(@(squad)
    squad.__merge({ battleRating = getLiveSquadBR(BRInfoBySquads.get(), squad.squadId) })))

let selectVehicleContent = {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    @() {
      watch = selectVehParams
      children = mkSquadName(selectVehParams.get()?.squadId, selectVehParams.get()?.armyId)
    }
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = midPadding
      behavior = DngBhv.MenuCameraControl
      children = [
        mkCurSquadsList({
          curSquadsList = vehicleListWithBR
          curSquadId
          setCurSquadId
        })
        vehiclesBlock
        {
          size = FLEX
          children = dmViewerPanelUi
        }
        {
          size = FLEX_V
          halign = ALIGN_RIGHT
          children = vehicleDetails
        }
      ]
    }
  ]
}

let selectVehicleScene = @() {
  watch = [safeAreaBorders, isDmViewerEnabled]
  size = const [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.get()
  behavior = Behaviors.TrackMouse
  onMouseMove = function(mouseEvent) {
    if (isDmViewerEnabled.get())
      onDmViewerMouseMove(mouseEvent)
  }
  onMouseWheel = function(mouseEvent) {
    changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
  }
  children = [
    @() {
      size = FLEX_H
      watch = selectVehParams
      children = mkHeader({
        armyId = selectVehParams.get()?.armyId
        textLocId = "Choose vehicle"
        addAfterText = mkPageButton(Tutorial.VEHICLE).__update({padding = [0, bigPadding]})
        closeButton = closeBtnBase({ onClick = vehicleClear })
      })
    }
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = selectVehicleContent
    }
  ]
}

viewVehicle.subscribe(@(_v) changeCameraFov(0))

function open(selectOnOpen = null) {
  let veh = selectOnOpen
    ? vehicles.get().findvalue(@(item) item?.basetpl == selectOnOpen)
    : null

  viewVehicle.set(veh ?? selectedVehicle.get())
  sceneWithCameraAdd(selectVehicleScene, "vehicles")
  updateSquadsBR(squadsWithVehicles.get())
}

if (selectVehParams.get()?.armyId != null
    && selectVehParams.get()?.squadId != null
    && !(selectVehParams.get()?.isCustomMode ?? false))
  open()

selectVehParams.subscribe(function(p) {
  let { armyId = null, squadId = null, isCustomMode = false, isHitcamMode = false,
    selectOnOpen = null } = p
  if (armyId != null && squadId != null && !isCustomMode && !isHitcamMode)
    open(selectOnOpen)
  else {
    sceneWithCameraRemove(selectVehicleScene)
    if (!isCustomMode && !isHitcamMode)
      viewVehicle.set(null)
  }
})
