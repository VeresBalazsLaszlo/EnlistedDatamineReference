import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/faComp.nut" as faComp
import "%ui/components/fontIconButton.nut" as fontIconButton
import "%ui/tutorial/squadTextTutorial.nut" as openSquadTextTutorial
import "%ui/components/armiesPresentation.nut" as armiesPresentation
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/squadsUiComps.nut" import mkCardText, squadBgColor, mkSquadIcon,
  mkSquadTypeIcon, mkSquadPremIcon, txtColor, mkRentInfo
from "%ui/style/designConst.nut" import midPadding, smallPadding, squadSlotHorSize,
  attentionTxtColor, listCtors, defTxtColor, selectedTxtColor, activeBgColor
from "%ui/components/itemsInfo.nut" import itemNameFromItem
from "%ui/soldiers/model/chooseSquadsState.nut" import selectedSquadId, reserveSquads,
  chosenSquads, canTakeSquad, squadsArmyLimits, maxSquadsInBattle, squadsArmy
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/control/active_controls.nut" import isGamepad
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/soldiers/armySquadTier.nut" import getSquadBR
from "%ui/ui_library.nut" import *

let { nameColor, txtDisabledColor } = listCtors


let squadIconSize = [hdpxi(60), hdpxi(60)]
const squadTypeIconSize = hdpxi(20)
const dragIconWidth = hdpxi(25)

let curDropData = Watched(null)
let curDropTgtIdx = Watched(-1)
curDropData.subscribe(@(_) curDropTgtIdx.set(-1))


let premSlotIcon = Computed(@() armiesPresentation?[squadsArmy.get()].premSlotIcon)

let highlightSlots = Computed(function() {
  let allSlots = chosenSquads.get()
  let total = allSlots.len()
  local reserveIdx = curDropData.get()?.squadIdx
  if (reserveIdx != null)
    reserveIdx -= total
  else {
    let selSquadId = selectedSquadId.get()
    reserveIdx = reserveSquads.get().findindex(@(s) s.squadId == selSquadId)
  }

  let squad = reserveSquads.get()?[reserveIdx]
  let maxSlots = maxSquadsInBattle.get()
  let armyLimits = squadsArmyLimits.get()
  let armySquadsCfg = squadsCfgById.get()
  return squad == null ? []
    : allSlots.map(@(_, idx)
        canTakeSquad(squad, allSlots, idx, maxSlots, armyLimits, armySquadsCfg))
})

let getMoveDirSameList = @(idx, dropIdx, targetIdx)
  dropIdx < idx && targetIdx >= idx ? -1
    : dropIdx > idx && targetIdx <= idx ? 1
    : 0

let mkMoveDirComputed = @(idx, fixedSlots) Computed(function() {
  let dropIdx = curDropData.get()?.squadIdx ?? -1
  let targetIdx = curDropTgtIdx.get()
  if (targetIdx < 0 || dropIdx < 0)
    return 0
  if (idx < fixedSlots)
    return dropIdx < fixedSlots && targetIdx < fixedSlots
      ? getMoveDirSameList(idx, dropIdx, targetIdx)
      : 0
  return dropIdx >= fixedSlots && targetIdx >= fixedSlots
    ? getMoveDirSameList(idx, dropIdx, targetIdx)
    : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx
      ? 1
      : 0
})

function squadDragAnim(moveDir, idx, stateFlags, content, chContent, needMoveCursor = false) {
  function onAttach(elem) {
    if (isGamepad.get() && needMoveCursor)
      move_mouse_cursor(elem, false)
  }

  function onElemState(sf) {
    stateFlags.set(sf)
    if (!curDropData.get() || curDropData.get().squadIdx == idx)
      return
    if (sf & S_ACTIVE)
      curDropTgtIdx.set(idx)
    else if (curDropTgtIdx.get() == idx)
      curDropTgtIdx.set(-1)
  }

  return content.__merge({
    behavior = Behaviors.DragAndDrop
    onAttach
    xmbNode = XmbNode()
    canDrop = @(data) data?.dragid == "squad"
    dropData = "dropData" in content ? content.dropData : { squadIdx = idx, dragid = "squad" }
    onDragMode = function(on, data){
      if (on)
        sound_play("ui/inventory_item_take")
      curDropData.set(on ? data : null)
    }
    onElemState
    transform = true
    children = curDropData.get() ? chContent.__merge({
      transform = true
      transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
      behavior = Behaviors.RtPropUpdate
      rtAlwaysUpdate = true
      update = @() {
        transform = { translate = [0, moveDir.get() * (squadSlotHorSize[1] + midPadding)] }
      }
    }) : chContent
  })
}

