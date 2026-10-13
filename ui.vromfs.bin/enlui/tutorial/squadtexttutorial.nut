import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/faComp.nut" as faComp
from "%ui/components/mkDotPaginator.nut" import mkDotPaginator
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "%ui/components/controlHudHint.nut" import controlHudHint, mkHasBinding
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/textButton.nut" import Regular
from "%ui/style/designConst.nut" import defTxtColor, maxContentWidth, midPadding, defInsideBgColor, titleTxtColor, disabledTxtColor, isWide
from "%ui/tutorial/squadTextTutorialPresentation.nut" import getTutorial
from "%ui/ui_library.nut" import *

const WND_UID = "SQUAD_TEXT_TUTORIAL"

let curPage = Watched(0)
const internalContentWidth = hdpx(1200)

const smallPadding = hdpx(30)
const largePadding = hdpx(60)
let imageSize = isWide ? [hdpx(1200), hdpx(505)] : [hdpx(1000), hdpx(421)]


let tutorialImage = @(image) image == null ? null :{
  rendObj = ROBJ_IMAGE
  size = imageSize
  hplace = ALIGN_CENTER
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FIT
}

function close(){
  removeModalWindow(WND_UID)
  curPage.set(0)
}

let closeButton = closeBtnBase({
  onClick = close
  hplace = ALIGN_RIGHT
})

let topBlock = @(squadType){
  rendObj = ROBJ_SOLID
  color = defInsideBgColor
  size = const [internalContentWidth, SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  padding = midPadding * 2
  children = {
    rendObj = ROBJ_TEXT
    text = loc($"{squadType}_available_header")
  }.__update(fontHeading2)
}

let tutorialPaginator = mkDotPaginator("squad_tutorial", curPage)

let centralBlock = @(neededTutorial, totalPagesCount) function() {
  let value = neededTutorial[curPage.get()]
  let watches = [curPage]
  let hotkeysArr = value?.hotkey ?? []
  foreach (key in hotkeysArr)
    watches.append(mkHasBinding(key))

  return {
    size = const [internalContentWidth, FLEX]
    watch = watches
    children = {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_CENTER
      children = [
        tutorialImage(value?.image)
        tutorialPaginator(totalPagesCount)
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_TOP
          gap = hdpx(10)
          size = const [pw(75), SIZE_TO_CONTENT]
          children = [
            hotkeysArr.len() <= 0 ? null : {
              flow = FLOW_HORIZONTAL
              children = hotkeysArr.filter(@(_, idx) watches[idx].get()).map(@(v)
                controlHudHint({
                  id = v ?? ""
                  text_params = {
                    fontSize = fontBody.fontSize
                  }
                })
              )
            }
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              size = FLEX_H
              text = loc(value?.text ?? "")
              color = defTxtColor
            }.__update(fontBody)
          ]
        }
      ]
    }
  }
}

let okBtn = Regular(loc("Close"), close, {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    hotkeys = [[$"^{JB.B}"]]
})

function prevPageArrow() {
  let onClick = @() curPage.get() > 0
    ? curPage.modify(@(v) v - 1)
    : null
  return watchElemState(@(sf){
    behavior = Behaviors.Button
    watch = curPage
    hplace = ALIGN_LEFT
    vplace = ALIGN_CENTER
    onClick
    hotkeys = [["^J:LB", {description = loc("tutorial/previousPage"), action = onClick} ]]
    children = faComp("chevron-left", {
      fontSize = hdpx(50)
      color = curPage.get() <= 0 ? disabledTxtColor
        : sf & S_ACTIVE ? defTxtColor
        : sf & S_HOVER ? titleTxtColor
        : defTxtColor
    })
  })
}

function nextPageArrow(totalPagesCount) {
  let onClick = @() curPage.get() < totalPagesCount - 1
    ? curPage.modify(@(v) v + 1)
    : null
  return watchElemState(@(sf){
    behavior = Behaviors.Button
    watch = curPage
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    onClick
    hotkeys = [["^J:RB", {description = loc("tutorial/nextPage"), action = onClick}]]
    children = faComp("chevron-right", {
      fontSize = hdpx(50)
      color = curPage.get() >= totalPagesCount - 1 ? disabledTxtColor
        : sf & S_ACTIVE ? defTxtColor
        : sf & S_HOVER ? titleTxtColor
        : defTxtColor
    })
  })
}

function squadTextTutorial(squadType){
  let neededTutorial = getTutorial(squadType)
  let totalPagesCount = neededTutorial.len()
  return {
    size = const [sw(95), hdpx(900)]
    maxWidth = maxContentWidth
    rendObj = ROBJ_IMAGE
    halign = ALIGN_CENTER
    image = Picture("ui/squads_tutorial_background.avif")
    keepAspect = KEEP_ASPECT_FILL
    padding = const [smallPadding, largePadding]
    clipChildren = true
    children = [
      closeButton
      {
        size = FLEX
        flow = FLOW_VERTICAL
        gap = smallPadding
        halign = ALIGN_CENTER
        children = [
          topBlock(squadType)
          centralBlock(neededTutorial, totalPagesCount)
        ]
      }
      okBtn
      prevPageArrow()
      nextPageArrow(totalPagesCount)
    ]
  }
}

let openSquadTextTutorial = @(squadType) addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = squadTextTutorial(squadType)
  onClick = @() null
})

return openSquadTextTutorial