import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/faComp.nut" as faComp
import "%ui/components/modalPopupWnd.nut" as modalPopupWnd
from "%ui/style/designConst.nut" import panelBgColor, hoverPanelBgColor, selectedPanelBgColor,
  defTxtColor, titleTxtColor, squadSlotBgHoverColor, squadSlotBgIdleColor, defBgColor,
  commonBtnHeight, soldierWndWidth, midPadding, smallPadding, listCtors
from "%ui/components/textButton.nut" import Regular
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/sounds.nut" import stateChangeSounds
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/ui_library.nut" import *


const WND_UID = "outfits_list"
const OUTFIT_ORDER = [
  "moscow", "berlin", "stalingrad", "pacific", "normandy", "tunisia", "ardennes", "manchuria"
]

let defTxtStyle = { color = defTxtColor }.__update(fontBody)
let selectedTxtStyle = { color = titleTxtColor }.__update(fontBody)
let popupWidth = soldierWndWidth - 2 * midPadding
let defStyle = {
  btnWidth = FLEX
  btnHeight = commonBtnHeight
  popupWidth
  label = "appearance/mode"
}

let slotBGColor = @(sf, isSelected = false) sf & S_HOVER ? hoverPanelBgColor
  : isSelected ? selectedPanelBgColor
  : panelBgColor

let outfitTextStyle = @(sf, isSelected = false) sf & S_HOVER ? selectedTxtStyle
  : isSelected ? selectedTxtStyle
  : defTxtStyle

let squadButtonBGColor = @(sf) sf & S_HOVER ? squadSlotBgHoverColor
  : squadSlotBgIdleColor

let squadButtonTitleTextColor = listCtors.nameColor
let squadButtonOutfitNameColor = listCtors.weaponColor

let mkName = @(name) loc($"outfit/{name}")

let close = @() modalPopupWnd.remove(WND_UID)

let open = @(popupParams, availableCampaignsTbl, selectedWatch, onSelect, style = defStyle)
  modalPopupWnd.add(popupParams.startPoint, {
    uid = WND_UID
    popupHalign = ALIGN_LEFT
    popupValign = ALIGN_TOP
    popupFlow = popupParams.popupFlow
    moveDuration = min(0.12 + 0.03 * availableCampaignsTbl.len(), 0.3)
    padding = 0
    fillColor = defBgColor
    children = @() {
      size = [style?.popupWidth ?? FLEX, SIZE_TO_CONTENT]
      rendObj = ROBJ_BOX
      fillColor = defBgColor
      flow = FLOW_VERTICAL
      children = OUTFIT_ORDER
        .filter(@(val) val in availableCampaignsTbl)
        .map(function(campaignId) {
          let isSelected = Computed(@() campaignId == selectedWatch.get())
          return watchElemState(@(sf) {
            watch = isSelected
            behavior = Behaviors.Button
            rendObj = ROBJ_BOX
            size = [FLEX, style?.btnHeight ?? commonBtnHeight]
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            sound = stateChangeSounds
            fillColor = slotBGColor(sf, isSelected.get())
            onClick = function() {
              if (isSelected.get()) {
                close()
                return
              }

              onSelect(campaignId)
              close()
            }
            children = {
              rendObj = ROBJ_TEXT
              text = mkName(availableCampaignsTbl[campaignId])
            }.__update(outfitTextStyle(sf, isSelected.get()))
          })
        })
    }
    hotkeys = [[$"^{JB.B} | Esc", { action = close }]]
  })

let label = @(locId) locId == null ? null : {
  rendObj = ROBJ_TEXT
  size = FLEX_H
  text = loc(locId)
  color = titleTxtColor
}.__update(fontSub)

function mkOutfitsListButton(listWatch, canOpenCb, selectedWatch, onSelect, style = defStyle) {

  let namesList = listWatch.get()
  if (namesList.len() <= 1)
    return null

  return @() {
    watch = [listWatch, selectedWatch]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      label(style?.label)
      Regular(
        mkName(namesList[selectedWatch.get()])
        function(event) {
          if (canOpenCb != null) {
            let recEvent = event
            let self = callee()
            if (!canOpenCb?(@() self(recEvent)))
              return
          }

          open({
              startPoint = [event.targetRect.l, event.targetRect.b]
              popupFlow = FLOW_VERTICAL
            },
            namesList, selectedWatch, onSelect, style)
        },
        style
      )
    ]
  }
}

function mkSquadListOutfitButton(listWatch, squadCampaignWatch, setValueFn) {
  let text = "".concat(utf8ToUpper(loc("outfits/campaign")), loc("ui/colon"))
  let group = ElemGroup()

  return watchElemState(function(sf) {
    let namesList = listWatch.get()
    if ((namesList?.len() ?? 0) <= 1)
      return { watch = listWatch }

    let onClick = @(event) open({
      startPoint = [event.targetRect.r + smallPadding, event.targetRect.t]
      popupFlow = FLOW_HORIZONTAL
    },
    namesList,
    squadCampaignWatch,
    setValueFn)

    let campaignText = mkName(namesList?[squadCampaignWatch.get()])
    return {
      watch = [squadCampaignWatch, listWatch]
      size = FLEX_H
      rendObj = ROBJ_WORLD_BLUR_PANEL
      behavior = Behaviors.Button
      flow = FLOW_HORIZONTAL
      fillColor = squadButtonBGColor(sf)
      group
      onClick
      children = [
        {
          flow = FLOW_VERTICAL
          size = FLEX_H
          valign = ALIGN_CENTER
          margin = smallPadding
          children = [
            {
              rendObj = ROBJ_TEXT
              text
              color = squadButtonTitleTextColor(sf, false)
              hplace = ALIGN_LEFT
            }.__update(fontSub)
            {
              rendObj = ROBJ_TEXT
              size = FLEX_H
              text = campaignText
              color = squadButtonOutfitNameColor(sf, false)
              hplace = ALIGN_LEFT
              behavior = [Behaviors.Marquee, Behaviors.Button]
              scrollOnHover = true
              group
              onClick
            }.__update(fontSub)
          ]
        }
        {
          size = const [hdpxi(36), FLEX]
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = faComp("angle-right", {
            fontSize = hdpxi(36)
            color = squadButtonTitleTextColor(sf, false)
          })
        }
      ]
    }
  })
}

return {
  mkOutfitsListButton
  mkSquadListOutfitButton
}