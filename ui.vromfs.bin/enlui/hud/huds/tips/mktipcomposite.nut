import "%ui/components/fontawesome.map.nut" as fa
from "%ui/style/fontsStyle.nut" import fontBody, fontawesome
from "%ui/hud/style.nut" import HUD_TIPS_FG
from "%ui/ui_library.nut" import *


const START_TOKEN = "{"
const END_TOKEN = "}"
const defIconSize = [hdpxi(26), hdpxi(26)]

const hintTags = {
  fa = fontawesome
}

let mkIcon = @(icon) function(style = null) {
  let { color = HUD_TIPS_FG, iconSize = defIconSize } = style
  return {
    rendObj = ROBJ_IMAGE
    size = iconSize
    image = Picture(icon.subst(iconSize[0], iconSize[1]))
    color
  }
}

let mkTextIcon = @(faChar) faChar in fa ? $"<fa>{fa[faChar]}</fa>" : null

let predefinedComps = {
  scythe = mkIcon("ui/skin#events/statistics_halloween_icon.svg:{0}:{1}") 
  soul = mkIcon("ui/skin#events/sinful_soul_icon.svg:{0}:{1}") 
}

function mkTipComposite(srcText, style = null) {
  let mkTextFragment = @(text) {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
    color = HUD_TIPS_FG
    tagsTable = hintTags
  }.__update(fontBody, style ?? {})

  let srcLen = srcText.len()
  let children = []
  local curText = "", srcIndex = 0
  while (srcIndex < srcLen) {
    let startIndex = srcText.indexof(START_TOKEN, srcIndex) ?? srcLen
    curText = $"{curText}{srcText.slice(srcIndex, startIndex)}"
    srcIndex = startIndex + START_TOKEN.len()
    if (srcIndex >= srcLen)
      break

    let endIndex = srcText.indexof(END_TOKEN, srcIndex) ?? srcLen
    let compId = srcText.slice(srcIndex, endIndex)
    let faText = mkTextIcon(compId)
    if (faText != null) {
      curText = $"{curText}{faText}"
    } else if (compId in predefinedComps) {
      if (curText != "") {
        children.append(mkTextFragment(curText))
        curText = ""
      }
      children.append(predefinedComps[compId](style))
    } else {
      curText = $"{curText}{START_TOKEN}{compId}{END_TOKEN}"
    }
    srcIndex = endIndex + END_TOKEN.len()
  }
  if (curText != "")
    children.append(mkTextFragment(curText))
  return children
}

return mkTipComposite
