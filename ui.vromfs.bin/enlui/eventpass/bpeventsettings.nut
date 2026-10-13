from "settings" import get_setting_by_blk_path
from "%ui/gameModes/eventModesState.nut" import selEvent
from "%ui/ui_library.nut" import *

let commonSettings = {
  getLockIcon = @(size) "!ui/uiskin/battlepass/lock_bp.svg:{0}:{1}:K".subst(size[0], size[1])
}

let eventPresentation = freeze({
    april_1 = {
      passTitle = "events/april_1_2025"
      passTitlePrem = "events/april_1_2025_elite"
      passRewardsPrem = "eventPass/premiumRewards/april_1"
      passProgress = "eventPass/howToProgress/april_1"
      passProgressPrem = "eventPass/howToProgressWithPremium/april_1"
      premPassDesc = "eventPass/description/april_1"

      premPassStat = "prempass_april_1_active"
      premPassItem = "prempassApril1"
      premPassTokenMult = 2

      bpImageBgPath = "ui/uiskin/battlepass/bp_seasons/bp_bg_white.avif:K"
      getBpImagePath = @(size)
        "!ui/uiskin/events/april_1_2025_logo.svg:{0}:{1}".subst(size[0], size[1])
      getTokenIcon = @(size)
        "!ui/uiskin/currency/april_1_2025_token.svg:{0}:{1}".subst(size[0], size[1])
      starColor = Color(255, 255, 0)
      seasonBgColor = Color(255, 255, 0)

      bpPremiumStat = "april_1_stage"
      bpDailyPoints = "april_1_daily_points"
      bpDailyPointsPrem = "april_1_daily_points"
      bpDailyUnlocks = "april_1_2025"
      bpDailyReward = "april_1_daily_event_chest"

      bpBasicUnlock = "april_1_common"
      bpPremiumUnlock = "april_1_premium"
      bpPremiumStage0 = "april_1_stage_0_premium"

      getEventLbUrl = function() {
        let lbUrls = {
          
          en = "https://enlisted.net/en/news/show/825-operation-earth-shield-en/#!/"
          ru = "https://enlisted.net/ru/news/show/839-operaciya-zemnoj-shit-ru/#!/"
        }
        return get_setting_by_blk_path("currentEventUrl")
          ?? lbUrls?[loc("langAbbreviation")]
          ?? lbUrls.en
      }
    }

    jap_vs_ussr = {
      rewardsDesc = "eventPass/rewardsDesc/ussr_japan"
      rewardsOwned = "eventPass/rewardsOwned"

      premPassStat = "prempass_active_stat_ussr_vs_japan"
      premPassItem = "boosterActiveUSSRvsJapan"
      premPassTokenMult = 1.25

      premPassItemIcons = [
        "ui/skin#battlepass/jap_vs_ussr_bonus",
        "ui/skin#battlepass/jap_vs_ussr_decorator"
      ]

      bpPremiumStat = "battle_score_with_bonus"

      bpBasicUnlock = "ussr_vs_japan_event_main"
      bpPremiumUnlock = "ussr_vs_japan_event_main"
      bpPremiumStage0 = "ussr_vs_japan_booster_purchased"

      purchaseStageUnlock = "ussr_vs_japan_event_unlock"
      isMarathonEvent = true
    }

    enlisted_paratrooper = {
      rewardsDesc = "eventPass/rewardsDesc/paratrooper"
      rewardsOwned = "eventPass/rewardsOwned"

      premPassStat = "prempass_active_stat_marken_garden"
      premPassItem = "boosterActiveParatroopersEvent"
      premPassTokenMult = 1.3

      premPassItemIcons = [
        "ui/skin#battlepass/paratroopers_event_booster",
        "ui/skin#battlepass/paratroopers_event_nickframe"
      ]
      infoIconColor = Color(40,40,40)

      bpPremiumStat = "battle_score_with_bonus"

      bpBasicUnlock = "marken_garden_event_main"
      bpPremiumUnlock = "marken_garden_event_main"
      bpPremiumStage0 = "marken_garden_booster_purchased"

      purchaseStageUnlock = "marken_garden_event_unlock"
      isMarathonEvent = true
    }

    uk_vs_ita = {
      rewardsDesc = "eventPass/rewardsDesc/uk_vs_ita"
      rewardsOwned = "eventPass/rewardsOwned"

      premPassStat = "prempass_active_stat_uk_vs_ita"
      premPassItem = "boosterActiveUkVsItaEvent"
      premPassTokenMult = 1.3

      premPassItemIcons = [
        "ui/skin#battlepass/uk_vs_ita_booster_reward",
        "ui/skin#battlepass/uk_vs_ita_nickframe_ger_reward"
      ]

      bpPremiumStat = "battle_score_with_bonus"

      bpBasicUnlock = "uk_vs_ita_event_main"
      bpPremiumUnlock = "uk_vs_ita_event_main"
      bpPremiumStage0 = "uk_vs_ita_booster_purchased"

      purchaseStageUnlock = "uk_vs_ita_event_unlock"
      isMarathonEvent = true
    }

    halloween_2025 = {
      passTitle = "events/halloween_2025"
      passTitlePrem = "events/halloween_2025"
      passRewardsPrem = "eventPass/premiumRewards/halloween_2025"
      passProgress = "eventPass/howToProgress/halloween_2025"
      passProgressPrem = "eventPass/howToProgressWithPremium/halloween_2025"
      premPassDesc = "eventPass/description/halloween_2025"

      premPassStat = "prempass_halloween_2025_active"
      premPassItem = "prempassHalloween_2025"

      bpImageBgPath = "ui/uiskin/battlepass/bp_seasons/bp_bg_white.avif:K"
      getBpImagePath = @(size)
        "!ui/uiskin/events/bp_halloween_logo_2025.svg:{0}:{1}".subst(size[0], size[1])
      getTokenIcon = @(size)
        "!ui/uiskin/events/statistics_halloween_icon.svg:{0}:{1}".subst(size[0], size[1])
      starColor = Color(0, 255, 150)
      seasonBgColor = Color(217, 37, 0)

      bpPremiumStat = "halloween_2025_stage"
      bpDailyPoints = "halloween_2025_daily_points"
      bpDailyPointsPrem = "halloween_2025_daily_points"
      bpDailyUnlocks = "halloween_2025"

      bpBasicUnlock = "halloween_2025_common"
      bpPremiumUnlock = "halloween_2025_premium"
      bpPremiumStage0 = "halloween_2025_stage_0_premium"
    }

    ww1_event = {
      passTitle = "events/ww1_april_1"
      passTitlePrem = "events/ww1_april_1_elite"
      passRewardsPrem = "eventPass/premiumRewards/ww1_april_1"
      passProgress = "eventPass/howToProgress/ww1_april_1"
      passProgressPrem = "eventPass/howToProgressWithPremium/ww1_april_1"
      premPassDesc = "eventPass/description/ww1_april_1"

      premPassStat = "prempass_ww1_april_1_active"
      premPassItem = "prempass_ww1_April_1"

      bpImageBgPath = "ui/uiskin/battlepass/bp_seasons/bp_bg_white.avif:K"
      getBpImagePath = @(size)
        "!ui/uiskin/events/ww1_april_1_logo.svg:{0}:{1}".subst(size[0], size[1])
      getTokenIcon = @(size)
        "!ui/uiskin/tasks/star_empty.svg:{0}:{1}".subst(size[0], size[1])
      starColor = Color(190, 12, 10)
      seasonBgColor = Color(0, 0, 0)

      bpPremiumStat = "ww1_april_1_stage"
      bpDailyPoints = "ww1_april_1_daily_points"
      bpDailyPointsPrem = "ww1_april_1_daily_points"
      bpDailyUnlocks = "ww1_april_1"

      bpBasicUnlock = "ww1_april_1_common"
      bpPremiumUnlock = "ww1_april_1_premium"
      bpPremiumStage0 = "ww1_april_1_stage_0_premium"
    }
  }.map(@(settings) commonSettings.__merge(settings)))

let bpWidget = Computed(function() {
  foreach (q in selEvent.get()?.queues ?? []) {
    let { battlepassWidget = "" } = q?.extraParams
    if (battlepassWidget != "")
      return battlepassWidget
  }
  return ""
})

let bpEventSettings = Computed(@() eventPresentation?[bpWidget.get()])
let needShowPass = Computed(@() bpEventSettings.get() != null)

return {
  bpEventSettings
  needShowPass
}
