import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import smallPadding, midPadding, defTxtColor, attentionTxtColor
from "%ui/components/defcomps.nut" import txt
from "%ui/ui_library.nut" import *

const HOUR_SEC = 3600

const typeImgPW = 100.0 * 100 / 170
const typeImgPH = 100.0 * 100 / 210
const typeImgOffsetPH = 100.0 * 14 / 210

let defOverride = { color = defTxtColor }.__update(fontSub)

const imgBooster = "ui/skin#battlepass/boost_global.avif"
const durationIconSize = hdpxi(20)

let durationBoosterBlock = txt({
  text = loc("booster/duration")
  margin = const [0, hdpx(35), 0, 0]
}).__update(fontSub)

function mkDurationInfo(icon, text, override = {}) {
  let color  = override?.color ?? defTxtColor
  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        size = const [durationIconSize, durationIconSize]
        rendObj = ROBJ_IMAGE
        color
        image = Picture($"{icon}:{durationIconSize}:{durationIconSize}")
      }
      {
        rendObj = ROBJ_TEXT
        text
      }.__update(fontSub, override)
    ]
  }
}

let mkXpBooster = @(override = {}, isPenalty = false) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  margin = midPadding
  image = Picture($"ui/skin#battlepass/{isPenalty ? "bg_penalty" : "bg_boost"}.avif")
  children = {
    size = const [pw(typeImgPW), ph(typeImgPH)]
    pos = const [0, ph(typeImgOffsetPH)]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture(imgBooster)
  }
}.__update(override)

function mkBoosterInfo(booster, override = fontSub) {
  let { expMul = 0 } = booster
  return expMul <= 0 ? null
    : {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        text = $"+{100 * expMul}%"
      }.__update(override)
}

const boostTimeIcon = "ui/skin#battlepass/boost_time.svg"
const boostBattlesIcon = "ui/skin#battlepass/boost_battles.svg"

let mkBoosterLeftBattles = @(battles, override = {})
  mkDurationInfo(boostBattlesIcon, battles, override)

let mkLimitsChildren = @(battles, lifeTime, hasDurationLabel, override) [
  battles == 0 ? null
    : mkBoosterLeftBattles(battles, override)
  hasDurationLabel && battles > 0
    ? durationBoosterBlock
    : null
  lifeTime == 0 ? null
    : mkDurationInfo(boostTimeIcon, secondsToHoursLoc(lifeTime), override)
]

let expiringStyle = { color = attentionTxtColor }

function mkBoosterExpireInfo(booster, cStyle = {}, override = defOverride) {
  let { expireTs = 0 } = booster
  return function() {
    let secondsRemained = expireTs - serverTime.get()
    let style = override.__merge(secondsRemained < HOUR_SEC ? expiringStyle : {})
    return {
      watch = serverTime
      children = mkDurationInfo(boostTimeIcon,
        secondsToHoursLoc(secondsRemained), style)
    }.__update(cStyle)
  }
}

function mkBoosterLimits(booster, override = defOverride) {
  let { battles = 0, lifeTime = 0 } = booster
  return {
    flow = FLOW_VERTICAL
    gap = smallPadding
    vplace = ALIGN_BOTTOM
    children = mkLimitsChildren(battles, lifeTime, false, override)
  }
}

return {
  mkXpBooster
  mkBoosterInfo
  mkBoosterExpireInfo
  mkBoosterLimits
  mkBoosterLeftBattles
}