let highlightBorder = {
  size = FLEX
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(1)
  color = activeBgColor
}

let getIconColor = @(sf, isSlotHovered) sf & S_ACTIVE ? selectedTxtColor
  : sf & S_HOVER ? Color(70,70,70)
  : isSlotHovered ? selectedTxtColor
  : defTxtColor

function mkSlotActionBtn(icon, cb, override, isSlotHovered) {
  if (cb == null)
    return null

  return fontIconButton(icon, {
    onClick = cb
    margin = 0
    iconParams = { size = const [dragIconWidth, dragIconWidth], halign = ALIGN_CENTER }
    fontSize = dragIconWidth
    iconColor = @(sf) getIconColor(sf, isSlotHovered)
  }.__update(override))
}

let dragIcon = @(sf) {
  rendObj = ROBJ_IMAGE
  size = const [dragIconWidth, dragIconWidth]
  margin = [0, midPadding, 0, 0]
  keepAspect = KEEP_ASPECT_FIT
  image = Picture("ui/skin#icons/drag_squads.svg:{0}:{0}".subst(dragIconWidth))
  color = txtColor(sf)
}

function mkRentComp(expireTime, override = {}) {
  let rentTimer = Computed(@() (max(expireTime - serverTime.get(), 0)))
  return @() {
    watch = rentTimer
    children = mkRentInfo(rentTimer.get(), loc("rented"), override)
  }.__update(override)
}


