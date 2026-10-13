import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/squad_members.nut" import watchedHeroSquadEid
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *



let personalOrders = mkEcsComputedEidMap({
  comps = [
    ["squad_member__squad", ecs.TYPE_EID],
    ["squad_member__orderType", ecs.TYPE_INT],
    ["squad_member__orderPosition", ecs.TYPE_POINT3],
  ]
  comps_filter = [["squad_member__isPersonalOrder", ecs.TYPE_BOOL]]
  filter = "squad_member__isPersonalOrder"
})

let heroPersonalOrders = Computed(@() personalOrders.get()
  .filter(@(row) row.squad_member__squad == watchedHeroSquadEid.get()))

let watchedHeroSquadPersonalOrdersSet = Computed(function(prev) {
  let res = heroPersonalOrders.get().map(@(_, eid) eid)
  return isEqual(res, prev) ? prev : res
})



let watchedHeroSquadPersonalOrdersGetWatched = memoize(@(eid) Computed(function(prev) {
  let row = heroPersonalOrders.get()?[eid]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return { orderType = row.squad_member__orderType, orderPosition = row.squad_member__orderPosition }
}))

return {
  watchedHeroSquadPersonalOrdersSet, watchedHeroSquadPersonalOrdersGetWatched
}
