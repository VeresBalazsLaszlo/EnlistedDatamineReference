from "%scripts/game/utils/bqSendAggregated.nut" import bqCreate, bqAppend, bqSend
from "matching.errors" import INVALID_USER_ID

let bqHolder = bqCreate()

function sendBqBattleResult(userId, soldiersStats, expReward, armyData, armyId) {
  if (userId == INVALID_USER_ID || userId == 0)
    return
  let { baseExp, armyExp, squadsExp, soldiersExp, activity } = expReward
  let hasPrem = (armyData?.premiumExpMul ?? 1.0) > 1

  
  
  bqAppend(bqHolder, "game_events_bq", {
    event_type = "army_battle_result",
    user_id    = userId,                      
    army       = armyId,                      
    baseExp    = baseExp,                     
    exp        = armyExp,                     
    prem       = hasPrem,                     
    activity,                                 
  })

  foreach (squad in (armyData?.squads ?? [])) {
    
    let squadId = squad?.squadId
    let premSquad = (squad?.battleExpBonus ?? 0) > 0
    if (squadId in squadsExp)
      
      bqAppend(bqHolder, "game_events_bq", {
        event_type = "squad_battle_result",
        user_id    = userId,                        
        army       = armyId,                        
        squad_id   = squadId,                       
        exp        = squadsExp[squadId],            
        expBonus   = squad?.expBonus ?? 0.0,        
        premSquad  = premSquad,                     
        prem       = hasPrem                        
      })

    let classBonus = armyData?.classBonus ?? {}
    foreach (soldier in (squad?.squad ?? [])) {
      let guid = soldier?.guid
      if (!(guid in soldiersExp))
        continue

      let { time, score } = soldiersStats[guid]
      let { sClass = "", level = 1 } = soldier
      
      bqAppend(bqHolder, "game_events_bq", {
        event_type       = "soldier_battle_result",
        user_id          = userId,                       
        army             = armyId,                       
        squad_id         = squadId,                      
        soldier_class    = sClass,                       
        soldier_level    = level,                        
        soldier_time     = time,                         
        score            = score,                        
        exp              = soldiersExp[guid],            
        expBonus         = classBonus?[sClass] ?? 0.0,   
        premSquad        = premSquad,                    
        prem             = hasPrem                       
      })
    }
  }

  bqSend(bqHolder)
}

return sendBqBattleResult