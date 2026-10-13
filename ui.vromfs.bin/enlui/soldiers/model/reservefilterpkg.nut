import "%ui/components/faComp.nut" as faComp
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/modalPopupWnd.nut" as modalPopupWnd
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding,
  darkTxtColor, defTxtColor, inactiveFilterTxtColor, hoverSlotBgColor, defSlotBgColor,
  fullTransparentBgColor
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/defcomps.nut" import txt
from "%ui/components/textButton.nut" import Regular
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/soldiers/armySquadTier.nut" import getSoldierBRImpl
from "%ui/components/soldiersUiComps.nut" import kindIcon, classIcon, mkMedalIcon
from "%ui/components/soldierClasses.nut" import soldierKindsList, soldierClasses, getKindCfg, getClassCfg
from "%ui/soldiers/model/readySoldiers.nut" import NOT_FIT_CUR_SQUAD
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/ui_library.nut" import *

const menuItemHeight = hdpxi(36)
const faStyle = { fontSize = hdpxi(20), padding = [smallPadding, bigPadding] }

const divider = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, hdpx(1)]
  color = hoverSlotBgColor
}

let innerBtnStyle = {
  hoverPanelBgColor = fullTransparentBgColor
  defBgColor = fullTransparentBgColor
  defBdColor = fullTransparentBgColor
}

let inlineBtnStyle = {
  btnWidth = menuItemHeight
  btnHeight = menuItemHeight
}

let inlineStyle = @(color, isSelected) innerBtnStyle
  .__merge(isSelected
    ? { defTxtColor = color, defBdColor = color }
    : {})

let faIconCtor = @(icon) @(color) faComp(icon, { color }.__update(faStyle))

const filterIconSize = hdpxi(22)
let mkKindIcon = @(sKind, color) {
  padding = bigPadding
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = kindIcon(sKind, filterIconSize, color)
}

let iconLabelCtor = @(iconCtor)
  function(_textField, params, handler, group, sf) {
    let { textParams = {} } = params
    return textButtonTextCtor({
      size = const [menuItemHeight, menuItemHeight]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = iconCtor?(sf & S_HOVER ? darkTxtColor : defTxtColor)
      margin = textParams?.margin
    }, params, handler, group, sf)
  }


let levelButtons = [1, 2, 3, 4, 5]
let levelHintCtor = @(label, level) txt("{0}: {1}".subst(label, getRomanNumeral(level)))
let levelBtn = {
  isTotalGroup = true
  inlineBtns = levelButtons
  inlineNameCtor = getRomanNumeral
  hintLabelCtor = levelHintCtor
}

let medalIcon = @(_) function() {
  let { country = "" } = allArmiesInfo.get()?[curArmy.get()]
  return {
    watch = [allArmiesInfo, curArmy]
    padding = bigPadding
    children = mkMedalIcon(country, filterIconSize)
  }
}

let config = [
  {
    id = "all"
    icon = faIconCtor("filter")
    isTotalGroup = true
    filterFn = @(...) true
  }
  {}
  {
    id = "fit"
    icon = faIconCtor("asterisk")
    filterFn = @(soldier, params, _)
      !((params.soldiersStatuses?[soldier.guid] ?? NOT_FIT_CUR_SQUAD) & NOT_FIT_CUR_SQUAD)
  }
  {
    id = "br"
    text = loc("battleRating")
    icon = @(color) {
      padding = bigPadding
      rendObj = ROBJ_TEXT
      text = loc("battleRating/abbrev")
      color
    }.__update(fontBody)
    filterFn = @(soldier, params, val)
      getSoldierBRImpl(soldier.guid, params.itemTypesInSlots, params.campItems) == val
  }.__update(levelBtn)
  {
    id = "tier"
    icon = faIconCtor("star")
    filterFn = @(soldier, _, val) soldier.tier == val
  }.__update(levelBtn)
  {
    id = "maxLevel"
    icon = faIconCtor("star-o")
    filterFn = @(soldier, params, val)
      val == max(soldier.tier, 1 + (params.maxTrainByClass?[soldier.sClass] ?? 0))
  }.__update(levelBtn)
  {
    id = "hero"
    icon = medalIcon
    filterFn = @(soldier, _, _) soldier.isHero
  }
  {
    id = "callname"
    icon = @(color) {
      rendObj = ROBJ_IMAGE
      margin = bigPadding
      size = const [filterIconSize, filterIconSize]
      color
      image = Picture("ui/skin#callsign_icon.svg:{0}:{0}".subst(filterIconSize))
    }
    filterFn = @(soldier, _, _) soldier.callname != ""
  }
  {}
]

const classIconSize = hdpxi(30)
let mkClassBtnCtor = @(sClass) iconLabelCtor(@(_)
  @() {
    watch = curArmy
    children = classIcon(curArmy.get(), sClass, classIconSize)
  })

let kindFilterCtor = @(sKind) function(soldier, _, args) {
  let { sClass, kind } = getClassCfg(soldier.sClass)
  return kind == sKind && (args == "" || args == sClass)
}

let filterValues = {}

