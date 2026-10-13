import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let battleAreas = mkEcsComputed({
  comps = [
    ["battle_area__activeBattleAreasPolygon", ecs.TYPE_POINT2_LIST],
    ["battle_area__nextBattleAreasPolygon", ecs.TYPE_POINT2_LIST],
  ]
})


let mkPolygon = @(comp) Computed(function() {
  let points = battleAreas.get()?[comp]
  return (points?.len() ?? 0) > 0 ? points : null
})

let battleAreasPolygon = mkPolygon("battle_area__activeBattleAreasPolygon")
let nextBattleAreasPolygon = mkPolygon("battle_area__nextBattleAreasPolygon")

return {
  battleAreasPolygon
  nextBattleAreasPolygon
}
