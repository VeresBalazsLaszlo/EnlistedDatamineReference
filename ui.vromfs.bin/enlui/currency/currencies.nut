import "%enlSqGlob/userInfo.nut" as userInfo
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let matchingNotifications = require("%ui/notifications/matchingNotifications.nut")

let currenciesList = mkWatched(persist, "currenciesList", [])

let currenciesBalance = nestWatched("currenciesBalance", {})
let currenciesExpiring = nestWatched("currenciesExpiring", {})
let currenciesPurchases = nestWatched("currenciesPurchases", {})

userInfo.subscribe(function(v) {
  if (v)
    return
  currenciesBalance.set({})
  currenciesPurchases.set({})
})

function mkCurrency(config){
  let id = config.id
  return {
    id = id
    image = @(_size) null
    locId = $"currency/code/{id}"
  }.__update(config)
}

let currenciesSorted = Computed(@() currenciesList.get().map(mkCurrency))

let currenciesById = Computed(function(){
  let res = {}
  foreach (config in currenciesList.get()){
    let currency = mkCurrency(config)
    let id = currency.id
    assert(!(id in res), $"Currency: duplicate currency id {id}")
    res[id] <- currency
  }
  return res
})

let notifications = {
  update_balance = function(ev) {
    if (typeof(ev?.balance) != "table") {
      log("Got currency notification without balance table")
      return
    }
    let newBalance = clone currenciesBalance.get()
    let newExpiring = clone currenciesExpiring.get()
    foreach (k, v in ev.balance) {
      newBalance[k] <- v?.value
      newExpiring[k] <- v?.expiring
    }
    if (!isEqual(newBalance, currenciesBalance.get()))
      currenciesBalance.set(newBalance)
    if (!isEqual(newExpiring, currenciesExpiring.get()))
      currenciesExpiring.set(newExpiring)
  }

  update_purchasable_list = function(ev) {
    let newPurch = ev?.purchases ?? {}
    if (!isEqual(newPurch, currenciesPurchases.get()))
      currenciesPurchases.set(newPurch)
  }
}

function processNotification(ev) {
  let handler = notifications?[ev?.func]
  if (handler)
    handler(ev)
  else
    log("Unexpected currency notification type:", (ev?.func ?? "null"))
}

matchingNotifications.subscribe("currency", processNotification)


console_register_command(@() console_print(currenciesBalance.get()), "currencies.balance")
console_register_command(function(key, val) {
  let balance = clone currenciesBalance.get()
  balance[key] <- val
  currenciesBalance.set(balance)
}, "currencies.set")

let hasValidBalance = Computed(@() currenciesBalance.get().findindex(@(val) val < 0) == null)

return {
  currenciesById
  currenciesSorted

  currenciesBalance
  currenciesExpiring
  hasValidBalance

  currenciesList
}
