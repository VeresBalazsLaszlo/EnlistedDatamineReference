from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

let vehicleGroupLimit = Watched(get_setting_by_blk_path("gameplay/limit_vehicle_by_group") ?? false)

return vehicleGroupLimit
