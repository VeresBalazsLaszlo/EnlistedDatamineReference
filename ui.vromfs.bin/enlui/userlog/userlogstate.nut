import "%ui/userstats/serverTime.nut" as serverTime
from "%enlSqGlob/battleParams.nut" import BattleResult
from "%ui/meta/clientApi.nut" import get_player_logs
from "%ui/ui_library.nut" import *
from "math" import max

enum UserLogType {
  PURCHASE = "purchase"
  ITEM = "item"
  SOLDIER = "soldier"
  SQUAD = "squad"
  WALLPOSTER = "wallposter"
  BONUS = "bonus"
  PREMDAYS = "premDays"
  BOOSTER = "booster"
  DECORATOR = "decorator"
  VEHDECORATOR = "vehDecorator"
  BATTLE_RESULT = "battleResult"
}

const PURCHASE = [
  UserLogType.PURCHASE, UserLogType.ITEM, UserLogType.SOLDIER, UserLogType.SQUAD,
  UserLogType.WALLPOSTER, UserLogType.BONUS, UserLogType.PREMDAYS, UserLogType.BOOSTER,
  UserLogType.DECORATOR, UserLogType.VEHDECORATOR
]

let userLogsTime = Watched(0)
let userLogsData = Watched([])
let isUserLogsRequesting = Watched(false)
let userLogsDebug = Watched(null)
let userLogs = Computed(@() userLogsDebug.get() ?? userLogsData.get())

let byTs = @(a, b) b.ts <=> a.ts
let exists = @(arr, f) arr.findindex(f) != null

let purchaseUserLogs = Computed(@()
  userLogs.get()
    .filter(@(entry)
      exists(entry?.records, @(record) PURCHASE.contains(record.findindex(@(_) true)) ))
    .sort(byTs))

let battlesUserLogs = Computed(@()
  userLogs.get()
    .filter(@(entry)
      exists(entry?.records, @(record) UserLogType.BATTLE_RESULT in record))
    .sort(byTs))

function updateUserLogs(newValue) {
  isUserLogsRequesting.set(false)
  userLogsTime.set(serverTime.get())
  userLogsData.set(newValue?.playerLog ?? [])
}

function userLogsRequest() {
  if (isUserLogsRequesting.get())
    return
  isUserLogsRequesting.set(true)
  let lastTime = max(0, userLogsTime.get())
  get_player_logs(lastTime, updateUserLogs)
}

function extractLogData(record) {
  let rType = record.findindex(@(_) true)
  return { rType, data = record?[rType] }
}

let debugResult = [BattleResult.DESERTION, BattleResult.WIN, BattleResult.DEFEAT]
console_register_command(function(num) {
  if (num <= 0) {
    userLogsDebug.set(null)
    console_print("User log debug is turned OFF")
    return
  }
  let logs = []
  for (local i = 0; i < num; ++i) {
    let missionId = $"test_map{i}"
    let activityPercent = i.tofloat() / num
    logs.append({
      ts = i
      records = [{
        battleResult = {
          missionId, activityPercent,
          armyId = "ger"
          exp = debugResult[i % debugResult.len()]
        }
      }]
    })
  }
  userLogsDebug.set(logs)
  console_print("User log debug is turned ON")
}, "meta.genDebugUserLogs")

console_register_command(userLogsRequest, "meta.getUserLogs")

return {
  UserLogType
  userLogsRequest
  purchaseUserLogs
  battlesUserLogs
  isUserLogsRequesting
  extractLogData
}
