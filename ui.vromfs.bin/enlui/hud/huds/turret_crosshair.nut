import "%sqstd/ecs.nut" as ecs
from "%ui/hud/state/vehicle_state.nut" import controlledVehicleEid, inPlane
from "%ui/hud/state/vehicle_turret_state.nut" import mainTurretEid, firstInputTurretEid
from "%ui/ui_library.nut" import *
from "weapons.behaviors" import TurretCrosshair

const lineWidth = max(1.1, hdpx(1.2))
let forbid = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = fsh(1.5)
  commands = [
    [VECTOR_WIDTH, lineWidth],
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0],
  ]
  color = Color(20, 80, 220, 80)

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}


function hair(color, line, width=null) {
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    size = FLEX
    color = color
    commands = [
      [VECTOR_WIDTH, width ?? lineWidth],
      line
    ]
  }
}

const w = fsh(2)
const h = fsh(2)
let crossHairSize = [2*w, 2*h]
const chPart = 35
let hair0 = @(color, width=null) hair(color, [VECTOR_LINE, 0, 50, chPart, 50], width)
let hair1 = @(color, width=null) hair(color, [VECTOR_LINE, 100-chPart, 50, 100, 50], width)
let hair2 = @(color, width=null) hair(color, [VECTOR_LINE, 50, 100-chPart, 50, 100], width)

const colorNotPenetrated = Color(245, 30, 30)
const colorInEffective = Color(150, 150, 140)
const colorEffective = Color(30, 255, 30)
const colorPossibleEffective = Color(230, 230, 20)
const colorShadow = Color(0,0,0,100)
let mkBlockImpl = @(color, pos = null, width=null) {size = crossHairSize, children = [hair0(color, width), hair1(color, width), hair2(color, width)], pos=pos}
let mkBlock = @(xhairMode, color) {size = crossHairSize, xhairMode = xhairMode, children = [mkBlockImpl(color), mkBlockImpl(colorShadow, [0, hdpx(1)], lineWidth*2)]}

let aimNotPenetratedBlock = mkBlock("aimNotPenetrated", colorNotPenetrated)
let aimIneffectiveBlock = mkBlock("aimIneffective", colorInEffective)
let aimEffectiveBlock = mkBlock("aimEffective", colorEffective)
let aimPossibleEffectiveBlock = mkBlock("aimPossibleEffective", colorPossibleEffective)
let seatHideCrosshair = Watched(false)

ecs.register_es("seat_crosshair_enbled_es",
  {
    [["onInit", "onChange"]] = @(_, comp) seatHideCrosshair.set(ecs.obsolete_dbg_get_comp_val(comp.human_vehicle__occupiedSeatEid, "seat__hideCrosshair") == null ? false : true)
  },
  {
    comps_track = [["human_vehicle__occupiedSeatEid", ecs.TYPE_EID]]
    comps_rq = ["hero"]
  }
)

let forbidBlock = {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  xhairMode = "teammate"
  children = [
    forbid
  ]
}

function crosshair() {
  return {
    size = crossHairSize
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = TurretCrosshair
    transform = true

    watch = [controlledVehicleEid, inPlane, mainTurretEid, firstInputTurretEid]
    eid = controlledVehicleEid.get()
    
    
    turretEid = inPlane.get() || firstInputTurretEid.get() != ecs.INVALID_ENTITY_ID
      ? firstInputTurretEid.get()
      : mainTurretEid.get()

    children = [
      forbidBlock
      aimNotPenetratedBlock
      aimIneffectiveBlock
      aimEffectiveBlock
      aimPossibleEffectiveBlock
    ]
  }
}


function root() {
  return {
    watch = seatHideCrosshair
    size = const [sw(100), sh(100)]
    children = seatHideCrosshair.get() ? null : crosshair
  }
}


return root
