import "%ui/mainMenu/bottomRightButtons.nut" as bottomBar
from "%ui/style/fontsStyle.nut" import fontTitle, fontHeading1
from "%ui/style/designConst.nut" import midPadding, titleTxtColor, defTxtColor, activeTxtColor, smallPadding, maxContentWidth, blurBgFillColor, isWide
from "%ui/gameModes/eventModeStyle.nut" import localGap
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle
from "%ui/ui_library.nut" import *

const wndHeaderHeight = hdpx(150)
const armyIconSize = hdpx(26)

let teamsColors = [
  {
    defBgColor = 0xAA9D2618
    hoverBgColor = 0xAA641C14
  },
  {
    defBgColor = 0xAA285d93
    hoverBgColor = 0xAA193C60
  }
]

function txtColor(sf){
  return sf & S_ACTIVE ? activeTxtColor
    : sf & S_HOVER ? titleTxtColor
    : defTxtColor
}

let windowTitle = @(title){
  vplace = ALIGN_CENTER
  children = mkHeaderFlag(
    {
      padding = [localGap, midPadding * 3]
      rendObj = ROBJ_TEXT
      text = title
    }.__update(isWide ? fontTitle : fontHeading1),
    casualFlagStyle.__merge({ offset = hdpx(15) })
  )
}

let headerImg = @(image) {
    size = const [FLEX, wndHeaderHeight]
    rendObj = ROBJ_IMAGE
    image = Picture(image)
    fallbackImage = Picture("ui/tunisia_city_inv_02.avif")
    keepAspect = KEEP_ASPECT_FILL
  }

let mkWindowHeader = @(title, image, addChild = null){
  size = FLEX_H
  children = [
    headerImg(image)
    windowTitle(title)
    addChild
  ]
}

function sequentialArmySelect(armies, armyId, deltaIdx, onArmySelect) {
  let currentArmieIdx = armies.findindex(@(val) val == armyId)
  if (currentArmieIdx != null){
    let newIdx = currentArmieIdx + deltaIdx
    if (newIdx >= 0 && newIdx < armies.len())
      onArmySelect(armies[newIdx])
  }
}

function armyButton(armyId, onArmySelect, isSelected) {
  let stateFlag = Watched(0)
  return @(){
    rendObj = ROBJ_BOX
    watch = stateFlag
    size = SIZE_TO_CONTENT
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlag.set(sf)
    borderWidth = (isSelected || (stateFlag.get() & S_HOVER)) ? const [0, 0, hdpx(4), 0] : 0
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        size = SIZE_TO_CONTENT
        vplace = ALIGN_BOTTOM
        children = [
          mkArmyIcon(armyId, armyIconSize)
        ]
      }
    ]
  }.__update(isSelected ? const {} : {
      behavior = Behaviors.Button
      onClick =  @() onArmySelect(armyId)
      sound = const {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
    }
  )
}

let selectArmyBlock = @(armiesList, curArmyId, onArmySelect) function(){
  let children = armiesList.map(@(armyId)
    armyButton(armyId, onArmySelect, armyId == curArmyId))
  return {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_CENTER
    gap = smallPadding
    hotkeys = [
      ["^J:LT",
        { action = @() sequentialArmySelect(armiesList, curArmyId, -1, onArmySelect),
          description = loc("army/previous")
        }],
      ["^J:RT",
        { action = @() sequentialArmySelect(armiesList, curArmyId, 1, onArmySelect),
          description = loc("army/next")
        }]
    ]
    children = children.len() > 1 ? children : null
  }
}


let footer = freeze({
  size = FLEX_H
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  children = bottomBar
})

let mkPanel = @(ovr) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = blurBgFillColor
  padding = localGap
}.__update(ovr)

return freeze({
  mkWindowHeader
  txtColor
  wndHeaderHeight
  selectArmyBlock
  footer
  mkPanel
  teamsColors
  armyIconSize
})