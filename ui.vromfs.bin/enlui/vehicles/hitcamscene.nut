import "%ui/control/gui_buttons.nut" as JB
import "%ui/vehicles/hitcam_cooldown.nut" as mkCircularIndicator
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/dasenums.nut" import HitcamResult
from "%ui/components/itemsInfo.nut" import iconByGameTemplate
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "dagor.math" import Point2
from "dasevents" import CmdShootGunScreenSpace
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/vehicles/vehiclesListState.nut" import selectVehParams
from "%ui/components/textButton.nut" import Regular
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/style/designConst.nut" import smallPadding, bigPadding, sidePadding, defSlotBgColor, panelBgColor, defBdColor, squadSlotBgIdleColor
  , squadSlotBgHoverColor, squadSlotBgActiveColor
from "%ui/style/cursors.nut" import normal
from "%ui/components/defcomps.nut" import txt
from "%ui/vehicles/hitcamState.nut" import mkHitcamData, initWeaponList, selWeaponEid
from "das.hitcam" import hangar_simulate_shot
from "%ui/vehicles/dmViewer.nut" import closeDmViewerMode
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/scene_update.nut" import frameUpdateCounter
from "xray_ui_order" import set_xray_before_ui
from "%ui/showState.nut" import changeCameraFov
from "%ui/ui_library.nut" import *

let comboBox = require("%ui/components/combobox.nut")
let slider = require("%ui/components/slider.nut")


const ADD_CAMERA_FOV_MIN = -25
const ADD_CAMERA_FOV_MAX = 45
const MAX_PROJECTILE_DISTANCE = 2000
const COOLDOWN_PERIOD = 2.0

let hangarHitcamShotResult = Watched(HitcamResult.EMPTY)
let isCooldown = Watched(false)

let setXrayModeQuery = ecs.SqQuery("setXrayModeQuery",
  { comps_rw = [ ["xray_context__isPictureInPicture", ecs.TYPE_BOOL] ]})

let vehImgSize = [hdpxi(300), hdpxi(180)]
let vehCardSize = [hdpxi(380), hdpxi(220)]

function resetVehicle() {
  selectVehParams.mutate(@(v) v.recreateVersionNo <- (v?.recreateVersionNo ?? 0) + 1)
}

function actionsOnClose() {
  resetVehicle()
  selectVehParams.mutate(@(v) v.isHitcamMode = false)
  setXrayModeQuery(@(_, comp) comp.xray_context__isPictureInPicture = true)
}

function close() {
  actionsOnClose()
}

let resetBtn = Regular(loc("hitcam/ResetBtn"), resetVehicle, { hotkeys = [[ "^J:X" ]] })

let backBtn = Regular(loc("BackBtn"), close, {
  hotkeys = [[ $"^{JB.B} | Esc", { description = loc("BackBtn") }]]
})


const colorNotPenetrated = Color(245, 30, 30)
const colorIneffective = Color(150, 150, 140)
const colorEffective = Color(30, 255, 30)
const colorPossibleEffective = Color(230, 230, 20)
const colorMiss = Color(150, 150, 140)

let resetCooldown = @() isCooldown.set(false)

function getCrosshairColor(hitResult) {
  if (hitResult == HitcamResult.EFFECTIVE)
    return colorEffective
  else if ( hitResult == HitcamResult.POSSIBLE_EFFECTIVE)
    return colorPossibleEffective
  else if ( hitResult == HitcamResult.NOT_PENETRATE || hitResult == HitcamResult.RICOCHET)
    return colorNotPenetrated
  else if ( hitResult == HitcamResult.INEFFECTIVE)
    return colorIneffective
  else if ( hitResult == HitcamResult.EMPTY)
    return colorMiss
  return colorMiss
}

