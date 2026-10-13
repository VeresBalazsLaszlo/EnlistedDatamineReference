import "%dngscripts/ecs.nut" as ecs
from "%ui/scene/transformItem.nut" import transformItem
from "dagor.math" import Point3, TMatrix
from "%ui/ui_library.nut" import *

function setItemTransformFunc(transform, data) {
  if (data == null)
    return transform

  let newTm = TMatrix(transform)
  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(data)
  let zoom = templ?.getCompValNullable("distanceOffset") ?? 0
  newTm[3] = Point3(transform[3].x + zoom, transform[3].y, transform[3].z)
  return transformItem(newTm, data)
}

return {
  setItemTransformFunc
}
