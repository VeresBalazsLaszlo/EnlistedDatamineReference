import "DataBlock" as DataBlock
import "%ui/components/colorize.nut" as colorize
from "math" import round, cos, PI
from "%ui/style/designConst.nut" import activeTxtColor
from "%ui/ui_library.nut" import *

const ABSOLUTE_ARMOR_THRESHOLD = 500.0
const RELATIVE_ARMOR_THRESHOLD = 5.0

let armorClassRemap = {
  CHA_tank_modern = "CHA_tank"
  RHA_tank_modern = "RHA_tank"
  RHAHH_tank_modern = "RHAHH_tank"
  ship_wood = "wood"
}

let getOwnArmorClass = @(blk, defArmorClass) blk.paramExists("armorClass")
  ? blk.getStr("armorClass", "")
  : defArmorClass



function findPartArmorClass(blk, partName, groupArmorClass) {
  let armorClass = getOwnArmorClass(blk, groupArmorClass)
  for (local i = 0; i < blk.blockCount(); i++) {
    let partBlk = blk.getBlock(i)
    if (partBlk.blockCount() > 0) {
      let res = findPartArmorClass(partBlk, partName, armorClass)
      if (res != null)
        return res
    }
    else if (partBlk.getBlockName() == partName)
      return getOwnArmorClass(partBlk, armorClass)
  }
  return null
}


function findDmArmorClass(unitBlk, partName) {
  let partsBlk = unitBlk.getBlockByName("DamageParts")
  return partsBlk == null ? null : findPartArmorClass(partsBlk, partName, null)
}

function getArmorClassLocName(dmBlkPath, partName) {
  if (dmBlkPath == "")
    return ""
  let blk = DataBlock()
  blk.load(dmBlkPath)
  local armorClass = findDmArmorClass(blk, partName)
  armorClass = armorClassRemap?[armorClass] ?? armorClass
  return armorClass ? loc($"armor_class/{armorClass}") : ""
}

function getEffectiveThicknessStr(thickness, viewingAngle) {
  let divider = cos(viewingAngle * PI / 180.0)
  let effThickness = round(divider != 0 ? (thickness / divider) : (ABSOLUTE_ARMOR_THRESHOLD + 1))
  let effThicknessMax = round(min(ABSOLUTE_ARMOR_THRESHOLD, RELATIVE_ARMOR_THRESHOLD * thickness))
  return "".concat(effThickness <= effThicknessMax ? "" : ">", min(effThickness, effThicknessMax))
}

function getArmorPartDesc(armorClassLoc, armorParams, partDebug) {
  let { thickness, normalAngle, viewingAngle } = armorParams
  let effectiveThickness = getEffectiveThicknessStr(thickness, viewingAngle)
  return "\n".join([
    colorize(activeTxtColor, armorClassLoc),
    " ".concat(loc("vehicle/armor/thickness"), loc("vehicleDetails/millimeter", { val = colorize(activeTxtColor, round(thickness)) })),
    " ".concat(loc("vehicle/armor/normal_angle"), loc("vehicleDetails/°", { val = round(normalAngle) })),
    " ".concat(loc("vehicle/armor/impact_angle"), loc("vehicleDetails/°", { val = round(viewingAngle) })),
    " ".concat(loc("vehicle/armor/effective_thickness"), loc("vehicleDetails/millimeter", { val = effectiveThickness })),
    partDebug,
  ], true)
}

return {
  findDmArmorClass
  getArmorClassLocName
  getArmorPartDesc
}