const crosshairSize = hdpx(42)
let crosshair = Cursor({
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  size = const [crosshairSize, crosshairSize]
  hotspot = [crosshairSize/2, crosshairSize/2]
  children = [
    @() {
      watch = [hangarHitcamShotResult]
      rendObj = ROBJ_VECTOR_CANVAS
      size = const [crosshairSize, crosshairSize]
      color = getCrosshairColor(hangarHitcamShotResult.get())
      transform = { pivot = [0, 0] }
      commands = [
        [VECTOR_WIDTH, max(1.1, hdpx(1.2))],
        [VECTOR_LINE, 0, 50, 100, 50],
        [VECTOR_LINE, 50, 0, 50, 100],
      ]
    }
    function() {
      let watch = isCooldown
      return !isCooldown.get() ? { watch }
        : {
            watch
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            size = hdpx(30)
            children = mkCircularIndicator(COOLDOWN_PERIOD)
          }
    }
  ]
})


let getCurrentVehicleQuery = ecs.SqQuery("getCurrentVehicleQuery", {
  comps_ro = [["menu_vehicle_to_control", ecs.TYPE_EID]]
})


let slotBgColor = @(sf, isSelected)
  sf & S_HOVER ? squadSlotBgHoverColor
    : isSelected ? squadSlotBgActiveColor
    : squadSlotBgIdleColor

let comboBoxStyle = { style = { fillColor = panelBgColor, borderColor = defBdColor } }
let ammoImgSize = [hdpxi(60), hdpxi(60)]

