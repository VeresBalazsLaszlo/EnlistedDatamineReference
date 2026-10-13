from "%ui/meta/sourceServProfile.nut" import sourceProfileData, profileStructure
from "%ui/meta/configs.nut" import updateAllConfigs
from "%ui/userstats/serverTimeUpdate.nut" import serverTimeUpdate
from "dagor.time" import get_time_msec
from "%ui/profileServer/profileServer.nut" import generateNextMessageId, doRequest, setHandler
from "dagor.debug" import logerr
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *
from "dagor.memtrace" import set_huge_alloc_threshold
from "%ui/state/login_state.nut" import isLoggedIn
import "%enlSqGlob/userInfo.nut" as userInfo
from "types" import Table

let logApi = with_prefix("[ClientApi] ")

const MAX_REQUESTS_HISTORY = 20
const LONG_TIME = 100 

let requestCallbacks = {}
let debugDelay = mkWatched(persist, "debugDelay", 0)
let delayedMessages = [] 
let lastRequests = Watched([])
let lastTransactId = nestWatched("lastTransactId", 0)

isLoggedIn.subscribe(function(v) {
  if (v)
    return

  requestCallbacks.clear()
  delayedMessages.clear()
  lastRequests.set([])
  lastTransactId.set(0)
})

let diffTime = @(time) get_time_msec() - time

function handleMessages(msg) {
  let messageIdInternal = msg?.id.tostring()
  let { result = null, success = true } = msg
  let cb = requestCallbacks.$rawdelete(messageIdInternal)
  local reqTime = 0
  local method

  lastRequests.mutate(function(v) {
    local data = v.findvalue(@(d) d.id == messageIdInternal)
    if (data == null) {
      data = { id = messageIdInternal, request = "unknown" }
      if (v.len() >= MAX_REQUESTS_HISTORY)
        v.remove(0)
      v.append(data)
    }
    data.resultKeys <- result?.keys()  
    reqTime = data?.reqTime ?? 0
    method = data.request?.method ?? messageIdInternal
  })
  let diffRequest = diffTime(reqTime)
  if (diffRequest > LONG_TIME)
    logApi($"TOO LONG request '{method}' takes {diffRequest} ms")

  if (!result || !success) {
    let errorMessage = msg?.error.message ?? msg?.error ?? "unknown error"
    logApi($"Request '{method}' returned error: {errorMessage}")
    cb?({ error = errorMessage })
    return
  }

  let { timeMs = 0, lastTransaction = null } = result
  if (reqTime > 0 && timeMs > 0) {
    serverTimeUpdate(timeMs, reqTime)
    result.$rawdelete("timeMs")
  }

  if (lastTransaction != null) {
    lastTransactId.set(lastTransaction)
    result.$rawdelete("lastTransaction")
  }

  if (result?.configs != null) {
    let curTime = get_time_msec()
    updateAllConfigs(result.configs)
    result.$rawdelete("configs")
    logApi($"Config update takes {diffTime(curTime)} ms")
  }

  if (result?.full ?? false) {
    result.$rawdelete("full")
    logApi($"Full profile update with {result.len()} fields")
    let curTime = get_time_msec()
    if ("removed" in result) {
      logerr($"Not empty removed field on full profile update on '{method}'")
      result.$rawdelete("removed")
    }

    foreach (key, _ in result)
      if (key not in profileStructure)
        logApi($"Try to full update not existed profile field '{key}' on '{method}'")

    sourceProfileData.mutate(function(profile) {
      foreach (profileId, _ in profileStructure)
        profile[profileId] <- (result?[profileId] ?? {})
    })

    logApi($"Full profile update on '{method}' takes {diffTime(curTime)} ms")
  }
  else if (typeof result == "table") {
    let found = result.findindex(@(tbl) tbl instanceof Table)
    if (found != null) {
      logApi($"Partial profile update with {result.len()} fields")
      let curTime = get_time_msec()
      local updated = 0
      local removed = 0

      let prevSize = set_huge_alloc_threshold(66560 << 10)
      sourceProfileData.mutate(function(profile) {
        foreach (profileId, _ in profileStructure) {
          local curVal
          let changeData = result?[profileId]
          if (changeData instanceof Table && changeData.len() > 0) {
            curVal = clone profile[profileId]
            profile[profileId] = curVal

            ++updated
            curVal.__update(changeData)
          }

          let removeData = result?.removed[profileId]
          if (removeData != null) {
            if (curVal == null) {
              curVal = clone profile[profileId]
              profile[profileId] = curVal
            }

            ++removed
            foreach (fieldId in removeData)
              if (fieldId in curVal)
                curVal.$rawdelete(fieldId)
          }
        }
      })
      set_huge_alloc_threshold(prevSize)

      logApi($"Profile updated:{updated} deleted:{removed} tables of '{method}' takes {diffTime(curTime)} ms")
    }
  }
  if (cb) {
    let curTime = get_time_msec()
    cb(result)
    let diffCall = diffTime(curTime)
    if (diffCall > 0)
      logApi($"Handler call on '{method}' takes {diffCall} ms")
  }
}

