import "%dngscripts/ecs.nut" as ecs
from "humaninv" import INVALID_ITEM_ID
from "dagor.math" import Point2
from "%ui/ui_library.nut" import *

let anyItemComps = {
  comps_rq = ["watchedPlayerItem"]
  
  comps_ro = [
    ["gun__maxAmmo", ecs.TYPE_INT, 0],
    ["item__name", ecs.TYPE_STRING, ""],
    ["item__id", ecs.TYPE_INT, INVALID_ITEM_ID],
    ["animchar__res", ecs.TYPE_STRING, ""],
    ["item__iconYaw", ecs.TYPE_FLOAT, 0.0],
    ["item__iconPitch", ecs.TYPE_FLOAT, 0.0],
    ["item__iconRoll", ecs.TYPE_FLOAT, 0.0],
    ["item__iconOffset", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["item__iconScale", ecs.TYPE_FLOAT, 1.0],
    ["item__weapType", ecs.TYPE_STRING, null],
    ["gun__reloadable", ecs.TYPE_BOOL, false],
    ["gun__propsId", ecs.TYPE_INT, -1],
    ["gunAttachable__gunSlotName", ecs.TYPE_STRING, ""],
    ["gun_delayed_shot__holdTriggerDelay", ecs.TYPE_FLOAT, 0.0],
  ]
}
let mkItemDescFromComp = @(eid, comp) {
  eid
  name = comp["item__name"]
  maxAmmo = comp["gun__maxAmmo"]
  itemPropsId = comp["gun__propsId"]
  isReloadable = comp["gun__propsId"] >= 0 && comp["gun__reloadable"]
  iconName = comp["animchar__res"]
  iconYaw = comp["item__iconYaw"]
  iconPitch = comp["item__iconPitch"]
  iconRoll = comp["item__iconRoll"]
  iconOffsX = comp["item__iconOffset"].x
  iconOffsY = comp["item__iconOffset"].y
  iconScale = comp["item__iconScale"]
  weapType = comp["item__weapType"]
  isDualMagGun = comp?["gun__additionalAmmo"] != null
  attachedItemModSlotName = comp["gunAttachable__gunSlotName"] ?? ""
  chargeTime = comp?["gun_delayed_shot__holdTriggerDelay"] ?? 0
}
return {
  anyItemComps
  mkItemDescFromComp
}