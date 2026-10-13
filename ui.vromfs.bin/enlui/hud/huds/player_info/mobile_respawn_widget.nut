import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/huds/player_info/style.nut" import blurBack
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/hud/huds/player_info/vehicle_weapon_widget.nut" import wWidth, wHeight, weaponWidgetAnims
from "%ui/ui_library.nut" import *

let mobileRespawn = mkEcsComputed({
  comps = [
    ["mobile_respawn__occupiedSeats", ecs.TYPE_INT],
    ["ownedByPlayer", ecs.TYPE_EID],
  ]
  comps_rq = ["mobileRespawnTag", "vehicleWithWatched"]
  tags = "ui"
})


let mobileRespawnOccupiedSeats = Computed(function() {
  let v = mobileRespawn.get()
  if (v == null || v.ownedByPlayer != localPlayerEid.get())
    return null
  return v.mobile_respawn__occupiedSeats
})

let iconSize = (wHeight * 0.8).tointeger()

let passengersText = {
  rendObj = ROBJ_TEXT
  text = loc("hud/mobile_respawn_passengers")
  vplace = ALIGN_CENTER
}

function mobileRespawnWidget(occupiedSeats) {
  let icon = {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = [iconSize, iconSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/skin#enlisted_unithelmet.svg:{iconSize}:{iconSize}")
    color = Color(255, 255, 255, occupiedSeats == 0 ? 120 : 255)
  }

  let countText = {
    rendObj = ROBJ_TEXT
    text = occupiedSeats
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
  }

  return {
    size = [wWidth, wHeight]
    animations = weaponWidgetAnims
    children = {
      size = [wWidth, wHeight]
      clipChildren = true
      children = [
        blurBack
        passengersText
        icon
        countText
      ]
    }
  }
}

return {
  mobileRespawnWidget
  mobileRespawnOccupiedSeats
}