let cleanKeys = ["method", "params", "token"]

function request(data, cb = null) {
  let { method, params = null } = data
  let token = data?.token ?? userInfo.get()?.token
  if (token == null) {
    logApi($"Absent token for request '{method}'")
    return
  }

  let messageId = generateNextMessageId()
  let messageIdInternal = messageId.tostring()
  requestCallbacks[messageIdInternal] <- cb

  lastRequests.mutate(function(v) {
    if (v.len() >= MAX_REQUESTS_HISTORY)
      v.remove(0)
    v.append({ id = messageIdInternal, request = data, reqTime = get_time_msec() })
  })

  let args = clone data
  cleanKeys.each(@(key) args?.$rawdelete(key))
  doRequest(method, params, args, messageId, token)
}

function applyDelayedMessages(curTime) {
  while (delayedMessages.len() > 0) {
    let { ts, msg } = delayedMessages[0]
    if (ts > curTime)
      break

    delayedMessages.remove(0)
    handleMessages(msg)
  }
}

function processDelayedMessages() {
  let curTime = get_time_msec()
  applyDelayedMessages(curTime)

  local { ts = 0 } = delayedMessages?[0]
  ts -= curTime
  if (ts > 0)
    gui_scene.resetTimeout(ts / 1000.0, processDelayedMessages)
}

function handleDelayedMessages(msg) {
  delayedMessages.append({
    ts = get_time_msec() + (debugDelay.get() * 1000).tointeger()
    msg
  })
  processDelayedMessages()
}

setHandler(handleMessages)
debugDelay.subscribe(function(delay) {
  if (delay > 0)
    setHandler(handleDelayedMessages)
  else {
    setHandler(handleMessages)
    gui_scene.clearTimer(processDelayedMessages)
    while (delayedMessages.len() > 0) {
      let { msg } = delayedMessages.remove(0)
      handleMessages(msg)
    }
  }
})

console_register_command(@(delay) debugDelay.set(delay), "pserver.delay_requests")
console_register_command(function() {
  logApi("lastRequests: ")
  debugTableData(lastRequests.get(), { recursionLevel = 7 })
}, "pserver.debug_last_requests")

