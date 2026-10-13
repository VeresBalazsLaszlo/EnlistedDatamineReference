import "%ui/components/fontawesome.map.nut" as fa
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/actions_state.nut" import pickupItemName, pickupItemEid, useActionEid, lookAtVehicle, useActionAvailable, customUsePrompt
from "%ui/hud/state/vehicle_state.nut" import inVehicle, inPlane, isSafeToExit, isPlayerCanEnter, isPlayerCanExit, isVehicleAlive
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/health_state.nut" import isDowned
from "%ui/hud/state/local_player.nut" import localPlayerEid, localPlayerTeam
from "%dngscripts/sound_system.nut" import sound_play
from "das.inventory" import is_fast_pickup_item
from "%ui/hud/human_actions.nut" import ACTION_USE, ACTION_REQUEST_AMMO, ACTION_RECOVER, ACTION_PICK_UP, ACTION_SWITCH_WEAPONS, ACTION_OPEN_DOOR, ACTION_CLOSE_DOOR
  , ACTION_REMOVE_SPRAY, ACTION_DENIED_TOO_MUCH_WEIGHT, ACTION_LOOT_BODY, ACTION_OPEN_WINDOW, ACTION_CLOSE_WINDOW, ACTION_REVIVE_TEAMMATE
from "%ui/hud/state/hero_in_vehicle_state.nut" import isInHatch
from "%ui/hud/state/useful_box_state.nut" import usefulBoxHintFull
from "%ui/ui_library.nut" import *
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "math" import round






let showTeamQuickHint = Watched(true)
let teamHintsQuery = ecs.SqQuery("teamHintsQuery", {comps_ro =[["team__id", ecs.TYPE_INT],["team__showQuickHint", ecs.TYPE_BOOL, true]]})
let findPromptQuery = ecs.SqQuery("findPromptQuery", {comps_ro = [["item__customUsePrompt", ecs.TYPE_STRING]]})

localPlayerEid.subscribe(function(v) {
  if ( v != ecs.INVALID_ENTITY_ID ) {
    teamHintsQuery.perform(function (_eid, comp) {
        showTeamQuickHint.set(comp["team__showQuickHint"])
      },
      $"eq(team__id, {localPlayerTeam.get()})"
    )
  }
})

function getItemPrice(entity_eid) {
    let price = ecs.obsolete_dbg_get_comp_val(entity_eid, "paid_loot__cost")
    return price
}


const pickupkeyId = "Inventory.Pickup"
const forcedPickupkeyId = "Inventory.ForcedPickup"
const usekeyId = "Human.Use"

let actionsMap = {
  [ACTION_USE] = {
                    textf = function (item) {
                              if (ecs.obsolete_dbg_get_comp_val(item.useEid, "paid_door__currentCost") != null){
                                let count = round(ecs.obsolete_dbg_get_comp_val(controlledHeroEid.get(), "paid_loot__souls"))
                                return loc("paid_loot/you_have_souls_to_put", { count })
                              }
                              if (item.usePrompt && item.usePrompt.len() > 0)
                                return loc(item.usePrompt, "Press to use")

                              let objectPrompt = ecs.obsolete_dbg_get_comp_val(item.useEid, "item__customUsePrompt", "")
                              if (objectPrompt && objectPrompt.len() > 0)
                                return loc(objectPrompt, "Press to use")

                              return loc("hud/use", "Press to use")
                            }
                    key = usekeyId
  },
  [ACTION_REQUEST_AMMO] = {text = loc("hud/request_ammo", "Request ammo") key = usekeyId},
  [ACTION_PICK_UP] = {
    keyf = @(item) is_fast_pickup_item(item.eid) ? pickupkeyId : forcedPickupkeyId ,
    textf = function(item) {
      local res
      local price = getItemPrice(item.eid)
      price = price ?? getItemPrice(item.useEid)
      if (price != null && price > 0) {
        res = loc("btn/buyItem", { item = item.item, currency = $"<fa>{fa["star"]}</fa>", price })
      }
      else {
        res = is_fast_pickup_item(item.eid)
        ? loc("hud/pickup", { item = item.item })
        : loc("hud/replaceItem", { item = item.item })
      }
      return res
    }
  },
  [ACTION_RECOVER] = {text = loc("hud/recover", "Recover"), key = usekeyId},
  [ACTION_SWITCH_WEAPONS] = {
                              keyf = @(item) is_fast_pickup_item(item.eid) ? pickupkeyId : forcedPickupkeyId ,
                              textf = @(params) loc("hud/switch_weapons", "Switch weapon to {item}", params)
                             },
  [ACTION_OPEN_DOOR] = {text = loc("hud/open_door", "Open door"), key=usekeyId},
  [ACTION_CLOSE_DOOR] = {text = loc("hud/close_door", "Close door"), key=usekeyId},
  [ACTION_REMOVE_SPRAY] = {text = loc("hud/remove_spray", "Remove spray"), key=usekeyId},
  [ACTION_DENIED_TOO_MUCH_WEIGHT] = {
    textf = function(params) {
      params.item = params.item.subst({ nickname = loc("teammate") })
      return loc("hud/too_much_weight_pickip", "Can't pickup {item} - too much weight", params)
    }
    textColor = Color(120, 120, 120, 120)
  },
  [ACTION_LOOT_BODY] = {text = loc("hud/loot_body", "Loot body") key = usekeyId},
  [ACTION_OPEN_WINDOW] = {text = loc("hud/open_window", "Open window"), key=usekeyId},
  [ACTION_CLOSE_WINDOW] = {text = loc("hud/close_window", "Close window"), key=usekeyId},
  [ACTION_REVIVE_TEAMMATE] = {text = loc("hud/revive_teammate", "Revive teammate"), key=usekeyId},
}