foreach (classConfig in soldierClasses) {
  let { sClass, kind, rank, isEvent = false, isPremium = false } = classConfig
  if (isEvent || isPremium)
    continue

  if (kind not in filterValues)
    filterValues[kind] <- {}

  if (sClass not in filterValues[kind])
    filterValues[kind][sClass] <- rank
}

let kindHintCtor = @(_, sClass) txt(loc(getClassCfg(sClass).locId))
function mkKindButtons(kind) {
  if (kind not in filterValues)
    return {}

  let rankToClass = array(filterValues[kind].len() + 1)
  foreach (sClass, rank in filterValues[kind])
    rankToClass[rank] = sClass

  return {
    inlineBtns = rankToClass.filter(@(v) v != null)
    inlineNameCtor = mkClassBtnCtor
    hintLabelCtor = kindHintCtor
  }
}

let kindItems = []
foreach (kind in soldierKindsList) {
  let sKind = kind
  kindItems.append({
    id = kind
    text = loc(getKindCfg(kind).locId)
    icon = @(color) mkKindIcon(sKind, color)
    filterFn = kindFilterCtor(kind)
  }.__update(mkKindButtons(kind)))
}

kindItems.sort(@(a, b) a.text <=> b.text)
config.extend(kindItems)

let counterTxt = @(count, color) {
  padding = smallPadding
  rendObj = ROBJ_TEXT
  text = "({0})".subst(count)
  color
}.__update(fontSub)

let labelTxt = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontSub)

let checkCtor = faIconCtor("check")

function mkBtn(watch, counters, btn) {
  let {
    id = null
    icon = null
    isTotalGroup = false
    text = null
    inlineBtns = []
    inlineNameCtor = null
    hintLabelCtor = null
  } = btn

  if (id == null)
    return divider

  let btnText = text ?? loc($"soldiers/filter/{id}")
  let ownCounters = Computed(@() counters.get()?[id] ?? {})

  return watchElemState(function(sf) {
    let isActive = watch.get()?.id == id
    let fillColor = isActive || (sf & S_HOVER) ? hoverSlotBgColor : defSlotBgColor

    let selectedArgs = watch.get()?.args
    let activeSubfilter = !isActive ? "" : inlineBtns.findvalue(@(args) args == selectedArgs) ?? ""

    let countersVal = ownCounters.get()
    let count = isTotalGroup && activeSubfilter == ""
      ? countersVal.reduce(@(res, v) res + v.count, 0)
      : countersVal?[activeSubfilter].count ?? 0

    let color = count == 0 ? inactiveFilterTxtColor
      : isActive || (sf & S_HOVER) ? darkTxtColor
      : defTxtColor

    local defaultArgs = ""
    let buttons = inlineBtns.map(function(args) {
      let splitCount = countersVal?[args].count ?? 0
      if (0 == splitCount)
        return null

      if (isTotalGroup && defaultArgs == "") defaultArgs = args

      return Regular(inlineNameCtor?(args),
        @() watch.set({ args, id, icon }),
        {
          style = inlineStyle(color, isActive && selectedArgs == args)
          hint = @() {
            flow = FLOW_VERTICAL
            children = [
              hintLabelCtor?(btnText, args)
              txt(loc("soldiers/filter/count", { count = splitCount }))
            ]
          }
        }.__update(inlineBtnStyle))
    })

    return {
      watch = [watch, ownCounters]
      rendObj = ROBJ_SOLID
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      color = fillColor
      children = [
        {
          behavior = Behaviors.Button
          onClick = @() watch.set({ id, icon, args = defaultArgs })
          flow = FLOW_HORIZONTAL
          size = const [FLEX, menuItemHeight]
          valign = ALIGN_CENTER
          children = [
            icon?(color)
            labelTxt(btnText, color)
            counterTxt(count, color)
            isActive ? checkCtor(color) : null
            { size = FLEX_H }
          ]
        }
      ].extend(buttons)
    }
  })
}

const offset = [hdpxi(20), -hdpxi(5)]
const WND_UID = "reserveFilter"

function open(event, curFilter, counters) {
  modalPopupWnd.add([event.targetRect.r + offset[0], event.targetRect.t + offset[1]], {
    uid = WND_UID
    popupHalign = ALIGN_LEFT
    popupValign = ALIGN_TOP
    popupFlow = FLOW_VERTICAL
    popupBg = { rendObj = null }
    padding = 0
    valign = ALIGN_TOP
    children = {
      flow = FLOW_VERTICAL
      size = const [hdpxi(450), SIZE_TO_CONTENT]
      children = config.map(@(btn) mkBtn(curFilter, counters, btn))
    }
    hotkeys = [[$"^{JB.B} | Esc | J:RS", { action = @() modalPopupWnd.remove(WND_UID) }]]
  })
}

let mkOpenFilterBtn = @(curFilter, counters) function() {
  let { icon = faIconCtor("filter") } = curFilter.get()
  let cb = @(event) open(event, curFilter, counters)

  let margin = isGamepad.get() ? [ bigPadding, bigPadding * 2] : [0, midPadding]

  let btn = Regular(iconLabelCtor(icon), cb, {
    textParams = { margin, fontStyle = fontSub }
    hotkeys = [["^J:RS"]]
  })

  return {
    watch = [curFilter, isGamepad]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = btn
  }
}

return {
  mkOpenFilterBtn
  filterConfig = config
}
