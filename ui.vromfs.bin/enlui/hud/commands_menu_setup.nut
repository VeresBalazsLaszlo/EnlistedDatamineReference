import "%ui/components/colorize.nut" as colorize
import "%ui/hud/components/pieMenuTextItemCtor.nut" as pieMenuTextItemCtor
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/dasenums.nut" import SquadMateOrder
from "dagor.math" import Point3
from "dasevents" import sendNetEvent, RequestSquadMateOrder, RqCancelContextCommand
from "%ui/hud/state/pie_menu_state.nut" import pieMenuItems
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/health_state.nut" import isDowned, isAlive, hp, maxHp
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/hero_weapons.nut" import hasPrimaryWeapon
from "%ui/hud/state/attached_gun_state.nut" import isAttachedToGun
from "%ui/hud/state/requestAmmoState.nut" import requestAmmoTimeout
from "%ui/hud/state/squad_members.nut" import localPlayerSquadMembers
from "%ui/hud/state/hero_squad.nut" import isLeaderNeedsAmmo, hasSpaceForMagazine, isCompatibleWeapon
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { quickChatCommands } = require("%ui/hud/quickchat_menu.nut")


const noMembersColor = 0xFFFF6060

let hasActive = Computed(@() localPlayerSquadMembers.get()
  .findvalue(@(m) m.eid != controlledHeroEid.get() && m.isAlive) != null)
let available = Computed(@() hasActive.get() && !inVehicle.get())
let notAvailable = Computed(@() !available.get())
let noMembersText = Computed(@() hasActive.get() ? null
  : colorize(noMembersColor, loc("msg/noAliveMembersToOrder")))

let sendCmd = @(orderType)
  sendNetEvent(ecs.obsolete_dbg_get_comp_val(controlledHeroEid.get(), "squad_member__squad", ecs.INVALID_ENTITY_ID),
    RequestSquadMateOrder({orderType, orderPosition=Point3(), orderUseEntity=ecs.INVALID_ENTITY_ID}))

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

let addTextCtor = @(cmd) cmd.__merge({
  ctor = pieMenuTextItemCtor({
    text = cmd.text, available = cmd?.available ?? WatchedRo(true), isBlocked = cmd?.isBlocked ?? WatchedRo(false)
  })
})

let cmdFollowMe = addTextCtor({
  action = @() ecs.g_entity_mgr.sendEvent(controlledHeroEid.get(), RqCancelContextCommand({include_personal_orders=true}))
  text = WatchedRo(loc("squad_orders/follow"))
  disabledtext = noMembersText
  available = available
  isBlocked = notAvailable
})

let canRequestAmmo = Computed(@() isLeaderNeedsAmmo.get()
  && requestAmmoTimeout.get() <= 0
  && available.get()
  && !isAttachedToGun.get())
let cantRequestAmmoText = Computed(@() (isLeaderNeedsAmmo.get() && requestAmmoTimeout.get() > 0
    ? loc("msg/canRequestIn", { time = secondsToStringLoc(requestAmmoTimeout.get()) })
    : null))

let requestAmmoReason = Computed(function() {
  if (isAttachedToGun.get())
    return loc("msg/cannotRequestAmmoWhenMounted")
  if (inVehicle.get())
    return loc("msg/cannotRequestAmmoFromVehicle")
  if (!hasActive.get())
    return loc("msg/cantRequestAmmoNotLivingSoldier")
  if (!hasPrimaryWeapon.get())
    return loc("msg/hasNoWeaponForAmmoRequest")
  if (!isCompatibleWeapon.get())
    return loc("msg/cantRequestAmmoForThisWeapon")
  if (!hasSpaceForMagazine.get())
    return loc("msg/hasNoSpaceForMagazine")
  if (requestAmmoTimeout.get() > 0)
    return loc("msg/canRequestIn", { time = secondsToStringLoc(requestAmmoTimeout.get()) })
  return loc("msg/hasAmmo")
})

let cmdBringAmmo = addTextCtor({
  action = @() sendCmd(SquadMateOrder.ESMO_BRING_AMMO)
  disabledAction = @() showMsg(requestAmmoReason.get())
  text = Computed(@() "\n".concat(loc("squad_orders/bring_ammo"), cantRequestAmmoText.get() ?? ""))
  disabledtext = Computed(@() noMembersText.get() ?? cantRequestAmmoText.get() ?? loc("pieMenu/actionUnavailable"))
  available = canRequestAmmo
  isBlocked = notAvailable
})


let healCount = Computed(@() (localPlayerSquadMembers.get() ?? [])
  .reduce(@(res, m) m.eid != controlledHeroEid.get() && m.isAlive ? res + m.targetHealCount : res, 0))
let reviveCount = Computed(@() (localPlayerSquadMembers.get() ?? [])
  .reduce(@(acc, m) m.eid != controlledHeroEid.get() && m.isAlive ? acc + m.targetReviveCount : acc, 0))
let canRequestHeal = Computed(@() available.get()
  && isAlive.get()
  && !isAttachedToGun.get()
  && ((isDowned.get() && reviveCount.get() > 0)
    || ((hp.get() ?? 0) < maxHp.get() && healCount.get() > 0)))
let textWithInfo = @(text, info) $"{text} ({info})"

let cmdHeal = addTextCtor({
  action = @() sendCmd(SquadMateOrder.ESMO_HEAL)
  disabledAction = function() {
    if (isAttachedToGun.get())
      showMsg(loc("msg/cantHealWhenMounted"))
    else if ((hp.get() ?? 0) >= maxHp.get())
      showMsg(loc("msg/noNeedHeal"))
    else if (!hasActive.get())
      showMsg(loc("msg/noAliveMembersToOrder"))
    else if (isDowned.get() ? reviveCount.get() <= 0 : healCount.get() <= 0)
      showMsg(loc("msg/noMedkits"))
  }
  text = Computed(@() isDowned.get() ? textWithInfo(loc("squad_orders/revive_me"), reviveCount.get())
      : textWithInfo(loc("squad_orders/heal_me"), healCount.get()))
  disabledtext = Computed(@() noMembersText.get() ?? loc("pieMenu/actionUnavailable"))
  available = canRequestHeal
  isBlocked = notAvailable
})

pieMenuItems.set([
  [],
  [
    cmdFollowMe
    cmdBringAmmo
    cmdHeal
  ],
  quickChatCommands,
  []
])
