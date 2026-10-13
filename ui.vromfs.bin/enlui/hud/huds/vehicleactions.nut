import "%ui/hud/state/vehicle_seats.nut" as vehicleSeats
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/cockpit.nut" import canChangeCockpitView, isBomberCockpitView
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp, mkInputHintBlock, defTipAnimations
from "%ui/hud/state/vehicle_state.nut" import inVehicle, inPlane, isPassengerInMobileRespawn, isPlayerCanExit, isVehicleAlive
from "%ui/hud/state/hero_in_vehicle_state.nut" import isInHatch, canHoldWeapon, isHoldingGunPassenger
from "%ui/hud/state/binocular.nut" import isBinocularMode, hasHeroBinocular
from "%ui/ui_library.nut" import *

let allowHints = Computed(@() controlledHeroEid.get() == watchedHeroEid.get()
  && controlledHeroEid.get() != ecs.INVALID_ENTITY_ID
  && isVehicleAlive.get()
  && isAlive.get())

let showExitAloneAction = Computed(@()
  allowHints.get()
  && inVehicle.get()
  && isPlayerCanExit.get()
  && !inPlane.get()
  && !isInHatch.get()
  && !isPassengerInMobileRespawn.get())

let showToggleHoldGunMode = Computed(@() canHoldWeapon.get() && !isHoldingGunPassenger.get())
let showToggleHoldGunModeCancel = Computed(@() isHoldingGunPassenger.get())
let showUseBinocular = Computed(@() canHoldWeapon.get() && hasHeroBinocular.get() && !isBinocularMode.get())

let canHatch = Computed(function() {
  if (!allowHints.get())
    return false

  let ownerEid = controlledHeroEid.get()
  let seat = vehicleSeats.get().data.findvalue(@(s) s?.owner.eid == ownerEid)
  return (seat?.seat.hatchNodes.len() ?? 0) > 0
})

function exitVehicleAlone() {
  let watch = showExitAloneAction
  if (!showExitAloneAction.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/leaveVehicleAlone")
      inputId = "Human.LeaveVehicleAlone"
    })
  }
}

function getOutOfTheTankHatch() {
  let watch = canHatch
  if (!canHatch.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("watchFromTheTankHatch")
      inputId = "Human.ToggleHatch"
    })
  }
}

let nextViewTip = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  transform = { pivot = [0.5,0.5] }
  animations = defTipAnimations

  children = [
    mkInputHintBlock("Vehicle.PrevCockpitView")
    tipCmp({
      inputId = "Vehicle.NextCockpitView"
      text = loc("lookTheOtherWay")
      animations = []
    })
  ]
}

function nextView() {
  let watch = [canChangeCockpitView, allowHints, isBomberCockpitView]
  if (!canChangeCockpitView.get() || !allowHints.get() || isBomberCockpitView.get())
    return { watch }

  return {
    watch
    children = nextViewTip
  }
}

function toggleHoldGunMode() {
  let watch = showToggleHoldGunMode
  if (!showToggleHoldGunMode.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/toggleHoldGunMode")
      inputId = "Human.ToggleHoldGunMode"
    })
  }
}

function toggleHoldGunModeCancel() {
  let watch = showToggleHoldGunModeCancel
  if (!showToggleHoldGunModeCancel.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/toggleHoldGunModeCancel")
      inputId = "Human.ToggleHoldGunMode"
    })
  }
}

function useBinocular() {
  let watch = showUseBinocular
  if (!showUseBinocular.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/useBinocular")
      inputId = "Human.UseBinocular"
    })
  }
}

return [
  exitVehicleAlone
  getOutOfTheTankHatch
  nextView
  toggleHoldGunMode
  toggleHoldGunModeCancel
  useBinocular
]