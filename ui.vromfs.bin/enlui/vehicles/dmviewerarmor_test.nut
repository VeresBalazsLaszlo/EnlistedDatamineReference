import "DataBlock" as DataBlock
from "%ui/vehicles/dmViewerArmor.nut" import findDmArmorClass


let blk = DataBlock()
let damageParts = blk.addBlock("DamageParts")
damageParts.setStr("armorClass", "tank_structural_steel")
let hull = damageParts.addBlock("hull")
hull.addBlock("body_front").setStr("armorClass", "RHA_tank")
hull.addBlock("body_top")
let chassis = damageParts.addBlock("chassis")
chassis.setStr("armorClass", "car_wheels")
chassis.addBlock("wheel_r_01")
damageParts.addBlock("driver").setStr("armorClass", "steel_tankman")

let cases = [
  { part = "body_front", res = "RHA_tank" }        
  { part = "body_top",   res = "tank_structural_steel" } 
  { part = "wheel_r_01", res = "car_wheels" }      
  { part = "driver",     res = "steel_tankman" }   
  { part = "hull",       res = null }              
  { part = "no_such_part", res = null }
]

foreach (case in cases) {
  let res = findDmArmorClass(blk, case.part)
  assert(res == case.res, @() $"findDmArmorClass('{case.part}') is '{res}', expected '{case.res}'")
}

let noPartsRes = findDmArmorClass(DataBlock(), "body_front")
assert(noPartsRes == null, @() $"findDmArmorClass without DamageParts is '{noPartsRes}', expected null")

println("dmViewerArmor: armor class lookup OK")
