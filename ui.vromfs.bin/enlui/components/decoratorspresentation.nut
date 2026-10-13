from "%ui/ui_library.nut" import *

local basePortrait = {
  name = ""
  icon = "ui/portraits/default_portrait.svg"
  color = Color(180,180,180)
}

local portraits = {
  berlin_axis_t1_1 = {
    icon = "ui/portraits/berlin/ger_berlin_2.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  berlin_axis_t2_1 = {
    icon = "ui/portraits/berlin/ger_berlin_3.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  berlin_axis_t3_1 = {
    icon = "ui/portraits/berlin/ger_berlin_1.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  berlin_axis_t4_1 = {
    icon = "ui/portraits/berlin/ger_berlin_4.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }

  berlin_allies_t1_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_4.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  berlin_allies_t2_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_1.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  berlin_allies_t2_2 = {
    icon = "ui/portraits/berlin/ussr_berlin_3.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  berlin_allies_t3_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_2.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  berlin_allies_t3_2 = {
    icon = "ui/portraits/berlin/ussr_berlin_6.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  berlin_allies_t4_1 = {
    icon = "ui/portraits/berlin/ussr_berlin_5.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }

  moscow_axis_t1_1 = {
    icon = "ui/portraits/moscow/ger_moscow_2.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  moscow_axis_t1_2 = {
    icon = "ui/portraits/moscow/ger_moscow_4.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  moscow_axis_t2_1 = {
    icon = "ui/portraits/moscow/ger_moscow_3.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  moscow_axis_t2_2 = {
    icon = "ui/portraits/moscow/ger_moscow_1.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  moscow_axis_t3_1 = {
    icon = "ui/portraits/moscow/ger_moscow_5.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  moscow_axis_t3_2 = {
    icon = "ui/portraits/moscow/ger_moscow_6.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  moscow_axis_t4_1 = {
    icon = "ui/portraits/moscow/ger_moscow_7.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }

  moscow_allies_t1_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_5.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  moscow_allies_t2_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_2.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  moscow_allies_t2_2 = {
    icon = "ui/portraits/moscow/ussr_moscow_4.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  moscow_allies_t3_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_3.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  moscow_allies_t3_2 = {
    icon = "ui/portraits/moscow/ussr_moscow_1.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  moscow_allies_t4_1 = {
    icon = "ui/portraits/moscow/ussr_moscow_6.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }


  normandy_axis_t1_1 = {
    icon = "ui/portraits/normandy/ger_normandy_2.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  normandy_axis_t2_1 = {
    icon = "ui/portraits/normandy/ger_normandy_3.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  normandy_axis_t3_1 = {
    icon = "ui/portraits/normandy/ger_normandy_1.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  normandy_axis_t4_1 = {
    icon = "ui/portraits/normandy/ger_normandy_4.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  normandy_axis_event_marathon_summer_2022 = {
    icon = "ui/portraits/normandy/ger_normandy_5.avif"
  }
  normandy_axis_lb_event_summer_2022_t1 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_1.avif"
  }
  normandy_axis_lb_event_summer_2022_t2 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_2.avif"
  }
  normandy_axis_lb_event_summer_2022_t3 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_3.avif"
  }
  normandy_axis_lb_event_summer_2022_t4 = {
    icon = "ui/portraits/normandy/ger_normandy_lb_4.avif"
  }

  normandy_allies_t1_1 = {
    icon = "ui/portraits/normandy/usa_normandy_3.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  normandy_allies_t2_1 = {
    icon = "ui/portraits/normandy/usa_normandy_1.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  normandy_allies_t3_1 = {
    icon = "ui/portraits/normandy/usa_normandy_2.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  normandy_allies_t4_1 = {
    icon = "ui/portraits/normandy/usa_normandy_4.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }

  tunisia_axis_t1_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_4.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  tunisia_axis_t2_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_3.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  tunisia_axis_t3_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_1.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  tunisia_axis_t4_1 = {
    icon = "ui/portraits/tunisia/axis_tunisia_5.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }

  tunisia_allies_t1_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_2.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  tunisia_allies_t1_2 = {
    icon = "ui/portraits/tunisia/allies_tunisia_1.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  tunisia_allies_t2_2 = {
    icon = "ui/portraits/tunisia/allies_tunisia_4.avif"
    bgimg = "ui/portraits/back_t2.avif"
  }
  tunisia_allies_t3_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_3.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  tunisia_allies_t3_2 = {
    icon = "ui/portraits/tunisia/allies_tunisia_5.avif"
    bgimg = "ui/portraits/back_t3.avif"
  }
  tunisia_allies_t4_1 = {
    icon = "ui/portraits/tunisia/allies_tunisia_6.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  tunisia_allies_event_marathon_summer_2022 = {
    icon = "ui/portraits/tunisia/allies_tunisia_7.avif"
  }




  preorder_dec_2022 = {
    icon = "ui/portraits/moscow/preorder_dec_2022.avif"
  }
  pacific_allies_preorder_2022 = {
    icon = "ui/portraits/pacific/pacific_allies_preorder_2022.avif"
  }
  enlisted2years_portrait_ussr = {
    icon = "ui/portraits/event/enlisted2years_portrait_ussr.avif"
  }
  enlisted2years_portrait_britain = {
    icon = "ui/portraits/event/enlisted2years_portrait_britain.avif"
  }
  enlisted2years_portrait_usa = {
    icon = "ui/portraits/event/enlisted2years_portrait_usa.avif"
  }
  armory_event_portrait_usa = {
    icon = "ui/portraits/normandy/armory_event_portrait_usa.avif"
  }
  armory_event_portrait_ger = {
    icon = "ui/portraits/tunisia/armory_event_portrait_ger.avif"
  }
  xmas_event_ussr_portrait = {
    icon = "ui/portraits/event/xmas_event_ussr_portrait.avif"
  }
  xmas_event_ger_portrait = {
    icon = "ui/portraits/event/xmas_event_ger_portrait.avif"
  }
  modes_engineer_portrait = {
    icon = "ui/portraits/event/engineer_portrait.avif"
  }
  stalingrad_event_portrait_ussr = {
    icon = "ui/portraits/event/stalingrad_event_portrait_ussr.avif"
  }
  engineerDay23_event_portrait = {
    icon = "ui/portraits/event/engineerDay23_event_portrait.avif"
  }
  portrait_preorder_paratrooper = {
    icon = "ui/portraits/event/portrait_preorder_paratrooper.avif"
  }
  mech_event_portrait = {
    icon = "ui/portraits/event/mech_event_portrait.avif"
  }
  berlin_operation_medic_portrait = {
    icon = "ui/portraits/event/berlin_operation_medic_portrait.avif"
  }
  portrait_preorder_sniper = {
    icon = "ui/portraits/event/portrait_preorder_sniper.avif"
  }
  stalingrad_bonus_portrait_ussr = {
    icon = "ui/portraits/event/stalingrad_bonus_portrait_ussr.avif"
  }
  stalingrad_bonus_portrait_ger = {
    icon = "ui/portraits/event/stalingrad_bonus_portrait_ger.avif"
  }
  armory2_bonus_portrait_ussr = {
    icon = "ui/portraits/event/armory2_bonus_portrait_ussr.avif"
  }
  armory2_bonus_portrait_ger = {
    icon = "ui/portraits/event/armory2_bonus_portrait_ger.avif"
  }
  armory3_bonus_portrait_italy = {
    icon = "ui/portraits/event/armory3_bonus_portrait_italy.avif"
  }
  armory3_bonus_portrait_britain = {
    icon = "ui/portraits/event/armory3_bonus_portrait_britain.avif"
  }
  portrait_opendev_23 = {
    icon = "ui/portraits/event/portrait_opendev_23.avif"
  }
  battlepass_11_portrait = {
    icon = "ui/portraits/event/battlepass_11_portrait.avif"
  }
   birthday2_bonus_portrait_tanker = {
    icon = "ui/portraits/event/birthday2_bonus_portrait_tanker.avif"
  }
  birthday2_bonus_portrait_pilot = {
    icon = "ui/portraits/event/birthday2_bonus_portrait_pilot.avif"
  }
  portrait_preorder_apc_driver = {
    icon = "ui/portraits/event/portrait_preorder_apc_driver.avif"
  }
  usentry_bonus_portrait = {
    icon = "ui/portraits/event/usentry_bonus_portrait.avif"
  }
  battlepass_12_portrait = {
    icon = "ui/portraits/event/battlepass_12_portrait.avif"
  }
  lunarNewyear24_bonus_portrait = {
    icon = "ui/portraits/event/lunarNewyear24_bonus_portrait.avif"
  }
  portrait_preorder_iron_fury = {
    icon = "ui/portraits/event/portrait_preorder_iron_fury.avif"
  }
  portrait_preorder_rocket_radioman = {
    icon = "ui/portraits/event/portrait_preorder_rocket_radioman.avif"
  }
  portrait_preorder_partisan = {
    icon = "ui/portraits/event/portrait_preorder_partisan.avif"
  }
  portrait_preorder_firestorm = {
    icon = "ui/portraits/event/portrait_preorder_firestorm.avif"
  }
  portrait_preorder_jet = {
    icon = "ui/portraits/event/portrait_preorder_jet.avif"
  }
  portrait_preorder_silent_storm = {
    icon = "ui/portraits/event/portrait_preorder_silent_storm.avif"
  }
  portrait_preorder_4_2025 = {
    icon = "ui/portraits/event/portrait_preorder_4_2025.avif"
  }
  portrait_preorder_1_2026 = {
    icon = "ui/portraits/event/portrait_preorder_1_2026.avif"
  }
  portrait_preorder_2_2026 = {
    icon = "ui/portraits/event/portrait_preorder_2_2026.avif"
  }
  portrait_preorder_3_2026 = {
    icon = "ui/portraits/event/portrait_preorder_3_2026.avif"
  }
  engineerDay24_bonus_portrait = {
    icon = "ui/portraits/event/engineerDay24_bonus_portrait.avif"
  }
  portrait_steam_pack = {
    icon = "ui/portraits/event/portrait_steam_pack.avif"
  }
  zombie_bonus_portrait_A = {
    icon = "ui/portraits/event/zombie_bonus_portrait_A.avif"
  }
  zombie_bonus_portrait_B = {
    icon = "ui/portraits/event/zombie_bonus_portrait_B.avif"
  }
  shpaginBirthday_bonus_portrait = {
    icon = "ui/portraits/event/shpaginBirthday_bonus_portrait.avif"
  }
  zombie_lb_portrait = {
    icon = "ui/portraits/event/zombie_lb_portrait.avif"
  }
  battlepass_13_portrait = {
    icon = "ui/portraits/event/battlepass_13_portrait.avif"
  }
  p47firstFlight_bonus_portrait = {
    icon = "ui/portraits/event/p47firstFlight_bonus_portrait.avif"
  }
  victory_bonus_portrait = {
    icon = "ui/portraits/event/victory_bonus_portrait.avif"
  }
  atr_type_97_bonus_portrait = {
    icon = "ui/portraits/event/atr_type_97_bonus_portrait.avif"
  }
  war_photograph_portrait = {
    icon = "ui/portraits/event/war_photograph_portrait.avif"
  }
  nkvd_bonus_portrait = {
    icon = "ui/portraits/event/nkvd_bonus_portrait.avif"
  }
  rocketstorm_event_ger_portrait = {
    icon = "ui/portraits/event/rocketstorm_event_ger_portrait.avif"
  }
  rocketstorm_event_ussr_portrait = {
    icon = "ui/portraits/event/rocketstorm_event_ussr_portrait.avif"
  }
  brestFortress_bonus_portrait = {
    icon = "ui/portraits/event/brestFortress_bonus_portrait.avif"
  }
  battlepass_14_portrait = {
    icon = "ui/portraits/event/battlepass_14_portrait.avif"
  }
  endOfKurskBattle_event_portrait = {
    icon = "ui/portraits/event/endOfKurskBattle_event_portrait.avif"
  }
  halloween_waverly_woodson = {
    icon = "ui/portraits/event/halloween_waverly_woodson.avif"
  }
  halloween_reinhard_rust = {
    icon = "ui/portraits/event/halloween_reinhard_rust.avif"
  }
  halloween_emelyan_barykin = {
    icon = "ui/portraits/event/halloween_emelyan_barykin.avif"
  }
  halloween_katsu_kato = {
    icon = "ui/portraits/event/halloween_katsu_kato.avif"
  }
  april_1_gangster = {
    icon = "ui/portraits/event/april_1_gangster.avif"
  }
  april_1_indian = {
    icon = "ui/portraits/event/april_1_indian.avif"
  }
  april_1_gendarm = {
    icon = "ui/portraits/event/april_1_gendarm.avif"
  }
  april_1_potman = {
    icon = "ui/portraits/event/april_1_potman.avif"
  }
  april_1_klyde = {
    icon = "ui/portraits/event/april_1_klyde.avif"
  }
  china_infantry_event_bonus_portrait = {
    icon = "ui/portraits/event/china_infantry_event_bonus_portrait.avif"
  }
  jap_vs_ussr_event_portrait_japan_tanker = {
    icon = "ui/portraits/event/jap_vs_ussr_event_portrait_japan_tanker.avif"
    bgImage = "ui/skin#events/bg_portrait_ussr_japan.avif"
  }
  jap_vs_ussr_event_portrait_soviet_soldier = {
    icon = "ui/portraits/event/jap_vs_ussr_event_portrait_soviet_soldier.avif"
    bgImage = "ui/skin#events/bg_portrait_ussr_japan.avif"
  }
  paratroopers_event_ger_portrait_reward = {
    icon = "ui/portraits/event/paratroopers_event_ger_portrait_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_paratroopers_event.avif"
  }
  paratroopers_event_usa_portrait_reward = {
    icon = "ui/portraits/event/paratroopers_event_usa_portrait_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_paratroopers_event.avif"
  }
  uk_vs_ita_ger_portrait_reward = {
    icon = "ui/portraits/event/uk_vs_ita_ger_portrait_event_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_uk_vs_ita.avif"
  }
  uk_vs_ita_usa_portrait_reward = {
    icon = "ui/portraits/event/uk_vs_ita_usa_portrait_event_reward.avif"
    bgImage = "ui/skin#events/bg_portrait_uk_vs_ita.avif"
  }
  t_34_first_run_event_portrait = {
    icon = "ui/portraits/event/t_34_first_run_event_portrait.avif"
  }
  ussr_elbe_day_event_portrait = {
    icon = "ui/portraits/event/ussr_elbe_day_event_portrait.avif"
  }
  usa_elbe_day_event_portrait = {
    icon = "ui/portraits/event/usa_elbe_day_event_portrait.avif"
  }
  victoryDay_2025_event_reward_portrait = {
    icon = "ui/portraits/event/victoryDay_2025_event_reward_portrait.avif"
  }
  german_assaulter_winter_event_portrait = {
    icon = "ui/portraits/event/german_assaulter_winter_event_portrait.avif"
  }
  normandieNeman_event_portrait = {
    icon = "ui/portraits/event/normandieNeman_event_portrait.avif"
  }
  end_of_the_siege_of_leningrad_event_portrait = {
    icon = "ui/portraits/event/end_of_the_siege_of_leningrad_event_portrait.avif"
  }
  lunar_new_year_2026_event_portrait = {
    icon = "ui/portraits/event/lunar_new_year_2026_event_portrait.avif"
  }
  ww1_1_april_reward_ger_portrait = {
    icon = "ui/portraits/event/ww1_1_april_reward_ger_portrait.avif"
    bgImage = "ui/skin#battlepass/bg_portrait_april_1_2026.avif"
  }
  ww1_1_april_reward_uk_portrait = {
    icon = "ui/portraits/event/ww1_1_april_reward_uk_portrait.avif"
    bgImage = "ui/skin#battlepass/bg_portrait_april_1_2026.avif"
  }
  victory_day_2026_reward_portrait = {
    icon = "ui/portraits/event/victory_day_2026_reward_portrait.avif"
  }
  trial_by_combat_2026_usa_reward_portrait = {
    icon = "ui/portraits/event/trial_by_combat_2026_usa_reward_portrait.avif"
  }
  trial_by_combat_2026_jap_reward_portrait = {
    icon = "ui/portraits/event/trial_by_combat_2026_jap_reward_portrait.avif"
  }
  trial_by_combat_2026_ger_reward_portrait = {
    icon = "ui/portraits/event/trial_by_combat_2026_ger_reward_portrait.avif"
  }
  trial_by_combat_2026_ussr_reward_portrait = {
    icon = "ui/portraits/event/trial_by_combat_2026_ussr_reward_portrait.avif"
  }
  trial_by_combat_2026_2_event_uk_reward_portrait = {
    icon = "ui/portraits/event/trial_by_combat_2026_2_event_uk_reward_portrait.avif"
  }
  trial_by_combat_2026_2_event_ita_reward_portrait = {
    icon = "ui/portraits/event/trial_by_combat_2026_2_event_ita_reward_portrait.avif"
  }
  hit_and_run_event_reward_ita_portrait = {
    icon = "ui/portraits/event/hit_and_run_event_reward_ita_portrait.avif"
  }
  hit_and_run_event_reward_usa_portrait = {
    icon = "ui/portraits/event/hit_and_run_event_reward_usa_portrait.avif"
  }

  common_china_portrait_1 = {
    icon = "ui/portraits/common/china_portrait_1.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  common_china_portrait_2 = {
    icon = "ui/portraits/common/china_portrait_2.avif"
  }
  common_china_portrait_3 = {
    icon = "ui/portraits/common/china_portrait_3.avif"
  }
  common_china_portrait_4 = {
    icon = "ui/portraits/common/china_portrait_4.avif"
  }
  common_china_portrait_5 = {
    icon = "ui/portraits/common/china_portrait_5.avif"
  }
  common_china_portrait_6 = {
    icon = "ui/portraits/common/china_portrait_6.avif"
  }
  common_china_portrait_7 = {
    icon = "ui/portraits/common/china_portrait_7.avif"
  }
  common_china_portrait_8 = {
    icon = "ui/portraits/common/china_portrait_8.avif"
  }
  common_china_portrait_9 = {
    icon = "ui/portraits/common/china_portrait_9.avif"
  }
  common_china_portrait_10 = {
    icon = "ui/portraits/common/china_portrait_10.avif"
  }
  common_china_portrait_11 = {
    icon = "ui/portraits/common/china_portrait_11.avif"
  }
  common_china_portrait_12 = {
    icon = "ui/portraits/common/china_portrait_12.avif"
  }
  common_china_portrait_13 = {
    icon = "ui/portraits/common/china_portrait_13.avif"
  }
  common_china_portrait_14 = {
    icon = "ui/portraits/common/china_portrait_14.avif"
    bgimg = "ui/portraits/back_t1.avif"
  }
  common_china_portrait_15 = {
    icon = "ui/portraits/common/china_portrait_15.avif"
  }
  common_china_portrait_16 = {
    icon = "ui/portraits/common/china_portrait_16.avif"
  }
  common_china_portrait_17 = {
    icon = "ui/portraits/common/china_portrait_17.avif"
  }
  common_china_portrait_18 = {
    icon = "ui/portraits/common/china_portrait_18.avif"
  }
  common_china_portrait_19 = {
    icon = "ui/portraits/common/china_portrait_19.avif"
  }
  common_china_portrait_20 = {
    icon = "ui/portraits/common/china_portrait_20.avif"
  }
  common_china_portrait_21 = {
    icon = "ui/portraits/common/china_portrait_21.avif"
  }
  common_china_portrait_22 = {
    icon = "ui/portraits/common/china_portrait_22.avif"
  }
  common_china_portrait_23 = {
    icon = "ui/portraits/common/china_portrait_23.avif"
  }
  common_china_portrait_24 = {
    icon = "ui/portraits/common/china_portrait_24.avif"
  }
  common_china_portrait_25 = {
    icon = "ui/portraits/common/china_portrait_25.avif"
  }
  common_china_portrait_26 = {
    icon = "ui/portraits/common/china_portrait_26.avif"
  }
  common_china_portrait_27 = {
    icon = "ui/portraits/common/china_portrait_27.avif"
  }
  common_china_portrait_28 = {
    icon = "ui/portraits/common/china_portrait_28.avif"
  }
  common_china_portrait_29 = {
    icon = "ui/portraits/common/china_portrait_29.avif"
  }
  common_china_portrait_30 = {
    icon = "ui/portraits/common/china_portrait_30.avif"
  }
  common_china_portrait_31 = {
    icon = "ui/portraits/common/china_portrait_31.avif"
  }
  common_china_portrait_32 = {
    icon = "ui/portraits/common/china_portrait_32.avif"
  }
  common_china_portrait_33 = {
    icon = "ui/portraits/common/china_portrait_33.avif"
  }
  common_china_portrait_34 = {
    icon = "ui/portraits/common/china_portrait_34.avif"
  }
  common_china_portrait_35 = {
    icon = "ui/portraits/common/china_portrait_35.avif"
  }
  common_china_portrait_36 = {
    icon = "ui/portraits/common/china_portrait_36.avif"
  }
  common_china_portrait_37 = {
    icon = "ui/portraits/common/china_portrait_37.avif"
  }
  common_china_portrait_38 = {
    icon = "ui/portraits/common/china_portrait_38.avif"
  }
  common_china_portrait_39 = {
    icon = "ui/portraits/common/china_portrait_39.avif"
  }
  common_china_portrait_40 = {
    icon = "ui/portraits/common/china_portrait_40.avif"
  }
  common_china_portrait_41 = {
    icon = "ui/portraits/common/china_portrait_41.avif"
  }
  common_china_portrait_42 = {
    icon = "ui/portraits/common/china_portrait_42.avif"
  }
  common_china_portrait_43 = {
    icon = "ui/portraits/common/china_portrait_43.avif"
  }
  common_china_portrait_44 = {
    icon = "ui/portraits/common/china_portrait_44.avif"
  }
  common_china_portrait_45 = {
    icon = "ui/portraits/common/china_portrait_45.avif"
  }
  common_china_portrait_46 = {
    icon = "ui/portraits/common/china_portrait_46.avif"
  }
  common_china_portrait_47 = {
    icon = "ui/portraits/common/china_portrait_47.avif"
  }
  common_china_portrait_48 = {
    icon = "ui/portraits/common/china_portrait_48.avif"
  }
  common_china_portrait_49 = {
    icon = "ui/portraits/common/china_portrait_49.avif"
  }
  common_china_portrait_50 = {
    icon = "ui/portraits/common/china_portrait_50.avif"
  }
  common_china_portrait_51 = {
    icon = "ui/portraits/common/china_portrait_51.avif"
  }
  common_china_portrait_52 = {
    icon = "ui/portraits/common/china_portrait_52.avif"
  }
  common_china_portrait_53 = {
    icon = "ui/portraits/common/china_portrait_53.avif"
  }
  common_china_portrait_54 = {
    icon = "ui/portraits/common/china_portrait_54.avif"
  }
  common_top_rank_portrait_1 = {
    icon = "ui/portraits/common/top_rank_portrait_1.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_2 = {
    icon = "ui/portraits/common/top_rank_portrait_2.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_3 = {
    icon = "ui/portraits/common/top_rank_portrait_3.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_4 = {
    icon = "ui/portraits/common/top_rank_portrait_4.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_5 = {
    icon = "ui/portraits/common/top_rank_portrait_5.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_6 = {
    icon = "ui/portraits/common/top_rank_portrait_6.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_7 = {
    icon = "ui/portraits/common/top_rank_portrait_7.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  common_top_rank_portrait_8 = {
    icon = "ui/portraits/common/top_rank_portrait_8.avif"
    bgimg = "ui/portraits/back_t4.avif"
  }
  avatar_halloween_assault = {
    icon = "ui/portraits/event/avatar_halloween_assault.avif"
  }
  avatar_halloween_anti_tank = {
    icon = "ui/portraits/event/avatar_halloween_anti_tank.avif"
  }
  avatar_aprilfools_2025_char_02 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_02.avif"
  }
  avatar_aprilfools_2025_char_08 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_08.avif"
  }
  avatar_halloween_engineer = {
    icon = "ui/portraits/event/avatar_halloween_engineer.avif"
  }
  avatar_aprilfools_2025_char_06 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_06.avif"
  }
  avatar_aprilfools_2025_char_04 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_04.avif"
  }
  avatar_aprilfools_2025_char_09 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_09.avif"
  }
  avatar_aprilfools_2025_char_03 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_03.avif"
  }
  avatar_aprilfools_2025_char_10 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_10.avif"
  }
  avatar_aprilfools_2025_char_11 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_11.avif"
  }
  avatar_aprilfools_2025_char_07 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_07.avif"
  }
  avatar_aprilfools_2025_char_13 = {
    icon = "ui/portraits/event/avatar_aprilfools_2025_char_13.avif"
  }
  bombardier_achievement_reward_portrait = {
    icon = "ui/portraits/common/bombardier_achievement_reward_portrait.avif"
  }
}


