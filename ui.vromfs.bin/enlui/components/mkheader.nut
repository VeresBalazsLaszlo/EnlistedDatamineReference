from "%ui/mainMenu/mainmenu.style.nut" import navHeight
from "%ui/style/designConst.nut" import midPadding
from "%ui/components/defcomps.nut" import sceneHeaderText
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/ui_library.nut" import *

let mkHeader = @(textLocId, closeButton = null, armyId = null, addToRight = null, addAfterText = null) {
  size = [FLEX, navHeight]
  flow = FLOW_HORIZONTAL
  gap = fsh(1)
  valign = ALIGN_CENTER
  margin = [0, 0, midPadding]
  children = [
    armyId ? mkArmyIcon(armyId, hdpx(46)) : null
    textLocId.len() > 0 ? sceneHeaderText(loc(textLocId)) : null
    addAfterText
    { size = FLEX }
    addToRight
    closeButton
  ]
}

return kwarg(mkHeader)
