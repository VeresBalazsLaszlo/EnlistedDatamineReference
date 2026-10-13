from "%enlSqGlob/battleHeroesAwards.nut" import BattleHeroesAward
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/ui_library.nut" import *

let battleHeroAwardIcon = {
  [BattleHeroesAward.TOP_PLACE] = { img = "ui/uiskin/battlehero/debriefing_awards_first_place.avif" },
  [BattleHeroesAward.TOP_VEHICLE_SQUAD] = { img = "ui/uiskin/battlehero/debriefing_awards_best_mechanic.avif" },
  [BattleHeroesAward.TOP_INFANTRY_SQUAD] = { img = "ui/uiskin/battlehero/debriefing_awards_best_infantryman.avif" },
  [BattleHeroesAward.TOP_KIND_RIFLE] = { img = "ui/uiskin/battlehero/debriefing_awards_best_rifle.avif" },
  [BattleHeroesAward.TOP_KIND_ASSAULT] = { img = "ui/uiskin/battlehero/debriefing_awards_best_assault.avif" },
  [BattleHeroesAward.TOP_KIND_MGUN] = { img = "ui/uiskin/battlehero/debriefing_awards_best_mgun.avif" },
  [BattleHeroesAward.TOP_KIND_ENGINEER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_engineer.avif" },
  [BattleHeroesAward.TOP_KIND_FLAMETROOPER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_flametrooper.avif" },
  [BattleHeroesAward.TOP_KIND_PILOT_ASSAULTER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_pilot_assaulter.avif" },
  [BattleHeroesAward.TOP_KIND_PILOT_FIGHTER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_pilot_fighter.avif" },
  [BattleHeroesAward.TOP_KIND_MORTARMAN] = { img = "ui/uiskin/battlehero/debriefing_awards_best_mortarman.avif" },
  [BattleHeroesAward.TOP_KIND_RADIOMAN] = { img = "ui/uiskin/battlehero/debriefing_awards_best_radioman.avif" },
  [BattleHeroesAward.TOP_KIND_TANKER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_tanker.avif" },
  [BattleHeroesAward.TOP_KIND_ANTI_TANK] = { img = "ui/uiskin/battlehero/debriefing_awards_best_anti_tank.avif" },
  [BattleHeroesAward.TOP_KIND_APC_DRIVER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_apc_driver.avif" },
  [BattleHeroesAward.TOP_KIND_SNIPER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_sniper.avif" },
  [BattleHeroesAward.TOP_KIND_MEDIC] = { img = "ui/uiskin/battlehero/debriefing_awards_best_medic.avif" },
  [BattleHeroesAward.TOP_KIND_BIKER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_biker.avif" },
  [BattleHeroesAward.TOP_KIND_PARTISAN] = { img = "ui/uiskin/battlehero/debriefing_awards_best_partisan.avif" },
  [BattleHeroesAward.TOP_KIND_PARATROOPER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_paratrooper.avif" },
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = { img = "ui/uiskin/battlehero/debriefing_awards_crusher.avif" },
  [BattleHeroesAward.TOP_MELEE_KILLS] = { img = "ui/uiskin/battlehero/debriefing_awards_melee_specialist.avif" },
  [BattleHeroesAward.TOP_GRENADE_KILLS] = { img = "ui/uiskin/battlehero/debriefing_awards_explosives_specialist.avif" },
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = { img = "ui/uiskin/battlehero/debriefing_awards_ranged_specialist.avif" },
  [BattleHeroesAward.TOP_ENGINEER_BUILDER] = { img = "ui/uiskin/battlehero/debriefing_awards_best_engineer_builder.avif" },
  [BattleHeroesAward.BERSERK] = { img = "ui/uiskin/battlehero/debriefing_awards_berserk.avif" },
  [BattleHeroesAward.FURIOUS] = { img = "ui/uiskin/battlehero/debriefing_awards_furious.avif" },
  [BattleHeroesAward.CONTRIBUTION_TO_VICTORY] = { img = "ui/uiskin/battlehero/debriefing_awards_contribution_to_victory.avif" },
  [BattleHeroesAward.PARATROOPER] = { img = "ui/uiskin/battlehero/debriefing_awards_paratrooper.avif" },
  [BattleHeroesAward.TACTICIAN] = { img = "ui/uiskin/battlehero/debriefing_awards_tactician.avif" },
  [BattleHeroesAward.UNIVERSAL] = { img = "ui/uiskin/battlehero/debriefing_awards_universal.avif" },
  [BattleHeroesAward.MULTISPECIALIST] = { img = "ui/uiskin/battlehero/debriefing_awards_multispecialist.avif" },
  [BattleHeroesAward.SQUAD_COMMAND] = { img = "ui/uiskin/battlehero/debriefing_awards_squad_command.avif" },
  [BattleHeroesAward.BATTLE_HEROES_CARD] = { img = "ui/uiskin/battlehero/debriefing_awards_postcard.avif" },
  [BattleHeroesAward.PLAYER_BATTLE_HERO] = { img = "ui/uiskin/battlehero/debriefing_awards_mvp.avif" },
  [BattleHeroesAward.TOP_KIND_SABOTEUR] = { img = "ui/uiskin/battlehero/debriefing_awards_saboteur_specialist.avif" },
}

let mkAwardForegroundIcon = @(img, size) {
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  size
  image = Picture($"{img}:{size[0]}:{size[1]}")
}

let mkAwardForegroundText = @(text, size) {
  fontSize = size[1]*0.5
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  size
  text
}

let mkAwardValue = @(text, isBig) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  text
}.__update(isBig ? fontHeading2 : fontSub)

function mkBattleHeroAwardIcon(award, size, isActive=true, isBig=false) {
  let awardId = award?.id ?? award
  let icon = battleHeroAwardIcon?[awardId] ?? { text = "?" }
  let tint = isActive ? {} : {tint = Color(40, 40, 40, 120), picSaturate = 0.0}
  return {
    size
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      icon?.img != null ? mkAwardForegroundIcon(icon.img, size) : mkAwardForegroundText(icon.text, size)
      award?.value != null ? mkAwardValue(award.value, isBig) : null
    ].map(@(v) v?.__merge(tint))
  }
}

return mkBattleHeroAwardIcon
