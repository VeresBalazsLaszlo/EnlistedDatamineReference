import "%dngscripts/ecs.nut" as ecs
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let comps = freeze([
  {comp = "vehicle_view__isAutomaticTransmission", typ = ecs.TYPE_BOOL,def=false,name="isAutomaticTransmission"}
  {comp = "vehicle_view__gear",                    typ = ecs.TYPE_INT, def=0,    name="gear"}
  {comp = "vehicle_view__neutralGear",             typ = ecs.TYPE_INT, def=0,    name="neutralGear"}
  {comp = "vehicle_view__rpm",                     typ = ecs.TYPE_INT, def=0,    name="rpm"}
  {comp = "vehicle_view__cruiseControl",           typ = ecs.TYPE_INT, def=0,    name="cruiseControl"}
  {comp = "vehicle_view__speed",                   typ = ecs.TYPE_INT, def=0,    name="speed"}
])

let defValue = freeze(comps.reduce(function(res, b){
  res[b.name] <- b.def
  res.enabled <- false
  return res
} ,{}))

let watchedVehicle = mkEcsComputed({
  comps = comps.map(@(obj) [obj.comp, obj.typ, obj.name])
  comps_rq = ["vehicleView", "vehicleWithWatched"]
  comps_no = ["deadEntity"]
  tags = "ui"
})

let state = Computed(function() {
  let row = watchedVehicle.get()
  if (row == null)
    return defValue
  let res = {}
  comps.each(@(v) res[v.name] <- row[v.comp])
  res.enabled <- true
  return res
})

let exportState = watchedTable2TableOfWatched(state)

return exportState
