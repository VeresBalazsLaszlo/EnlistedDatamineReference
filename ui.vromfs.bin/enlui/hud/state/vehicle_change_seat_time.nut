import "%dngscripts/ecs.nut" as ecs
from "net" import get_sync_time
from "dasevents" import EventOnStartVehicleChangeSeat, EventOnSeatOwnersChanged
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "%ui/ui_library.nut" import *

const defValue = {
  switchSeatsEndTime = 0.0
  switchSeatsTotalTime = 0.0
}
let switchSeatsTimeState = mkWatched(persist, "switchSeatsTimeState", defValue)
let { switchSeatsEndTime, switchSeatsTotalTime } = watchedTable2TableOfWatched(switchSeatsTimeState)

ecs.register_es("vehicle_seats_on_chage_seat_ui_es",
  {
    [EventOnStartVehicleChangeSeat] = function(evt, _eid, _comp) {
      let endTime = evt.endTime
      let totalTime = max(0, endTime - get_sync_time())
      switchSeatsTimeState.set({
        switchSeatsEndTime = endTime
        switchSeatsTotalTime = totalTime
      })
    },
    [["onDestroy", EventOnSeatOwnersChanged]] = function() {
      switchSeatsTimeState.set(defValue)
    }
  },
  {
    comps_rq = ["heroVehicle"]
  }
)

return {switchSeatsEndTime, switchSeatsTotalTime}