from "dagor.math" import Point4
from "%ui/ui_library.nut" import *
from "types" import String, Array

function getTexReplaceString(item) {
  let { objTexReplace = null } = item
  if (objTexReplace == null)
    return ""

  if (objTexReplace instanceof String)
    return objTexReplace

  let ruleSets = objTexReplace instanceof Array ? objTexReplace : [objTexReplace]
  let list = []
  foreach (idx, set in ruleSets) {
    list.append($"r{idx}")
    list.append("{")
    foreach (from, to in set)
      list.append($"objTexReplace:t={from};objTexReplace:t={to};")
    list.append("}")
  }
  return "".join(list)
}

function getTexSetString(item) {
  let { objTexSet = null } = item
  if (objTexSet == null)
    return ""

  let ruleSets = objTexSet instanceof Array ? objTexSet : [objTexSet]
  let list = []
  foreach (idx, set in ruleSets) {
    list.append($"r{idx}")
    list.append("{")
    foreach (key, pair in set) {
      let from = pair?.keys()[0]
      let to = pair?[from]
      if (from != null && to != null) {
        list.append($"objTexSet:t={key};objTexSet:t={from};objTexSet:t={to};")
      }
    }
    list.append("}")
  }
  return "".join(list)
}

function getCamouflageString(camouflageParams) {
  if ((camouflageParams?.len() ?? 0) == 0)
    return null

  let materialsList = []
  foreach (matProperties in camouflageParams) {
    let {
      material_id = -1, color_multiplier = 1, force_solid_fill = false,
      solid_fill_color = Point4(1, 1, 1, 1)
    } = matProperties
    let { x, y, z, w } = solid_fill_color
    let params = [].append(
      "material_id:i={0};force_solid_fill:b={1}".subst(material_id, force_solid_fill),
      "solid_fill_color:p4={0},{1},{2},{3}".subst(x, y, z, w),
      "color_multiplier:r={0}".subst(color_multiplier)
    )
    materialsList.append("a{{0}}".subst(";".join(params)))
  }
  return "".join(materialsList)
}

return {
  getTexReplaceString
  getTexSetString
  getCamouflageString
}
