from "%ui/hud/style.nut" import HUD_TIPS_FAIL_TEXT_COLOR
from "%ui/hud/state/vehicle_state.nut" import inGroundVehicle
from "%ui/hud/state/vehicle_turret_state.nut" import mainTurretAmmo
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let showTip = Watched(true)

let hideTip = @() showTip.set(false)
let hideTipAfterDelay = @() gui_scene.resetTimeout(6, hideTip)

let tipAmmoCurDepleted = tipCmp({
  size = SIZE_TO_CONTENT
  text = loc("resupply/ammo_depleted", "Ammo depleted")
  style = { color = HUD_TIPS_FAIL_TEXT_COLOR, onAttach = hideTipAfterDelay }
})

let tipEngineerAmmoDepleted = tipCmp({
  size = SIZE_TO_CONTENT
  text = loc("resupply/engineer_ammo_depleted", "Ammunition replenish by engineer required")
  style = { color = HUD_TIPS_FAIL_TEXT_COLOR, onAttach = hideTipAfterDelay }
})


let tipAmmoTotalDepleted = tipCmp({
  size = SIZE_TO_CONTENT
  text = loc("resupply/ammo_total_depleted", "All ammo depleted")
  style = { color = HUD_TIPS_FAIL_TEXT_COLOR }
})

let isAmmoCurrentTurretDepleted =
  Computed(@() inGroundVehicle.get() && mainTurretAmmo.get()?.curAmmo != null && mainTurretAmmo.get().curAmmo <= 1
              && mainTurretAmmo.get()?.totalAmmo != null && mainTurretAmmo.get().totalAmmo <= 1)
let isAmmoTotalDepleted = Computed(@() inGroundVehicle.get() && mainTurretAmmo.get()?.ammoByBullet
  .findindex(@(ammo) ammo > 0) == null)

let canBeResuppliedOnPoint = Computed(@() mainTurretAmmo.get()?.canBeResuppliedOnPoint ?? true)
let canBeResuppliedByEngineer = Computed(@() mainTurretAmmo.get()?.canBeResuppliedByEngineer ?? false)

isAmmoCurrentTurretDepleted.subscribe( @(tip) tip ? showTip.set(true) : null)

function ammo_depleted(){
  let watch = [isAmmoCurrentTurretDepleted, isAmmoTotalDepleted, showTip, canBeResuppliedOnPoint,
    canBeResuppliedByEngineer]
  if (!isAmmoCurrentTurretDepleted.get())
    return { watch }

  if (!isAmmoTotalDepleted.get()){
    return {
      watch
      children = showTip.get() ?
        [
          canBeResuppliedOnPoint.get() ? tipAmmoCurDepleted : null
          canBeResuppliedByEngineer.get() ? tipEngineerAmmoDepleted : null
        ]
        : null
    }
  }

  return {
    watch
    children = [
      canBeResuppliedOnPoint.get() ? tipAmmoTotalDepleted : null
      canBeResuppliedByEngineer.get() ? tipEngineerAmmoDepleted : null
    ]
  }
}

return ammo_depleted