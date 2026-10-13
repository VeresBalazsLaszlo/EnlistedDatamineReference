import "%ui/hud/components/squad_soldiers_menu_item_ctor.nut" as mkPieItemCtor
from "dasevents" import sendNetEvent, RequestSquadChangeLeader
from "%ui/hud/state/squad_members.nut" import localPlayerSquadMembers
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/hero_squad.nut" import squadEid, heroSquadNumAliveMembers, canChangeSquadMember
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

let radius = Watched(hdpx(365))
let elemSize = Computed(@() [(radius.get()*0.35).tointeger(),(radius.get()*0.35).tointeger()] )
let showSquadSoldiersMenu = mkWatched(persist, "showSquadSoldiersMenu", false)

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })
let selectSoldier = @(eid) sendNetEvent(squadEid.get(), RequestSquadChangeLeader({eid}))

let mkSoldierItem = @(member, isCurrent) {
  action = @() selectSoldier(member.eid)
  disabledAction = @() showMsg(loc("msg/squadMemberNotAvailable") )
  available = member.isAlive && member.canBeLeader
  text = member?.name ?? ""
  ctor = mkPieItemCtor(member, isCurrent, radius.get())
}

let squadSoldiersMenuItems = Computed(function() {
  local actualSquadSoldiers = localPlayerSquadMembers.get()
  if (isGamepad.get())
    actualSquadSoldiers = actualSquadSoldiers.filter(@(member)
      member.isAlive && member.eid != controlledHeroEid.get())
  return actualSquadSoldiers.map(@(member) mkSoldierItem(member, member.eid == controlledHeroEid.get()))
})

let isSquadSoldiersMenuAvailable = Computed(@() canChangeSquadMember.get()
                                             && heroSquadNumAliveMembers.get() > 1)

return {
  squadSoldiersMenuItems
  showSquadSoldiersMenu
  isSquadSoldiersMenuAvailable
  radius
  elemSize
}
