from "eventbus" import eventbus_subscribe
from "%ui/meta/clientApi.nut" import reward_single_player_mission
from "%ui/ui_library.nut" import *

function chargeExp(data) {
  let { singleMissionRewardId, armyId, squadsExp, soldiersExp } = data
  reward_single_player_mission(singleMissionRewardId, armyId, squadsExp.keys(), soldiersExp.keys())
}

eventbus_subscribe("charge_battle_exp_rewards", @(data) chargeExp(data))
