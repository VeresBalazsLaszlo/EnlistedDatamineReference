from "%ui/components/textarea.nut" import smallTextarea as textarea
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading1, fontHeading2
from "%ui/style/designConst.nut" import strokeStyle, midPadding
from "%ui/ui_library.nut" import *

const winColor = Color(255,200,50,200)
const loseColor = Color(200,40,20,200)
const neutralColor = Color(150,180,250,150)

let textFx = { halign = ALIGN_CENTER }.__update(fontHeading1, strokeStyle)


let animations = [
  { prop=AnimProp.opacity, from=0, to=1 duration=0.5, play=true, easing=InOutCubic}
  { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.3, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0 duration=0.5, playFadeOut=true, easing=InOutCubic}
  { prop=AnimProp.scale, from=[1,1], to=[2,2], duration=0.3, playFadeOut=true, easing=InOutCubic}
]


let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = neutralColor
  text
}.__update(fontBody, override)


function mkShortDebriefing(debriefing) {
  let { success = false, fail = false, title = "", who = "", popupInfo = [] } = debriefing?.result

  let titleObj = textarea(" ".concat(title, who), textFx.__merge({
    size = const [sh(100), SIZE_TO_CONTENT]
    color = success ? winColor
      : fail ? loseColor
      : neutralColor
  }))

  return {
    key = "debriefingRootShort"
    size = const [sw(100), sh(80)]
    flow = FLOW_VERTICAL
    gap = sh(4)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      titleObj
      popupInfo.len() == 0 ? null
        : {
            size = FLEX_H
            flow = FLOW_VERTICAL
            gap = midPadding
            halign = ALIGN_CENTER
            children = popupInfo.map(@(pData) {
              flow = FLOW_HORIZONTAL
              gap = midPadding
              valign = ALIGN_CENTER
              children = [
                mkText(pData.statTxt)
                mkText(pData.statVal, fontHeading2)
              ]
            })
          }
    ]
    transform = {pivot = [0.5, 0.25]}
    animations = animations
    sound = {
      attach = success ? "ui/victory" : "ui/fail"
      detach = "ui/menu_highlight"
    }
  }
}



let mkDebriefing = @(dataWatched) function() {
  let children = mkShortDebriefing(dataWatched.get())
  return {
    watch = dataWatched
    children
  }
}

return mkDebriefing
