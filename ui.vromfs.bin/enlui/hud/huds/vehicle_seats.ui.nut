import "%ui/hud/style.nut" as style
import "%ui/hud/state/vehicle_seats.nut" as vehicleSeatsState
import "%ui/hud/state/getFramedNickByEid.nut" as getFramedNickByEid
import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/state/vehicle_state.nut" import inPlane
from "%ui/hud/state/plane_hud_state.nut" import planeSeatNext
from "%ui/hud/state/squad_members.nut" import watchedHeroSquadMembers
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/components/controlHudHint.nut" import controlHudHint
from "%ui/ui_library.nut" import *
from "math" import min

let NORMAL_HINT_SIZE = [hdpx(20), fontH(100)]
let GAMEPAD_HINT_SIZE = [hdpx(36), fontH(120)]

const colorBlue = Color(150, 160, 255, 180)
const maxSeatsCountToShow = 10

let memberTextColor = @(member) (member.eid == watchedHeroEid.get()) ? style.SUCCESS_TEXT_COLOR
  : member.isAlive ? style.DEFAULT_TEXT_COLOR
  : style.DEAD_TEXT_COLOR

let mkText = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontSub)

function seatMember(seatDesc) {
  let { owner, seat, order } = seatDesc
  let locName = seat?.locName ?? (seat?.name ? $"vehicle_seats/{seat.name}" : null)
  let place = locName ? $"[{loc(locName)}]: " : ""
  if (owner == null)
    return mkText(place, style.DEFAULT_TEXT_COLOR)

  let member = watchedHeroSquadMembers.get().findvalue(@(v) v.eid == owner.eid)
  local name = member?.name
  local color = member?.eid ? memberTextColor(member) : style.DEFAULT_TEXT_COLOR
  if (member == null) {
    if (owner.isPlayer)
      name = getFramedNickByEid(owner.player) ?? getFramedNickByEid(owner.eid)
    else if (owner.eid != ecs.INVALID_ENTITY_ID)
      name = ecs.obsolete_dbg_get_comp_val(owner.eid, "name") ?? "<Unknown>"
    if (name != null)
      color = colorBlue
  }
  name = name ?? (order.canPlaceManually ? loc("vehicle_seats/free_seat") : "...")
  return mkText($"{place}{name}", color)
}

function seatHint(seat, isGpad) {
  let size = isGpad ? GAMEPAD_HINT_SIZE : NORMAL_HINT_SIZE
  return seat.order.canPlaceManually
    ? controlHudHint({
        id = (inPlane.get() && isGpad) ?
              planeSeatNext.get() == seat.order.seatNo ?
              $"Plane.SeatNext" : "" : seat.order.seatNo < 9 ?
              $"Human.Seat0{seat.order.seatNo + 1}" : $"Human.Seat{seat.order.seatNo + 1}"
        size
        hplace = ALIGN_RIGHT
        text_params = fontSub
      })
    : {
        size = [size[0], SIZE_TO_CONTENT]
      }
}

let mkSeat = @(seat, isGpad) {
  rendObj = ROBJ_WORLD_BLUR
  flow = FLOW_HORIZONTAL
  padding = const [hdpx(5), hdpx(2)]
  gap = hdpx(5)
  color = Color(220, 220, 220, 220)
  children = [
    seatHint(seat, isGpad)
    seatMember(seat)
  ]
}

let hasVehicleSeats = Computed(@() vehicleSeatsState.get().data.len() > 0)

function vehicleSeats() {
  
  let watch = [ hasVehicleSeats, watchedHeroSquadMembers, vehicleSeatsState,
    watchedHeroEid, isGamepad, inPlane, planeSeatNext ]
  if (!hasVehicleSeats.get())
    return { watch }

  let seatsToShow = min(vehicleSeatsState.get().data.len(), maxSeatsCountToShow)
  return {
    watch
    flow = FLOW_VERTICAL
    size = FLEX_H
    hplace = ALIGN_RIGHT
    padding = fsh(1)
    children = vehicleSeatsState.get().data.slice(0, seatsToShow).map(@(seat) mkSeat(seat, isGamepad.get()))
  }
}

return vehicleSeats
