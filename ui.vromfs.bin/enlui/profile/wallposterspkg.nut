import "%ui/components/exclamation.nut" as exclamation
from "dagor.localize" import doesLocTextExist
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/profile/profilePkg.nut" import bgColor, txtColor
from "%ui/style/designConst.nut" import midPadding, smallPadding, defTxtColor, darkTxtColor, bigPadding, disabledTxtColor
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/battlepass/battlePassPkg.nut" import staticSeasonBPIcon
from "%ui/ui_library.nut" import *

const wpSize = hdpxi(190)
const wpHeaderWidth = hdpxi(150)
const iconSize = hdpxi(60)

let weakTxtColor = @(sf) sf & S_HOVER ? darkTxtColor : disabledTxtColor

let mkText = @(text, style) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(style)

let mkTextArea = @(text, style, sf=0) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
  color = txtColor(sf)
  text
}.__update(style)

let mkTitleColumn = @(text, sf) {
  size = const [wpHeaderWidth, SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  children = mkText(text, { color = weakTxtColor(sf) }.__update(fontBody))
}

let mkWpRow = @(locId, rowTitleText, isEmptyHidden = false, sf = 0)
  doesLocTextExist(locId) || !isEmptyHidden
    ? {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        children = [
          mkTitleColumn(rowTitleText, sf)
          mkTextArea(loc(locId), fontBody, sf)
        ]
      }
    : null

function mkWpBpSeasonIcon(wallposter) {
  let { bpSeason = null, icon = null } = wallposter
  return {
    size = const [wpHeaderWidth, SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    children = icon != null
      ? {
          rendObj = ROBJ_IMAGE
          size = const [iconSize, iconSize]
          image = Picture($"{icon}:{iconSize.tointeger()}:{iconSize.tointeger()}:K?Ac")
        }
      : (bpSeason ?? 0) == 0 ? null : staticSeasonBPIcon(bpSeason, iconSize)
  }
}

let mkWpBottomRow = @(wallposter, sf) {
  rendObj = ROBJ_FRAME
  size = const [pw(70), SIZE_TO_CONTENT]
  margin = const [0, wpHeaderWidth]
  flow = FLOW_VERTICAL
  color = weakTxtColor(sf)
  borderWidth = const [hdpx(1), 0, 0, 0]
  children = mkText(loc(wallposter.armyLocId), {
    color = weakTxtColor(sf)
    margin = [0, bigPadding]
  }.__update(fontBody))
}

let mkWallposterImg = @(img, hasReceived, isHovered, wpImgSize) {
  rendObj = ROBJ_IMAGE
  size = [wpImgSize, wpImgSize]
  picSaturate = hasReceived ? 1.2
    : isHovered ? 0.5
    : 0.1
  opacity = hasReceived || isHovered ? 1 : 0.7
  image = Picture(img)
}

function mkWallposter(wallposter, sf = 0, isUnseen = false) {
  let { hasReceived, isHidden, img, nameLocId, descLocId, hintLocId } = wallposter
  let isHovered = sf & S_HOVER
  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      mkWallposterImg(img, hasReceived, isHovered, wpSize)
      {
        rendObj = ROBJ_SOLID
        size = FLEX
        padding = midPadding
        color = bgColor(sf)
        children = [
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            gap = midPadding
            children = [
              mkWpRow(nameLocId, loc("wp/name"), false, sf)
              { size = [FLEX, smallPadding] }
              mkWpRow(descLocId, loc("wp/desc"), true, sf)
              mkWpRow(hintLocId, loc("wp/toToGet"), true, sf)
              mkWpBottomRow(wallposter, sf)
            ]
          }
          mkWpBpSeasonIcon(wallposter)
          isHidden ? exclamation().__update({ hplace = ALIGN_RIGHT }) : null
          isUnseen ? smallUnseenNoBlink : null
        ]
      }
    ]
  }
}

function makeBigWpImage(wallposter, onClick) {
  let { img, nameLocId } = wallposter
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = midPadding
    padding = midPadding
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    children = [
      mkTextArea(loc(nameLocId), {
        size = const [pw(80), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
      }.__update(fontBody))
      {
        rendObj = ROBJ_IMAGE
        size = FLEX
        image = Picture(img)
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }
}

return {
  mkWallposter
  mkWallposterImg
  makeBigWpImage
}
