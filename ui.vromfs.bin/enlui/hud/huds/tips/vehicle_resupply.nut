import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/resupplyZones.nut" import heroActiveResupplyZonesEids
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/style.nut" import HUD_TIPS_FAIL_TEXT_COLOR
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  text = loc("resupply/tip")
  style = { color = HUD_TIPS_FAIL_TEXT_COLOR }
})

let isResupplyTipShown = Watched(false)

function resupplyTipTimer(){
  isResupplyTipShown.set(false)
}

const RESUPPLY_TIP_SHOW_TIME = 5

function showResupplyTip() {
  isResupplyTipShown.set(true)
  gui_scene.resetTimeout(RESUPPLY_TIP_SHOW_TIME, resupplyTipTimer)
}

let resupplyVehicleQuery = ecs.SqQuery("resupplyVehicleQuery", {comps_ro = [["turret_control__gunEids", ecs.TYPE_EID_LIST]] comps_rq = ["heroVehicle"]})

function isShootingDry() {
  local isAnyTurretShooting = false

  resupplyVehicleQuery(function(_eid, comp) {
    let gunEids = comp["turret_control__gunEids"].getAll()
    for (local turretNo = 0; turretNo < gunEids.len(); ++turretNo) {
      let gunEid = gunEids[turretNo]

      let isShooting = ecs.obsolete_dbg_get_comp_val(gunEid, "turret_input__shootFlag") ?? false
      isAnyTurretShooting = isAnyTurretShooting || isShooting

      let gunAmmo = ecs.obsolete_dbg_get_comp_val(gunEid, "gun__ammo", 0)
      let gunTotalAmmo = ecs.obsolete_dbg_get_comp_val(gunEid, "gun__totalAmmo", 0)
      if (isShooting && (gunAmmo + gunTotalAmmo) > 0) {
        isAnyTurretShooting = false
        return false
      }
    }
  })

  return isAnyTurretShooting
}

function trackComps() {
  if (heroActiveResupplyZonesEids.get().len() == 0)
    return
  if (isShootingDry())
    showResupplyTip()
}

ecs.register_es("turret_dry_shoot",
  { [["onInit", "onChange"]] = @(_evt, _eid, _comp) trackComps(),
  },
  {
    comps_track = [["turret_input__shootFlag", ecs.TYPE_BOOL]]
  }
)

return @() {
  flow = FLOW_HORIZONTAL
  watch = [isResupplyTipShown]
  children = isResupplyTipShown.get() ? tip : null
}
