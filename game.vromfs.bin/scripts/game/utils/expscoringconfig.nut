let logExp = require("%enlSqGlob/library_logs.nut").with_prefix("[ExpConfig] ")
let { isNoBotsMode } = require("%enlSqGlob/missionType.nut")
let { get_matching_invite_data } = require("app")


let constSquads = {
  BASE_EXP_MUL = 1.0
  HERO_AWARDS = true
  SCORE_MUL = 2.0
  AVG_SCORE_PER_SEC = 3.0
  EXP_PER_SEC = 5.4
  MIN_BATTLE_TIME = 1.0
  EARLY_EXIT_MULT = 1.0
  NOT_ENOUGH_REAL_PLAYER_MULT = 1.0
  DESERTER_MULT = 0.7
  DESERTER_ENABLE = true
  WIN_MULT = 1.5
  LOSE_MULT = 1.0
  SOLDIER_EFF_COEF_MUL = 0.2
  EXP_MUL_BY_REAL_ENEMY_COUNT = [
    1.0 
  ]
  ANY_TEAM_EXP_MUL_WIN = 1.2
  ANY_TEAM_EXP_MUL_LOSE = 1.5
}

let constAlone = constSquads.__merge({
  AVG_SCORE_PER_SEC = 1.25
  EXP_PER_SEC = 5.1
})

let noExp = constSquads.__merge({
  BASE_EXP_MUL = 0.0
  HERO_AWARDS = false
  DESERTER_ENABLE = false
})

let modsExp = constSquads.__merge({
  ANY_TEAM_EXP_MUL_WIN = 1.0
  ANY_TEAM_EXP_MUL_LOSE = 1.0
  EXP_PER_SEC = 2.7
  EXP_BY_TIME = true
  DESERTER_ENABLE = false
})

let modsExpPrem = {
  EXP_PER_SEC = 5.4
}

let customCommon = {
  ANY_TEAM_EXP_MUL_WIN = 1.0
  ANY_TEAM_EXP_MUL_LOSE = 1.0
  MIN_REAL_PLAYERS_FOR_WIN_MULT = 10
  MIN_REAL_PLAYERS_FOR_BATTLE_HERO_MULT = 10
  MIN_REAL_PLAYERS_FOR_EX_BOOSTS = 10
  MIN_REAL_PLAYERS_WITH_SCORE_FOR_WIN_MULT = 5
  MIN_REAL_PLAYERS_WITH_SCORE_FOR_BATTLE_HERO_MULT = 5
  MIN_REAL_PLAYERS_WITH_SCORE_FOR_EX_BOOSTS = 5
  EXP_MUL_BY_REAL_ENEMY_COUNT = [
    0.2 
    0.5 
    1.0 
    
  ]
  DESERTER_ENABLE = false
}

let constByMode = {
  custom_squads = constSquads.__merge(customCommon)
  custom_lone_fighters = constAlone.__merge(customCommon)
  mods = modsExp
  no_econ_events = noExp
}

let premConstByMode = {
  mods = modsExp.__merge(modsExpPrem)
}

let { expMode = null } = get_matching_invite_data()?.mode_info
logExp($"Init expMode = {expMode}")

let getCurModeConstForAll = @() constByMode?[expMode]
  ?? (isNoBotsMode() ? constAlone : constSquads)
let getCurModeConstForPrem = @() premConstByMode?[expMode] ?? getCurModeConstForAll()
let getCurModeConst = @(isPremium = false) isPremium ? getCurModeConstForPrem()
                                                     : getCurModeConstForAll()

return {
  getCurModeConstForAll
  getCurModeConst
  expMode
}
