import "%enlSqGlob/userInfo.nut" as userInfo
from "%sqstd/json.nut" import saveJson
from "dagor.clipboard" import set_clipboard_text
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierGuid
from "%ui/soldiers/model/playerStatistics.nut" import genPerksPointsStatistics
from "%ui/soldiers/model/state.nut" import resetProfile, dumpProfile
from "%ui/meta/clientApi.nut" import get_all_configs, premium_add, premium_remove, get_gdpr_report,
  reset_mutations_context, check_purchases, inventory_add_item, appearance_change, remove_item,
  remove_items, decrease_purchases_count, apply_profile_mutation, consume_items
from "%ui/soldiers/model/soldierActions.nut" import soldierTrain, addExpToSoldiers
from "%ui/soldiers/model/chooseSoldiersState.nut" import selectedSoldierGuid
from "%ui/scene/soldier_overrides.nut" import soldierReset, soldierResetAll, isSoldierDisarmed,
  setSoldierDisarmed, setSoldierIdle, switchSoldierIdle, setSoldierHead, switchSoldierHead,
  setSoldierFace, switchSoldierFace, isSoldierSlotsSwap, setSoldierSlotsSwap
from "%ui/ui_library.nut" import *

let curSoldier = Computed(@() selectedSoldierGuid.get() ?? curSoldierGuid.get())

console_register_command(
  function(exp) {
    let guid = curSoldier.get()
    if (exp <= 0)
      log_for_user("Unable to substract exp")
    else if (!guid)
      log_for_user("Select soldier in squad list")
    else
      addExpToSoldiers({ [guid] = exp }, log_for_user)
  },
  "meta.addCurSoldierExp")

console_register_command(function(steps) {
  let guid = curSoldier.get()
  if (guid)
    soldierTrain(guid, steps, log_for_user)
  else
    log_for_user("Select soldier in squad list")
}, "meta.trainCurSoldier")

console_register_command(@() appearance_change(curSoldier.get()), "meta.changeSoldierAppearance")

console_register_command(function() {
  let info = $"{userInfo.get().nameorig}:{userInfo.get().userId}"
  set_clipboard_text(info)
  console_print(info)
}, "whoami")
console_register_command(@() resetProfile(), "meta.resetProfile")
console_register_command(@() dumpProfile(), "meta.dumpProfile")
console_register_command(@() reset_mutations_context(), "meta.resetMutationsContext")
console_register_command(@(key) apply_profile_mutation(key), "meta.applyMutation")
console_register_command(@() check_purchases(), "meta.check_purchases")
console_register_command(function() {
  let { userId = -1 } = userInfo.get()
  if (userId < 0)
    return

  get_gdpr_report(function(result) {
    let path = $"enlisted_gdpr_{userId}.json"
    saveJson(path, result, { logger = log_for_user })
    console_print($"GDPR data saved to {path}")
  })
}, "meta.dumpGDPR")

console_register_command(@(sTier, count, genId) genPerksPointsStatistics(sTier, count, genId), "stat.perksPoints")

console_register_command(@() get_all_configs(), "meta.getAllConfigs")

console_register_command(@(durationSec) premium_add(durationSec), "meta.cheatPremiumAdd")

console_register_command(@(durationSec) premium_remove(durationSec), "meta.cheatPremiumRemove")

console_register_command(soldierResetAll, "soldier.resetOverrideAll")
console_register_command(@() soldierReset(curSoldier.get()), "soldier.resetOverrideCurrent")

console_register_command(@()
  setSoldierDisarmed(curSoldier.get(), !isSoldierDisarmed(curSoldier.get())),
  "soldier.disarmedToggle")

console_register_command(@()
  setSoldierSlotsSwap(curSoldier.get(), !isSoldierSlotsSwap(curSoldier.get())),
  "soldier.swapToggle")

console_register_command(@(anim) setSoldierIdle(curSoldier.get(), anim), "soldier.idleSet")
console_register_command(@() switchSoldierIdle(curSoldier.get(), 1), "soldier.idleNext")
console_register_command(@() switchSoldierIdle(curSoldier.get(), -1), "soldier.idlePrev")

console_register_command(@(anim) setSoldierHead(curSoldier.get(), anim), "soldier.headSet")
console_register_command(@() switchSoldierHead(curSoldier.get(), 1), "soldier.headNext")
console_register_command(@() switchSoldierHead(curSoldier.get(), -1), "soldier.headPrev")

console_register_command(@(anim) setSoldierFace(curSoldier.get(), anim), "soldier.faceSet")
console_register_command(@() switchSoldierFace(curSoldier.get(), 1), "soldier.faceNext")
console_register_command(@() switchSoldierFace(curSoldier.get(), -1), "soldier.facePrev")

console_register_command(@(itemdef) inventory_add_item(itemdef), "meta.cheatInvAddItem")
console_register_command(@(itemdef, count) inventory_add_item(itemdef, count), "meta.cheatInvAddItems")


console_register_command(@(itemGuid) remove_item(itemGuid), "meta.removeItem")
console_register_command(remove_item, "meta.removeItemWithCount")
console_register_command(remove_items, "meta.removeItems")
console_register_command(consume_items, "meta.consumeItems")
console_register_command(decrease_purchases_count, "meta.cheatDecreasePurchasesCount")
