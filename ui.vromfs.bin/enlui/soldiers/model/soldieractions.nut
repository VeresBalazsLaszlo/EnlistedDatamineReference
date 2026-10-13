from "%ui/meta/clientApi.nut" import soldier_train, add_exp_to_soldiers, add_perk, remove_perk, reset_perks, free_reroll_perks, buy_soldier_exp
  , use_soldier_levelup_orders, dismiss_reserve_soldiers, set_perks
from "%ui/soldiers/model/soldierPerks.nut" import markPerksUnseen, markPerksSeen
from "%ui/ui_library.nut" import *

local isPerkActionInProgress = false

let mkSoldierActionCb = @(guidsList, cb = null) function(res) {
  markPerksUnseen(guidsList)
  cb?(res)
}

function soldierTrain(guid, steps, cb) {
  soldier_train(guid, steps, mkSoldierActionCb([guid], cb))
}

function addExpToSoldiers(list, cb) {
  add_exp_to_soldiers(list, mkSoldierActionCb(list.keys(), cb))
}

function buySoldierExp(guid, exp, cost, cb) {
  buy_soldier_exp(guid, exp, cost, mkSoldierActionCb([guid], cb))
}

function dismissReserveSoldiers(armyId, guidsList, cb) {
  dismiss_reserve_soldiers(armyId, guidsList, mkSoldierActionCb(guidsList, cb))
}

function useSoldierLevelupOrders(guid, barterData) {
  use_soldier_levelup_orders(guid, barterData, mkSoldierActionCb([guid]))
}

function perform(soldierGuid, action, cb = null) {
  if (isPerkActionInProgress)
    return
  isPerkActionInProgress = true

  action(function(res) {
    markPerksSeen([soldierGuid])
    isPerkActionInProgress = false
    cb?(res)
  })
}

let addPerk = @(soldierGuid, perkId, cb)
  perform(soldierGuid, @(fn)
    add_perk(soldierGuid, perkId, fn), cb)

let removePerk = @(soldierGuid, perkId, cb)
  perform(soldierGuid, @(fn)
    remove_perk(soldierGuid, perkId, fn), cb)

let setPerks = @(soldierGuid, perks, cb)
  perform(soldierGuid, @(fn)
    set_perks(soldierGuid, perks, fn), cb)

let resetPerks = @(soldierGuid, needTotalReset)
  perform(soldierGuid, @(fn)
    reset_perks(soldierGuid, needTotalReset, fn))

let freeRerollPerks = @(soldierGuid, needTotalReset)
  perform(soldierGuid, @(fn)
    free_reroll_perks(soldierGuid, needTotalReset, fn))


return {
  soldierTrain
  addExpToSoldiers
  buySoldierExp
  dismissReserveSoldiers
  useSoldierLevelupOrders

  addPerk
  removePerk
  setPerks
  resetPerks
  freeRerollPerks
}
