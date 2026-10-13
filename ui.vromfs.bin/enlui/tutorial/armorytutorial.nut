import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import midPadding, activeTxtColor, smallPadding, accentTitleTxtColor
from "%ui/components/defcomps.nut" import noteTextArea, txt
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/components/msgbox.nut" import showMsgboxWithCloseButton
from "%ui/ui_library.nut" import *

const localGap = hdpx(20)
let iconParams = @(itemType){
  itemType
  size = hdpx(27)
}

function soldierIconWithType(soldierIcon, soldierName) {
  let { itemType, itemSubType = null } = iconParams(soldierIcon)
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    minWidth = hdpx(150)
    children = [
      itemTypeIcon(itemType, itemSubType)
      txt(soldierName).__update(fontBody, { color = accentTitleTxtColor })
    ]
  }
}

function weaponIconWithType(weapons){
  if (weapons.len() == 0)
    return null

  let children = weapons.map(function(weapon) {
    let { itemType, itemSubType = null } = iconParams(weapon.keys()[0])
    return {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        itemTypeIcon(itemType, itemSubType)
        txt(weapon.values()[0]).__update(fontBody)
      ]
    }
  })

  return {
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    gap = midPadding
    minWidth = hdpx(200)
    children
  }
}

function mkSoldierInfoRow(soldierIcon, soldierName, soldiersWeapons){
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = localGap
    children = [
      soldierIconWithType(soldierIcon, soldierName)
      faComp("arrow-right", {fontSize = hdpx(17)})
      weaponIconWithType(soldiersWeapons)
    ]
  }
}

let textAreaParams = {
  halign = ALIGN_CENTER
  color = activeTxtColor
}.__update(fontBody)

let windowDescription = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    noteTextArea(loc("armory_tutorial/soldierWeapons")).__update(textAreaParams)
    mkSoldierInfoRow("boltaction_noscope",loc("soldierClass/rifle"),[
      { boltaction_noscope = loc("itemtype/boltaction_noscope") },
      { semiauto = loc("itemtype/semiauto") }
    ])
    mkSoldierInfoRow("submgun",loc("soldierClass/assault"),[{ submgun = loc("itemtype/submgun") }])
    noteTextArea(loc("armory_tutorial/unavailableSoldierWeapons")).__update(textAreaParams)
  ]
}

let armoryTutorial = {
  text = loc("armory_tutorial/armoryWnd")
  txtColor = accentTitleTxtColor
    children = {
      size = const [fsh(90), SIZE_TO_CONTENT]
      margin = const [localGap, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      gap = localGap
      children = windowDescription
    }
}

function openArmoryTutorial() {
  showMsgboxWithCloseButton(armoryTutorial)
}

return openArmoryTutorial