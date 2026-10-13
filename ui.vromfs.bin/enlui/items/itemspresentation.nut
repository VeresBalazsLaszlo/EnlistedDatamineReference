from "%ui/items/itemsPresentationUtils.nut" import mkImageParams, mkImageCtor, mkTemplateImageCtor,
  goldRadialGradient, goldVerticalGradient
from "%ui/style/designConst.nut" import darkTxtColor
from "%ui/ui_library.nut" import *


let defRewardPresentation = {
  cardImage = "ui/skin#rewards/crate_small_1.avif"
  cardImageParams = mkImageParams([240, 240])
  cardImageOpen = "ui/skin#rewards/crate_small_1_open.avif"
}

let GOLD_PRESENTATION = {
  name = loc("currency/code/EnlistedGold")
  description = loc("currency/gold_currency_desc")
  icon = "!ui/uiskin/currency/enlisted_gold.svg"
  gametemplate = "item_ecoin"
  bgImage = "ui/skin#battlepass/bg_gold.avif"
  cardImage = "ui/skin#battlepass/gold_coins.avif"
  cardImageParams = mkImageParams([166, 136], [0, -4])
  worth = 10
}

let SILVER_PRESENTATION = {
  name = loc("currency/silver_currency")
  description = loc("currency/silver_currency_desc")
  icon = "!ui/uiskin/currency/enlisted_silver.svg"
  itemTemplate = "enlisted_silver"
  bgImage = "ui/skin#battlepass/bg_other.avif"
  cardImage = "ui/skin#battlepass/silver_coins.avif"
  cardImageParams = mkImageParams([166, 136], [0, -4])
}

let CALLNAME_ORDER_PRESENTATION = {
  name = loc("items/callname_change_order")
  description = loc("items/callname_change_order/desc")
  icon = "ui/skin#currency/soldier_name_change.svg"
  itemTemplate = "callname_change_order"
  bgImage = "ui/skin#battlepass/bg_other.avif"
  cardImage = "ui/skin#battlepass/rename.avif"
  cardImageParams = mkImageParams([154, 144], [0, 15])
}

let APPEARANCE_ORDER_PRESENTATION = {
  name = loc("items/appearance_change_order")
  description = loc("items/appearance_change_order/desc")
  icon = "ui/skin#currency/soldier_appearance.svg"
  itemTemplate = "appearance_change_order"
  bgImage = "ui/skin#battlepass/bg_other.avif"
  cardImage = "ui/skin#battlepass/makeup.avif"
  cardImageParams = mkImageParams([162, 148], [0, 18])
}

let LEVELUP_ORDER_PRESENTATION = {
  name = loc("items/soldier_levelup_order")
  description = loc("items/soldier_levelup_order/desc")
  icon = "!ui/uiskin/currency/soldier_levelup.svg"
  itemTemplate = "soldier_levelup_order"
  worth = 2
  bgImage = "ui/skin#battlepass/bg_other.avif"
  cardImage = "ui/skin#battlepass/up_soldier.avif"
  cardImageParams = mkImageParams([170, 142], [-2, 4])
}

let VEH_UPGRADE_PRESENTATION = {
  name = loc("items/vehicle_upgrade_order")
  description = loc("items/vehicle_upgrade_order/desc")
  icon = "ui/skin#currency/vehicle_upgrade.svg"
  itemTemplate = "vehicle_upgrade_order"
  bgImage = "ui/skin#battlepass/bg_gold.avif"
  cardImage = "ui/skin#battlepass/up_vehicles.avif"
  cardImageParams = mkImageParams([170, 124], [3, 1])
}

let ITEM_UPGRADE_PRESENTATION = {
  name = loc("items/item_upgrade_order")
  description = loc("items/item_upgrade_order/desc")
  icon = "ui/skin#currency/item_upgrade.svg"
  itemTemplate = "item_upgrade_order"
  bgImage = "ui/skin#battlepass/bg_gold.avif"
  cardImage = "ui/skin#battlepass/up_weapons.avif"
  cardImageParams = mkImageParams([170, 124], [3, 1])
}

