import "%dngscripts/ecs.nut" as ecs
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

const defSquadState = {
  heroSquadOrderType = 0
  hasPersonalOrder = false
  isLeaderNeedsAmmo = false
  hasSpaceForMagazine = false
  isCompatibleWeapon = false
  canChangeSquadMember = true
}



let squadRows = mkEcsComputedEidMap({
  comps = [
    ["order_ammo__hasSpaceForMagazine", ecs.TYPE_BOOL],
    ["order_ammo__isCompatibleWeapon", ecs.TYPE_BOOL],
    ["squad__numAliveMembers", ecs.TYPE_INT],
    ["squad__orderType", ecs.TYPE_INT],
    ["squad__hasPersonalOrder", ecs.TYPE_BOOL],
    ["squad__isLeaderNeedsAmmo", ecs.TYPE_BOOL],
    ["squad__canChangeMember", ecs.TYPE_BOOL],
  ]
})

let squadEid = Watched(ecs.INVALID_ENTITY_ID)
ecs.register_es("hero_squad_eid_es",
  {
    [["onInit", "onChange"]] = @(_, _eid, comp) squadEid.set(comp["squad_member__squad"]),
  },
  { comps_track = [["squad_member__squad", ecs.TYPE_EID],]
    comps_rq = ["human_input"]
  })



let heroSquadRow = Computed(function(prev) {
  let row = squadRows.get()?[squadEid.get()]
  if (row == null)
    return prev == FRP_INITIAL ? null : prev
  return row
})

let squadState = Computed(function() {
  let row = heroSquadRow.get()
  if (row == null)
    return defSquadState
  return {
    heroSquadOrderType = row.squad__orderType
    hasPersonalOrder = row.squad__hasPersonalOrder
    isLeaderNeedsAmmo = row.squad__isLeaderNeedsAmmo
    hasSpaceForMagazine = row.order_ammo__hasSpaceForMagazine
    isCompatibleWeapon = row.order_ammo__isCompatibleWeapon
    canChangeSquadMember = row.squad__canChangeMember
  }
})
let {heroSquadOrderType, hasPersonalOrder, isLeaderNeedsAmmo,
  hasSpaceForMagazine, isCompatibleWeapon, canChangeSquadMember
} = watchedTable2TableOfWatched(squadState)



let heroSquadNumAliveMembers = Computed(@() squadEid.get() == ecs.INVALID_ENTITY_ID ? -1
  : (heroSquadRow.get()?.squad__numAliveMembers ?? -1))

return {
  squadEid
  heroSquadNumAliveMembers
  heroSquadOrderType
  hasPersonalOrder
  isLeaderNeedsAmmo
  hasSpaceForMagazine
  isCompatibleWeapon
  canChangeSquadMember
}