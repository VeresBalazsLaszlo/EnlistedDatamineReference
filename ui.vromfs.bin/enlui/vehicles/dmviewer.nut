import "%ui/soldiers/model/config/upgradesConfig.nut" as upgrades
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/colorize.nut" as colorize
import "%ui/components/faComp.nut" as faComp
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "dagor.math" import Point2
from "%ui/vehicles/vehiclesListState.nut" import viewVehicle, selectVehParams, CAN_USE
from "%ui/soldiers/model/collectWeaponData.nut" import getVehicleData, applyUpgrades
from "%ui/vehicles/physSpecs.nut" import specsCache, getItemUpgrade, getItemSpec, requireItemSpec
from "%ui/vehicles/dmViewerArmor.nut" import getArmorClassLocName, getArmorPartDesc
from "%ui/vehicles/dmViewerXray.nut" import getXrayPartDesc
from "%ui/state/queueState.nut" import isInQueue
from "%ui/state/appState.nut" import isInBattleState
from "%ui/style/cursors.nut" import setTooltip
from "%ui/style/designConst.nut" import midPadding, listCtors, hoverBgColor, defBgBtn, defBgActiveBtn
from "%ui/components/textButton.nut" import Regular
from "%ui/soldiers/components/itemDetailsPkg.nut" import blur
from "%ui/vehicles/customizeState.nut" import viewVehCustSchemes
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/featureFlags.nut" import hasHitCamera
from "%ui/control/active_controls.nut" import isGamepad
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let dmViewerAvailable = { tank = true, truck = true, jeep = true }

enum MODE {
  VIEW_NONE = 0
  VIEW_ARMOR = 1
  VIEW_XRAY = 2
}

let mods = [
  MODE.VIEW_NONE,
  MODE.VIEW_ARMOR,
  MODE.VIEW_XRAY
]

let curViewModeIdx = Watched(0)

let hitcamButtonUi = @() {
  watch = hasHitCamera
  size = FLEX_H
  children = !hasHitCamera.get() ? null
    : Regular(loc("hitcam/HITCAM"),
        @() selectVehParams.mutate(@(v) v.isHitcamMode = true),
        {
          size = FLEX_H
          margin = [0,0,midPadding,0]
          hotkeys = [["^J:RT"]]
        }
      )
}

function mkCustomizeButton(curVehicle) {
  let { guid = "" } = curVehicle
  let { flags = 0 } = curVehicle?.status
  return flags != CAN_USE && guid == "" ? null
    : Regular(loc("customizeVehicle"),
        @() selectVehParams.mutate(@(v) v.isCustomMode = true),
        {
          size = FLEX_H
          hotkeys = [["^J:LT"]]
          margin = [0,0,midPadding,0]
        })
}

let isDebugMode = mkWatched(persist, "isDebugMode", false)
const debugTextColor = Color(255, 128, 0)
let listTxtColor = listCtors.txtColor

let armorAnalyzer = mkEcsComputed({
  comps = [
    ["armor_analyzer__target", ecs.TYPE_EID],
    ["armor_analyzer__mode", ecs.TYPE_INT],
    ["armor_analyzer__partName", ecs.TYPE_STRING, ""],
    ["armor_analyzer__thickness", ecs.TYPE_FLOAT, 0.0],
    ["armor_analyzer__normalAngle", ecs.TYPE_FLOAT, 0.0],
    ["armor_analyzer__angle", ecs.TYPE_FLOAT, 0.0],
  ]
  comps_no = ["armorAnalyzerForDecor"]
})

let dmViewerTarget = Computed(@() armorAnalyzer.get()?.armor_analyzer__target ?? ecs.INVALID_ENTITY_ID)
let dmViewerMode = Computed(@() armorAnalyzer.get()?.armor_analyzer__mode ?? MODE.VIEW_NONE)

let partName = Computed(@() armorAnalyzer.get()?.armor_analyzer__partName ?? "")
let armorParams = Computed(function() {
  let state = armorAnalyzer.get()
  return {
    thickness = state?.armor_analyzer__thickness ?? 0.0
    normalAngle = state?.armor_analyzer__normalAngle ?? 0.0
    viewingAngle = state?.armor_analyzer__angle ?? 0.0
  }
})

let canUseDmViewer = @(vehicle) vehicle?.itemsubtype in dmViewerAvailable