return {
  lastRequests
  lastTransactId

  update_profile = @(cb = null, token = null) request({
    method = "get"
    token
    memory_threshold_bytes = 45 << 20
  }, cb)

  update_partial = @(transactionId) request({
    method = "get_partial"
    params = { transactionId = transactionId.tostring() }
  })

  get_all_configs = @(cb = null, token = null) request({
    method = "get_all_configs"
    token
    memory_threshold_bytes = 11 << 20
  }, cb)

  check_purchases = @() request({
    method = "check_purchases"
  })

  get_player_logs = @(timestamp = 0, cb = null) request({
    method = "get_player_logs"
    params = { timestamp }
  }, cb)

  equip_item = @(target, item, slot, index, cb = null) request({
    method = "equip_item"
    params = { target, item, slot, index = index ?? -1 }
  }, cb)

  equip_by_list = @(target, equipList, cb = null) request({
    method = "equip_by_list"
    params = { target, equipList }
  }, cb)

  mass_equip = @(equipListBySoldier, cb) request({
    method = "mass_equip"
    params = { equipListBySoldier }
  }, cb)

  swap_soldiers_equipment = @(soldierAGuid, soldierBGuid) request({
    method = "swap_soldiers_equipment"
    params = { soldierAGuid, soldierBGuid }
  })

  set_vehicle_to_squad = @(vehicle, squad, cb) request({
    method = "set_vehicle_to_squad"
    params = { vehicle, squad }
  }, cb)

  set_squad_order = @(armyId, orderedGuids) request({
    method = "set_squad_order"
    params = { armyId, orderedGuids }
  })

  sell_squad = @(armyId, squadGuid, silverCost, cb = null) request({
    method = "sell_squad"
    params = { armyId, squadGuid, silverCost }
  }, cb)

  rent_squad = @(armyId, squadId, rentTime, price) request({
    method = "rent_squad"
    params = { armyId, squadId, rentTime, price }
  })

  manage_squad_soldiers = @(armyId, squadGuid, squadSoldiers, reserveSoldiers, cb = null) request({
    method = "manage_squad_soldiers"
    params = { armyId, squadGuid, squadSoldiers, reserveSoldiers }
  }, cb)

  buy_apply_squad_soldiers = @(squadGuid, squadSoldiers, reserveSoldiers, buySoldiers,
      payItems, cb = null) request({
    method = "buy_apply_squad_soldiers"
    params = { squadGuid, squadSoldiers, reserveSoldiers, buySoldiers, payItems }
  }, cb)

  soldier_reside = @(soldierGuids, newTemplate) request({
    method = "soldier_reside"
    params = { soldierGuids, newTemplate }
  })

  use_orders_soldier_reside = @(soldierGuids, newTemplate, payItems, cb = null) request({
    method = "use_orders_soldier_reside"
    params = { soldierGuids, newTemplate, payItems }
  }, cb)

  buy_soldier_reside = @(soldierGuids, newTemplate, cost, cb = null) request({
    method = "buy_soldier_reside"
    params = { soldierGuids, newTemplate, cost }
  }, cb)

  dismiss_reserve_soldiers = @(armyId, guidsList, cb) request({
    method = "dismiss_reserve_soldiers"
    params = { armyId, guidsList }
  }, cb)

  swap_items = @(soldier1, slot1, index1, soldier2, slot2, index2, cb = null) request({
    method = "swap_items"
    params = { soldier1, slot1, index1 = index1 ?? -1, soldier2, slot2, index2 = index2 ?? -1 }
  }, cb)

  drop_items = @(crateId) request({
    method = "drop_items"
    params = { crateId }
  })

  add_squad = @(squadId) request({
    method = "add_squad"
    params = { squadId }
  })

  remove_squad = @(squadId) request({
    method = "remove_squad"
    params = { squadId }
  })

  add_all_squads = @(armyId) request({
    method = "add_all_squads"
    params = { armyId }
  })

  recreate_squad = @(squadId) request({
    method = "recreate_squad"
    params = { squadId }
  })

  add_soldier = @(armyId, sClass, tier) request({
    method = "add_soldier"
    params = { armyId, sClass, tier }
  })

  add_booster = @(booster, lifetime = 0) request({
    method = "add_booster"
    params = { booster, lifetime }
  })

  remove_booster = @(booster) request({
    method = "remove_booster"
    params = { booster }
  })

  add_items = @(itemTmpl, count) request({
    method = "add_items"
    params = { itemTmpl, count }
  })

  remove_item = @(itemGuid, count = 1) request({
    method = "remove_item"
    params = { itemGuid, count }
  })

  remove_items = @(itemTmpl, count = 1) request({
    method = "remove_items"
    params = { itemTmpl, count }
  })

  consume_items = @(itemTmpl, count = 1) request({
    method = "consume_items_debug"
    params = { consumed = { [itemTmpl] = count } }
  })

  add_items_by_type = @(armyId, itemTypes, count) request({
    method = "add_items_by_type"
    params = { armyId, itemTypes, count }
  })

  exchange_exp_to_silver = @(armyId, count) request({
    method = "exchange_exp_to_silver"
    params = { armyId, count }
  })

  add_army_exp = @(armyId, exp, cb = null) request({
    method = "add_army_exp"
    params = { armyId, exp }
  }, cb)

  global_gift_reset = @(guid) request({
    method = "global_gift_reset"
    params = { guid }
  })

  buy_squad_exp = @(armyId, squadId, exp, cost, cb = null) request({
    method = "buy_squad_exp"
    params = { armyId, squadId, exp, cost }
  }, cb)

  buy_squad_max_exp = @(squadId, cost, cb = null) request({
    method = "buy_squad_max_exp"
    params = { squadId, cost }
  }, cb)

  get_squad_point = @(armyId, squadId, cb = null) request({
    method = "get_squad_point"
    params = { armyId, squadId }
  }, cb)

  use_soldier_levelup_orders = @(guid, barterData, cb = null) request({
    method = "use_soldier_levelup_orders"
    params = { guid, barterData }
  }, cb)

  buy_soldier_exp = @(guid, exp, cost, cb) request({
    method = "buy_soldier_exp"
    params = { guid, exp, cost }
  }, cb)

  make_squad_researches = @(armyId, squadId, cb = null) request({
    method = "make_squad_researches"
    params = { armyId, squadId }
  }, cb)

  barter_shop_items = @(armyId, shopItemGuid, payItems, count, cb = null) request({
    method = "barter_shop_items"
    params = { armyId, shopItemGuid, payItems, count }
  }, cb)

  barter_shop_items_multiple = @(armyId, itemData, payData, cb) request({
    method = "barter_shop_items_multiple"
    params = { armyId, itemData, payData }
  }, cb)

  buy_with_upgrade_items_multiple = @(armyId, itemData, payData, upgradeItems, cb) request({
    method = "buy_with_upgrade_items_multiple"
    params = { armyId, itemData, payData, upgradeItems }
  }, cb)

  buy_shop_items = @(armyId, shopItemGuid, currencyId, price, count, cb = null) request({
    method = "buy_shop_items"
    params = { armyId, shopItemGuid, currencyId, price, count }
  }, cb)

  buy_shop_items_list = @(armyId, itemData, payData, cb) request({
    method = "buy_shop_items_list"
    params = { armyId, itemData, payData }
  }, cb)

  update_offers = @(cb = null) request({
    method = "update_offers"
  }, cb)

  expire_offers = @(needClearGenData = false) request({
    method = "expire_offers"
    params = { needClearGenData }
  })

  reset_offers = @(cb = null) request({
    method = "reset_offers"
  }, cb)

  buy_shop_offer = @(armyId, shopItemGuid, currencyId, price, offerGuid = "", cb = null) request({
    method = "buy_shop_offer"
    params = { armyId, shopItemGuid, currencyId, offerGuid, price }
  }, cb)

  get_shop_item = @(shopId, cb = null) request({
    method = "get_shop_item"
    params = { shopId }
  }, cb)

  reset_profile = @(cb) request({
    method = "reset_profile"
  }, cb)

  soldiers_regenerate_view = @() request({
    method = "soldiers_regenerate_view"
  })

  reset_mutations_context = @() request({
    method = "reset_mutations_context"
  })

  apply_profile_mutation = @(key) request({
    method = "apply_profile_mutation"
    params = { key }
  })

  soldier_train = @(guid, steps, cb = null) request({
    method = "soldier_train"
    params = { guid, steps }
  }, cb)

  add_exp_to_soldiers = @(list, cb) request({
    method = "add_exp_to_soldiers"
    params = { list }
  }, cb)

  add_perk = @(soldierGuid, perkId, cb) request({
    method = "add_perk"
    params = { soldierGuid, perkId }
  }, cb)

  set_perks = @(soldierGuid, perks, cb) request({
    method = "set_perks"
    params = { soldierGuid, perks }
  }, cb)

  remove_perk = @(soldierGuid, perkId, cb) request({
    method = "remove_perk"
    params = { soldierGuid, perkId }
  }, cb)

  reset_perks = @(soldierGuid, needTotalReset, cb) request({
    method = "reset_perks"
    params = { soldierGuid, needTotalReset }
  }, cb)

  free_reroll_perks = @(soldierGuid, needTotalReset, cb) request({
    method = "free_reroll_perks"
    params = { soldierGuid, needTotalReset }
  }, cb)

  add_army_squad_exp_by_id = @(exp, squadId) request({
    method = "add_army_squad_exp_by_id"
    params = { exp, squadId }
  })

  set_research_points = @(points, squadId) request({
    method = "set_research_points"
    params = { points, squadId }
  })

  do_research = @(armyId, researchId, cb = null) request({
    method = "research"
    params = { armyId, researchId }
  }, cb)

  change_research = @(armyId, researchFrom, researchTo, payItems, cb = null) request({
    method = "change_research"
    params = { armyId, researchFrom, researchTo, payItems }
  }, cb)

  buy_change_research = @(armyId, researchFrom, researchTo, cost, cb = null) request({
    method = "buy_change_research"
    params = { armyId, researchFrom, researchTo, cost }
  }, cb)

  research_army_unlock = @(armyId, cb = null) request({
    method = "research_army_unlock"
    params = { armyId }
  }, cb)

  upgrade_items_count = @(itemData, sacrificeItems, cb = null) request({
    method = "upgrade_items_count"
    params = { itemData, sacrificeItems }
  }, cb)

  dispose_items_count = @(itemData, cb = null) request({
    method = "dispose_items_count"
    params = { itemData }
  }, cb)

  gen_perks_points_statistics = @(tier, count, genId, cb) request({
    method = "gen_perks_points_statistics"
    params = { tier, count, genId }
  }, cb)

  get_bots_data = @(armyId, campaignId, cb) request({
    method = "get_bots_data"
    params = { armyId, campaignId }
    timeout_factor = 4.0
  }, cb)

  get_profile_data_jwt_armies = @(armies, campaignId, cb) request({
    method = "get_profile_data_jwt"
    params = { genData = { armies, campaignId }}
    timeout_factor = 4.0
  }, cb)

  get_profile_data_jwt_offer = @(offerGuid, cb) request({
    method = "get_profile_data_jwt"
    params = { genData = { offerGuid }}
    timeout_factor = 4.0
  }, cb)

  gen_default_profile = @(target, armies, cb) request({
    method = "gen_default_profile"
    params = { target, armies }
    timeout_factor = 4.0
  }, cb)

  gen_tutorial_profiles = @(cb) request({
    method = "gen_tutorial_profiles"
  }, cb)

  mark_seen_objects = @(objectsGuids = [], cb = null) request({
    method = "mark_seen_objects"
    params = { objectsGuids }
  }, cb)

  reward_single_player_mission = @(missionId, armyId, squads, soldiers) request({
    method = "reward_single_player_mission"
    params = { missionId, armyId, squads, soldiers }
  })

  premium_add = @(duration) request({
    method = "premium_add"
    params = { duration }
  })

  premium_remove = @(duration) request({
    method = "premium_remove"
    params = { duration }
  })

  use_callname_change_order = @(guid, callname, ticket, cb = null) request({
    method = "use_callname_change_order"
    params = { guid, callname, ticket }
  }, cb)

  buy_callname_change = @(guid, callname, cost, cb = null) request({
    method = "buy_callname_change"
    params = { guid, callname, cost }
  }, cb)

  appearance_change = @(guid, cb = null) request({
    method = "appearance_change"
    params = { guid }
  }, cb)

  inventory_add_item = @(itemdef, quantity = 1) request({
    method = "inventory_add_item"
    params = { itemdef, quantity }
  })

  gen_testdrive_squad_profile_jwt_v2 = @(squadId, shopItemGuid, cb) request({
    method = "gen_testdrive_squad_profile_jwt_v2"
    params = { squadId, shopItemGuid }
  }, cb)

  gen_testdrive_vehicle_profile_jwt_v2 = @(templateId, shopItemGuid, cb) request({
    method = "gen_testdrive_vehicle_profile_jwt_v2"
    params = { templateId, shopItemGuid }
  }, cb)

  gen_testdrive_weapon_profile_jwt_v2 = @(templateId, cb) request({
    method = "gen_testdrive_weapon_profile_jwt_v2"
    params = { templateId }
  }, cb)

  choose_decorator = @(cType, guid) request({
    method = "choose_decorator"
    params = { cType, guid }
  })

  buy_decorator = @(guid, cost, cb = null) request({
    method = "buy_decorator"
    params = { guid, cost }
  }, cb)

  add_decorator = @(guid, lifeTime = 0) request({
    method = "add_decorator"
    params = { guid, lifeTime }
  })

  add_all_decorators = @() request({
    method = "add_all_decorators"
  })

  remove_decorator = @(guid) request({
    method = "remove_decorator"
    params = { guid }
  })

  add_veh_decorators = @(id) request({
    method = "add_veh_decorators"
    params = { id }
  })

  apply_decorator_unique = @(guid, vehGuid, cType, details, slot, hasUnique, cb = null) request({
    method = "apply_decorator_unique"
    params = { guid, vehGuid, cType, details, slot, hasUnique }
  }, cb)

  buy_apply_veh_decorators = @(decorators, camouflage, vehGuid, cost, cb = null) request({
    method = "buy_apply_veh_decorators"
    params = { decorators, camouflage, vehGuid, cost }
  }, cb)

  apply_camouflage = @(vehGuid, id, details, hasUnique,
      isCommon, campaignId, cb) request({
    method = "apply_camouflage"
    params = { vehGuid, id, details, hasUnique, isCommon, campaignId }
  }, cb)

  add_medal = @(id) request({
    method = "add_medal"
    params = { id }
  })

  debug_apply_booster_in_battle = @(battleBoosters) request({
    method = "debug_apply_booster_in_battle"
    params = { battleBoosters }
  })

  debug_apply_test_drive_in_battle = @(offerGuid) request({
    method = "debug_apply_test_drive_in_battle"
    params = { offerGuid }
  })

  decrease_purchases_count = @(goodsGuid, count) request({
    method = "decrease_purchases_count"
    params = { goodsGuid, count }
  })

  add_wallposter = @(tpl) request({
    method = "add_wallposter"
    params = { tpl }
  })

  update_meta_config = @(data, cb = null) request({
    method = "update_meta_config"
    params = { data }
  }, cb)

  change_outfit = @(guid, free, premium, campaignId, cb = null) request({
    method = "change_outfit"
    params = { guid, free, premium, campaignId }
  }, cb)

  change_outfit_squad = @(equipListBySoldier, campaignId) request({
    method = "change_outfit_squad"
    params = { equipListBySoldier, campaignId }
  })

  add_outfit = @(outfitTmpl, count) request({
    method = "add_outfit"
    params = { outfitTmpl, count }
  })

  buy_outfit = @(armyId, items, cost, cb = null) request({
    method = "buy_outfit"
    params = { armyId, items, cost }
  }, cb)

  use_outfit_orders = @(armyId, items, orders, cb = null) request({
    method = "use_outfit_orders"
    params = { armyId, items, orders }
  }, cb)

  buy_outfit_bundle = @(squadGuid, outfitId, cost, cb = null) request({
    method = "buy_outfit_bundle"
    params = { squadGuid, outfitId, cost }
  }, cb)

  usermail_check = @(ts, cb) request({
    method = "usermail_check"
    params = { ts }
  }, cb)

  usermail_list = @(ts, limit, cb) request({
    method = "usermail_list"
    params = { ts, limit }
  }, cb)

  usermail_take_reward = @(guid, cb) request({
    method = "usermail_take_reward"
    params = { guid }
  }, cb)

  usermail_reset_reward = @(cb) request({
    method = "usermail_reset_reward"
    params = {}
  }, cb)

  rate_mission = @(missionId, rate, cb = null) request({
    method = "rate_mission"
    params = { missionId, rate }
  }, cb)

  growth_select = @(armyId, growthId) request({
    method = "growth_select"
    params = { armyId, growthId }
  })

  growth_use_army_exp = @(armyId, growthId, exp, cb) request({
    method = "growth_use_army_exp"
    params = { armyId, growthId, exp }
  }, cb)

  growth_select_forced = @(armyId, growthId) request({
    method = "growth_select_forced"
    params = { armyId, growthId }
  })

  growth_purchase = @(armyId, growthId, payItems, cb) request({
    method = "growth_purchase"
    params = { armyId, growthId, payItems }
  }, cb)

  growth_reward_take_forced = @(armyId, growthId) request({
    method = "growth_reward_take_forced"
    params = { armyId, growthId }
  })

  growth_state_set = @(growthId, exp, status) request({
    method = "growth_state_set"
    params = { growthId, exp, status }
  })

  growth_buy_exp = @(armyId, growthId, exp, cost, cb) request({
    method = "growth_buy_exp"
    params = { armyId, growthId, exp, cost }
  }, cb)

  growth_tier_set = @(armyId, index, progress, status) request({
    method = "growth_tier_set"
    params = { armyId, index, progress, status }
  })

  growth_reset = @() request({
    method = "growth_reset"
  })

  set_squad_outfit_preset = @(squadGuid, campaignId) request({
    method = "set_squad_outfit_preset"
    params = { squadGuid, campaignId }
  })

  force_squad_outfit_preset = @(squadGuid, presetId) request({
    method = "force_squad_outfit_preset"
    params = { squadGuid, presetId }
  })

  set_soldier_outfit_preset = @(soldierGuid, campaignId) request({
    method = "set_soldier_outfit_preset"
    params = { soldierGuid, campaignId }
  })

  growth_army_unlock = @(armyId) request({
    method = "growth_army_unlock"
    params = { armyId }
  })

  activate_booster = @(guid, cb = null) request({
    method = "activate_booster"
    params = { guid }
  }, cb)

  deactivate_booster = @(guid, cb = null) request({
    method = "deactivate_booster"
    params = { guid }
  }, cb)

  get_gdpr_report = @(cb) request({
    method = "get_gdpr_report"
  }, cb)

  get_reward = @(reward) request({
    method = "get_reward"
    params = { reward }
  })

  remove_reward = @(reward) request({
    method = "remove_reward"
    params = { reward }
  })

}