function mkHorizontalSlot(squadData) {
  let { guid, squadId, idx, onClick, manageLocId,
    isSelected = Watched(false), onInfoCb = null, onDropCb = null, group = null, addChildren = null,
    icon = "", squadType = "", level = 0, vehicle = null, squadSize = null, battleExpBonus = 0,
    isOwn = true, fixedSlots = -1, override = {}, premIcon = null, isLocked = false, unlockObj = null,
    needMoveCursor = false, firstSlotToAnim = null, secondSlotToAnim = null,
    needSquadTutorial = false, expireTime = 0, size = null, onSellCb = null,
    onFavoriteCb = null, isFavorite = Watched(false) } = squadData
  local { stateFlags = null } = squadData
  let stateFlagsUnfiltered = stateFlags ?? Watched(0)
  stateFlags = Computed(@() stateFlagsUnfiltered.get() & ~S_TOP_HOVER)

  let onDrop = @(data) onDropCb?(data?.squadIdx, idx)

  let isDropTarget = Computed(@() idx < fixedSlots
    && curDropTgtIdx.get() == idx
    && (curDropData.get()?.squadIdx ?? -1) >= fixedSlots)

  let needHighlight = Computed(@() highlightSlots.get()?[idx] ?? false)

  let animations = [
    { prop=AnimProp.translate, from=[0, squadSlotHorSize[1]], to=[0, 0],
      duration=0.2, trigger = $"squadMoveTop{idx}",  easing=OutCubic }
    { prop=AnimProp.translate, from=[0, -squadSlotHorSize[1]], to=[0, 0],
      duration=0.2, trigger = $"squadMoveBottom{idx}", easing=OutCubic }
  ]

  function onAttach() {
    if (firstSlotToAnim != null || secondSlotToAnim != null) {
      anim_start($"squadMoveTop{min(firstSlotToAnim, secondSlotToAnim)}")
      anim_start($"squadMoveBottom{max(firstSlotToAnim, secondSlotToAnim)}")
    }
  }

  let squadIcon = mkSquadIcon(icon, {
    size = squadIconSize
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
  })
  let squadPremIcon = mkSquadPremIcon(premIcon)
  let watch = [isSelected, stateFlags, isFavorite,
    isDropTarget, needHighlight, isGamepad, curDropData]
  let opacity = isOwn ? 1.0 : 0.5

  local bonusText = ""
  let { isEvent = false, isPremium = false } = squadData
  if (battleExpBonus > 0) {
    let expBonus = (100 * battleExpBonus).tointeger()
    bonusText = $"{loc("XP")}{loc("ui/colon")}+{expBonus}%"
  }
  else if (isEvent || isPremium)
    bonusText = loc("levelInfo", { level = loc("squad/allResearchesCompleted") })
  else
    bonusText = loc("levelInfo", { level = level + 1 })

  let mainText = $"{bonusText}, {loc("squad/contain")}{squadSize ?? size}"
  let vehicleText = vehicle ? $"{loc("menu/vehicle")} {itemNameFromItem(vehicle)}" : ""
  let manageText = loc(manageLocId)
  let moveDir = onDropCb != null ? mkMoveDirComputed(idx, fixedSlots) : null
  let rentInfo = expireTime > 0 ? mkRentComp(expireTime) : null

  return function() {
    let sf = stateFlags.get()
    let selected = isSelected.get() || isDropTarget.get()
    let bgColor = squadBgColor(sf, selected, isLocked)
    let keySuffix = curDropData.get() == null ? "" : "draging"
    let key = $"slot{guid}{idx}{keySuffix}"
    let isBtnColorHovered = (sf & S_HOVER) || selected

    let chContent = {
      key
      size = FLEX
      opacity
      transform = true
      onAttach
      animations
      children = [
        {
          rendObj = ROBJ_SOLID
          flow = FLOW_HORIZONTAL
          size = FLEX
          valign = ALIGN_CENTER
          gap = midPadding
          color = bgColor
          children = [
            {
              size = ph(100)
              children = [
                squadIcon
                squadPremIcon
              ]
            }
            {
              size = FLEX
              flow = FLOW_VERTICAL
              valign = ALIGN_CENTER
              gap = smallPadding
              clipChildren = true
              children = [
                {
                  size = FLEX_H
                  behavior = Behaviors.Marquee
                  scrollOnHover = true
                  children = mkCardText(manageText, sf)
                }
                {
                  size = FLEX_H
                  behavior = Behaviors.Marquee
                  orientation = O_HORIZONTAL
                  delay = 1
                  children = {
                    flow = FLOW_HORIZONTAL
                    valign = ALIGN_BOTTOM
                    children = [
                      mkSquadTypeIcon(squadType, sf, selected, squadTypeIconSize)
                      {
                        flow = FLOW_HORIZONTAL
                        valign = ALIGN_CENTER
                        gap = midPadding
                        children = [
                          {
                            flow = FLOW_HORIZONTAL
                            valign = ALIGN_CENTER
                            children = [
                              mkCardText(mainText, sf)
                              faComp("user-o", {
                                fontSize = hdpx(12)
                                color = txtColor(sf & S_HOVER, selected)
                              })
                            ]
                          }
                          mkBattleRatingShort(getSquadBR(squadId)).__update({ color = txtColor(sf) })
                          vehicle == null ? null : mkCardText(vehicleText, sf)
                        ]
                      }
                    ]
                  }
                }
              ]
            }
            rentInfo
            unlockObj
            mkSlotActionBtn("trash", onSellCb, override, isBtnColorHovered)
            needSquadTutorial
              ? mkSlotActionBtn("book",
                  @() openSquadTextTutorial(squadType), override, isBtnColorHovered)
              : null
            isGamepad.get() ? null : mkSlotActionBtn("info", onInfoCb, override, isBtnColorHovered)
            mkSlotActionBtn(isFavorite.get() ? "bookmark" : "bookmark-o",
              onFavoriteCb, override, isBtnColorHovered)
            !isLocked ? dragIcon(sf) : null
          ]
        }
        needHighlight.get() ? highlightBorder : null
      ]
    }

    if (addChildren)
      chContent.children.extend(addChildren)

    return onDropCb != null
      ? squadDragAnim(moveDir, idx, stateFlagsUnfiltered,
          {
            watch
            group
            size = squadSlotHorSize
            key = $"{guid}{idx}"
            onDrop
            onClick
          }.__update(override),
          chContent, needMoveCursor)
      : {
          watch
          group
          size = squadSlotHorSize
          onClick
          behavior = Behaviors.Button
          xmbNode = XmbNode()
          onElemState = @(s) stateFlagsUnfiltered.set(s)
          transform = true
          children = chContent
        }
  }
}