let isDmViewerEnabled = Computed(@() dmViewerMode.get() != MODE.VIEW_NONE && dmViewerTarget.get() != ecs.INVALID_ENTITY_ID)

let dmBlkPath = Computed(function() {
  if (!isDmViewerEnabled.get() || (viewVehicle.get()?.gametemplate ?? "") == "")
    return ""
  let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(viewVehicle.get().gametemplate)
  return template?.getCompValNullable("damage_model__blk") ?? ""
})

let vehicleUpgradedData = Computed(function() {
  if (viewVehicle.get() == null || dmViewerMode.get() == MODE.VIEW_NONE)
    return null

  let { upgradesId = null, upgradeIdx = 0, gametemplate = null } = viewVehicle.get()
  let itemData = gametemplate != null ? getVehicleData(gametemplate) : null
  if (itemData == null)
    return null

  let upgradesCurWatch = getItemUpgrade(upgrades.get(), upgradesId, upgradeIdx)
  let specs = getItemSpec(specsCache.get(), viewVehicle.get())
  itemData.__update(specs)
  return applyUpgrades(itemData, upgradesCurWatch)
})

viewVehicle.subscribe(requireItemSpec)

let cacheArmorClass = {}
let cacheXrayDesc = {}

function resetCache() {
  cacheArmorClass.clear()
  cacheXrayDesc.clear()
}
subscribeList(resetCache, dmBlkPath, vehicleUpgradedData)

let partDebug = Computed(@() isDebugMode.get() ? colorize(debugTextColor, $"DEBUG: {partName.get()}") : null)

let tooltipTextArmor = Computed(function() {
  if (dmBlkPath.get() == "" || partName.get() == "")
    return null
  if (cacheArmorClass?[partName.get()] == null)
    cacheArmorClass[partName.get()] <- getArmorClassLocName(dmBlkPath.get(), partName.get())
  return getArmorPartDesc(cacheArmorClass[partName.get()], armorParams.get(), partDebug.get())
})

let tooltipTextXray = Computed(function() {
  if (dmBlkPath.get() == "" || partName.get() == "")
    return null
  if (cacheXrayDesc?[partName.get()] == null)
    cacheXrayDesc[partName.get()] <- getXrayPartDesc(viewVehicle.get(), vehicleUpgradedData.get(),
      dmBlkPath.get(), partName.get(), partDebug.get())
  return cacheXrayDesc[partName.get()]
})

let mkTooltipComp = @(text) tooltipCtor({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(800)
  fontSize = hdpx(20)
  color = Color(160,160,160)
  text
})

let updateTooltip = @(text) setTooltip(text != null ? mkTooltipComp(text) : null)

function updateTooltipSubscriptions() {
  tooltipTextArmor.unsubscribe(updateTooltip)
  tooltipTextXray.unsubscribe(updateTooltip)
  updateTooltip(null)
  if (dmViewerTarget.get() != ecs.INVALID_ENTITY_ID) {
    if (dmViewerMode.get() == MODE.VIEW_ARMOR)
      tooltipTextArmor.subscribe(updateTooltip)
    else if (dmViewerMode.get() == MODE.VIEW_XRAY)
      tooltipTextXray.subscribe(updateTooltip)
  }
}

subscribeList(updateTooltipSubscriptions, dmViewerTarget, dmViewerMode)

let setDmViewerTargetQuery = ecs.SqQuery("setDmViewerTargetQuery",
  { comps_rw = [ ["armor_analyzer__target", ecs.TYPE_EID] ], comps_no = ["armorAnalyzerForDecor"]})

function setDmViewerTarget(targetEid) {
  setDmViewerTargetQuery.perform(function(_eid, comp) {
    comp["armor_analyzer__target"] = targetEid
  })
}

let setDmViewerModeQuery = ecs.SqQuery("setDmViewerModeQuery",
  { comps_rw = [ ["armor_analyzer__mode", ecs.TYPE_INT] ] })

function setDmViewerMode(mode) {
  setDmViewerModeQuery.perform(function(_eid, comp) {
    comp["armor_analyzer__mode"] = mode
  })
}

let setDmViewerScreenPosQuery = ecs.SqQuery("setDmViewerScreenPosQuery",
  { comps_rw = [ ["armor_analyzer__screenPos", ecs.TYPE_POINT2] ] })