local baseNickFrame = @(n) n

local nickFrames = {
  pistol = @(n) $"⌈{n}⌉"
  flame = @(n) $"⋔{n}⋕"
  flag = @(n) $"⋝{n}⋞"
  rhomb = @(n) $"⋍{n}⋎"
  pyramid = @(n) $"⋒{n}⋓"
  grenade = @(n) $"⋘{n}⋙"
  helmet = @(n) $"⋤{n}⋥"
  rocket = @(n) $"⋰{n}⋱"
  line_1 = @(n) $"⋚{n}⋚"
  line_2 = @(n) $"⋦{n}⋦"
  lines_1 = @(n) $"⋛{n}⋛"
  lines_2 = @(n) $"⋜{n}⋜"
  lines_3 = @(n) $"⌂{n}⌆"
  lines_4 = @(n) $"⋩{n}⋩"
  wings_1 = @(n) $"⋖{n}⋗"
  wings_2 = @(n) $"⋢{n}⋣"
  wings_3 = @(n) $"⋪{n}⋫"
  wings_4 = @(n) $"⋬{n}⋭"
  wings_5 = @(n) $"⋮{n}⋯"
  wings_6 = @(n) $"⋧{n}⋨"
  nickFrame_1 = @(n) $"⋏{n}⋏"
  nickFrame_2 = @(n) $"⋐{n}⋐"
  nickFrame_3 = @(n) $"⋑{n}⋑"
  nickFrame_4 = @(n) $"⋟{n}⋟"
  nickFrame_5 = @(n) $"⋠{n}⋠"
  nickFrame_6 = @(n) $"⋡{n}⋡"
  nickFrame_100_days_in_row = @(n) $"⌠{n}⌠"
  nickFrame_365_days_in_row = @(n) $"⌋{n}⌊"
  nickFrame_730_days_in_row = @(n) $"⌡{n}⌢"
  nickFrame_1095_days_in_row = @(n) $"┯{n}┯"
  kongzhong_star = @(n) $"␉{n}␉"
  kongzhong_nickFrame_1 = @(n) $"␛{n}␛"
  kongzhong_nickFrame_2 = @(n) $"␜{n}␜"
  kongzhong_nickFrame_3 = @(n) $"␝{n}␝"
  kongzhong_nickFrame_4 = @(n) $"␞{n}␞"
  kongzhong_nickFrame_5 = @(n) $"␟{n}␠"
  kongzhong_nickFrame_6 = @(n) $"┅{n}┅"
  kongzhong_nickFrame_7 = @(n) $"┆{n}┆"
  kongzhong_nickFrame_8 = @(n) $"┇{n}┈"
  kongzhong_nickFrame_9 = @(n) $"┉{n}┊"
  kongzhong_nickFrame_10 = @(n) $"┋{n}┋"
  kongzhong_nickFrame_11 = @(n) $"┌{n}┌"
  kongzhong_nickFrame_12 = @(n) $"┍{n}┍"
  kongzhong_nickFrame_13 = @(n) $"┐{n}┐"
  kongzhong_nickFrame_14 = @(n) $"┑{n}┑"
  pacific_nickFrame_1 = @(n) $"␡{n}␡"
  pacific_nickFrame_2 = @(n) $"␣{n}␢"
  pacific_nickFrame_3 = @(n) $"␤{n}─"
  pacific_nickFrame_4 = @(n) $"━{n}│"
  pacific_nickFrame_5 = @(n) $"┃{n}┃"
  pacific_nickFrame_6 = @(n) $"␅{n}␆"
  nickFrame_hammer = @(n) $"⌣{n}␀"
  nickFrame_wrench = @(n) $"␁{n}␁"
  nickFrame_gear = @(n) $"␂{n}␂"
  nickFrame_bomb_1 = @(n) $"␃{n}␃"
  nickFrame_bomb_2 = @(n) $"␌{n}␌"
  nickFrame_tnt = @(n) $"␄{n}␄"
  nickFrame_rocket = @(n) $"␇{n}␈"
  nickFrame_bullet = @(n) $"␊{n}␊"
  nickFrame_target = @(n) $"␋{n}␋"
  nickFrame_aim = @(n) $"␎{n}␎"
  nickFrame_ribbon_1 = @(n) $"␏{n}␐"
  nickFrame_parachute = @(n) $"␑{n}␑"
  nickFrame_lines_5 = @(n) $"␒{n}␒"
  nickFrame_lines_6 = @(n) $"␓{n}␔"
  nickFrame_lines_7 = @(n) $"␕{n}␖"
  nickFrame_lines_8 = @(n) $"␗{n}␘"
  nickFrame_lines_9 = @(n) $"␙{n}␚"
  nickFrame_samurai = @(n) $"┄{n}┄"
  nickFrame_mgun = @(n) $"┏{n}┏"
  nickFrame_preorder_mgun = @(n) $"┏{n}┏"
  nickFrame_preorder_paratrooper = @(n) $"┒{n}┒"
  nickFrame_alfa_tester = @(n) $"┓{n}┓"
  nickFrame_preorder_sniper = @(n) $"└{n}└"
  nickFrame_prem_shop_bonus = @(n) $"┕{n}┕"
  nickFrame_bday_3 = @(n) $"┖{n}┖"
  nickFrame_preorder_apc_driver = @(n) $"┗{n}┗"
  nickFrame_new_year24_event = @(n) $"┘{n}┙"
  kongzhong_nickFrame_15 = @(n) $"┚{n}┛"
  kongzhong_nickFrame_16 = @(n) $"├{n}┝"
  nickFrame_lunarNewyear24_event = @(n) $"┦{n}┧"
  nickFrame_preorder_iron_fury = @(n) $"┤{n}┥"
  nickFrame_steam_pack = @(n) $"┨{n}┩"
  nickFrame_zombie_event = @(n) $"┪{n}┪"
  nickFrame_preorder_rocket_radioman = @(n) $"┫{n}┬"
  nickFrame_preorder_partisan = @(n) $"┰{n}┱"
  nickFrame_birthday_2024_event = @(n) $"┴{n}┴"
  nickFrame_preorder_firestorm = @(n) $"┢{n}┣"
  nickFrame_preorder_jet = @(n) $"┹{n}┺"
  nickFrame_preorder_silent_storm = @(n) $"╁{n}╁"
  nickFrame_oak_leaf = @(n) $"┵{n}┵"
  nickFrame_officer_star = @(n) $"┶{n}┶"
  nickFrame_lunar_new_year_2025_event = @(n) $"┷{n}┸"
  nickFrame_jap_vs_ussr_event = @(n) $"┲{n}┳"
  nickFrame_tomahawk = @(n) $"┽{n}┾"
  nickFrame_competition_2025_event = @(n) $"┿{n}╀"
  nickFrame_1460_days_in_row = @(n) $"┿{n}╀"
  nickFrame_preorder_heavy_assault_ussr = @(n) $"╂{n}╃"
  nickFrame_preorder_heavy_assault_ger = @(n) $"╄{n}╅"
  nickFrame_preorder_4_2025 = @(n) $"┞{n}┞"
  nickFrame_preorder_1_2026 = @(n) $"╎{n}╏"
  nickFrame_preorder_2_2026 = @(n) $"═{n}║"
  nickFrame_preorder_3_2026 = @(n) $"╓{n}╓"
  nickFrame_paratroopers_event = @(n) $"┭{n}┮"
  nickFrame_uk_vs_ita_ger = @(n) $"╊{n}╊"
  nickFrame_uk_vs_ita_usa = @(n) $"╋{n}╋"
  nickFrame_Bitrhday2025 = @(n) $"┟{n}┟"
  nickframe_lunar_new_year_2026_event = @(n) $"╌{n}╍"
  nickframe_hit_and_run_event = @(n) $"╔{n}╕"
}


return {
  basePortrait
  portraits
  nickFrames
  isPortrait = @(id) id in portraits
  isFrameNick = @(frameId) frameId in nickFrames
  getPortrait = @(id) portraits?[id] ?? basePortrait
  getFrameNick = @(id) nickFrames?[id] ?? baseNickFrame
  frameNick = @(nick, frameId) nickFrames?[frameId](nick) ?? nick
}
