import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *
from "%enlSqGlob/vehicle_spawn_comps.nut" import vehicleStringListComps, vehicleFloatListComps,
  vehiclePoint3ListComps
from "%enlSqGlob/vehDecorUtils.nut" import skinDetailsToViewParams


let createVehicleExcludes = {
  animchar__objTexReplace = {}
  animchar__objTexSet = {}
}

function createVehicle(
  template, transform, callback = null, customization = null, extraTemplates = []
) {
  if (template == null)
    return ecs.INVALID_ENTITY_ID

  let updateParams = {}

  local {
    animchar__objTexReplace = null,
    animchar__objTexSet = null,
    details = ""
  } = customization

  let { age, scale, rotation } = skinDetailsToViewParams(details)
  updateParams.vehicle_camo_condition <- age
  updateParams.vehicle_camo_scale <- scale
  updateParams.vehicle_camo_rotation <- rotation

  if (animchar__objTexReplace != null)
    updateParams["animchar__objTexReplace"] <- animchar__objTexReplace
  if (animchar__objTexSet != null)
    updateParams["animchar__objTexSet"] <- animchar__objTexSet
  else if (animchar__objTexReplace != null)
    updateParams["animchar__objTexSet"] <- {}

  if (customization != null) {
    foreach (k, v in customization) {
      if (k in createVehicleExcludes)
        continue
      local list
      if (k in vehicleStringListComps)
        list = ecs.CompStringList()
      else if (k in vehicleFloatListComps)
        list = ecs.CompFloatList()
      else if (k in vehiclePoint3ListComps)
        list = ecs.CompPoint3List()
      else {
        if (typeof(v) == "array")
          updateParams[k] <- [v, ecs.TYPE_ARRAY]
        else if (typeof(v) == "table")
          updateParams[k] <- [v, ecs.TYPE_OBJECT]
        else
          updateParams[k] <- v
        continue
      }

      v.each(@(elem) list.append(elem))
      updateParams[k] <- list
    }
  }

  local entityParams = { transform }.__update(updateParams)

  template = "+".join([template].extend(extraTemplates))

  return ecs.g_entity_mgr.createEntity(template, entityParams, callback)
}

return {
  createVehicle = kwarg(createVehicle)
}
