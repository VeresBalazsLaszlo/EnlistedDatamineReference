from "%sqstd/math.nut" import round_by_value
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/ui_library.nut" import *

let isProfileOpened = mkWatched(persist, "isProfileOpened", false)
let isRanksInfoVisible = Watched(false)


let curTabIdx = mkWatched(persist, "curTabIdx", 0)

let killsList = [
  {
    statId = "kill"
    calculator = @(stat) stat?.kills ?? 0
  }
  {
    statId = "assists"
  }
  {
    statId = "capture"
    calculator = @(stat) (stat?.points_captured ?? 0) + (stat?.mission_objectives_destroyed ?? 0)
  }
  {
    statId = "rifle_kills"
  }
  {
    statId = "semiauto_kills"
  }
  {
    statId = "submachine_gun_kills"
  }
  {
    statId = "machine_gun_kills"
  }
  {
    statId = "grenade_kills"
  }
  {
    statId = "kills_using_apc"
  }
  {
    statId = "kills_using_tank"
  }
  {
    statId = "kills_using_bike"
  }
  {
    statId = "kills_using_aircraft"
  }
  {
    statId = "artillery_kills"
  }
  {
    statId = "flamethrower_kills"
  }
  {
    statId = "pistol_kills"
  }
  {
    statId = "mortar_kills"
  }
  {
    statId = "shotgun_kills"
  }
  {
    statId = "melee_kills"
  }
  {
    statId = "launcher_kills"
  }
  {
    statId = "apc_kills"
  }
  {
    statId = "tank_kills"
  }
  {
    statId = "bike_kills"
  }
  {
    statId = "aircraft_kills"
  }
  {
    statId = "vehicle_mine_kills"
    calculator = @(stat) (stat?.vehicle_mine_kills ?? 0)
      + (stat?.vehicle_antitank_mine_kills ?? 0)
      + (stat?.lunge_mine_vehicle_kills ?? 0)
      + (stat?.vehicle_tnt_kills ?? 0)
  }
  {
    statId = "infantry_mine_kills_profile"
    calculator = @(stat) (stat?.infantry_mine_kills ?? 0) + (stat?.crew_mine_kills ?? 0)
  }
  {
    statId = "infantry_antitank_mine_kills_profile"
    calculator = @(stat) (stat?.infantry_antitank_mine_kills ?? 0)
      + (stat?.crew_antitank_mine_kills ?? 0)
  }
  {
    statId = "infantry_tnt_kills"
    calculator = @(stat) (stat?.infantry_tnt_kills ?? 0) + (stat?.crew_tnt_kills ?? 0)
  }
  {
    statId = "lunge_mine_kills"
    calculator = @(stat) (stat?.lunge_mine_kills ?? 0) + (stat?.lunge_mine_crew_kills ?? 0)
  }
  {
    statId = "headshot"
    calculator = @(stat) stat?.headshots ?? 0
  }
  {
    statId = "long_range_kill"
    calculator = @(stat) stat?.long_range_kills ?? 0
  }
  {
    statId = "ampulomet_kills"
  }
  {
    statId = "engineer_ammo_box_usage"
  }
  {
    statId = "infantry_bomb_kills"
    calculator = @(stat) (stat?.infantry_bomb_kills ?? 0) + (stat?.crew_bomb_kills ?? 0)
  }
  {
    statId = "infantry_rocket_kills"
    calculator = @(stat) (stat?.infantry_rocket_kills ?? 0) + (stat?.crew_rocket_kills ?? 0)
  }
  {
    statId = "engineer_rally_point_usage_short"
    calculator = @(stat) stat?.engineer_rally_point_usage ?? 0
  }
  {
    statId = "owned_mobile_spawn_usage"
  }
  {
    statId = "tank_commander_kills"
  }
  {
    statId = "vehicle_spots"
    calculator = @(stat) (stat?.tank_spots ?? 0) + (stat?.apc_spots ?? 0)
  }
]

let playerStatsList = [
  {
    statId = "battles"
    calculator = @(stat) stat?.battles ?? 0
  }
  {
    statId = "killsDeaths"
    calculator = function(stat) {
      let { kills = 0, deaths = 0 } = stat
      return deaths <= 0 ? 0
        : round_by_value(kills.tofloat() / deaths.tofloat(), 0.01)
    }
  }
  {
    statId = "winRate"
    unitSign = "%"
    calculator = function(stat) {
      let { victories = 0, defeats = 0 } = stat
      let battles = victories + defeats
      return battles <= 0 ? 0
        : round_by_value(100.0 * victories / battles, 0.01)
    }
  }
  {
    statId = "battleTime"
    calculator = @(stat) secondsToHoursLoc(stat?.battle_time ?? 0)
  }
]

return {
  curTabIdx
  isProfileOpened
  playerStatsList
  killsList
  isRanksInfoVisible
}