function onDmViewerMouseMove(mouseEvent) {
  setDmViewerScreenPosQuery.perform(function(_eid, comp) {
    comp["armor_analyzer__screenPos"] = Point2(mouseEvent.screenX, mouseEvent.screenY)
  })
}

curViewModeIdx.subscribe(@(v) setDmViewerMode(v))

let modeTabs = [{
    id = MODE.VIEW_ARMOR
    locId = "vehicle/inspect/mode/armor"
    tooltipLocId = "vehicle/inspect/mode/armor/tooltip"
  }, {
    id = MODE.VIEW_XRAY
    locId = "vehicle/inspect/mode/xray"
    tooltipLocId = "vehicle/inspect/mode/xray/tooltip"
  }]

let eyeButtonBlock = watchElemState(@(sf) {
  rendObj = ROBJ_SOLID
  watch = dmViewerMode
  behavior = Behaviors.Button
  size = FLEX_V
  valign = ALIGN_CENTER
  padding = const [0, hdpx(10)]
  onClick = @() setDmViewerMode(MODE.VIEW_NONE)
  onHover = @(on) setTooltip(on ? loc("vehicle/inspect/mode/off/tooltip") : null)
  color = sf & S_HOVER ? hoverBgColor
    : dmViewerMode.get() <= 0 ? defBgActiveBtn
    : defBgBtn
  children = faComp("eye-slash", {
    fontSize = hdpx(30)
    color = listTxtColor(sf)
  })
})

function changeViewMods(idx) {
  let newIdx = curViewModeIdx.get() + idx
  if (newIdx >= 0 && newIdx < mods.len())
    curViewModeIdx.set(newIdx)
}

let dmViewerPanelUi = @() canUseDmViewer(viewVehicle.get())
  ? {
      watch = [viewVehicle, isDebugMode, dmBlkPath]
      size = SIZE_TO_CONTENT
      vplace = ALIGN_BOTTOM
      flow = FLOW_VERTICAL
      gap = midPadding
      children = [
        !isDebugMode.get() || dmBlkPath.get() == ""
          ? null
          : {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              hplace = ALIGN_CENTER
              color = debugTextColor
              fontSize = hdpx(20)
              text = $"DEBUG: Damage Model: {dmBlkPath.get()}"
            }
        function() {
          let children = [eyeButtonBlock].extend(modeTabs.map(function(v) {
            let id = v.id
            let isCurrent = dmViewerMode.get() == id
            return Regular(loc(v.locId), @() setDmViewerMode(id), {
              minWidth = hdpx(130)
              style = {
                defBgColor = isCurrent ? defBgActiveBtn : defBgBtn
                borderWidth = 0
              }
              onHover = @(on) setTooltip(on ? loc(v.tooltipLocId) : null)
            })
          }))
          if (isGamepad.get()) {
            children.insert(0, mkHotkey("^J:LB", @() changeViewMods(-1)))
            children.append(mkHotkey("^J:RB", @() changeViewMods(1)))
          }
          return blur({
            watch = [viewVehCustSchemes, viewVehicle, dmViewerMode, isGamepad]
            hplace = ALIGN_CENTER
            padding = midPadding
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            children = [
              viewVehCustSchemes.get() != null
                ? mkCustomizeButton(viewVehicle.get())
                : null
              hitcamButtonUi
              {
                flow = FLOW_HORIZONTAL
                valign = ALIGN_CENTER
                gap = midPadding
                children
              }
            ]
          })
        }
      ]
    }
  : {
      watch = [viewVehCustSchemes, viewVehicle]
      vplace = ALIGN_BOTTOM
      children = viewVehCustSchemes.get() != null
        ? mkCustomizeButton(viewVehicle.get())
        : null
    }

let closeDmViewerMode = @() setDmViewerMode(MODE.VIEW_NONE)

viewVehicle.subscribe(function(vehicle) {
  if (!canUseDmViewer(vehicle))
    closeDmViewerMode()
})
isInQueue.subscribe(function(val) {
  if (!val) 
    closeDmViewerMode()
})
isInBattleState.subscribe(function(val) {
  if (val) 
    closeDmViewerMode()
})

console_register_command(function () {
    resetCache()
    isDebugMode.set(!isDebugMode.get())
  }, "dmViewer.toggleDebugMode")

return {
  isDmViewerEnabled
  setDmViewerTarget
  dmViewerPanelUi
  onDmViewerMouseMove
  closeDmViewerMode
}
