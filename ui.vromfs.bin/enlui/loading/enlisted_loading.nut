from "%ui/style/fontsStyle.nut" import fontHeading1, fontHeading2, fontBody
from "%ui/state/missionParams.nut" import missionParams
from "%ui/state/appState.nut" import levelIsLoading
from "%ui/loading/loadingComponents.nut" import mkParallaxBkg, mkAnimatedEllipsis
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/style/designConst.nut" import darkBgColor
from "dagor.localize" import doesLocTextExist
from "%ui/hud/state/loading.nut" import loadingImages
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let {set_fully_covering = @(_) null} = require_optional("loading_ui")
let { shuffle } = require("%sqstd/rand.nut")

let curImg = Computed(@() shuffle(loadingImages.get() ?? [])?[0])

local hintsToChange = []

const hintsKey = "loading_tip"
local lastAddedTipIdx = 0

for(local idx = 1; idx - lastAddedTipIdx < 3 ; idx++){
  let newKey = $"{hintsKey}{idx}"
  if (doesLocTextExist(newKey)){
    hintsToChange.append(newKey)
    lastAddedTipIdx = idx
  }
}

hintsToChange = shuffle(hintsToChange)

let curIdx = Watched(0)

let curHint = Computed(@() hintsToChange.len() > 0
  ? hintsToChange[curIdx.get() % hintsToChange.len()]
  : "practice_desc")

const tipHeaderColor = Color(230,200,30,255)

const defaultTimeToSwitch = 20
const defaultAutoTimeToSwitch = 15
function nextTipAuto(){
  curIdx.modify(@(v)v + 1)
}
function nextTip() {
  gui_scene.clearTimer(nextTipAuto)
  gui_scene.resetTimeout(defaultTimeToSwitch, callee())
  curIdx.modify(@(v)v + 1)
}
function prevTip(){
  gui_scene.clearTimer(nextTipAuto)
  gui_scene.resetTimeout(defaultTimeToSwitch, nextTip)
  curIdx.modify(@(v)v + 1)
}
gui_scene.setInterval(defaultAutoTimeToSwitch, nextTipAuto)

let showImage = keepref(Computed(@() curImg.get() != null && !levelIsLoading.get()))
showImage.subscribe(set_fully_covering)
const color = Color(160,160,160,160)

const fontSize = hdpx(25)
let animatedEllipsis = mkAnimatedEllipsis(fontSize, color)

let animatedLoading = @(){
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  watch = [safeAreaVerPadding, safeAreaHorPadding]
  valign = ALIGN_CENTER
  padding = [safeAreaVerPadding.get() + fsh(1), safeAreaHorPadding.get() + sw(4)]
  pos = const [-fsh(7),-fsh(3)]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("Loading")
      color = color
    }.__update(fontHeading1)
    {size=const [hdpx(4),0]}
    animatedEllipsis
  ]
}

const parallaxK = -0.025
local letterBoxHeight=(sh(100) - sw(100)/16*9)/2
if (letterBoxHeight < 0)
  letterBoxHeight = 0

let letterboxUp = {rendObj = ROBJ_SOLID size=[FLEX, letterBoxHeight], color = Color(0,0,0)}
let letterboxDown = letterboxUp.__merge({vplace=ALIGN_BOTTOM})


let loadingBkg = mkParallaxBkg(curImg, parallaxK, (sh(100)-letterBoxHeight*2), sw(100))

let blackScreen = {
  rendObj = ROBJ_SOLID
  color = Color(0,0,0)
  size = FLEX
}

let tipsHotkeys = @() {
  size = FLEX
  children = {
    behavior = Behaviors.Button
    size = FLEX
    hotkeys = [
      ["^A | Down | S | M:0", prevTip],
      ["^W | Up | D | | M:1", nextTip],
      ["^J:D.Left | Left", prevTip],
      ["^J:D.Right | Right", nextTip]
    ]
  }
}

let decoratedImage = @(){
  size = FLEX
  watch = curImg
  children = curImg.get() != null ? [
    blackScreen
    loadingBkg
    letterboxUp
    letterboxDown
  ] : null
}

let animations = [
  { prop=AnimProp.translate, from=[sw(10),0], to=[0,0], duration=0.2, play=true, easing=InCubic},
  { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InCubic},
  { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InCubic},
  { prop=AnimProp.translate, from=[0,0], to=[-sw(10),0], duration=0.3, playFadeOut=true, easing=OutCubic}
]

let activeTipHdr = tipCmp({
  fontFxColor = Color(0,0,0,190)
  fontFxFactor = 64
  fontFx = FFT_SHADOW
  fontFxOffsX = 2
  fontFxOffsY = 2
  text = loc("loading/controlsHelpTip")
  inputId = "HUD.Briefing"
  style = { rendObj = null, color = tipHeaderColor }
}.__update(fontHeading2))


let tipText = @() {
  watch = curHint
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  text = loc(curHint.get())
  size = FLEX_H
  orientation = O_VERTICAL
  transform = true
  speed = [hdpx(10),hdpx(200)]
  delay = 3
}.__update(fontBody)

let activeTipText = {
  size = const [min(sw(80), sh(100)), SIZE_TO_CONTENT]
  clipChildren = true
  children = tipText
  valign = ALIGN_CENTER
}

let tips = @() {
  size = const [sw(75), SIZE_TO_CONTENT]
  transform = {pivot = [0.5, 0.5]}
  watch = curHint
  vplace = ALIGN_CENTER
  children = [
    {
      size = FLEX_H
      key = curHint.get()
      transform = {pivot = [0.5, 0.5]}
      animations = animations
      flow = FLOW_VERTICAL
      children = activeTipText
    }
    tipsHotkeys
  ]
}


let bottomBlock = @(){
  padding = [safeAreaVerPadding.get() + fsh(1), safeAreaHorPadding.get() + sw(4)]
  watch = [safeAreaVerPadding, safeAreaHorPadding]
  rendObj = ROBJ_SOLID
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  size = FLEX_H
  minHeight = max(fsh(18), safeAreaVerPadding.get() + fsh(18))
  color = darkBgColor
  children = [
    {
      size = FLEX
      children = [
        activeTipHdr
        tips
      ]
    }
    animatedLoading
  ]
}

let titleStyle = {
  fontFxColor = Color(0,0,0,190)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_SHADOW
  fontFxOffsX = min(2,hdpx(2))
  fontFxOffsY = min(2, hdpx(2))
}

let missionTitle = @(){
  watch = missionParams
  rendObj = ROBJ_TEXT
  text = missionParams.get().name
  color
}.__update(fontHeading1, titleStyle)

function campaignTitle() {
  let campaignName = missionParams.get().campaign
  if (!campaignName)
    return { watch = missionParams }

  return {
    watch = missionParams
    rendObj = ROBJ_TEXT
    text = campaignName
    color
  }.__update(fontBody, titleStyle)
}

let missionBlock = {
  flow = FLOW_VERTICAL
  margin = [safeAreaVerPadding.get() + sh(5), safeAreaHorPadding.get() + sw(7)]
  children = [
    missionTitle
    campaignTitle
  ]
}

let screen = {
  size = FLEX
  children = [
    decoratedImage
    missionBlock
    bottomBlock
  ]
}

return screen