let triggerBlinkAnimations = {}
let listnerForPickupAction = {
  eventHandlers = {["Inventory.Pickup"] = @(...) anim_start(triggerBlinkAnimations),}
}
let blinkAnimations = [
  { prop=AnimProp.translate, from=[0,0], to=[hdpx(20),0], duration=0.7, trigger = triggerBlinkAnimations, easing=Shake4, onEnter = @() sound_play("ui/enlist/login_fail")}
]

let showExitAction = Computed(
  @()(!inPlane.get() || isSafeToExit.get() ) && isPlayerCanExit.get() && isVehicleAlive.get() && !isInHatch.get()
)

function mainAction() {
  let res = {
    size = SIZE_TO_CONTENT
    watch = [isDowned, pickupItemEid, pickupItemName, useActionAvailable,
      inVehicle, showExitAction, useActionEid, customUsePrompt, isPlayerCanEnter,
      isPlayerCanExit, usefulBoxHintFull]
  }
  if (isDowned.get())
    return res

  local children = []
  let curAction = useActionAvailable.get()
  let actScheme = actionsMap?[curAction]
  local { key = null, text = null, textColor = DEFAULT_TEXT_COLOR } = actScheme
  local isVisible = true
  if (text == null && "textf" in actScheme) {
    text = actScheme.textf({ eid=pickupItemEid.get(),
                             item=loc(pickupItemName.get()),
                             itemName=pickupItemName.get(),
                             useEid=useActionEid.get(),
                             usePrompt = customUsePrompt.get()})
  }
  if (key == null && "keyf" in actScheme) {
    key = actScheme.keyf({ eid=pickupItemEid.get(),
                           useEid=useActionEid.get() })
  }
  if (curAction == ACTION_USE && inVehicle.get()) {
    text = loc("hud/leaveVehicle")
    isVisible = showExitAction.get()
  }
  if (curAction == ACTION_USE && usefulBoxHintFull.get()) {
    isVisible = false
  }
  if (curAction == ACTION_USE && lookAtVehicle.get() && !isPlayerCanEnter.get() && !inVehicle.get()) {
    let customUsePromt = ecs.obsolete_dbg_get_comp_val(useActionEid.get(), "vehicle__brokenUsePrompt")
    isVisible = customUsePromt && customUsePromt.len() > 0
    text = loc(customUsePromt)
    key = null
  }
  if (curAction == ACTION_USE) {
    findPromptQuery(useActionEid.get(), function(_, comp){
      let customUsePromt = comp["item__customUsePrompt"]
      isVisible = customUsePromt.len() > 0
      text = loc(customUsePromt)
    })
  }

  children = !isVisible ? [] : [tipCmp({
    inputId = key
    text
    extraAnimations = blinkAnimations
    style = { color = textColor, preformatted = FMT_KEEP_SPACES }
  })]

  if (curAction == ACTION_SWITCH_WEAPONS || key == forcedPickupkeyId)
    children.append(listnerForPickupAction)
  return res.__update({ children  })
}

return {
  mainAction
}