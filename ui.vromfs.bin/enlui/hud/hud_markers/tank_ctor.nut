import "%ui/hud/components/teammateName.nut" as teammateName
from "%ui/components/decoratorsPresentation.nut" import frameNick
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "dagor.math" import Point2
from "%ui/hud/state/vehicle_state.nut" import controlledVehicleEid, inPlane, inVehicle
from "%ui/hud/state/vehicle_markers.nut" import tank_markers_Set, tank_markers_GetWatched
from "%ui/hud/state/vehicle_maintenance_state.nut" import hasRepairKit
from "%ui/style/unit_colors.nut" import HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER
from "%ui/ui_library.nut" import *

const MIN_HUD_REPAIR_ICON_MAX_DIST = 40
const REPAIR_ICON_MAX_DIST = 50
const MIN_HUD_ICON_MAX_DIST = 200
const ICON_MAX_DIST = 1000

let unitIconSize = [hdpxi(10), hdpxi(10)]
let repairIconSize = [hdpxi(32), hdpxi(32)]

let tank_unit_outer = Picture($"ui/skin#tank_unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}")
let tank_unit_inner = Picture($"ui/skin#tank_unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}")
let repairIco = Picture($"ui/skin#item_repair_kit.svg:{repairIconSize[0]}:{repairIconSize[1]}")

let mkIcon = memoize(@(colors) {
  rendObj = ROBJ_IMAGE
  color = colors.outer
  image = tank_unit_outer
  size = unitIconSize

  children = {
    rendObj = ROBJ_IMAGE
    color = colors.inner
    image = tank_unit_inner
    size = unitIconSize
  }
  markerFlags = DngBhv.MARKER_SHOW_ONLY_IN_VIEWPORT
})

let mkRepairIcon = memoize(@(colors) {
  rendObj = ROBJ_IMAGE
  color = colors.outer
  image = repairIco
  size = repairIconSize
  pos = const [0, fsh(2)]
  children = {
    rendObj = ROBJ_IMAGE
    color = colors.inner
    image = repairIco
    size = repairIconSize
  }
})

let getIconColors = memoize(@(hasSquadmates, hasGroupmates)
  hasSquadmates
    ? {inner=HUD_COLOR_SQUADMATE_INNER,     outer=HUD_COLOR_SQUADMATE_OUTER}
    : hasGroupmates
      ? {inner=HUD_COLOR_GROUPMATE_BOT_INNER, outer=HUD_COLOR_GROUPMATE_BOT_OUTER}
      : {inner=HUD_COLOR_TEAMMATE_INNER,      outer=HUD_COLOR_TEAMMATE_OUTER}
)

let nameOffset = [fsh(0), fsh(10), -fsh(10)]

function mkNames(eid, names) {
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    pos = const [0, -fsh(2)]
    gap = hdpx(5)
    children = names.slice(0, 3).map(@(name, index)
      teammateName(eid, name, HUD_COLOR_TEAMMATE_INNER)
        ?.__update({pos=[nameOffset[index], 0]})
    )
  }
}
let opRangeX = Point2(0.25, 0.35)
let opRangeY = Point2(0.25, 0.75)
let opRangeX_hardcore = Point2(0.125, 0.145)
let zeroPoint = Point2(0, 0)
let sz = [0,0]

function tank(eid, repairMarker){
  let infoState = tank_markers_GetWatched(eid)
  let watch = [infoState, forcedMinimalHud, controlledVehicleEid, inPlane, hasRepairKit, inVehicle]
  return function(){
    
    let row = infoState.get()
    if (row == null || controlledVehicleEid.get() == eid)
      return {watch}
    let isEmpty = row.vehicle_marker_ui__isEmpty
    let repairRequired = row.repairable__repairRequired
    let hasSquadmates = row.vehicle_marker_ui__hasSquadmates
    let hasGroupmates = row.vehicle_marker_ui__hasGroupmates
    let nicks = row.vehicle_marker_ui__gropmateNames ?? []
    let nickFrames = row.vehicle_marker_ui__gropmateNickFrames
    let showNames = nicks.len() > 0
    
    let namesComp = showNames
      ? mkNames(eid, nicks.map(@(name, i) frameNick(remap_nick(name), nickFrames?[i])))
      : null
    let minHud = forcedMinimalHud.get()
    let maxRepairIconDistance = minHud ? MIN_HUD_REPAIR_ICON_MAX_DIST : REPAIR_ICON_MAX_DIST
    let maxIconDistance = minHud && !inPlane.get() ? MIN_HUD_ICON_MAX_DIST : ICON_MAX_DIST
    let minDistance = !repairMarker && hasRepairKit.get() && repairRequired ? maxRepairIconDistance : 0
    let maxDistance = !repairMarker ? maxIconDistance : maxRepairIconDistance
    let ico = isEmpty
      ? null
      : repairMarker && hasRepairKit.get() && repairRequired && !inVehicle.get()
        ? mkRepairIcon(getIconColors(hasSquadmates, hasGroupmates))
        : mkIcon(getIconColors(hasSquadmates, hasGroupmates))
    return {
      data = {
        eid
        distScaleFactor = 0.5
        clampToBorder = false
        yOffs = 0.25
        opacityRangeX = showNames && !minHud
          ? zeroPoint
          : minHud ? opRangeX_hardcore : opRangeX
        opacityRangeY = showNames && !minHud ? zeroPoint : opRangeY
        minDistance
        maxDistance
      }

      sortOrder = eid
      watch
      transform = true

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      size = sz 
      children = [namesComp, ico]
    }
  }
}

let memoizedMapRepair = mkMemoizedMapSet(@(eid) tank(eid, true))
let memoizedMap = mkMemoizedMapSet(@(eid) tank(eid, false))

return {
  tank_ctor = freeze({
    watch = tank_markers_Set
    ctor = function() {
      let v = tank_markers_Set.get()
      return memoizedMap(v).values().extend(memoizedMapRepair(v).values())
    }
  })
}