import "%ui/components/colorize.nut" as colorize
import "%ui/helpers/icon3dByGameTemplate.nut" as icon3dByGameTemplate
from "string" import endswith
from "%ui/style/designConst.nut" import accentTitleTxtColor
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%darg/helpers/mkGradientImg.nut" import mkRadialGradientImg
from "%ui/helpers/gradients.nut" import mkColoredGradientY
from "%ui/components/decoratorsPresentation.nut" import portraits, nickFrames
from "%ui/profile/medalsPresentation.nut" import medalsPresentation
from "%ui/ui_library.nut" import *

let rewardBgSizePx = [hdpx(170), hdpx(210)]
let rewardWidthToHeight = rewardBgSizePx[0].tofloat() / rewardBgSizePx[1]

let calcSize = @(sizeBg, pxSize) [
  hdpxi(sizeBg[0] * pxSize[0].tofloat() / rewardBgSizePx[0]),
  hdpxi(sizeBg[1] * pxSize[1].tofloat() / rewardBgSizePx[1])
]

let mkImageParams = @(pxSize, pxOffset = [0, 12]) @(sizeBg) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = calcSize(sizeBg, pxSize)
  pos = calcSize(sizeBg, pxOffset)
}

let mkImageCtor = @(pxSize, pxOffset = [0, 12]) function(sizeBg, image) {
  let size = calcSize(sizeBg, pxSize)
  let img = endswith(image,".svg")
    ? $"{image}:{size[0]}:{size[1]}:F"
    : image
  return {
    size
    pos = calcSize(sizeBg, pxOffset)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture(img)
  }
}

let mkTemplateImageCtor = @(pxSize, pxOffset, gametemplate, genOverride = {}) function(sizeBg, _) {
  let size = calcSize(sizeBg, pxSize)
  return icon3dByGameTemplate(gametemplate, {
    width = size[0]
    height = size[1]
    pos = calcSize(sizeBg, pxOffset)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    genOverride
  })
}


function mkReward(reward, pName = "") {
  let { decorators = [] } = reward
  if (decorators.len() > 0) {
    let viewDecorator = decorators[0]
    let { guid, lifeTime = 0 } = viewDecorator
    let isTemporary = lifeTime > 0
    let lifeTimeText = !isTemporary ? ""
      : colorize(accentTitleTxtColor, loc("issuedFor", {
          timeTxt = secondsToHoursLoc(lifeTime)
        }))

    if (guid in portraits) {
      let { icon, name = null, bgimg = "", bgImage = null } = portraits[guid]
      return {
        middleImage = bgimg
        bgImage = bgImage ?? "ui/skin#battlepass/bg_portrait.avif"
        mkImage = mkImageCtor([130, 130], [0, 0])
        isTemporary
        name = loc(name ?? "portrait/baseName")
        description = "\n".join([ loc("decorator/baseDesc"), lifeTimeText ], true)
        stackImages = [
          {
            img = icon
            params = {
              size = FLEX
              hplace = ALIGN_CENTER
              vplace = ALIGN_CENTER
            }
          }
        ]
        gametemplate = guid
      }
    }
    if (guid in nickFrames){
      let cfg = nickFrames[guid]
      return {
        name = loc("nickFrames/baseName", { nick = cfg(pName) })
        isTemporary
        description = "\n".join([ loc("decorator/baseDesc"), lifeTimeText ], true)
        cardText = cfg("")
      }
    }
  }

  let { medals = [] } = reward
  if (medals.len() > 0) {
    let medal = medalsPresentation?[medals[0]]
    return medal == null ? null
      : {
          name = loc(medal.name)
          bgImage = medal.bgImage
          stackImages = medal.stackImages
        }
  }
  return null
}

let goldRadialGradient = {
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = mkRadialGradientImg({
    width = 16
    height = 16
    points = [
      { color = [0xFA, 0xD9, 0x7A] }
      { color = [0xC3, 0xAA, 0x5C] }
    ]
  })
}

let goldVerticalGradient = freeze({
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = mkColoredGradientY({colorTop=0xFFFAD97A, colorBottom=0xFF7D6D3D})
})

return {
  mkImageParams
  mkImageCtor
  mkTemplateImageCtor
  goldRadialGradient
  goldVerticalGradient
  mkReward
  rewardWidthToHeight
  rewardBgSizePx
}