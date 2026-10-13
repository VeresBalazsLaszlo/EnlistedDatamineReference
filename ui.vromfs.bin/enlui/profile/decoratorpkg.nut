import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/style/fontsStyle.nut" import fontBody, fontTitle, fontawesome
from "%ui/components/defcomps.nut" import txt
from "%ui/profile/profilePkg.nut" import borderColor
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/style/designConst.nut" import midPadding, smallPadding, defBgColor,
  idleBgColor, defTxtColor, titleTxtColor, shadowStyle, accentTitleTxtColor
from "string" import endswith
from "%ui/components/rankPresentation.nut" import mkRank, getRankConfig
from "%ui/components/decoratorsPresentation.nut" import isPortrait, isFrameNick,
  getPortrait, getFrameNick
from "%ui/ui_library.nut" import *

const PORTRAIT_SIZE = hdpx(160)
const NICKFRAME_SIZE = hdpx(140)

const timerIcon = "ui/skin#battlepass/boost_time.svg"
const timerSize = hdpxi(20)

let mkImage = @(path, size, override = {}) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  imageValign = ALIGN_TOP
  image = Picture(endswith(path, ".svg") ? $"!{path}:{size}:{size}" : $"{path}?Ac")
}.__update(override)

function mkExpireTime(expireTime, override = {}) {
  let expireText = Computed(function() {
    let expireSec = expireTime - serverTime.get()
    return expireSec <= 0 ? loc("timeExpired") : secondsToHoursLoc(expireSec)
  })
  return @() {
    watch = expireText
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    padding = midPadding
    margin = hdpx(2)
    halign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = const [timerSize, timerSize]
        image = Picture($"{timerIcon}:{timerSize}:{timerSize}")
      }
      txt({
        text = expireText.get()
        color = titleTxtColor
      })
    ]
  }.__update(override)
}

function mkPortraitIcon(portraitCfg, pSize = PORTRAIT_SIZE) {
  let { bgimg = "", icon = "", color = Color(255,255,255) } = portraitCfg
  let size = (pSize - smallPadding * 2).tointeger()
  return {
    padding = smallPadding
    children = [
      bgimg == "" ? null : mkImage(bgimg, size)
      icon == "" ? null : mkImage(icon, size, { color })
    ]
  }
}

let disabledParams = {
  tint = Color(40, 40, 40, 180)
  picSaturate = 0.0
}

function mkDisabledPortraitIcon(portraitCfg) {
  let { bgimg = "", icon = "" } = portraitCfg
  let size = (PORTRAIT_SIZE - smallPadding * 2).tointeger()
  return {
    padding = smallPadding
    children = [
      bgimg != "" ? mkImage(bgimg, size, disabledParams) : null
      icon != "" ? mkImage(icon, size, disabledParams) : null
    ]
  }
}


let mkIcon = @(text, color) {
  hplace = ALIGN_RIGHT
  padding = midPadding
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontawesome, shadowStyle)


let mkPortraitFrame = @(portraitCfg, isEnabled = true, onClick = null, onHover = null, icon = null)
  watchElemState(function(sf) {
    return {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = [PORTRAIT_SIZE, PORTRAIT_SIZE]
      fillColor = defBgColor
      borderColor = borderColor(sf)
      behavior = onClick == null ? null : Behaviors.Button
      xmbNode = XmbNode()
      onClick
      onHover
      children = [
        isEnabled || (sf & S_HOVER)
          ? mkPortraitIcon(portraitCfg)
          : mkDisabledPortraitIcon(portraitCfg),
        icon == null ? null
          : mkIcon(icon, borderColor(sf))
      ]
    }
  })


let mkNickFrame = @(nCfg, color = defTxtColor, brdColor = idleBgColor) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  size = const [NICKFRAME_SIZE, NICKFRAME_SIZE]
  fillColor = defBgColor
  borderColor = brdColor
  children = txt({
    text = nCfg?("") ?? ""
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color
  }).__update(fontTitle)
}

let mkRatingBlock = @(rankDataWatch, cb = null)
  watchElemState(function(sf) {
    let { rank = 0 } = rankDataWatch.get()
    let { locId } = getRankConfig(rank)
    return {
      watch = rankDataWatch
      size = FLEX_V
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      behavior = cb == null ? null : Behaviors.Button
      onClick = cb
      children = [
        txt({
          text = loc(locId)
          color = sf & S_HOVER ? accentTitleTxtColor : titleTxtColor
        }).__update(fontBody)
        mkRank(rank, hdpxi(120))
      ]
    }
  })


let mkViewDecoratorById = @(id)
  isPortrait(id) ? mkPortraitIcon(getPortrait(id))
    : isFrameNick(id) ? mkNickFrame(getFrameNick(id))
    : null


return {
  mkPortraitFrame
  mkPortraitIcon
  mkRatingBlock
  mkNickFrame
  mkExpireTime
  mkViewDecoratorById
  PORTRAIT_SIZE
  NICKFRAME_SIZE
}