function mkAmmo(ammo, gunName, gunTemplateId, weaponId, ammoIndex) {
  let { aType, slot } = ammo
  let isSelected = Computed(@() gunTemplateId == weaponId.get() && slot == ammoIndex.get())
  return watchElemState(@(sf) {
    watch = isSelected
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    padding = [0, bigPadding]
    rendObj = ROBJ_BOX
    fillColor = slotBgColor(sf, isSelected.get())
    borderWidth = isSelected.get() ? 1 : 0
    borderColor = defBdColor
    behavior = Behaviors.Button
    onClick = function() {
      weaponId.set(gunTemplateId)
      ammoIndex.set(slot)
    }
    children = [
      {
        size = FLEX_H
        vplace = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = aType == null ? gunName : loc($"{aType}/name/short")
      }
      {
        size = ammoImgSize
        rendObj = ROBJ_IMAGE
        imageHalign = ALIGN_RIGHT
        imageValign = ALIGN_CENTER
        image = ammo.icon.image
        color = ammo.icon.color
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  })
}

function onVehicleZoom(mouseEvent) {
  changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
}

function hitcamScene() {
  closeDmViewerMode()
  initWeaponList()
  setXrayModeQuery(@(_, comp) comp.xray_context__isPictureInPicture = false)
  set_xray_before_ui(true)

  let {
    hitcamVehiclesList, hitcamAmmoList, hitcamArmyId, hitcamVehicleId, weaponId, ammoIndex,
    shotDistance
  } = mkHitcamData()

  local lastCheckedFrame = null
  local previousPos = Point2(0, 0)
  function analyzeShot(event) {
    let frame = frameUpdateCounter.get()
    if (frame == lastCheckedFrame)
      return

    let screenPos = Point2(event.screenX, event.screenY)
    if (screenPos.x == previousPos.x && screenPos.y == previousPos.y)
      return

    previousPos = screenPos

    let target = getCurrentVehicleQuery(@(_, comp) comp.menu_vehicle_to_control) ?? ecs.INVALID_ENTITY_ID
    if (target == ecs.INVALID_ENTITY_ID)
      return

    let gunEid = selWeaponEid.get()
    let distance = shotDistance.get()
    if (ammoIndex.get() != null) {
      let result = hangar_simulate_shot(target, gunEid, ammoIndex.get(), distance, screenPos)
      hangarHitcamShotResult.set(result)
      lastCheckedFrame = frame
    }
  }

  function makeShot(x, y) {
    if (isCooldown.get())
      return

    if ((weaponId.get() ?? "") != "") {
      isCooldown.set(true)
      gui_scene.resetTimeout(COOLDOWN_PERIOD, resetCooldown)

      ecs.g_entity_mgr.broadcastEvent(CmdShootGunScreenSpace({
        gunTemplate = $"{weaponId.get()}+xray_activator"
        bulletNo = ammoIndex.get()
        distance = shotDistance.get()
        screenPos = Point2(x, y)
      }))
    }
  }

  let selectedInfoUi = {
    size = vehCardSize
    rendObj = ROBJ_SOLID
    color = defSlotBgColor
    borderWidth = 1
    children = [
      @() {
        watch = hitcamVehicleId
        size = FLEX
        children = iconByGameTemplate(hitcamVehicleId.get(), {
          width = vehImgSize[0]
          height = vehImgSize[1]
        })
      }
      @() {
        watch = hitcamArmyId
        hplace = ALIGN_RIGHT
        children = mkArmyIcon(hitcamArmyId.get())
      }
    ]
  }

  let armiesListUi = @() {
    watch = curArmiesList
    size = const [FLEX, hdpxi(40)]
    children = comboBox(hitcamArmyId, curArmiesList.get().map(@(v) [v, loc($"{v}/full")]),
      comboBoxStyle)
  }

  let vehiclesListUi = {
    size = const [FLEX, hdpxi(40)]
    children = comboBox(hitcamVehicleId, hitcamVehiclesList, comboBoxStyle)
  }

  let weaponsListUi = @() {
    watch = hitcamAmmoList
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    margin = [sidePadding, 0]
    children = hitcamAmmoList.get().map(function(weapon) {
      let { gunName, gunTemplateId, ammoData } = weapon
      return {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = ammoData.map(@(ammo) mkAmmo(ammo, gunName, gunTemplateId, weaponId, ammoIndex))
      }
    })
  }

  function changeDistance(delta) {
    let dist = clamp(shotDistance.get() + delta, 0, MAX_PROJECTILE_DISTANCE)
    shotDistance.set(dist)
  }

  let shotDistanceUi = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    hotkeys = [
      ["^J:LB", { description = loc("hitcam/distance_dec"), action = @() changeDistance(-50) }],
      ["^J:RB", { description = loc("hitcam/distance_inc"), action = @() changeDistance(50) }]
    ]
    children = [
      @() {
        watch = shotDistance
        children = txt(loc("hitcam/distance", { distance = shotDistance.get() })),
      }
      {
        size = const [FLEX, hdpxi(30)]
        children = slider.Horiz(shotDistance, { min = 0, max = MAX_PROJECTILE_DISTANCE })
      }
    ]
  }

  return {
    cursor = crosshair
    size = FLEX
    children = @() {
      watch = safeAreaBorders
      size = FLEX
      padding = safeAreaBorders.get()
      behavior = [DngBhv.MenuCameraControl, Behaviors.Button, Behaviors.TrackMouse]
      onMouseMove = analyzeShot
      onMouseWheel = onVehicleZoom
      onClick = @(event) makeShot(event.screenX, event.screenY)
      onDetach = function() {
        resetCooldown()
        gui_scene.clearTimer(resetCooldown)
      }
      hotkeys = [
        ["^J:RT", { description = loc("hitcam/shot"), action = function() {
          let curPos = get_mouse_cursor_pos()
          makeShot(curPos.x, curPos.y)
        }}]
      ]
      children = {
        cursor = normal
        size = [vehCardSize[0], FLEX]
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            margin = [sidePadding, 0]
            children = [backBtn, resetBtn]
          }
          selectedInfoUi
          armiesListUi
          vehiclesListUi
          weaponsListUi
          shotDistanceUi
        ]
      }
    }
  }
}


selectVehParams.subscribe(function(v) {
  if (v?.isHitcamMode ?? false)
    sceneWithCameraAdd(hitcamScene, "vehicles")
  else
    sceneWithCameraRemove(hitcamScene)
})