let rewardsPresentation = freeze({
  ["EnlistedGold"]            = GOLD_PRESENTATION,
  ["enlisted_silver"]         = SILVER_PRESENTATION,
  ["callname_change_order"]   = CALLNAME_ORDER_PRESENTATION,
  ["appearance_change_order"] = APPEARANCE_ORDER_PRESENTATION,
  ["soldier_levelup_order"]   = LEVELUP_ORDER_PRESENTATION,
  ["vehicle_upgrade_order"]   = VEH_UPGRADE_PRESENTATION,
  ["item_upgrade_order"]      = ITEM_UPGRADE_PRESENTATION,

  ["any_weapon"] = {
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
  },
  ["any_vehicle"] = {
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
  },
  ["any_portrait"] = {
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["any_vehdecorator"] = {
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/up_vehicles.avif"
    cardImageParams = mkImageParams([170, 124], [3, 1])
  },
  ["any_soldier"] = {
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["any_squad"] = {
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },


  ["9"]  = { worth = 0.5 }.__update(SILVER_PRESENTATION),
  ["10"] = { worth = 0.5 }.__update(SILVER_PRESENTATION),
  ["11"] = { worth = 1 }.__update(SILVER_PRESENTATION),
  ["12"] = { worth = 1 }.__update(SILVER_PRESENTATION),
  ["13"] = {
    name = loc("items/weapon_order_gold")
    description = loc("items/weapon_order_gold/battlepass_desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    itemTemplate ="weapon_order_gold"
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    specialRewards = {
      [15] = {
        ussr = "yazikov_smg"
        ger = "pavesi_prototype_svt_copy"
        usa = "bren_100_round_drum"
        jap = "murata_type_22"
      }
    }
  },
  ["14"] = {
    name = loc("items/soldier_order_gold")
    description = loc("items/soldier_order_gold/battlepass_desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    itemTemplate ="soldier_order_gold"
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["23"] = {
    name = loc("items/random_battlepass_order_crate")
    description = loc("items/random_battlepass_order_crate/desc")
    icon = "ui/skin#currency/random_battlepass_order.svg"
    gametemplate = "random_battlepass_order"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/random.avif"
    cardImageParams = mkImageParams([144, 122])
  },
  ["30"] = {
    name = loc("items/soldier_reward")
    icon = "ui/skin#events/soldier_reward_icon.svg"
    worth = 3
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["31"] = {
    name = loc("items/vehicle_with_skin_order_gold")
    description = loc("items/vehicle_with_skin_order_gold/desc")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    itemTemplate ="vehicle_with_skin_order_gold"
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["33"] = {
    name = loc("items/research_change_order")
    description = loc("items/research_change_order/desc")
    icon = "ui/skin#currency/squad_respec.svg"
    itemTemplate ="research_change_order"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/reset_xp.avif"
    cardImageParams = mkImageParams([146, 148])
  },
  ["34"] = { worth = 2 }.__update(ITEM_UPGRADE_PRESENTATION),
  ["35"] = { worth = 2 }.__update(LEVELUP_ORDER_PRESENTATION),
  ["36"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["37"] = { worth = 2 }.__update(CALLNAME_ORDER_PRESENTATION),
  ["38"] = { worth = 2 }.__update(APPEARANCE_ORDER_PRESENTATION),
  ["40"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100]) 
  },
  ["41"] = {
    name = loc("vehicleDetails/fw_189a_1")
    description = loc("items/fw_189a_1/desc")
    icon = "ui/skin#aircraft_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkTemplateImageCtor([190, 190], [0, 18], "fw_189a1", { iconRoll = 50, iconYaw = -35 })
  },
  ["42"] = {
    name = loc("vehicleDetails/us_m5a1_stuart_rhino_event_premium")
    description = loc("items/us_m5a1_stuart_rhino_event_premium/desc")
    icon = "ui/skin#tank_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkTemplateImageCtor([170, 150], [0, 12], "us_m5a1_stuart_rhino_event_premium")
  },
  ["43"] = {
    name = loc("squad/ussr_berlin_event_assault_1")
    description = loc("squadannounce/ussr_berlin_event_assault_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#squads/ussr/ussr_berlin_event_assault_1_icon.svg"
    mkImage = mkImageCtor([120, 111], [-4, 28]) 
  },
  ["45"] = defRewardPresentation.__merge({
    name = loc("smallTrophyTitle_1")
  }),
  ["49"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["50"] = {
    name = loc("items/booster_global_battlepass_100_battle_3")
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["186"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["187"] = {
    name = loc("items/battlepass_buster_soldier_3")
    description = loc("items/battlepass_buster_soldier_3/desc")
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_soldier_3_template"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_soldier.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["188"] = {
    name = loc("items/battlepass_buster_squad_5")
    description = loc("items/battlepass_buster_squad_5/desc")
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_squad_5_template"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_squad.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["179"] = {
    name = loc("squad/allies_tunisia_event_mgun_1")
    description = loc("squadannounce/allies_tunisia_event_mgun_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#squads/usa/allies_tunisia_event_mgun_1_icon.svg"
    mkImage = mkImageCtor([120, 111], [-4, 28]) 
  },
  ["180"] = {
    name = loc("items/tunisia_axis_hero_marathon_2021_autumn")
    description = loc("items/tunisia_axis_hero_marathon_2021_autumn/desc")
    icon = "ui/skin#icons/germany/italy_hero_medal_1_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#icons/germany/italy_hero_medal_1_icon.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["181"] = {
    name = loc("items/p_47d_22_re")
    description = loc("items/p_47d_22_re/desc")
    icon = "ui/skin#aircraft_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkTemplateImageCtor([190, 190], [0, 18], "p_47d_22_re_joan_premium", { iconRoll = 50, iconYaw = -35 })
  },
  ["182"] = {
    name = loc("items/germ_jgdpz_iv_l48")
    description = loc("items/germ_jgdpz_iv_l48/desc")
    icon = "ui/skin#tank_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkTemplateImageCtor([170, 150], [0, 12], "germ_panzerjager_IV_L_48_berlin_premium")
  },
  ["189"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["190"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["191"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["192"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["209"] = {
    name = loc("wp/agit_poster_china_a_preview/name")
    description = loc("wp/agit_poster_china_a_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["210"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["211"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_5"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["212"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["213"] = {
    name = loc("items/engineer_event_reward_moscow_allies")
    description = loc("items/engineer_event_reward_moscow_allies/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["214"] = {
    name = loc("items/engineer_event_reward_moscow_axis")
    description = loc("items/engineer_event_reward_moscow_axis/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["215"] = {
    name = loc("items/engineer_event_reward_normandy_allies")
    description = loc("items/engineer_event_reward_normandy_allies/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["216"] = {
    name = loc("items/engineer_event_reward_normandy_axis")
    description = loc("items/engineer_event_reward_normandy_axis/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["217"] = {
    name = loc("items/engineer_event_reward_berlin_allies")
    description = loc("items/engineer_event_reward_berlin_allies/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["218"] = {
    name = loc("items/engineer_event_reward_berlin_axis")
    description = loc("items/engineer_event_reward_berlin_axis/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["219"] = {
    name = loc("items/engineer_event_reward_tunisia_allies")
    description = loc("items/engineer_event_reward_tunisia_allies/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["220"] = {
    name = loc("items/engineer_event_reward_tunisia_axis")
    description = loc("items/engineer_event_reward_tunisia_axis/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["241"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["242"] = {
    name = loc("items/victory_day_event_order")
    description = loc("items/victory_day_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["243"] = {
    name = loc("items/soldier_exclusive")
    description = loc("items/soldier_exclusive/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    itemTemplate ="soldier_order_gold"
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["244"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["245"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["246"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_6"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["247"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["248"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["249"] = { worth = 2 }.__update(VEH_UPGRADE_PRESENTATION),
  ["250"] = {
    name = loc("squad/allies_tunisia_event_assault_1")
    description = loc("squadannounce/allies_tunisia_event_assault_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#squads/usa/allies_tunisia_event_assault_1_icon.svg"
    mkImage = mkImageCtor([120, 111], [-4, 28]) 
  },
  ["251"] = {
    name = loc("squad/ger_normandy_event_assault_1")
    description = loc("squadannounce/ger_normandy_event_assault_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#squads/germany/ger_normandy_event_assault_1_icon.svg"
    mkImage = mkImageCtor([120, 111], [-4, 28]) 
  },
  ["252"] = {
    name = loc("items/ussr_bt_7a_f32")
    description = loc("items/ussr_bt_7a_f32/desc")
    icon = "ui/skin#tank_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkTemplateImageCtor([170, 150], [0, 12], "ussr_bt_7a_f32_stalingrad_premium")
  },
  ["253"] = {
    name = loc("items/moscow_allies_hero_marathon_2022_summer")
    description = loc("items/moscow_allies_hero_marathon_2022_summer/desc")
    icon = "ui/skin#icons/ussr/ussr_hero_medal_1_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#icons/ussr/ussr_hero_medal_1_icon.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["254"] = {
    name = loc("items/normandy_axis_event_marathon_summer_2022_portrait")
    description = loc("items/normandy_axis_event_marathon_summer_2022_portrait/desc")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["255"] = {
    name = loc("items/tunisia_allies_event_marathon_summer_2022_portrait")
    description = loc("items/tunisia_allies_event_marathon_summer_2022_portrait/desc")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["256"] = {
    name = loc("items/marathon_2022_summer_event_order")
    description = loc("items/marathon_2022_summer_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["257"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["259"] = {
    name = loc("wp/agit_poster_china_b_preview/name")
    description = loc("wp/agit_poster_china_b_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["260"] = {
    name = loc("wp/agit_poster_china_c_preview/name")
    description = loc("wp/agit_poster_china_c_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["261"] = {
    name = loc("wp/agit_poster_china_d_preview/name")
    description = loc("wp/agit_poster_china_d_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["262"] = {
    name = loc("wp/agit_poster_china_e_preview/name")
    description = loc("wp/agit_poster_china_e_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["263"] = {
    name = loc("wp/agit_poster_china_f_preview/name")
    description = loc("wp/agit_poster_china_f_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["265"] = {
    name = loc("items/normandy_allies_hero_airborne_day_2022")
    description = loc("items/normandy_allies_hero_airborne_day_2022/desc")
    icon = "ui/skin#icons/usa/usa_hero_medal_1_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#icons/usa/usa_hero_medal_1_icon.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["324"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["344"] = {
    name = loc("items/pacific_event_2022_order")
    description = loc("items/pacific_event_2022_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["348"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_7"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["353"] = {
    name = loc("wp/agit_poster_china_g_preview/name")
    description = loc("wp/agit_poster_china_g_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["354"] = {
    name = loc("wp/agit_poster_china_h_preview/name")
    description = loc("wp/agit_poster_china_h_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["356"] = {
    name = loc("items/sea_predator_reward_order")
    description = loc("items/sea_predator_reward_order/desc")
    icon = "ui/skin#currency/random_reward_order.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/random_reward.avif"
    cardImageParams = mkImageParams([102, 146], [0, -10])
  },
  ["357"] = {
    name = loc("items/sea_predator_decal_order")
    description = loc("items/sea_predator_decal_order/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["359"] = {
    name = loc("items/armory_event_crate")
    description = loc("items/armory_event_crate/desc")
    icon = "ui/skin#currency/random_reward_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/random_reward_order.svg"
    mkImage = mkImageCtor([72, 100]) 
  },
  ["360"] = {
    name = loc("items/armory_event_portrait_usa")
    description = loc("decorator/armory_event_portrait_usa/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["361"] = {
    name = loc("items/armory_event_portrait_ger")
    description = loc("decorator/armory_event_portrait_ger/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["364"] = {
    name = loc("wp/agit_poster_china_i_preview/name")
    description = loc("wp/agit_poster_china_i_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["365"] = {
    name = loc("wp/agit_poster_china_j_preview/name")
    description = loc("wp/agit_poster_china_j_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["368"] = {
    name = loc("items/enlisted2years_portrait_ussr")
    description = loc("decorator/enlisted2years_portrait/tip")
    icon = "!ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["369"] = {
    name = loc("items/enlisted2years_portrait_britain")
    description = loc("decorator/enlisted2years_portrait/tip")
    icon = "!ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["370"] = {
    name = loc("items/enlisted2years_portrait_usa")
    description = loc("decorator/enlisted2years_portrait/tip")
    icon = "!ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["371"] = {
    name = loc("decals/su_ulan_ude_bear")
    description = loc("decals/su_ulan_ude_bear/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    mkImage = mkImageCtor([144, 170], [0, 17])
  },
  ["372"] = {
    name = loc("decals/uk_britannia_defiant")
    description = loc("decals/uk_britannia_defiant/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    mkImage = mkImageCtor([144, 170], [0, 17])
  },
  ["373"] = {
    name = loc("decals/su_guards_emblem")
    description = loc("decals/su_guards_emblem/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    mkImage = mkImageCtor([144, 170], [0, 17])
  },
  ["374"] = {
    name = loc("decals/us_836_bmb_sqn_liberty_belle")
    description = loc("decals/us_836_bmb_sqn_liberty_belle/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    mkImage = mkImageCtor([144, 170], [0, 17])
  },
  ["375"] = {
    name = loc("decals/de_jg26_sqn_4_who_tiger")
    description = loc("decals/de_jg26_sqn_4_who_tiger/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    mkImage = mkImageCtor([144, 170], [0, 17])
  },
  ["377"] = {
    name = loc("wp/agit_poster_china_k_preview/name")
    description = loc("wp/agit_poster_china_k_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["378"] = {
    name = loc("items/xmas_event_order")
    description = loc("items/xmas_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["379"] = {
    name = loc("items/xmas_event_ussr_portrait")
    description = loc("decorator/xmas_event_portrait/tip")
    icon = "!ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["380"] = {
    name = loc("items/xmas_event_ger_portrait")
    description = loc("decorator/xmas_event_portrait/tip")
    icon = "!ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["382"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_8"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["384"] = {
    name = loc("items/stalingrad_event_portrait_ussr")
    description = loc("decorator/stalingrad_event_portrait_ussr/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["385"] = {
    name = loc("items/heavy_weapons_event_order")
    description = loc("items/heavy_weapons_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["386"] = {
    name = loc("vehicleDetails/jp_type_97_kai")
    description = loc("items/jp_type_97_kai/desc")
    icon = "ui/skin#tank_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkTemplateImageCtor([170, 150], [0, 12], "jp_type_97_kai_pacific_premium")
  },
  ["412"] = {
    name = loc("wp/agit_poster_china_l_preview/name")
    description = loc("wp/agit_poster_china_l_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["413"] = {
    name = loc("wp/agit_poster_china_m_preview/name")
    description = loc("wp/agit_poster_china_m_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#currency/poster_icon.svg"
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["414"] = {
    icon = "ui/skin#battlepass/deserter_penalty_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_penalty.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["415"] = {
    name = loc("items/engineerDay23_event_portrait")
    description = loc("decorator/engineerDay23_event_portrait/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["316"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["416"] = {
    name = loc("items/engineer_event_reward_stalingrad_allies")
    description = loc("items/engineer_event_reward_stalingrad_allies/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["417"] = {
    name = loc("items/engineer_event_reward_stalingrad_axis")
    description = loc("items/engineer_event_reward_stalingrad_axis/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["418"] = {
    name = loc("items/engineer_event_reward_pacific_allies")
    description = loc("items/engineer_event_reward_pacific_allies/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["419"] = {
    name = loc("items/engineer_event_reward_pacific_axis")
    description = loc("items/engineer_event_reward_pacific_axis/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["420"] = {
    name = loc("items/m2_mortar")
    description = loc("items/m2_mortar/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/m2_mortar.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["421"] = {
    name = loc("squad/ussr_moscow_event_antitank_1")
    description = loc("squadannounce/ussr_moscow_event_antitank_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/ussr/ussr_moscow_event_antitank_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["422"] = {
    name = loc("squad/ger_moscow_event_antitank_1")
    description = loc("squadannounce/ger_moscow_event_antitank_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/ger_moscow_event_antitank_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["423"] = {
    name = loc("items/mech_event_crate")
    description = loc("items/mech_event_crate/desc")
    cardImage = "ui/skin#random_reward_chest.avif"
    mkImage = mkImageCtor([200, 200], [0, 0]) 
  },
  ["436"] = {
    name = loc("squad/usa_normandy_event_paratrooper_1")
    description = loc("squadannounce/usa_normandy_event_paratrooper_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/usa_normandy_event_paratrooper_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["437"] = {
    name = loc("squad/ger_normandy_event_paratrooper_1")
    description = loc("squadannounce/ger_normandy_event_paratrooper_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/ger_normandy_event_paratrooper_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["438"] = {
    name = loc("squad/allies_pacific_event_paratrooper_1")
    description = loc("squadannounce/allies_pacific_event_paratrooper_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/allies_pacific_event_paratrooper_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["439"] = {
    name = loc("squad/axis_pacific_event_paratrooper_1")
    description = loc("squadannounce/axis_pacific_event_paratrooper_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/japan/axis_pacific_event_paratrooper_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["440"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_9"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["441"] = {
    name = loc("items/berlin_operation_medic_portrait")
    description = loc("decorator/berlin_operation_medic_portrait/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "!ui/portraits/default_portrait.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["442"] = {
    name = loc("squad/ussr_moscow_event_tank_1")
    description = loc("squadannounce/ussr_moscow_event_tank_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/ussr/ussr_moscow_event_tank_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["443"] = {
    name = loc("squad/ger_moscow_event_tank_1")
    description = loc("squadannounce/ger_moscow_event_tank_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/ger_moscow_event_tank_1_image.avif"
    mkImage = mkImageCtor([400, 300], [0, 0])
  },
  ["444"] = {
    name = loc("items/victory_day_2023_event_order")
    description = loc("items/victory_day_2023_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["445"] = {
    name = loc("items/victory_day_2023_event_crate")
    description = loc("items/victory_day_2023_event_crate/desc")
    icon = "ui/skin#currency/random_reward_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/random_reward_order.svg"
    mkImage = mkImageCtor([72, 100]) 
  },
  ["446"] = {
    name = loc("items/armedForces_day_2023_event_order")
    description = loc("items/armedForces_day_2023_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["448"] = {
    name = loc("decals/summer_ops_girl_usa")
    description = loc("decals/summer_ops_girl_usa/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    cardImage = "https://static-ggc.gaijin.net/chronicle/item_summer_ops_girl_usa.png"
    mkImage = mkImageCtor([170, 170], [0, 17])
  },
  ["449"] = {
    name = loc("items/stalingrad_2023_event_order")
    description = loc("items/stalingrad_2023_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["450"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_10"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["451"] = {
    name = loc("items/armory2_bonus_portrait_ussr")
    description = loc("items/armory2_bonus_portrait_ussr/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/armory2_bonus_portrait_ussr.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["452"] = {
    name = loc("items/armory2_bonus_portrait_ger")
    description = loc("items/armory2_bonus_portrait_ger/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/armory2_bonus_portrait_ger.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["453"] = {
    name = loc("items/armory2_event_order")
    description = loc("items/armory2_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["454"] = {
    name = loc("items/luftfaust_b")
    description = loc("items/luftfaust_b/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/luftfaust_b.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["455"] = {
    name = loc("squad/axis_pacific_event_pilot_fighter_1")
    description = loc("squadannounce/axis_pacific_event_pilot_fighter_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/japan/axis_pacific_event_pilot_fighter_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["456"] = {
    name = loc("squad/allies_pacific_event_pilot_fighter_1")
    description = loc("squadannounce/allies_pacific_event_pilot_fighter_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/allies_pacific_event_pilot_fighter_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["457"] = {
    name = loc("decals/uk_no_2_sqn_fox_head")
    description = loc("decals/uk_no_2_sqn_fox_head/desc")
    icon = "!ui/uiskin/currency/decal_order_event.svg"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    mkImage = mkImageCtor([170, 170], [0, 17])
  },
  ["458"] = {
    name = loc("squad/squad_uk_paratrooper_2_event_2")
    description = loc("squadannounce/squad_uk_paratrooper_2_event_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/squad_uk_paratrooper_2_event_2_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["459"] = {
    name = loc("squad/squad_it_paratrooper_2_event_2")
    description = loc("squadannounce/squad_it_paratrooper_2_event_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/squad_it_paratrooper_2_event_2_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["460"] = {
    name = loc("items/italyParatroopers_event_order")
    description = loc("items/italyParatroopers_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["461"] = { worth = 0.5 }.__update(SILVER_PRESENTATION),
  ["476"] = {
    name = loc("items/armory3_event_order")
    description = loc("items/armory3_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["477"] = {
    name = loc("items/armory3_bonus_portrait_italy")
    description = loc("items/armory3_bonus_portrait_italy/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/armory3_bonus_portrait_italy.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["478"] = {
    name = loc("items/armory3_bonus_portrait_britain")
    description = loc("items/armory3_bonus_portrait_britain/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/armory3_bonus_portrait_britain.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["479"] = {
    name = loc("squad/squad_ussr_paratrooper_2_event_1")
    description = loc("squadannounce/squad_ussr_paratrooper_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/ussr/squad_ussr_paratrooper_2_event_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["481"] = {
    name = loc("items/battlepass_11_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/battlepass_11_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["482"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["484"] = {
    name = loc("decorator/birthday2_bonus_portrait_tanker")
    description = loc("decorator/birthday2_bonus_portrait_tanker/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/birthday2_bonus_portrait_tanker.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["485"] = {
    name = loc("decorator/birthday2_bonus_portrait_pilot")
    description = loc("decorator/birthday2_bonus_portrait_pilot/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/birthday2_bonus_portrait_pilot.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["486"] = {
    name = loc("items/ussr_hero_birthday_2023")
    description = loc("items/ussr_hero_birthday_2023/desc")
    icon = "ui/skin#icons/ussr/ussr_hero_medal_1_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#icons/ussr/ussr_hero_medal_1_icon.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["487"] = {
    name = loc("items/birthday2_event_order")
    description = loc("items/birthday2_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["490"] = {
    name = loc("squad/ussr_berlin_event_assault_2")
    description = loc("squadannounce/ussr_berlin_event_assault_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#research/squad_points_icon.svg"
    mkImage = mkImageCtor([150, 150], [0, 0])
  },
  ["491"] = {
    name = loc("squad/ger_berlin_event_assault_1")
    description = loc("squadannounce/ger_berlin_event_assault_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#research/squad_points_icon.svg"
    mkImage = mkImageCtor([150, 150], [0, 0])
  },
  ["492"] = {
    name = loc("decorator/usentry_bonus_portrait")
    description = loc("decorator/usentry_bonus_portrait/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/usentry_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["493"] = {
    name = loc("decals/new_year24_event_decal")
    description = loc("decals/new_year24_event_decal/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["494"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["495"] = {
    name = loc("decorator/snowshoes")
    description = loc("decorator/snowshoes/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["496"] = {
    name = loc("decorator/ski")
    description = loc("decorator/ski/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["497"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_12"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_poster.avif"
    cardImage = "ui/skin#battlepass/posters.avif"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["498"] = {
    name = loc("items/battlepass_12_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/battlepass_12_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["499"] = {
    name = loc("squad/squad_uk_apc_driver_2_event_1")
    description = loc("squadannounce/squad_uk_apc_driver_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/squad_uk_apc_driver_2_event_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["500"] = {
    name = loc("squad/squad_ger_apc_driver_2_event_1")
    description = loc("squadannounce/squad_ger_apc_driver_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/squad_ger_apc_driver_2_event_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["501"] = {
    name = loc("items/ger_pelzmutze_m43_closed_1")
    description = loc("items/ger_pelzmutze_m43_closed_1/desc")
    icon = "!ui/portraits/default_portrait.svg"
    itemTemplate ="ger_pelzmutze_m43_closed_1"
    worth = 2
    cardImage = "ui/skin#battlepass/battle_pass_ger_outfit_1.avif"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    mkImage = mkImageCtor([180, 180], [0, -5])
  },
  ["504"] = {
    name = loc("items/lunarNewyear24_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/lunarNewyear24_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["505"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["506"] = {
    name = loc("decals/usa_1st_armoured_division")
    description = loc("decals/usa_1st_armoured_division/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["507"] = {
    name = loc("items/engineerDay24_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/engineerDay24_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["508"] = {
    name = loc("squad/squad_ger_engineer_2_event_1")
    description = loc("squadannounce/squad_ger_engineer_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/squad_ger_engineer_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["509"] = {
    name = loc("squad/squad_ussr_engineer_2_event_1")
    description = loc("squadannounce/squad_ussr_engineer_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/ussr/squad_ussr_engineer_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["510"] = {
    name = loc("items/m1911a1_colt_nickel")
    description = loc("items/m1911a1_colt_nickel/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/m1911a1_colt_nickel.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["511"] = {
    icon = "ui/skin#battlepass/base_booster_icon.svg"
    worth = 2
    bgImage = "ui/skin#battlepass/bg_boost.avif"
    cardImage = "ui/skin#battlepass/boost_global.avif"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["512"] = {
    name = loc("items/mauser_gewehr_98_warmod")
    description = loc("items/mauser_gewehr_98_warmod/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mauser_gewehr_98_warmod.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["513"] = {
    name = loc("items/mauser_event_order")
    description = loc("items/mauser_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["514"] = {
    name = loc("decorator/zombie_bonus_portrait_A")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/zombie_bonus_portrait_A.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["515"] = {
    name = loc("decorator/zombie_bonus_portrait_B")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/zombie_bonus_portrait_B.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["516"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["517"] = {
    name = loc("items/shpagin_event_order")
    description = loc("items/shpagin_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["518"] = {
    name = loc("decorator/shpaginBirthday_bonus_portrait")
    description = loc("decorator/shpaginBirthday_bonus_portrait/desc")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/shpaginBirthday_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["519"] = {
    name = loc("decorator/zombie_lb_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/zombie_lb_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["520"] = {
    name = loc("decorator/battlepass_13_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/battlepass_13_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["521"] = {
    name = loc("decals/us_332_fg_spitfire")
    description = loc("decals/us_332_fg_spitfire/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["522"] = {
    name = loc("items/p47firstFlight_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/p47firstFlight_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["523"] = {
    name = loc("items/sw_m1917_engraved")
    description = loc("items/sw_m1917_engraved/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/sw_m1917_engraved.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["524"] = {
    name = loc("items/colt_swartz")
    description = loc("items/colt_swartz/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/colt_swartz.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["525"] = {
    name = loc("items/thompson_30_cal")
    description = loc("items/thompson_30_cal/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/thompson_30_cal.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["526"] = {
    name = loc("items/pps_42_red")
    description = loc("items/pps_42_red/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/weapons/pps_42_red.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["527"] = {
    name = loc("items/whirlwind_mk1")
    description = loc("items/whirlwind_mk1/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_vehicles.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/vehicles/whirlwind_mk1.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["528"] = {
    name = loc("items/ussr_t_34_100")
    description = loc("items/ussr_t_34_100/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_vehicles.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/vehicles/ussr_t_34_100.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["529"] = {
    name = loc("decorator/victory_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/victory_bonus_portrait.avif"
  },
  ["530"] = {
    name = loc("items/nambu_type_14_engraved")
    description = loc("items/nambu_type_14_engraved/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/nambu_type_14_engraved.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["531"] = {
    name = loc("items/atr_type_97_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/atr_type_97_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["532"] = {
    name = loc("items/besal_lmg")
    description = loc("items/besal_lmg/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/weapons/besal_lmg.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["533"] = {
    name = loc("items/lanchester_50_round")
    description = loc("items/lanchester_50_round/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/weapons/lanchester_50_round.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["534"] = {
    name = loc("decorator/war_photograph_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/war_photograph_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["535"] = {
    name = loc("items/tt_33_red")
    description = loc("items/tt_33_red/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/tt_33_red.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["536"] = {
    name = loc("squad/squad_ger_mgun_3_event_1")
    description = loc("squadannounce/squad_ger_mgun_3_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/squad_ger_mgun_3_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["537"] = {
    name = loc("squad/squad_ussr_assault_3_event_1")
    description = loc("squadannounce/squad_ussr_assault_3_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/ussr/squad_ussr_assault_3_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["538"] = {
    name = loc("decorator/nkvd_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/nkvd_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["539"] = {
    name = loc("items/nkvd_knife")
    description = loc("items/nkvd_knife/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/nkvd_knife.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["540"] = {
    name = loc("squad/squad_jap_radioman_2_event_1")
    description = loc("squadannounce/squad_jap_radioman_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/japan/squad_jap_radioman_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["541"] = {
    name = loc("squad/squad_usa_radioman_2_event_1")
    description = loc("squadannounce/squad_usa_radioman_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/squad_usa_radioman_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["542"] = {
    name = loc("squad/squad_ussr_radioman_2_event_1")
    description = loc("squadannounce/squad_ussr_radioman_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/ussr/squad_ussr_radioman_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["543"] = {
    name = loc("squad/squad_ger_radioman_2_event_1")
    description = loc("squadannounce/squad_ger_radioman_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/germany/squad_ger_radioman_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["544"] = {
    name = loc("decorator/rocketstorm_event_ger_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/rocketstorm_event_ger_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["545"] = {
    name = loc("decorator/rocketstorm_event_ussr_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/rocketstorm_event_ussr_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["546"] = {
    name = loc("items/voevodin_pistol")
    description = loc("items/voevodin_pistol/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/voevodin_pistol.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["547"] = {
    name = loc("decorator/soviet_officer_bonus_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/brestFortress_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["548"] = {
    name = loc("items/an_m2_stinger")
    description = loc("items/an_m2_stinger/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/an_m2_stinger.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["549"] = {
    name = loc("decals/ussr_3_tank_corps")
    description = loc("decals/ussr_3_tank_corps/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["550"] = {
    name = loc("decals/jp_34th_sensha_rentai_2_company")
    description = loc("decals/jp_34th_sensha_rentai_2_company/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["551"] = {
    name = loc("decals/it_reg_lancieri_di_novara")
    description = loc("decals/it_reg_lancieri_di_novara/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["552"] = {
    name = loc("decals/usa_747th_tank_battalion")
    description = loc("decals/usa_747th_tank_battalion/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["553"] = {
    name = loc("items/trialByCombat_event_order")
    description = loc("items/trialByCombat_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["554"] = {
    name = loc("items/ppsh_41_german")
    description = loc("items/ppsh_41_german/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/ppsh_41_german.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["556"] = {
    name = loc("decals/text_relentless_red")
    description = loc("decals/text_relentless_red/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["557"] = {
    name = loc("decals/jp_64th_air_regiment")
    description = loc("decals/jp_64th_air_regiment/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["558"] = {
    name = loc("decorator/battlepass_14_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/battlepass_14_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["559"] = {
    name = loc("decorator/endOfKurskBattle_event_portrait")
    icon = "!ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/endOfKurskBattle_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["202"] = {
    name = loc("items/mosin_m91")
    description = loc("items/mosin_m91/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/weapons/mosin_m91_camouflaged_w.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["560"] = {
    name = loc("decals/uk_no_898_nas_fish")
    description = loc("decals/uk_no_898_nas_fish/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["561"] = {
    name = loc("decals/de_3_boflgr_seahorse")
    description = loc("decals/de_3_boflgr_seahorse/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["562"] = {
    name = loc("items/battleOfTheAtlantic_event_order")
    description = loc("items/battleOfTheAtlantic_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["563"] = {
    name = loc("items/mp_35")
    description = loc("items/mp_35/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mp_35.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["564"] = {
    name = loc("items/breda_m1935_pg_carcano")
    description = loc("items/breda_m1935_pg_carcano/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/breda_m1935_pg_carcano.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["567"] = {
    name = loc("squad/squad_fr_partisan_2_event_1")
    description = loc("squadannounce/squad_fr_partisan_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/squad_fr_partisan_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["569"] = {
    cardImage = "!ui/portraits/event/avatar_halloween_assault.avif"
    previewImage = "!ui/portraits/event/avatar_halloween_assault.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["570"] = {
    cardImage = "!ui/portraits/event/avatar_halloween_engineer.avif"
    previewImage = "!ui/portraits/event/avatar_halloween_engineer.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["571"] = {
    cardImage = "!ui/portraits/event/avatar_halloween_medic.avif"
    previewImage = "!ui/portraits/event/avatar_halloween_medic.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["572"] = {
    cardImage = "!ui/portraits/event/avatar_halloween_anti_tank.avif"
    previewImage = "!ui/portraits/event/avatar_halloween_anti_tank.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["573"] = {
    eventImage = "ui/skin#events/card_fg_42.avif"
    previewImage = "ui/skin#events/card_fg_42.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["574"] = {
    eventImage = "ui/skin#events/card_stg_44.avif"
    previewImage = "ui/skin#events/card_stg_44.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["575"] = {
    eventImage = "ui/skin#events/card_thompson_m1928a1_50_drum.avif"
    previewImage = "ui/skin#events/card_thompson_m1928a1_50_drum.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["576"] = {
    eventImage = "ui/skin#events/card_ppsh_41.avif"
    previewImage = "ui/skin#events/card_ppsh_41.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["577"] = {
    eventImage = "ui/skin#events/card_type_100_mg.avif"
    previewImage = "ui/skin#events/card_type_100_mg.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["578"] = {
    eventImage = "ui/skin#events/card_browning_m1919a6.avif"
    previewImage = "ui/skin#events/card_browning_m1919a6.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["590"] = {
    eventImage = "ui/skin#events/card_rd_44.avif"
    previewImage = "ui/skin#events/card_rd_44.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["589"] = {
    name = loc("items/halloween_2024_hero_main_crate")
    description = loc("items/halloween_2024_hero_main_crate/desc")
    icon = "ui/skin#currency/soldier_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/lootbox_soldier.avif"
    previewImage = "ui/shop/event/halloween_hero_preview.avif"
    previewSize = [hdpxi(800), hdpxi(600)]
    mkImage = mkImageCtor([160, 168], [0, 18])
    worth = 3
  },
  ["568"] = {
    name = loc("items/selfres_syringe")
    description = loc("items/selfres_syringe/desc")
    icon = "ui/skin#currency/syringe_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_selfres_syringe.avif"
    mkImage = mkImageCtor([160, 168], [0, 18])
    isMultiple = true
    worth = 3
  },
  ["583"] = {
    itemTemplate ="fg_42_model_2_blood"
    name = loc("items/fg_42_model_2_blood")
    description = loc("items/fg_42_model_2_blood_pass/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_fg_42_model_2.avif"
    mkImage = mkImageCtor([164, 136], [1, 36])
  },
  ["584"] = {
    itemTemplate ="stg_44_blood"
    name = loc("items/stg_44_blood")
    description = loc("items/stg_44_blood_pass/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_stg_44.avif"
    mkImage = mkImageCtor([168, 142], [0, 32])
    worth = 4
  },
  ["585"] = {
    itemTemplate ="thompson_m1928a1_50_drum_blood"
    name = loc("items/thompson_m1928a1_50_drum_blood")
    description = loc("items/thompson_m1928a1_50_drum_blood_pass/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_thompson_m1928a1_50_drum.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
  },
  ["586"] = {
    itemTemplate ="ppsh_41_blood"
    name = loc("items/ppsh_41_blood")
    description = loc("items/ppsh_41_blood_pass/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_ppsh_41.avif"
    mkImage = mkImageCtor([168, 122], [0, 42])
    worth = 4
  },
  ["587"] = {
    itemTemplate ="type_100_mg_blood"
    name = loc("items/type_100_mg_blood")
    description = loc("items/type_100_mg_blood_pass/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_type_100_mg.avif"
    mkImage = mkImageCtor([168, 154], [0, 26])
  },
  ["588"] = {
    itemTemplate ="browning_m1919a6_blood"
    name = loc("items/browning_m1919a6_blood")
    description = loc("items/browning_m1919a6_blood_pass/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_browning_m1919a6.avif"
    mkImage = mkImageCtor([168, 132], [0, 36])
    worth = 4
  },
  ["591"] = {
    name = loc("decals/demon_head_halloween_2024")
    description = loc("decals/demon_head_halloween_2024/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_halloween.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_demon_head.avif"
    previewImage = "ui/shop/event/halloween_2024_demon_head_preview.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
    mkImage = mkImageCtor([168, 160], [0, 20])
  },
  ["592"] = {
    name = loc("decorator/halloween_waverly_woodson")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/halloween_waverly_woodson.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["593"] = {
    name = loc("decorator/halloween_reinhard_rust")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/halloween_reinhard_rust.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["594"] = {
    name = loc("decorator/halloween_emelyan_barykin")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/halloween_emelyan_barykin.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["595"] = {
    name = loc("decorator/halloween_katsu_kato")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/halloween_katsu_kato.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["596"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["597"] = {
    name = loc("items/ppd_3438_snail")
    description = loc("items/ppd_3438_snail/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/ppd_3438_snail.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["598"] = {
    name = loc("items/ussr_hero_birthday_2024")
    description = loc("items/ussr_hero_birthday_2024/desc")
    icon = "ui/skin#icons/ussr/ussr_hero_medal_1_icon.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#icons/ussr/ussr_hero_medal_1_icon.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["599"] = {
    name = loc("items/germ_sdkfz_234_3")
    description = loc("items/germ_sdkfz_234_3/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_vehicles.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/vehicles/germ_sdkfz_234_3.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["600"] = {
    name = loc("items/katana")
    description = loc("items/katana/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/katana.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["601"] = {
    name = loc("items/engineer_award_building_tool")
    description = loc("items/engineer_award_building_tool/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/engineer_award_building_tool.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["602"] = {
    name = loc("items/browning_hp_blued")
    description = loc("items/browning_hp_blued/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/twitch_drop_2021_obt_pistol_normandy_allies.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["jap_newYear_2025_Marathon_event_gun_crate"] = {
    name = loc("items/thompson_m1921_jp")
    description = loc("items/thompson_m1921_jp/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/thompson_m1921_jp.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["ger_newYear_2025_Marathon_event_gun_crate"] = {
    name = loc("items/mkb_42_m")
    description = loc("items/mkb_42_m/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mkb_42_m.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["ussr_newYear_2025_Marathon_event_ussr_gun_crate"] = {
    name = loc("items/fedorov_rifle_1913")
    description = loc("items/fedorov_rifle_1913/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/fedorov_rifle_1913.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["usa_newYear_2025_Marathon_event_gun_crate"] = {
    name = loc("items/m2a1_carbine")
    description = loc("items/m2a1_carbine/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/m2a1_carbine.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["winchester_m1907_gold"] = {
    itemTemplate ="winchester_m1907"
    name = loc("items/winchester_m1907")
    description = loc("items/winchester_m1907/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    worth = 4
  },
  ["ussr_hero_battlepass_15_crate"] = {
    name = loc("hero/victor_zavalin")
    description = loc("hero/victor_zavalin/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_15.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_15_crate"] = {
    name = loc("hero/gunter_halm")
    description = loc("hero/gunter_halm/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_15.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_vehicle_battle_pass_15_crate"] = {
    name = loc("items/jp_type_4_chi_to_striped_fourcolor_battlepass")
    description = loc("items/jp_type_4_chi_to_striped_fourcolor_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/jap_vehicle_battle_pass_15.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_vehicle_battle_pass_15_crate"] = {
    name = loc("items/i_185_m82_red_nose_93_battlepass_premium")
    description = loc("items/i_185_m82_red_nose_93_battlepass_premium/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ussr_vehicle_battle_pass_15.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["t26e4_superpershing_3rd_ad_33rd"] = {
    name = loc("shop/t26e4_superpershing_3rd_ad_33rd")
    description = loc("shop/t26e4_superpershing_3rd_ad_33rd/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/t26e4_superpershing_3rd_ad_33rd.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "us_t26e4_superpershing"
    bpSeason = 17
  },
  ["pzkpfw_vi_ausf_b_tiger_iih_abt_505"] = {
    name = loc("shop/pzkpfw_vi_ausf_b_tiger_iih_abt_505")
    description = loc("shop/pzkpfw_vi_ausf_b_tiger_iih_abt_505/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/pzkpfw_vi_ausf_b_tiger_iih_abt_505.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "germ_pzkpfw_vi_ausf_b_tiger_iih_berlin"
    bpSeason = 17
  },
  ["ussr_hero_battlepass_17_crate"] = {
    name = loc("hero/nikolai_kabalin")
    description = loc("hero/nikolai_kabalin/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_17.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_16_crate"] = {
    name = loc("hero/llewellyn_chilson")
    description = loc("hero/llewellyn_chilson/desc")
    icon = "ui/skin#currency/soldier_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_16.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_17_crate"] = {
    name = loc("hero/john_baskeyfield")
    description = loc("hero/john_baskeyfield/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_17.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_16_crate"] = {
    name = loc("hero/shoichi_yokoi")
    description = loc("hero/shoichi_yokoi/desc")
    icon = "ui/skin#currency/soldier_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_16.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ppsh_45_gold"] = {
    itemTemplate ="ppsh_45"
    name = loc("items/ppsh_45")
    description = loc("items/ppsh_45/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/ppsh_45_gold.avif"
    cardImageParams = mkImageParams([158, 120], [0, 6])
    worth = 4
  },
  ["hino_komuro_m1904_gold"] = {
    itemTemplate ="hino_komuro_m1904"
    name = loc("items/hino_komuro_m1904")
    description = loc("items/hino_komuro_m1904/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/hino_komuro_m1904_gold.avif"
    cardImageParams = mkImageParams([170, 120], [0, 17])
    worth = 4
  },
  ["ger_vehicle_battle_pass_17_crate"] = {
    name = loc("shop/bf_109k_4_red_tulip_battlepass")
    description = loc("shop/bf_109k_4_red_tulip_battlepass/desc")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ger_vehicle_battle_pass_17.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["jap_vehicle_battle_pass_17_crate"] = {
    name = loc("shop/ki_61_hien_red_17_battlepass")
    description = loc("shop/ki_61_hien_red_17_battlepass/desc")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/jap_vehicle_battle_pass_17.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_supplyDrop_USSR_event_pistol_crate"] = {
    name = loc("items/browning_hp_silver")
    description = loc("items/browning_hp_silver/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/twitch_drop_2021_obt_pistol_normandy_allies.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["ussr_supplyDrop_USSR_event_gun_crate"] = {
    name = loc("items/sks_30")
    description = loc("items/sks_30/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/sks_30.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["china_infantry_event_bonus_portrait"] = {
    name = loc("decorator/china_infantry_event_bonus_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/china_infantry_event_bonus_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["squad_ch_rifle_2_event_1_crate"] = {
    name = loc("squad/squad_ch_rifle_2_event_1")
    description = loc("squadannounce/squad_ch_rifle_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/skin#squads/usa/squad_ch_rifle_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["nickFrame_lunar_new_year_2025_event"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["squad_ussr_biker_2_event_1"] = {
    name = loc("squad/squad_ussr_biker_2_event_1")
    description = loc("squadannounce/squad_ussr_biker_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    eventImage = "ui/skin#events/ussr_japan_squad_bike_m_72.avif"
    previewImage = "ui/shop/event/ussr_japan_squad_bike_m_72.avif"
    bgImage = "ui/shop/event/ussr_japan_squad_bike_m_72.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["jp_heavy_tank_n_6_crate"] = {
    name = loc("items/jp_pzkpfw_vi_ausf_e_tiger")
    description = loc("items/jp_pzkpfw_vi_ausf_e_tiger/desc")
    icon = "ui/skin#currency/event_order.svg"
    eventImage = "ui/skin#events/ussr_japan_jp_heavy_tank_n6.avif"
    previewImage = "ui/shop/event/jp_heavy_tank_n_6.avif"
    bgImage = "ui/shop/event/ussr_japan_jp_heavy_tank_n6.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["jap_vs_ussr_event_portrait_japan_tanker"] = {
    name = loc("decorator/jap_vs_ussr_event_portrait_japan_tanker")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/jap_vs_ussr_event_portrait_japan_tanker.avif"
    bgImage = "ui/skin#events/bg_portrait_ussr_japan.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["jap_vs_ussr_event_portrait_soviet_soldier"] = {
    name = loc("decorator/jap_vs_ussr_event_portrait_soviet_soldier")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/jap_vs_ussr_event_portrait_soviet_soldier.avif"
    bgImage = "ui/skin#events/bg_portrait_ussr_japan.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["nickFrame_jap_vs_ussr_event"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["mech_event_weapon_prize"] = defRewardPresentation.__merge({
    name = loc("items/mech_event_crate")
    description = loc("items/mech_event_crate/desc")
    icon = "ui/skin#currency/random_reward_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/random_reward_order.svg"
    mkImage = mkImageCtor([72, 100]) 
  }),
  ["ussr_2_guards_tank_corps"] = {
    name = loc("decals/ussr_2_guards_tank_corps")
    description = loc("decals/ussr_2_guards_tank_corps/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["ussr_3rd_tank_brigade"] = {
    name = loc("decals/ussr_3rd_tank_brigade")
    description = loc("decals/ussr_3rd_tank_brigade/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["t_34_first_run_event_portrait"] = {
    name = loc("decorator/t_34_first_run_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/t_34_first_run_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["russian_cavalry_sword_1927"] = {
    name = loc("items/russian_cavalry_sword_1927")
    description = loc("items/russian_cavalry_sword_1927/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/russian_cavalry_sword_1927.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["german_officer_sword"] = {
    name = loc("items/german_officer_sword")
    description = loc("items/german_officer_sword/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/german_officer_sword.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["us_officer_sword_1902"] = {
    name = loc("items/us_officer_sword_1902")
    description = loc("items/us_officer_sword_1902/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/us_officer_sword_1902.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["british_officer_sword"] = {
    name = loc("items/british_officer_sword")
    description = loc("items/british_officer_sword/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/british_officer_sword.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["italian_m1929_infantry_sword"] = {
    name = loc("items/italian_m1929_infantry_sword")
    description = loc("items/italian_m1929_infantry_sword/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/italian_m1929_infantry_sword.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["april_1_gangster_portrait"] = {
    name = loc("decorator/april_1_gangster_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/april_1_gangster.avif"
    mkImage = mkImageCtor([150, 150])
    previewImage = "!ui/portraits/event/april_1_gangster.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
    worth = 4
  },
  ["april_1_indian_portrait"] = {
    name = loc("decorator/april_1_indian_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/april_1_indian.avif"
    mkImage = mkImageCtor([150, 150])
    previewImage = "!ui/portraits/event/april_1_indian.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
  },
  ["april_1_gendarm_portrait"] = {
    name = loc("decorator/april_1_gendarm_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/april_1_gendarm.avif"
    mkImage = mkImageCtor([150, 150])
    previewImage = "!ui/portraits/event/april_1_gendarm.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
  },
  ["april_1_potman_portrait"] = {
    name = loc("decorator/april_1_potman_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/april_1_potman.avif"
    mkImage = mkImageCtor([150, 150])
    previewImage = "!ui/portraits/event/april_1_potman.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
  },
  ["april_1_klyde_portrait"] = {
    name = loc("decorator/april_1_klyde_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/april_1_klyde.avif"
    mkImage = mkImageCtor([150, 150])
    previewImage = "!ui/portraits/event/april_1_klyde.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
  },
  ["trench_club"] = {
    itemTemplate ="trench_club"
    name = loc("items/trench_club")
    description = loc("shop/trench_club/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_trench_club.avif"
    mkImage = mkImageCtor([134, 144], [0, 30])
    worth = 4
  },
  ["mg_42_blood"] = {
    itemTemplate ="mg_42_blood"
    name = loc("items/mg_42_blood")
    description = loc("items/mg_42_blood/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_mg_42_blood.avif"
    mkImage = mkImageCtor([168, 154], [0, 26])
  },
  ["uk_machete"] = {
    itemTemplate ="uk_machete"
    name = loc("items/uk_machete")
    description = loc("shop/uk_machete/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_2025_machete.avif"
    mkImage = mkImageCtor([140, 148], [0, 28])
    worth = 4
  },
  ["tomahawk"] = {
    itemTemplate ="tomahawk"
    name = loc("items/tomahawk")
    description = loc("shop/tomahawk/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_2025_tomohawk.avif"
    mkImage = mkImageCtor([142, 144], [0, 30])
    worth = 4
  },
  ["m1921ac_thompson_gangster"] = {
    itemTemplate ="m1921ac_thompson_gangster"
    name = loc("items/m1921ac_thompson_gangster")
    description = loc("items/m1921ac_thompson_gangster/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_m1921ac_thompson_gangster.avif"
    mkImage = mkImageCtor([168, 154], [0, 26])
  },
  ["st_etienne_shotgun_sawoff"] = {
    itemTemplate ="st_etienne_shotgun_sawoff"
    name = loc("items/st_etienne_shotgun_sawoff")
    description = loc("shop/st_etienne_shotgun_sawoff/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_2025_sawoff.avif"
    mkImage = mkImageCtor([160, 118], [0, 44])
    worth = 4
  },
  ["winchester_1866_carbine"] = {
    itemTemplate ="winchester_1866_carbine"
    name = loc("items/winchester_1866_carbine")
    description = loc("shop/winchester_1866_carbine/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_2025_winchester_1866.avif"
    mkImage = mkImageCtor([160, 116], [0, 44])
  },
  ["mas_38"] = {
    itemTemplate ="mas_38"
    name = loc("items/mas_38")
    description = loc("shop/mas_38/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2025.avif"
    cardImage = "ui/skin#battlepass/april_1_2025_mas_38.avif"
    mkImage = mkImageCtor([160, 136], [0, 34])
    worth = 4
  },
  ["pzkpfw_iv_ausf_e_15th_panzer_div_n8_battlepass"] = {
    name = loc("shop/pzkpfw_iv_ausf_e_15th_panzer_div_n8_battlepass")
    description = loc("shop/pzkpfw_iv_ausf_e_15th_panzer_div_n8_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/pzkpfw_iv_ausf_e_15th_panzer_div_n8_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "germ_pzkpfw_IV_ausf_E"
    bpSeason = 21
  },
  ["t_50_20th_battlepass"] = {
    name = loc("shop/t_50_20th_battlepass")
    description = loc("shop/t_50_20th_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/t_50_20th_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "ussr_t_50"
    bpSeason = 19
  },
  ["type_5_chi_ri_tricolor_flags_battlepass"] = {
    name = loc("shop/type_5_chi_ri_tricolor_flags_battlepass")
    description = loc("shop/type_5_chi_ri_tricolor_flags_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/type_5_chi_ri_tricolor_flags_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "jp_type_5_chi_ri"
    bpSeason = 20
  },
  ["koko_rifle_gold"] = {
    itemTemplate ="koko_rifle"
    name = loc("items/koko_rifle")
    description = loc("items/koko_rifle/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/koko_rifle_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["winchester_1887_gold"] = {
    itemTemplate ="winchester_1887"
    name = loc("items/winchester_1887")
    description = loc("items/winchester_1887/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/winchester_1887_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 11])
    worth = 4
  },
  ["solothurn_s_18_100_gold"] = {
    itemTemplate ="solothurn_s_18_100"
    name = loc("items/solothurn_s_18_100")
    description = loc("items/solothurn_s_18_100/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/solothurn_s_18_100_gold.avif"
    cardImageParams = mkImageParams([174, 120], [0, 13])
    worth = 4
  },
  ["usa_vehicle_battle_pass_2025_3_crate"] = {
    name = loc("items/f4u_1c_5272_battlepass_premium")
    description = loc("items/f4u_1c_5272_battlepass_premium/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/usa_vehicle_battle_pass_2025_3.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_vehicle_battle_pass_2025_4_crate"] = {
    name = loc("items/p_40e_blue_10_battlepass_premium")
    description = loc("items/p_40e_blue_10_battlepass_premium/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ussr_vehicle_battle_pass_2025_4.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["jap_vehicle_battle_pass_2025_5_crate"] = {
    name = loc("items/d4y1_bi_217_battlepass_premium")
    description = loc("items/d4y1_bi_217_battlepass_premium/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/jap_vehicle_battle_pass_2025_5.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ger_hero_battlepass_2025_3_crate"] = {
    name = loc("hero/giulio_martinat")
    description = loc("hero/giulio_martinat/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2025_3.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_2025_3_crate"] = {
    name = loc("hero/isao_yamazoe")
    description = loc("hero/isao_yamazoe/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2025_3.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_hero_battlepass_2025_4_crate"] = {
    name = loc("hero/pyotr_vershigora")
    description = loc("hero/pyotr_vershigora/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2025_4.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2025_4_crate"] = {
    name = loc("hero/karl_heinz_wittig")
    description = loc("hero/karl_heinz_wittig/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2025_4.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_8th_self_prop_art_brigade"] = {
    name = loc("decals/ussr_8th_self_prop_art_brigade")
    description = loc("decals/ussr_8th_self_prop_art_brigade/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    cardImage = "ui/shop/event/competition_2025_event_preview_ger_reward.avif"
    mkImage = mkImageCtor([168, 160], [0, 20])
  },
  ["ge_559th_pzj_abt"] = {
    name = loc("decals/ge_559th_pzj_abt")
    description = loc("decals/ge_559th_pzj_abt/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    cardImage = "ui/shop/event/competition_2025_event_preview_ussr_reward.avif"
    mkImage = mkImageCtor([168, 160], [0, 20])
  },
  ["nickFrame_competition_2025_event"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["competition_2025_event_chest"] = {
    name = loc("items/competition_2025_event_chest")
    description = loc("items/competition_2025_event_chest/desc")
    icon = "ui/skin#currency/random_reward_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#random_reward_chest.avif"
    mkImage = mkImageCtor([200, 200], [0, 0]) 
  },
  ["event_chest"] = {
    itemTemplate = "silver_chest"
    name = loc("items/silver_chest")
    description = loc("items/silver_chest/desc")
    cardImage = "ui/skin#rewards/event_chest.avif"
    cardImageOpen = "ui/skin#rewards/event_chest_open.avif"
    background = goldRadialGradient
    icon = "ui/skin#currency/event_chest.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    mkImage = mkImageCtor([200, 200], [0, 0])
  },
  ["ussr_elbe_day_event_portrait"] = {
    name = loc("decorator/ussr_elbe_day_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/ussr_elbe_day_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["usa_elbe_day_event_portrait"] = {
    name = loc("decorator/usa_elbe_day_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/usa_elbe_day_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["victoryDay_2025_event_ussr_vehicle_reward_skin"] = {
    name = loc("skin/kv_1_zis_5_n264_green_hero_event")
    description = loc("skin/kv_1_zis_5_n264_green_hero_event/desc")
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
  },
  ["victoryDay_2025_event_reward_portrait"] = {
    name = loc("decorator/victoryDay_2025_event_reward_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/victoryDay_2025_event_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["victoryDay_2025_event_ussr_reward_weapon"] = {
    name = loc("items/weapons_season_5_gold")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/weapons_ussr_ppd_gold_5.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["victoryDay_2025_event_usa_reward_aircraft"] = {
    name = loc("items/xa_38")
    description = loc("items/xa_38/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    mkImage = mkImageCtor([150, 150])
    bgImage = "ui/skin#battlepass/bg_gold.avif"
  },
  ["end_of_african_campaign_event_ger_reward_weapon"] = {
    name = loc("items/pavesi_prototype_svt_copy")
    description = loc("items/pavesi_prototype_svt_copy/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/silver_weapons.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    tooltipImage = "!ui/shop/weapons/pavesi_prototype_svt_copy.avif"
    tooltipImgSize = [hdpxi(350), hdpxi(200)]
  },
  ["trial_by_combat_2025_event_order"] = {
    name = loc("items/trial_by_combat_2025_event_order")
    description = loc("items/trial_by_combat_2025_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["trial_by_combat_2025_event_ger_reward_weapon"] = {
    name = loc("items/beretta_m1934_gold")
    description = loc("items/beretta_m1934_gold/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/twitch_drop_2021_tunisia_pistol_tunisia_axis.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["dDay_2025_event_uk_reward_vehicle"] = {
    name = loc("items/uk_alecto_mk_1")
    description = loc("items/uk_alecto_mk_1/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/uk_alecto_mk_1.avif"
    mkImage = mkImageCtor([150, 150])
    bgImage = "ui/skin#battlepass/bg_gold.avif"
  },
  ["dDay_2025_event_ger_reward_vehicle"] = {
    name = loc("items/germ_sturmpanzer_ii")
    description = loc("items/germ_sturmpanzer_ii/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/germ_sturmpanzer_ii.avif"
    mkImage = mkImageCtor([150, 150])
    bgImage = "ui/skin#battlepass/bg_gold.avif"
  },
  ["dDay_2025_event_usa_reward_weapon"] = {
    name = loc("items/winchester_automatic_rifle")
    description = loc("items/winchester_automatic_rifle/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/winchester_automatic_rifle.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["dDay_2025_event_ger_reward_weapon"] = {
    name = loc("items/vollmer_m35")
    description = loc("items/vollmer_m35/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/vollmer_m35.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["battle_of_Midway_event_usa_decorator_reward"] = {
    name = loc("decals/us_44_sqn_pacific_prowler")
    description = loc("decals/us_44_sqn_pacific_prowler/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["battle_of_Midway_event_jp_decorator_reward"] = {
    name = loc("decals/jp_ijaaf_47_snt_sakamoto")
    description = loc("decals/jp_ijaaf_47_snt_sakamoto/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["ussr_vs_japan_jp_gun_reward"] = {
    name = loc("items/thompson_m1921_jp")
    description = loc("items/thompson_m1921_jp/desc")
    icon = "ui/skin#currency/event_order.svg"
    eventImage = "ui/skin#events/ussr_japan_thompson_m1921_jp.avif"
    previewImage = "ui/shop/event/ussr_japan_thompson_m1921_jp.avif"
    bgImage = "ui/shop/event/ussr_japan_thompson_m1921_jp.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["ussr_vs_japan_ussr_gun_reward"] = {
    name = loc("items/fedorov_rifle_1913")
    description = loc("items/fedorov_rifle_1913/desc")
    icon = "ui/skin#currency/event_order.svg"
    eventImage = "ui/skin#events/ussr_japan_fedorov_rifle_1913.avif"
    previewImage = "ui/shop/event/ussr_japan_fedorov_rifle_1913.avif"
    bgImage = "ui/shop/event/ussr_japan_fedorov_rifle_1913.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["ussr_vs_japan_silver_reward"]  = {
    name = loc("currency/silver_currency")
    description = loc("currency/silver_currency_desc")
    icon = "!ui/uiskin/currency/enlisted_silver.svg"
    itemTemplate ="enlisted_silver"
    bgImage = "ui/skin#events/bg_ussr_japan.avif"
    cardImage = "ui/skin#battlepass/silver_coins.avif"
    cardImageParams = mkImageParams([166, 136], [0, -4])
    worth = 0.5
  },
  ["ussr_vs_japan_appearance_reward"]  = {
    name = loc("items/appearance_change_order")
    description = loc("items/appearance_change_order/desc")
    icon = "ui/skin#currency/soldier_appearance.svg"
    itemTemplate ="appearance_change_order"
    bgImage = "ui/skin#events/bg_ussr_japan.avif"
    cardImage = "ui/skin#battlepass/makeup.avif"
    cardImageParams = mkImageParams([162, 148], [0, 18])
  },
  ["jap_hero_battlepass_2025_5_crate"] = {
    name = loc("hero/michiro_okuyama")
    description = loc("hero/michiro_okuyama/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2025_5.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_2025_5_crate"] = {
    name = loc("hero/tommy_prince")
    description = loc("hero/tommy_prince/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2025_5.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["supplyDropGer_ger_gun_reward"] = {
    name = loc("items/mp_40_winter")
    description = loc("items/mp40/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mp_40_winter.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["german_assaulter_winter_event_portrait"] = {
    name = loc("decorator/supplyDropGer_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/german_assaulter_winter_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["crusader_mk_3_21lancers_6ad_battlepass"] = {
    name = loc("shop/crusader_mk_3_21lancers_6ad_battlepass")
    description = loc("shop/crusader_mk_3_21lancers_6ad_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/crusader_mk_3_21lancers_6ad_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "uk_crusader_mk_3"
    bpSeason = 22
  },
  ["t_34_85_d_5t_winter_dmitri_donskoi_battlepass"] = {
    name = loc("shop/t_34_85_d_5t_winter_dmitri_donskoi_battlepass")
    description = loc("shop/t_34_85_d_5t_winter_dmitri_donskoi_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/t_34_85_d_5t_winter_dmitri_donskoi_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "ussr_t_34_85_d_5t"
    bpSeason = 23
  },
  ["type_3_camo_late_brown_olive_yellow_jap_sign_battlepass"] = {
    name = loc("shop/type_3_camo_late_brown_olive_yellow_jap_sign_battlepass")
    description = loc("shop/type_3_camo_late_brown_olive_yellow_jap_sign_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/type_3_camo_late_brown_olive_yellow_jap_sign_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "jp_type_3_ho_ni_i_pacific"
    bpSeason = 24
  },
  ["arisaka_type_38_bouganville_gold"] = {
    itemTemplate ="arisaka_type_38_bouganville"
    name = loc("items/arisaka_type_38_bouganville")
    description = loc("items/arisaka_type_38_bouganville/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/arisaka_type_38_bouganville_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["ger_vehicle_battle_pass_2025_6"] = {
    name = loc("items/re_2000_int_236_battlepass")
    description = loc("items/re_2000_int_236_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ger_vehicle_battle_pass_2025_6.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["usa_vehicle_battle_pass_2025_7"] = {
    name = loc("items/spitfire_vc_trop_ksh_battlepass")
    description = loc("items/spitfire_vc_trop_ksh_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/usa_vehicle_battle_pass_2025_7.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_vehicle_battle_pass_2025_8"] = {
    name = loc("items/la_7_red_14_battlepass")
    description = loc("items/la_7_red_14_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ussr_vehicle_battle_pass_2025_8.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["usa_hero_battlepass_2025_6_crate"] = {
    name = loc("hero/stanley_hollis")
    description = loc("hero/stanley_hollis/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2025_6.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2025_6_crate"] = {
    name = loc("hero/josef_allerberger")
    description = loc("hero/josef_allerberger/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2025_6.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_hero_battlepass_2025_7_crate"] = {
    name = loc("hero/stepan_averyanov")
    description = loc("hero/stepan_averyanov/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2025_7.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_2025_7_crate"] = {
    name = loc("hero/makoto_ogawa")
    description = loc("hero/makoto_ogawa/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2025_7.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_hero_battlepass_2025_8_crate"] = {
    name = loc("hero/aleksey_alelyukhin")
    description = loc("hero/aleksey_alelyukhin/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2025_8.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_2025_8_crate"] = {
    name = loc("hero/charles_chibitty")
    description = loc("hero/charles_chibitty/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2025_8.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_kretz_p13_gold"] = {
    itemTemplate ="kretz_p13"
    name = loc("items/kretz_p13")
    description = loc("items/kretz_p13/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/kretz_p13_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["ger_scotti_naval_rifle_gold"] = {
    itemTemplate ="scotti_naval_rifle"
    name = loc("items/scotti_naval_rifle")
    description = loc("items/scotti_naval_rifle/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/scotti_naval_rifle_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["aviation_event_uk_reward_vehicle"] = {
    name = loc("items/spitfire_ix")
    description = loc("items/spitfire_ix/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/spitfire_ix_e_raf_johnnie_dday_premium.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["aviation_event_ger_reward_vehicle"] = {
    name = loc("items/bf_109z")
    description = loc("items/bf_109z/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/bf_109z.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["aviation_event_ger_reward_weapon"] = {
    name = loc("items/lahti_saloranta_m26")
    description = loc("items/lahti_saloranta_m26/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/lahti_saloranta_m26.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["liberationParis_event_pistol"] = {
    name = loc("items/fp_45_liberator")
    description = loc("items/fp_45_liberator/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/fp_45_liberator.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["liberationParis_event_weapon"] = {
    name = loc("items/farquhar_hill_1918")
    description = loc("items/farquhar_hill_1918/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/farquhar_hill_1918.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["nickFrame_paratroopers_event"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["squad_usa_paratrooper_2_event_3"] = {
    name = loc("squad/squad_usa_paratrooper_2_event_3")
    description = loc("squadannounce/squad_usa_paratrooper_2_event_3")
    icon = "ui/skin#research/squad_points_icon.svg"
    eventImage = "ui/skin#events/paratroopers_event_squad_icon.avif"
    previewImage = "ui/shop/event/paratroopers_event_squad_icon.avif"
    bgImage = "ui/shop/event/paratroopers_event_squad_icon.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["paratroopers_event_ger_reward_gun"] = {
    name = loc("items/mkb_42_h_15_rounds")
    description = loc("items/mkb_42_h_15_rounds/desc")
    icon = "ui/skin#currency/event_order.svg"
    eventImage = "ui/skin#events/paratroopers_event_ger_gun.avif"
    previewImage = "ui/shop/event/paratroopers_event_ger_gun.avif"
    bgImage = "ui/shop/event/paratroopers_event_ger_gun.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["paratroopers_event_silver_reward"]  = {
    name = loc("currency/silver_currency")
    description = loc("currency/silver_currency_desc")
    icon = "!ui/uiskin/currency/enlisted_silver.svg"
    itemTemplate ="enlisted_silver"
    bgImage = "ui/skin#events/bg_paratroopers_event.avif"
    cardImage = "ui/skin#battlepass/silver_coins.avif"
    cardImageParams = mkImageParams([166, 136], [0, -4])
    worth = 0.5
  },
  ["paratroopers_event_appearance_reward"]  = {
    name = loc("items/appearance_change_order")
    description = loc("items/appearance_change_order/desc")
    icon = "ui/skin#currency/soldier_appearance.svg"
    itemTemplate ="appearance_change_order"
    bgImage = "ui/skin#events/bg_paratroopers_event.avif"
    cardImage = "ui/skin#battlepass/makeup.avif"
    cardImageParams = mkImageParams([162, 148], [0, 18])
  },
  ["paratroopers_event_ger_portrait_reward"] = {
    name = loc("decorator/paratroopers_event_ger_portrait_reward")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/paratroopers_event_ger_portrait_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_paratroopers_event.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["paratroopers_event_usa_portrait_reward"] = {
    name = loc("decorator/paratroopers_event_usa_portrait_reward")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/paratroopers_event_usa_portrait_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_paratroopers_event.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["supplyDrop2_event_reward_jap_gun"] = {
    name = loc("items/sig_ke_7_50_rounds")
    description = loc("items/sig_ke_7_50_rounds/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/sig_ke_7_50_rounds.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["uk_vs_ita_ger_portrait_reward"] = {
    name = loc("decorator/uk_vs_ita_ger_portrait_event_reward")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/uk_vs_ita_ger_portrait_event_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_uk_vs_ita.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["uk_vs_ita_usa_portrait_reward"] = {
    name = loc("decorator/uk_vs_ita_usa_portrait_event_reward")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/uk_vs_ita_usa_portrait_event_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_uk_vs_ita.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["uk_vs_ita_silver_reward"]  = {
    name = loc("currency/silver_currency")
    description = loc("currency/silver_currency_desc")
    icon = "!ui/uiskin/currency/enlisted_silver.svg"
    itemTemplate ="enlisted_silver"
    bgImage = "ui/skin#events/bg_uk_vs_ita.avif"
    cardImage = "ui/skin#battlepass/silver_coins.avif"
    cardImageParams = mkImageParams([166, 136], [0, -4])
    worth = 0.5
  },
  ["uk_vs_ita_appearance_reward"]  = {
    name = loc("items/appearance_change_order")
    description = loc("items/appearance_change_order/desc")
    icon = "ui/skin#currency/soldier_appearance.svg"
    itemTemplate ="appearance_change_order"
    bgImage = "ui/skin#events/bg_uk_vs_ita.avif"
    cardImage = "ui/skin#battlepass/makeup.avif"
    cardImageParams = mkImageParams([162, 148], [0, 18])
  },
  ["uk_vs_ita_ger_reward_gun"] = {
    name = loc("items/cei_rigotti_rifle")
    description = loc("items/cei_rigotti_rifle/desc")
    icon = "ui/skin#currency/event_order.svg"
    eventImage = "ui/skin#events/uk_vs_ita_ger_gun.avif"
    previewImage = "ui/shop/event/uk_vs_ita_ger_gun.avif"
    bgImage = "ui/shop/event/uk_vs_ita_ger_gun.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["uk_vs_ita_usa_reward_gun"] = {
    name = loc("items/lewis_303_lmg")
    description = loc("items/lewis_303_lmg/desc")
    icon = "ui/skin#currency/event_order.svg"
    eventImage = "ui/skin#events/uk_vs_ita_usa_gun.avif"
    previewImage = "ui/shop/event/uk_vs_ita_usa_gun.avif"
    bgImage = "ui/shop/event/uk_vs_ita_usa_gun.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["nickFrame_uk_vs_ita_ger"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["nickFrame_uk_vs_ita_usa"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/uk_vs_ita_nickframe_usa_reward.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["uk_vs_ita_ger_vehicle_reward_skin"] = {
    name = loc("skin/m14_41_it_camo_olive_green_event_decorated")
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    bgImage = "ui/skin#events/bg_uk_vs_ita.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    vehicle = "it_m14_41"
  },
  ["shermanFirstFight_event_reward_skin"] = {
    name = loc("skin/m4a1_76w_sherman_us_camo_olive_late_event_decorated")
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    cardImage = "!ui/shop/vehicles/m4a1_76w_sherman_us_camo_olive_late_event_decorated.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["shermanFirstFight_event_reward_decorator"] = {
    name = loc("decals/usa_kilroy_was_here")
    description = loc("decals/usa_kilroy_was_here/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["avt_40_halloween_2025_card"] = {
    eventImage = "ui/skin#events/card_avt_40.avif"
    previewImage = "ui/skin#events/card_avt_40.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["beretta_m38_halloween_2025_card"] = {
    eventImage = "ui/skin#events/card_beretta_m38.avif"
    previewImage = "ui/skin#events/card_beretta_m38.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["hyde_m1944_halloween_2025_card"] = {
    eventImage = "ui/skin#events/card_hyde_m1944.avif"
    previewImage = "ui/skin#events/card_hyde_m1944.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["madsen_halloween_2025_card"] = {
    eventImage = "ui/skin#events/card_madsen.avif"
    previewImage = "ui/skin#events/card_madsen.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["type_hei_automatic_rifle_halloween_2025_card"] = {
    eventImage = "ui/skin#events/card_type_hei_automatic_rifle.avif"
    previewImage = "ui/skin#events/card_type_hei_automatic_rifle.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["patchett_gun_card"] = {
    eventImage = "ui/skin#events/card_patchett.avif"
    previewImage = "ui/skin#events/card_patchett.avif"
    previewSize = [hdpxi(120), hdpxi(120)]
  },
  ["usa_halloween_2025_squad"] = {
    eventImage = "ui/skin#events/card_halloween_squad.avif"
    previewImage = "ui/skin#events/card_halloween_squad.avif"
    previewSize = [hdpxi(400), hdpxi(400)]
  },
  ["avt_40_halloween_2025"] = {
    itemTemplate ="avt_40_halloween_2025"
    name = loc("items/avt_40_20_rounds")
    description = loc("shop/avt_40_halloween_2025/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/avt_40_halloween_2025.avif"
    eventImage = "ui/skin#events/card_avt_40.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
  },
  ["beretta_m38_halloween_2025"] = {
    itemTemplate ="beretta_m38_halloween_2025"
    name = loc("items/beretta_m38")
    description = loc("shop/beretta_m38_halloween_2025/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/beretta_m38_halloween_2025.avif"
    eventImage = "ui/skin#events/card_beretta_m38.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
  },
  ["hyde_m1944_halloween_2025"] = {
    itemTemplate ="hyde_m1944_halloween_2025"
    name = loc("items/hyde_m1944")
    description = loc("shop/hyde_m1944_halloween_2025/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/hyde_m1944_halloween_2025.avif"
    eventImage = "ui/skin#events/card_hyde_m1944.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
    worth = 3
  },
  ["madsen_halloween_2025"] = {
    itemTemplate ="madsen_halloween_2025"
    name = loc("items/madsen")
    description = loc("shop/madsen_halloween_2025/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/madsen_halloween_2025.avif"
    eventImage = "ui/skin#events/card_madsen.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
  },
  ["type_hei_automatic_rifle_halloween_2025"] = {
    itemTemplate ="type_hei_automatic_rifle_halloween_2025"
    name = loc("items/type_hei_automatic_rifle")
    description = loc("shop/type_hei_automatic_rifle_halloween_2025/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/type_hei_automatic_rifle_halloween_2025.avif"
    eventImage = "ui/skin#events/card_type_hei_automatic_rifle.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
    worth = 3
  },
  ["patchett_gun"] = {
    itemTemplate ="patchett_mk1"
    name = loc("items/patchett_mk1")
    description = loc("shop/patchett_mk1/desc")
    icon = "ui/skin#currency/weapon_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/patchett_mk1_halloween_2025.avif"
    eventImage = "ui/skin#events/card_patchett.avif"
    mkImage = mkImageCtor([168, 124], [0, 40])
  },
  ["event_squad_halloween_2025"] = {
    name = loc("squad/squad_uk_flametrooper_2_event_1")
    description = loc("regiment/squad_uk_flametrooper_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    previewImage = "ui/soldiers/usa/squad_uk_flametrooper_2_event_1_image.avif"
    previewSize = [hdpxi(800), hdpxi(600)]
    mkImage = mkImageCtor([160, 168], [0, 18])
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/boost_squad.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["selfres_syringe_halloween_2025"] = {
    itemTemplate ="selfres_syringe"
    name = loc("items/selfres_syringe")
    description = loc("items/selfres_syringe/desc")
    icon = "ui/skin#currency/syringe_halloween_icon.svg"
    bgImage = "ui/skin#battlepass/bg_halloween_2025.avif"
    cardImage = "ui/skin#battlepass/halloween_2024_selfres_syringe.avif"
    mkImage = mkImageCtor([160, 168], [0, 18])
    isMultiple = true
    worth = 3
  },
  ["kv_1_l_11_ussr_camo_halloween_event"] = {
    name = loc("skin/kv_1_l_11_ussr_camo_halloween_event")
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    cardImage = "!ui/shop/vehicles/kv_1_l_11_ussr_camo_halloween_event.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["birthday2025_event_ger_reward_weapon"] = {
    name = loc("items/coenders_mp")
    description = loc("items/coenders_mp/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/coenders_mp.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["birthday2025_event_usa_reward_weapon"] = {
    name = loc("items/lewis_assault_rifle")
    description = loc("items/lewis_assault_rifle/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/lewis_assault_rifle.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["birthday2025_event_jap_squad_reward"] = {
    name = loc("squad/squad_jap_apc_driver_2_event_1")
    description = loc("squadannounce/squad_jap_apc_driver_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/japan/squad_jap_apc_driver_2_event_1_image.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["birthday2025_event_ussr_squad_reward"] = {
    name = loc("squad/squad_ussr_apc_driver_2_event_1")
    description = loc("squadannounce/squad_ussr_apc_driver_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/ussr/squad_ussr_apc_driver_2_event_1_image.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["birthday2025_event_ussr_squad_vehicle_reward"] = {
    name = loc("items/il_8")
    description = loc("items/il_8/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/il_8.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["usa_hero_battlepass_2025_9"] = {
    name = loc("hero/arthur_wermuth")
    description = loc("hero/arthur_wermuth/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2025_9.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_2025_9"] = {
    name = loc("hero/jinzo_tsugi")
    description = loc("hero/jinzo_tsugi/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2025_9.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_2025_10"] = {
    name = loc("hero/hiroshi_funasaka")
    description = loc("hero/hiroshi_funasaka/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2025_10.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2025_10"] = {
    name = loc("hero/hermann_bix")
    description = loc("hero/hermann_bix/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2025_10.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_hero_battlepass_2025_11"] = {
    name = loc("hero/vasily_melnikov")
    description = loc("hero/vasily_melnikov/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2025_11.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2025_11"] = {
    name = loc("hero/karl_heinz_noak")
    description = loc("hero/karl_heinz_noak/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2025_11.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["pzkpfw_vi_ausf_b_tiger_iih_213"] = {
    name = loc("shop/pzkpfw_vi_ausf_b_tiger_iih_213_battlepass")
    description = loc("shop/pzkpfw_vi_ausf_b_tiger_iih_213_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/pzkpfw_vi_ausf_b_tiger_iih_213_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "germ_pzkpfw_vi_ausf_b_tiger_iih_berlin"
    bpSeason = 25
  },
  ["type_5_ho_ri_production_jp_camo_ho_ri_rust"] = {
    name = loc("shop/type_5_ho_ri_production_jp_camo_ho_ri_rust_battlepass")
    description = loc("shop/type_5_ho_ri_production_jp_camo_ho_ri_rust_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/type_5_ho_ri_production_jp_camo_ho_ri_rust_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "jp_type_5_ho_ri_production"
    bpSeason = 26
  },
  ["is_2_1944_ussr_snow"] = {
    name = loc("shop/is_2_1944_ussr_snow_battlepass")
    description = loc("shop/is_2_1944_ussr_snow_battlepass/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/is_2_1944_ussr_snow_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "ussr_is_2_1944_berlin"
    bpSeason = 27
  },
  ["pp_shpitalniy_1943_gold"] = {
    itemTemplate ="ppsh_43_smg"
    name = loc("items/ppsh_43_smg")
    description = loc("items/ppsh_43_smg/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/pp_shpitalniy_1943_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["browning_303_infantry_gold"] = {
    itemTemplate ="browning_303_infantry"
    name = loc("items/browning_303_infantry")
    description = loc("items/browning_303_infantry/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/browning_303_infantry_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["og_44_gold"] = {
    itemTemplate ="og_44"
    name = loc("items/og_44")
    description = loc("items/og_44/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/og_43_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["jap_vehicle_battle_pass_2025_9"] = {
    name = loc("items/j2m3_gray_battlepass")
    description = loc("items/j2m3_gray_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/jap_vehicle_battle_pass_2025_9.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ger_vehicle_battle_pass_2025_10"] = {
    name = loc("items/me_262a_1a_early_gray6_battlepass")
    description = loc("items/me_262a_1a_early_gray6_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ger_vehicle_battle_pass_2025_10.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_vehicle_battle_pass_2025_11"] = {
    name = loc("items/tu_2s_moscow_32_battlepass")
    description = loc("items/tu_2s_moscow_32_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ussr_vehicle_battle_pass_2025_11.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["squad_fr_pilot_fighter_2_event_1_reward"] = {
    name = loc("squad/squad_fr_pilot_fighter_2_event_1")
    description = loc("squadannounce/squad_fr_pilot_fighter_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/ussr/squad_fr_pilot_fighter_2_event_1_image.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["normandieNeman_event_portrait_reward"] = {
    name = loc("decorator/normandieNeman_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/normandieNeman_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["usa_new_year_2026_reward_squad"] = {
    name = loc("squad/squad_usa_engineer_2_event_1")
    description = loc("squadannounce/squad_usa_engineer_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/usa/squad_usa_engineer_2_event_1_image.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["jap_new_year_2026_reward_squad"] = {
    name = loc("squad/squad_jap_engineer_2_event_1")
    description = loc("squadannounce/squad_jap_engineer_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/japan/squad_jap_engineer_2_event_1_image.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["ussr_new_year_2026_reward_weapon_lmg"] = {
    name = loc("items/tkb_336")
    description = loc("items/tkb_336/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/tkb_336.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["usa_new_year_2026_reward_weapon_pistol"] = {
    name = loc("items/mars_pistol")
    description = loc("items/mars_pistol/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mars_pistol.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["ger_new_year_2026_reward_weapon_ar"] = {
    name = loc("items/mkb_42_h_15_rounds")
    description = loc("items/mkb_42_h_15_rounds/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mkb_42_h_15_rounds.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["ger_new_year_2026_reward_weapon_smg"] = {
    name = loc("items/weapons_season_5_gold")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/weapons_axis_gold_5.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["end_of_the_siege_of_leningrad_event_portrait"] = {
    name = loc("decorator/end_of_the_siege_of_leningrad_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/end_of_the_siege_of_leningrad_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["end_of_the_battle_of_stalingrad_reward_decal"] = {
    name = loc("decals/ussr_text_snaiper")
    description = loc("decals/ussr_text_snaiper/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["end_of_the_battle_of_guadalcanal_reward_decal"] = {
    name = loc("decals/usmc_tank_emblem")
    description = loc("decals/usmc_tank_emblem/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["end_of_the_battle_of_guadalcanal_reward_gun"] = {
    name = loc("items/owen_mk1_42_camo")
    description = loc("items/owen_mk1_42_camo/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/owen_mk1_42_camo.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["lunar_new_year_2026_ussr_reward_gun"] = {
    name = loc("items/mosin_obrez")
    description = loc("items/mosin_obrez/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mosin_obrez.avif"
    mkImage = mkImageCtor([350, 200], [0, 0])
  },
  ["lunar_new_year_2026_event_portrait"] = {
    name = loc("decorator/lunar_new_year_2026_event_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/lunar_new_year_2026_event_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["lunar_new_year_2026_event_nickframe"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["lunar_new_year_2026_ussr_reward_squad"] = {
    name = loc("squad/squad_ch_assault_2_event_1")
    description = loc("squadannounce/squad_ch_assault_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/ussr/squad_ch_assault_2_event_1_image.avif"
    mkImage = mkImageCtor([210, 157], [0, 0])
  },
  ["ger_hero_battlepass_2026_3"] = {
    name = loc("hero/friedrich_lengfeld")
    description = loc("hero/friedrich_lengfeld/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2026_3.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_2026_3"] = {
    name = loc("hero/masashi_ito")
    description = loc("hero/masashi_ito/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2026_3.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_2026_4"] = {
    name = loc("hero/john_rowe")
    description = loc("hero/john_rowe/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2026_4.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2026_4"] = {
    name = loc("hero/kurt_knispel")
    description = loc("hero/kurt_knispel/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2026_4.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_hero_battlepass_2026_5"] = {
    name = loc("hero/vasily_vataman")
    description = loc("hero/vasily_vataman/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2026_5.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_2026_5"] = {
    name = loc("hero/jack_treadwell")
    description = loc("hero/jack_treadwell/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2026_5.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["type_95_ha_go_205_imperial_navy_marine_corps"] = {
    name = loc("shop/type_95_ha_go_205_imperial_navy_marine_corps")
    description = loc("shop/type_95_ha_go_205_imperial_navy_marine_corps/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/type_95_ha_go_205_imperial_navy_marine_corps_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "jp_type_95_ha_go_pacific"
    bpSeason = 28
  },
  ["pzkpfw_iv_ausf_f_newspaper_camo"] = {
    name = loc("shop/pzkpfw_iv_ausf_f_newspaper_camo")
    description = loc("shop/pzkpfw_iv_ausf_f_newspaper_camo/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/pzkpfw_iv_ausf_f_newspaper_camo_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "germ_pzkpfw_IV_ausf_F"
    bpSeason = 29
  },
  ["m8_scott_6th_squad_6th_cavalry"] = {
    name = loc("shop/m8_scott_6th_squad_6th_cavalry")
    description = loc("shop/m8_scott_6th_squad_6th_cavalry/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/m8_scott_6th_squad_6th_cavalry_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "us_m8_scott_pacific"
    bpSeason = 30
  },
  ["usa_viper_no_3_gold"] = {
    itemTemplate ="viper_no3"
    name = loc("items/viper_no3")
    description = loc("items/viper_no3/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/viper_no_3_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["ussr_tkb_264_gold"] = {
    itemTemplate ="tkb_264_42"
    name = loc("items/tkb_264_42")
    description = loc("items/tkb_264_42/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/tkb_264_gold.avif"
    cardImageParams = mkImageParams([170, 134], [-3, 40])
    worth = 4
  },
  ["jap_arisaka_type_38_modified_gold"] = {
    itemTemplate ="arisaka_type_38_modified"
    name = loc("items/arisaka_type_38_modified")
    description = loc("items/arisaka_type_38_modified/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/arisaka_type_38_modified_gold.avif"
    cardImageParams = mkImageParams([170, 121], [0, 6])
    worth = 4
  },
  ["ussr_vehicle_battle_pass_2026_3"] = {
    name = loc("items/il_2m_type3_1945_winter28_battlepass")
    description = loc("items/il_2m_type3_1945_winter28_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ussr_vehicle_battle_pass_2026_3.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["jap_vehicle_battle_pass_2026_4"] = {
    name = loc("items/b5n2_ai301_battlepass")
    description = loc("items/b5n2_ai301_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/jap_vehicle_battle_pass_2026_4.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ger_vehicle_battle_pass_2026_5"] = {
    name = loc("items/bf_109f_4_trop_desert6_battlepas")
    description = loc("items/bf_109f_4_trop_desert6_battlepas/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ger_vehicle_battle_pass_2026_5.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_anti_tank_reward_weapon"] = {
    name = loc("items/ptrs_41_late")
    description = loc("items/ptrs_41_late/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/ptrs_41_late.avif"
    mkImage = mkImageCtor([350, 250], [0, 0])
  },
  ["ger_anti_tank_reward_weapon"] = {
    name = loc("items/mauser_tankgewehr_m1918")
    description = loc("items/mauser_tankgewehr_m1918/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mauser_tankgewehr_m1918.avif"
    mkImage = mkImageCtor([350, 250], [0, 0])
  },
  ["saboteurs_event_reward_order"] = {
    name = loc("items/saboteurs_event_reward_order")
    description = loc("items/saboteurs_event_reward_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["viena_offensive_ussr_reward_gun_skin"] = {
    name = loc("items/ppsh_41_finewood")
    description = loc("items/ppsh_41_finewood/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/ppsh_41_finewood.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["viena_offensive_ussr_reward_gun"] = {
    name = loc("items/pps_42_red")
    description = loc("items/pps_42_red/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/pps_42_red.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["ww1_1_april_reward_ger_gewehr_88_gun"] = {
    itemTemplate ="gewehr_88"
    name = loc("items/gewehr_88")
    description = loc("shop/gewehr_88/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/gewehr_88.avif"
    mkImage = mkImageCtor([170, 86], [0, 15])
  },
  ["ww1_1_april_reward_ger_mauser_gewehr_98_warmod_gun"] = {
    itemTemplate ="mauser_gewehr_98_warmod"
    name = loc("items/mauser_gewehr_98_warmod")
    description = loc("shop/mauser_gewehr_98_warmod/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/mauser_gewehr_98_warmod.avif"
    mkImage = mkImageCtor([170, 80], [0, 20])
  },
  ["ww1_1_april_reward_ger_mondragon_m1908_10_round_gun"] = {
    itemTemplate ="mondragon_m1908_10_round"
    name = loc("items/mondragon_m1908_10_round")
    description = loc("shop/mondragon_m1908_10_round/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/mondragon_m1908_10_round.avif"
    worth = 3
    mkImage = mkImageCtor([170, 94], [0, 20])
  },
  ["ww1_1_april_reward_uk_lewis_303_lmg_gun"] = {
    itemTemplate ="lewis_303_lmg"
    name = loc("items/lewis_303_lmg")
    description = loc("shop/lewis_303_lmg/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/lewis_303_lmg.avif"
    mkImage = mkImageCtor([170, 84], [0, 15])
  },
  ["ww1_1_april_reward_uk_smle_mk3_with_scope_gun"] = {
    itemTemplate ="smle_mk3_t"
    name = loc("items/smle_mk3_t")
    description = loc("shop/smle_mk3_t/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/smle_mk3_with_scope.avif"
    worth = 3
    mkImage = mkImageCtor([170, 84], [0, 20])
  },
  ["ww1_1_april_reward_uk_gear_head_trench_club_gun"] = {
    itemTemplate ="gear_trench_club"
    name = loc("items/gear_trench_club")
    description = loc("shop/gear_trench_club/desc")
    icon = "ui/skin#currency/weapon_order_gold.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/gear_head_trench_club.avif"
    mkImage = mkImageCtor([170, 90], [0, 20])
  },
  ["ww1_1_april_reward_ger_portrait"] = {
    name = loc("decorator/ww1_1_april_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/ww1_1_april_reward_ger_portrait.avif"
    mkImage = mkImageCtor([150, 150])
    bgImage = "ui/skin#battlepass/bg_portrait_april_1_2026.avif"
    previewImage = "!ui/portraits/event/ww1_1_april_reward_ger_portrait.avif"
    worth = 3
    previewSize = [hdpxi(256), hdpxi(256)]
  },
  ["ww1_1_april_reward_uk_portrait"] = {
    name = loc("decorator/ww1_1_april_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/ww1_1_april_reward_uk_portrait.avif"
    mkImage = mkImageCtor([150, 150])
    bgImage = "ui/skin#battlepass/bg_portrait_april_1_2026.avif"
    previewImage = "!ui/portraits/event/ww1_1_april_reward_uk_portrait.avif"
    previewSize = [hdpxi(256), hdpxi(256)]
  },
  ["ww1_1_april_reward_ger_helmet"] = {
    name = loc("shop/attachable_wear_ger_m17_helmet")
    description = loc("shop/attachable_wear_ger_m17_helmet/desc")
    icon = "!ui/portraits/default_portrait.svg"
    itemTemplate ="attachable_wear_ger_m17_helmet"
    cardImage = "ui/skin#battlepass/ww1_event_ger_helmet.avif"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    mkImage = mkImageCtor([170, 120])
  },
  ["ger_trench_club_ww1"] = {
    itemTemplate ="trench_club"
    name = loc("items/trench_club")
    description = loc("shop/trench_club/desc")
    icon = "ui/skin#currency/april_1_2025_weapon.svg"
    bgImage = "ui/skin#battlepass/bg_april_1_2026.avif"
    cardImage = "ui/skin#battlepass/april_1_trench_club.avif"
    mkImage = mkImageCtor([134, 144], [0, 30])
  },
  ["svt_assigned_ussr_reward_gun"] = {
    name = loc("items/svt_40_15_round")
    description = loc("items/svt_40_15_round/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/svt_40_15.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["gewehr_43_assigned_ger_reward_gun"] = {
    name = loc("items/gewehr_43_dfr")
    description = loc("items/gewehr_43_dfr/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/gewehr_43_dfr.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["victory_day_2026_ussr_skin_reward"] = {
    name = loc("skin/t_60_malutka")
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    cardImage = "!ui/shop/vehicles/victory_day_2026_ussr_skin_reward.avif"
    mkImage = mkImageCtor([350, 250], [0, 0])
  },
  ["victory_day_2026_usa_decal_reward"] = {
    name = loc("decals/usa_tanks_white_star_and_bar")
    description = loc("decals/usa_tanks_white_star_and_bar/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["victory_day_2026_ussr_decal_reward"] = {
    name = loc("decals/ussr_tanks_rough_star")
    description = loc("decals/ussr_tanks_rough_star/desc")
    icon = "ui/skin#currency/decal_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/decal_order_event.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["victory_day_2026_usa_weapon_reward"] = {
    name = loc("items/russell_turner_1941_rifle")
    description = loc("items/russell_turner_1941_rifle/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/russell_turner_1941_rifle.avif"
    mkImage = mkImageCtor([300, 250], [0, 0])
  },
  ["victory_day_2026_reward_portrait"] = {
    name = loc("decorator/victory_day_2026_reward_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/victory_day_2026_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["victory_day_2026_ussr_vehicle_reward"] = {
    name = loc("items/ussr_isu_152")
    description = loc("items/ussr_isu_152/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/ussr_isu_152.avif"
    mkImage = mkImageCtor([350, 250], [0, 0])
  },
  ["end_the_battle_of_monte_cassino_event_order"] = {
    name = loc("items/end_the_battle_of_monte_cassino_event_order")
    description = loc("items/end_the_battle_of_monte_cassino_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["liberation_of_rome_ger_vehicle_camo_reward"] = {
    name = loc("skin/m41_75_32_it_camo_armored")
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    cardImage = "!ui/shop/vehicles/m41_75_32_it_camo_armored.avif"
    mkImage = mkImageCtor([350, 260], [0, 0])
  },
  ["liberation_of_rome_usa_vehicle_camo_reward"] = {
    name = loc("skin/m4a1_sherman_1942_camo_armored")
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    cardImage = "!ui/shop/vehicles/m4a1_sherman_1942_camo_armored.avif"
    mkImage = mkImageCtor([350, 260], [0, 0])
  },
  ["dday_2026_uk_camo_reward"] = {
    name = loc("skin/churchill_7_ambush_camo")
    cardImageParams = mkImageParams([144, 170], [0, 17])
    icon = "ui/skin#currency/enlisted_camo_order_event.svg"
    cardImage = "!ui/shop/vehicles/churchill_7_ambush_camo.avif"
    mkImage = mkImageCtor([267, 200], [0, 0])
  },
  ["dday_2026_usa_reward_gun"] = {
    name = loc("items/kretz_p13")
    description = loc("items/kretz_p13/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/usa_kretz_p13_gold.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["dday_2026_ger_vehicle_reward"] = {
    name = loc("items/germ_sdkfz_221_s_pz_b_41")
    description = loc("items/germ_sdkfz_221_s_pz_b_41/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/germ_sdkfz_221_s_pz_b_41.avif"
    mkImage = mkImageCtor([267, 200], [0, 0])
  },
  ["dday_2026_ger_reward_gun"] = {
    name = loc("items/mkb_42_m")
    description = loc("items/mkb_42_m/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/mkb_42_m.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["dday_2026_usa_vehicle_reward"] = {
    name = loc("items/us_m6a2e1")
    description = loc("items/us_m6a2e1/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/vehicles/us_m6a2e1.avif"
    mkImage = mkImageCtor([267, 200], [0, 0])
  },
  ["jap_hero_battlepass_2026_6"] = {
    name = loc("hero/ei_yamaguchi")
    description = loc("hero/ei_yamaguchi/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2026_6.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ussr_hero_battlepass_2026_6"] = {
    name = loc("hero/mihail_kyrchanov")
    description = loc("hero/mihail_kyrchanov/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2026_6.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2026_7"] = {
    name = loc("hero/gottlob_binnermann")
    description = loc("hero/gottlob_binnermann/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2026_7.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["jap_hero_battlepass_2026_7"] = {
    name = loc("hero/kinshichi_kozuka")
    description = loc("hero/kinshichi_kozuka/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/jap_hero_battlepass_2026_7.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_2026_8"] = {
    name = loc("hero/don_harlem")
    description = loc("hero/don_harlem/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2026_8.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["ger_hero_battlepass_2026_8"] = {
    name = loc("hero/helmut_lent")
    description = loc("hero/helmut_lent/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ger_hero_battlepass_2026_8.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["type_3_chi_nu_75cm_type_5_threecolor_lines_bp"] = {
    name = loc("shop/type_3_chi_nu_75cm_type_5_threecolor_lines_bp")
    description = loc("shop/type_3_chi_nu_75cm_type_5_threecolor_lines_bp/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/type_3_chi_nu_75cm_type_5_threecolor_lines_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "jp_type_3_chi_nu_75cm_type_5"
    bpSeason = 32
  },
  ["kv_1_l_11_ussr_camo_leningradec"] = {
    name = loc("shop/kv_1_l_11_ussr_camo_leningradec")
    description = loc("shop/kv_1_l_11_ussr_camo_leningradec/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/kv_1_l_11_ussr_camo_leningradec_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "ussr_kv_1_L_11_stalingrad"
    bpSeason = 31
  },
  ["pzkpfw_v_ausf_a_panther_ger_ii_011"] = {
    name = loc("shop/pzkpfw_v_ausf_a_panther_ger_ii_011")
    description = loc("shop/pzkpfw_v_ausf_a_panther_ger_ii_011/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/pzkpfw_v_ausf_a_panther_ger_ii_011_battlepass.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "germ_pzkpfw_V_ausf_a_panther"
    bpSeason = 33
  },
  ["lahti_saloranta_m26_32_gold"] = {
    itemTemplate ="lahti_saloranta_m26_32"
    name = loc("items/lahti_saloranta_m26_32")
    description = loc("items/lahti_saloranta_m26_32/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/lahti_saloranta_m26_32_gold.avif"
    cardImageParams = mkImageParams([170, 92], [7, 10])
    worth = 4
  },
  ["slr_gold"] = {
    itemTemplate ="canadian_slr_1944"
    name = loc("items/canadian_slr_1944")
    description = loc("items/canadian_slr_1944/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/canadian_slr_1944_gold.avif"
    cardImageParams = mkImageParams([170, 88], [0, 18])
    worth = 4
  },
  ["ppt_28_gold"] = {
    itemTemplate ="ppt_28"
    name = loc("items/ppt_28")
    description = loc("items/ppt_28/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/ppt_28_gold.avif"
    cardImageParams = mkImageParams([170, 96], [0, 18])
    worth = 4
  },
  ["usa_vehicle_battle_pass_2026_6"] = {
    name = loc("items/f4u_1c_sky_pirates_battlepass")
    description = loc("items/f4u_1c_sky_pirates_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/usa_vehicle_battle_pass_2026_6.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_vehicle_battle_pass_2026_7"] = {
    name = loc("items/il_10_camo_green_battlepass")
    description = loc("items/il_10_camo_green_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ussr_vehicle_battle_pass_2026_7.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["jap_vehicle_battle_pass_2026_8"] = {
    name = loc("items/n1k2_j_orange_battlepass")
    description = loc("items/n1k2_j_orange_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/jap_vehicle_battle_pass_2026_8.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["ussr_hero_battlepass_2026_9"] = {
    name = loc("hero/anatoliy_kokorin")
    description = loc("hero/anatoliy_kokorin/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/ussr_hero_battlepass_2026_9.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["usa_hero_battlepass_2026_9"] = {
    name = loc("hero/hershel_williams")
    description = loc("hero/hershel_williams/desc")
    icon = "ui/skin#currency/soldier_order_gold.svg"
    previewImage = "ui/shop/battlepass/usa_hero_battlepass_2026_9.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_soldier.avif"
    cardImageParams = mkImageParams([162, 178])
  },
  ["m10_wolverine_black_star"] = {
    name = loc("shop/m10_wolverine_black_star")
    description = loc("shop/m10_wolverine_black_star/desc")
    icon = "ui/skin#currency/enlisted_camo_order_gold.svg"
    previewImage = "ui/shop/battlepass/m10_wolverine_black_star.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicle_camo.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
    vehicle = "us_m10_wolverine"
    bpSeason = 34
  },
  ["zh_32_gold"] = {
    itemTemplate ="zh_32"
    name = loc("items/zh_32")
    description = loc("items/zh_32/desc")
    icon = "ui/skin#currency/weapon_gold.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/zh_32_gold.avif"
    cardImageParams = mkImageParams([170, 110], [7, 10])
    worth = 4
  },
  ["ger_vehicle_battle_pass_2026_9"] = {
    name = loc("items/fw_190a_4_grunehertz_battlepass")
    description = loc("items/fw_190a_4_grunehertz_battlepass/subtitle")
    icon = "ui/skin#currency/vehicle_with_skin.svg"
    previewImage = "ui/shop/battlepass/ger_vehicle_battle_pass_2026_9.avif"
    previewSize = [hdpxi(500), hdpxi(385)]
    worth = 3
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#battlepass/gold_vehicles.avif"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["trial_by_combat_2026_event_order"] = {
    name = loc("items/trial_by_combat_2026_event_order")
    description = loc("items/trial_by_combat_2026_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["trial_by_combat_2026_usa_reward_portrait"] = {
    name = loc("decorator/trial_by_combat_2026_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/trial_by_combat_2026_usa_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["trial_by_combat_2026_jap_reward_portrait"] = {
    name = loc("decorator/trial_by_combat_2026_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/trial_by_combat_2026_jap_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["trial_by_combat_2026_ger_reward_portrait"] = {
    name = loc("decorator/trial_by_combat_2026_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/trial_by_combat_2026_ger_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["trial_by_combat_2026_ussr_reward_portrait"] = {
    name = loc("decorator/trial_by_combat_2026_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/trial_by_combat_2026_ussr_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["independence_day_usa_2026_reward_melee"] = {
    name = loc("items/khukuri_1916_knife")
    description = loc("items/khukuri_1916_knife/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/khukuri_1916_knife.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["operation_husky_reward_it_squad"] = {
    name = loc("squad/squad_it_mgun_2")
    description = loc("squadannounce/squad_it_mgun_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/germany/squad_it_mgun_2_image.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["operation_husky_reward_uk_squad"] = {
    name = loc("squad/squad_uk_radioman_2")
    description = loc("squadannounce/squad_uk_radioman_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/usa/squad_uk_radioman_2_image.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["arsenal_event_order"] = {
    name = loc("items/arsenal_event_order")
    description = loc("items/arsenal_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["arsenal_jap_reward_gun"] = {
    name = loc("items/type_97_antitank_grenade_launcher")
    description = loc("items/type_97_antitank_grenade_launcher/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/type_97_antitank_grenade_launcher.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["johnson_bday_usa_reward_gun"] = {
    name = loc("items/m1944_johnson_mg")
    description = loc("items/m1944_johnson_mg/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/m1944_johnson_mg.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["fire_and_flight_squad_usa_reward"] = {
    name = loc("squad/squad_usa_pilot_fighter_2_event_1")
    description = loc("squadannounce/squad_usa_pilot_fighter_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/usa/squad_usa_pilot_fighter_2_event_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["fire_and_flight_squad_ussr_reward"] = {
    name = loc("squad/squad_ussr_rifle_2_event_1")
    description = loc("squadannounce/squad_ussr_rifle_2_event_1")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/ussr/squad_ussr_rifle_2_event_1_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["fire_and_flight_event_order"] = {
    name = loc("items/fire_and_flight_event_order")
    description = loc("items/fire_and_flight_event_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  ["trial_by_combat_2026_2_event_uk_reward_gun"] = {
    name = loc("items/lanchester_model_1")
    description = loc("items/lanchester_model_1/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/lanchester_model_1.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["trial_by_combat_2026_2_event_ita_reward_gun"] = {
    name = loc("items/cei_rigotti_rifle")
    description = loc("items/cei_rigotti_rifle/desc")
    icon = "ui/skin#currency/event_order.svg"
    cardImage = "!ui/shop/weapons/cei_rigotti_rifle.avif"
    mkImage = mkImageCtor([300, 200], [0, 0])
  },
  ["trial_by_combat_2026_2_event_uk_reward_portrait"] = {
    name = loc("decorator/trial_by_combat_2026_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/trial_by_combat_2026_2_event_uk_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["trial_by_combat_2026_2_event_ita_reward_portrait"] = {
    name = loc("decorator/trial_by_combat_2026_reward_portrait_bundle")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/trial_by_combat_2026_2_event_ita_reward_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["hit_and_run_event_reward_nickframe"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#currency/nickframe_order_event.svg"
    bgImage = "ui/skin#battlepass/bg_other.avif"
    cardImage = "ui/skin#battlepass/nickframe_bp.avif"
    cardImageParams = mkImageParams([160, 178])
  },
  ["hit_and_run_event_reward_ita_portrait"] = {
    name = loc("decorator/hit_and_run_event_reward_ita_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/hit_and_run_event_reward_ita_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["hit_and_run_event_reward_usa_portrait"] = {
    name = loc("decorator/hit_and_run_event_reward_usa_portrait")
    icon = "ui/portraits/default_portrait.svg"
    cardImage = "!ui/portraits/event/hit_and_run_event_reward_usa_portrait.avif"
    mkImage = mkImageCtor([150, 150])
  },
  ["hit_and_run_event_usa_squad_reward"] = {
    name = loc("squad/squad_usa_apc_driver_2_event_2")
    description = loc("squadannounce/squad_usa_apc_driver_2_event_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/usa/squad_usa_apc_driver_2_event_2_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["hit_and_run_event_ger_squad_reward"] = {
    name = loc("squad/squad_it_apc_driver_2_event_2")
    description = loc("squadannounce/squad_it_apc_driver_2_event_2")
    icon = "ui/skin#research/squad_points_icon.svg"
    cardImage = "ui/soldiers/germany/squad_it_apc_driver_2_event_2_image.avif"
    mkImage = mkImageCtor([300, 225], [0, 0])
  },
  ["end_of_smolensk_operation_event_reward"] = {
    name = loc("items/end_of_smolensk_operation_event_reward_order")
    description = loc("items/end_of_smolensk_operation_event_reward_order/desc")
    icon = "ui/skin#currency/event_order.svg"
    bgImage = "ui/skin#battlepass/bg_gold.avif"
    cardImage = "ui/skin#currency/event_order.svg"
    mkImage = mkImageCtor([72, 100])
  },
  
  ["every_day_award_small_pack"] = defRewardPresentation.__merge({
    name = loc("smallTrophyTitle_2")
    cardImage = "ui/skin#rewards/crate_small_2.avif"
    cardImageOpen = "ui/skin#rewards/crate_small_2_open.avif"
  }),
  ["every_day_award_medium_pack"] = defRewardPresentation.__merge({
    name = loc("mediumTrophyTitle_1")
    cardImage = "ui/skin#rewards/crate_medium_1.avif"
    cardImageOpen = "ui/skin#rewards/crate_medium_1_open.avif"
  }),
  ["every_day_award_medium_pack_2"] = defRewardPresentation.__merge({
    name = loc("mediumTrophyTitle_1")
    cardImage = "ui/skin#rewards/crate_medium_1.avif"
    cardImageOpen = "ui/skin#rewards/crate_medium_1_open.avif"
  }),
  ["every_day_award_big_pack"] = defRewardPresentation.__merge({
    name = loc("bigTrophyTitle_1")
    cardImage = "ui/skin#rewards/crate_big_1.avif"
    cardImageOpen = "ui/skin#rewards/crate_big_1_open.avif"
  }),
  ["event_chest_daily_login_reward"] = defRewardPresentation.__merge({
    name = loc("items/silver_chest")
    description = loc("items/silver_chest/desc")
    cardImage = "ui/skin#rewards/event_chest.avif"
    cardImageOpen = "ui/skin#rewards/event_chest_open.avif"
    background = goldRadialGradient
    rewardGlow = "!ui/gameImage/enlisted_box_glow_dark_small.avif"
    progressConfig = {
      textColor = darkTxtColor
      background = goldVerticalGradient
    }
  }),

  
  ["event_chest_squads"] = defRewardPresentation.__merge({
    name = loc("items/event_chest_squads")
    cardImage = "ui/skin#rewards/crate_big_1"
  }),
  ["chest_new_meta_bp_weapon"] = defRewardPresentation.__merge({
    name = loc("items/chest_new_meta_bp_weapon")
    cardImage = "ui/skin#rewards/crate_medium_1"
  }),
  ["chest_old_meta_bp_weapon"] = defRewardPresentation.__merge({
    name = loc("items/chest_old_meta_bp_weapon")
    cardImage = "ui/skin#rewards/crate_medium_1"
  }),
  ["chest_event_weapon"] = defRewardPresentation.__merge({
    name = loc("items/chest_event_weapon")
    cardImage = "ui/skin#rewards/crate_medium_1"
  }),
  ["silver_chest_event_vehicle"] = defRewardPresentation.__merge({
    name = loc("items/silver_chest_event_vehicle")
    cardImage = "ui/skin#rewards/crate_big_1"
  }),
  ["chest_event_soldier"] = defRewardPresentation.__merge({
    name = loc("items/chest_event_soldier")
    cardImage = "ui/skin#rewards/crate_small_1"
  }),
  ["chest_customization_decor"] = defRewardPresentation.__merge({
    name = loc("items/chest_customization_decor")
    cardImage = "ui/skin#rewards/crate_small_1"
  }),
  ["chest_vehicle_camo"] = defRewardPresentation.__merge({
    name = loc("items/chest_vehicle_camo")
    cardImage = "ui/skin#rewards/crate_small_2"
  }),
  ["chest_vehicle_decor"] = defRewardPresentation.__merge({
    name = loc("items/chest_vehicle_decor")
    cardImage = "ui/skin#rewards/crate_small_2"
  }),
  ["chest_booster"] = defRewardPresentation.__merge({
    name = loc("items/chest_booster")
    cardImage = "ui/skin#rewards/crate_small_1"
  }),
  ["chest_silver"] = defRewardPresentation.__merge({
    name = loc("items/chest_silver")
    cardImage = "ui/skin#rewards/crate_small_1"
  }),
})

return {
  rewardsPresentation
}
