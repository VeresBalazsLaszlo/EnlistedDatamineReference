from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/ui_library.nut" import *

let allowedBySquads = Computed(@()
  squadsCfgById.get().map(@(squadsCfg)
    squadsCfg.map(function(squad) {
      let res = {}
      let squadVehicle = squad?.startVehicle ?? "" 
      if (squadVehicle != "")
        res[squadVehicle] <- true
      foreach (vehicle in squad?.allowedVehicles ?? [])
        res[vehicle] <- true
      return res
    })
  ))

return allowedBySquads