let horSlotText = @(hasBlink, isDropTarget, text, style = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  key = $"hasBlink{hasBlink}"
  text
  color = hasBlink
    ? nameColor(0, isDropTarget)
    : txtDisabledColor(0, isDropTarget)
  animations = hasBlink
    ? [{
        prop = AnimProp.opacity, from = 0.4, to = 0.6,
        duration = 1, play = true, loop = true, easing = Blink
      }]
    : null
}.__merge(fontSub, style)

let mkAngleLeft = @(color) faComp("angle-left", {
  hplace = ALIGN_RIGHT
  padding = const [0, hdpx(15)], fontSize = hdpx(30)
  color
})

let mkEmptyHorizontalSlot = kwarg(function(
  idx, onDropCb, onClick = null, fixedSlots = -1, group = null, hasBlink = false, isPrem = false
) {
    let stateFlags = Watched(0)
    let isDropTarget = Computed(@() idx < fixedSlots
      && curDropTgtIdx.get() == idx
      && (curDropData.get()?.squadIdx ?? -1) >= fixedSlots)
    let needHighlight = Computed(@() highlightSlots.get()?[idx] ?? false)
    let onDrop = @(data) onDropCb(data?.squadIdx, idx)
    let moveDir = mkMoveDirComputed(idx, fixedSlots)
    let color = isPrem ? attentionTxtColor : defTxtColor

    let slotText = isPrem
      ? loc("squads/squadFreePremSlot")
      : loc("squads/squadFreeSlot")

    return function() {
      let textObj = horSlotText(hasBlink, isDropTarget.get(), slotText, {
        size = const [FLEX, SIZE_TO_CONTENT]
        hplace = ALIGN_LEFT
        color
      })

      let chContent = {
        rendObj = ROBJ_SOLID
        key = $"empty_slot{idx}" 
        size = FLEX
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform = true
        color = squadBgColor(stateFlags.get(), isDropTarget.get())
        children = [
          {
            size = FLEX_H
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            padding = const [0, 0, 0, hdpx(30)]
            gap = smallPadding
            children = isPrem
              ? [ textObj, mkAngleLeft(color) ]
              : [
                  textObj
                  {
                    size = FLEX_H
                    flow = FLOW_HORIZONTAL
                    hplace = ALIGN_RIGHT
                    halign = ALIGN_RIGHT
                    valign = ALIGN_CENTER
                    children = [
                      horSlotText(hasBlink, isDropTarget.get(), loc("squads/dragFromReserve"),
                        { color, halign = ALIGN_RIGHT })
                      mkAngleLeft(color)
                    ]
                  }
              ]
          }
          !isPrem ? null
            : @() {
                watch = premSlotIcon
                hplace = ALIGN_LEFT
                vplace = ALIGN_TOP
                children = mkSquadPremIcon(premSlotIcon.get())
              }
          needHighlight.get() ? highlightBorder : null
        ]
      }
      return squadDragAnim(moveDir, idx, stateFlags,
        {
          watch = [stateFlags, isDropTarget, needHighlight]
          size = squadSlotHorSize
          key = $"empty_{idx}"
          onDrop
          onClick
          dropData = null
          fixedSlots
          group
        },
        chContent)
    }
  })

return {
  mkHorizontalSlot
  mkEmptyHorizontalSlot
  curDropData
  mkRentComp
}
