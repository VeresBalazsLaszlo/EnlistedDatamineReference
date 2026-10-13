import "%ui/hud/huds/vehicle_change_indicator.nut" as indicatorCtor
from "%ui/hud/state/vehicle_change_seat_time.nut" import switchSeatsEndTime, switchSeatsTotalTime
from "%ui/ui_library.nut" import *

return indicatorCtor(switchSeatsEndTime, switchSeatsTotalTime, loc("vehicle/hint/change_seats", "Seat change"))