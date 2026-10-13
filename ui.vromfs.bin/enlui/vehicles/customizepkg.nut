import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/colorize.nut" as colorize
import "%ui/components/faComp.nut" as faComp
import "%ui/currency/premiumWnd.nut" as premiumWnd
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/helpers/icon3dByGameTemplate.nut" as iconByGameTemplate
import "%ui/vehicles/customizePresentation.nut" as customizePresentation
from "%enlSqGlob/vehDecorUtils.nut" import getVehSkinById, skinDataForIcon
from "string" import endswith
from "%ui/style/cursors.nut" import setTooltip, withTooltip
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/defcomps.nut" import txt
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/components/textButton.nut" import FARegular
from "%ui/style/designConst.nut" import defBgColor, activeBgColor, defTxtColor,
  accentTitleTxtColor, activeTxtColor, smallPadding, midPadding, titleTxtColor,
  tinyOffset, bonusColor, warningColor, vehicleListCardSize
from "%ui/components/textButton.style.nut" import BdActive, BdHover, BdNormal, BgHover, BgNormal, TextHover, TextNormal
from "%ui/vehicles/vehDecorState.nut" import getCurSkinFromTemplate
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/control/active_controls.nut" import isGamepad
from "vehicle_decals" import decal_preprocess_tex_name
from "%ui/components/slider.nut" import Horiz
from "%ui/items/itemsPresentation.nut" import rewardsPresentation
from "%ui/battlepass/bpState.nut" import seasonIndex
from "%ui/battlepass/battlePassPkg.nut" import staticSeasonBPIcon
from "%ui/ui_library.nut" import *

const SKIN_ICON_SIZE = hdpx(40)
const TXT_ICON_SIZE = hdpx(36)
const TXT_SMALL_SIZE = hdpx(16)


let slotSize = const [hdpx(100), hdpx(100)]
let slotBigSize = const [hdpx(180), hdpx(180)]
let skinSize = const [FLEX, hdpx(50)]
let arrowIconSize = const [hdpx(30), hdpx(30)]

const slotNormalColor = Color(40,40,40,160)
const slotActiveColor = Color(45,40,35,160)
const borderNormalColor = Color(80,80,80,200)
const borderHoverColor = Color(120,120,120,200)
const borderActiveColor = Color(180,180,180,200)
const slotTxtNormalColor = Color(95,95,95,200)
const slotTxtHoverColor = borderActiveColor

const DISABLED_ITEM = { tint = Color(40, 40, 40, 160), picSaturate = 0.0 }

let slotColor = @(sf, isSelected = false) isSelected ? slotActiveColor
  : sf & S_HOVER ? slotActiveColor
  : slotNormalColor

let slotBorderColor = @(sf, isSelected = false) isSelected ? borderActiveColor
  : sf & S_HOVER ? borderHoverColor
  : borderNormalColor

let slotTxtColor = @(sf, isSelected = false) isSelected ? slotTxtHoverColor
  : sf & S_HOVER ? slotTxtHoverColor
  : slotTxtNormalColor

let btnBorderColor = @(sf) sf & S_ACTIVE ? BdActive
  : sf & S_HOVER ? BdHover
  : BdNormal

let btnFillColor = @(sf) sf & S_ACTIVE ? BgNormal
  : sf & S_HOVER ? BgHover
  : BgNormal

let btnTxtColor = @(sf) sf & S_ACTIVE ? accentTitleTxtColor
  : sf & S_HOVER ? TextHover
  : TextNormal

let txtColor = @(sf, isSelected = false) isSelected ? titleTxtColor
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

let decorNamesByType = {
  vehCamouflage = @(id) loc($"skin/{id}")
  vehDecal = @(id) loc($"decals/{id}")
  vehDecorator = @(id) loc($"decorators/{id}")
}

let getDecorName = @(d) decorNamesByType?[d.cType]?(d.id)

let cropSkinName = @(skinName)
  skinName == null || !endswith(skinName, "*")
    ? skinName
    : skinName.slice(0, skinName.len() - 1)

let mkTextarea = @(text, override = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text
}.__update(override)

let mkSkinImage = @(img, sf, isSelected) {
  rendObj = ROBJ_VECTOR_CANVAS
  size = const [SKIN_ICON_SIZE, SKIN_ICON_SIZE]
  fillColor = 0
  commands = [
    [ VECTOR_WIDTH, hdpx(2) ],
    [ VECTOR_ELLIPSE, 50, 50, 52, 52 ]
  ]
  color = slotBorderColor(sf, isSelected)
  children = {
    rendObj = ROBJ_MASK
    size = FLEX
    image = Picture("ui/uiskin/skin_mask.avif")
    children = {
      rendObj = ROBJ_IMAGE
      size = FLEX
      image = Picture(img)
    }
  }
}

let defDecorSize = hdpx(95)

function mkDecorImage(cfg, override = {}) {
  let { iconSize = defDecorSize } = override
  let decorImg = iconByGameTemplate(cfg.id, {
    width = iconSize
    height = iconSize
  })
  return decorImg == null ? decorImg : decorImg.__update(override)
}

let mkDecalImage = @(cfg, override = {}) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  margin = midPadding
  keepAspect = KEEP_ASPECT_FIT
  image = Picture(customizePresentation?[cfg.id] ?? $"!{decal_preprocess_tex_name(cfg.id)}*")
}.__update(override)

function mkCamouflageImage(cfg, override = {}) {
  let { subType, id } = cfg
  let texName = getVehSkinById(subType, id)?.objTexReplace.values()[0] ?? ""

  return {
    rendObj = ROBJ_IMAGE
    size = FLEX
    margin = midPadding
    keepAspect = KEEP_ASPECT_FIT
    image = Picture(customizePresentation?[cropSkinName(texName)] ?? texName)
  }.__update(override)
}

let animFrame = {
  rendObj = ROBJ_BOX
  size = FLEX
  borderWidth = hdpx(2)
  borderColor = activeBgColor
  animations = [{
    prop = AnimProp.opacity, from = 0, to = 1, easing = CosineFull,
    duration = 1, play = true, loop = true
  }]
}

let mkBlockHeader = @(text) {
  rendObj = ROBJ_TEXT
  color = activeTxtColor
  padding = [0, smallPadding]
  text
}.__update(fontSub)

let mkCurrencyView = @(currencies, currencyId, price) mkCurrency({
  currency = currencies.findvalue(@(c) c.id == currencyId)
  price
  iconSize = hdpxi(20)
})

let mkLockedIcon = @(sf, isSelected, fontSize = TXT_SMALL_SIZE)
  faComp("lock", { fontSize, color = slotTxtColor(sf, isSelected) })

let mkApplyIcon = @(sf, isSelected)
  faComp("plus", {
    fontSize = hdpx(TXT_ICON_SIZE)
    color = slotTxtColor(sf, isSelected)
  })

let mkSlotBox = @(sf, isSelected = false) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  size = FLEX
  borderColor = slotBorderColor(sf, isSelected)
  fillColor = slotColor(sf, isSelected)
}

let showNeedPremiumBox = @() showMsgbox({
  text = loc("reqPremiumToUseDecorSlot")
  buttons = [
    { text = loc("Close"), customStyle = { hotkeys = [[$"^{JB.B}" ]] } }
    { text = loc("btn/buy"), action = premiumWnd, customStyle = { hotkeys = [["^J:Y"]] } }
  ]
})

let mkLockedSlotPrice = @(sf, hasPrice, currencies, currencyId, price) {
  rendObj = ROBJ_SOLID
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = { size = FLEX }
  margin  = hdpx(2)
  padding = smallPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  color = defBgColor
  children = [
    mkLockedIcon(sf, false, TXT_SMALL_SIZE)
    hasPrice ? mkCurrencyView(currencies, currencyId, price) : null
  ]
}

function mkDecorSlot(decorator, isSelected, hasLocked, onClick,
  onRemove = null, buyData = null, currencies = null, decorSlotSize = slotSize
) {
  let { cType = "" } = decorator
  let iconCtor = cType == "vehDecorator" ? mkDecorImage : mkDecalImage
  let { price = 0, currencyId = "" } = buyData
  let hasPrice = currencies != null && price > 0 && currencyId != ""
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = decorSlotSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = hasLocked ? showNeedPremiumBox : onClick
    children = [
      mkSlotBox(sf, isSelected)
      hasLocked && decorator == null ? mkLockedIcon(sf, isSelected, hdpx(TXT_ICON_SIZE))
        : hasLocked && decorator != null ? iconCtor(decorator, {
            key = $"decal_{decorator.id}"
            picSaturate = 0.0
            opacity = 0.3
          })
        : decorator == null ? mkApplyIcon(sf, isSelected)
        : iconCtor(decorator)
      hasPrice ? mkLockedSlotPrice(sf, hasPrice, currencies, currencyId, price) : null
      isSelected ? animFrame : null
      onRemove == null ? null
        : {
            size = FLEX
            children = FARegular("times", onRemove, {
              stopMouse = true
              padding = smallPadding
            })
          }
    ]
  })
}

let mkTooltip = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = defTxtColor
  maxWidth = sw(25)
}.__update(fontSub)

function mkSkinIcon(skinData, isSelected, hasOwned, currencies, onClick) {
  let { buyData = null, locId = null, id = null } = skinData
  let { price = 0, currencyId = "" } = buyData
  let { bpSeason = null } = rewardsPresentation?[id]
  let currencyObject = !hasOwned && price > 0 && currencyId != ""
    ? mkCurrencyView(currencies, currencyId, price)
    : bpSeason != null ? staticSeasonBPIcon(bpSeason, hdpxi(30))
    : null

  let texName = skinData?.objTexReplace.findvalue(@(_) true)
  let name = cropSkinName(texName)
  let skinImg = customizePresentation?[name] ?? texName

  let group = ElemGroup()
  let content = watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = skinSize
    behavior = Behaviors.Button
    group
    onClick
    children = [
      mkSlotBox(sf, isSelected)
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = midPadding
        padding = [0, midPadding]
        valign = ALIGN_CENTER
        children = [
          skinImg != null ? mkSkinImage(skinImg, sf, isSelected) : null
          hasOwned ? null : mkLockedIcon(sf, isSelected, TXT_SMALL_SIZE)
          {
            rendObj = ROBJ_TEXT
            size = FLEX_H
            group
            text = loc(locId ?? "skin/{0}".subst(name ?? "baseSkinName"))
            color = txtColor(sf, isSelected)
            scrollOnHover = true
            behavior = Behaviors.Marquee
          }.__update(fontSub)
          currencyObject
        ]
      }
    ]
  })

  if (bpSeason == null || hasOwned)
    return content

  let textId = bpSeason == seasonIndex.get() ? "camouflage/source/bp" : "camouflage/source/bp_past"
  return withTooltip(content, @() tooltipCtor(mkTooltip(loc(textId))))
}

function mkCustGroup(groupName, hasOpened, onClick, availCount, limit, count) {
  local limitTxtObj = null
  if (limit > 0) {
    let limitColor = count < limit ? bonusColor : warningColor
    limitTxtObj = mkTextarea(colorize(limitColor, $"{count}/{limit}"), {
      size = FLEX_H
      halign = ALIGN_RIGHT
      margin = [0, smallPadding]
    })
  }
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = FLEX_H
    behavior = Behaviors.Button
    onClick
    children = [
      mkSlotBox(sf, hasOpened)
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        padding = [smallPadding, 0]
        valign = ALIGN_CENTER
        children = [
          {
            size = arrowIconSize
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = faComp(hasOpened ? "angle-down" : "angle-right", { fontSize = hdpx(20) })
          }
          {
            rendObj = ROBJ_TEXT
            text = loc($"decals/category/{groupName}")
            color = txtColor(sf, hasOpened)
          }.__update(fontSub)
          availCount <= 0 ? null
            : {
                rendObj = ROBJ_TEXT
                text = loc("shop/item/count", { count = availCount, itemName = "" })
                color = accentTitleTxtColor
                margin = [0, smallPadding]
              }.__update(fontSub)
          limitTxtObj
        ]
      }
    ]
  })
}

let iconSize = hdpxi(36)
let btnSize = [hdpx(64), hdpx(64)]

let flipActionIcon = $"ui/skin#actions/flip_action_icon.svg:{iconSize}:{iconSize}"
let closeActionIcon = $"ui/skin#actions/close_action_icon.svg:{iconSize}:{iconSize}"
let twoSideIcons = [
  $"ui/skin#actions/single_icon.svg:{iconSize}:{iconSize}",
  $"ui/skin#actions/two_side.svg:{iconSize}:{iconSize}",
  $"ui/skin#actions/two_side_mirror.svg:{iconSize}:{iconSize}"
]

let selectedLine = {
  rendObj = ROBJ_SOLID
  size = [FLEX, smallPadding]
  pos = [0, 2 * smallPadding]
  margin = const [0, hdpx(1)]
  vplace = ALIGN_BOTTOM
  color = BgHover
}

let mkBtnImage = @(img, override = {}) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = Picture(img)
}.__update(override)

let mkButton = kwarg(@(
  icon, onClick, gpadHotkey, hotkey, hasHotkeyHint = false,
  descLocId = "", override = {}
)
  watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    size = btnSize
    padding = tinyOffset
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    borderColor = btnBorderColor(sf)
    fillColor = btnFillColor(sf)
    onClick
    onHover = descLocId == "" ? null
      : @(on) setTooltip(on ? tooltipCtor(txt(loc(descLocId))) : null)
    hotkeys = [[ $"^{gpadHotkey} | {hotkey}", onClick, loc(descLocId) ]]
    children = [
      mkBtnImage(icon, { color = btnTxtColor(sf) })
      !hasHotkeyHint ? null
        : @() {
            watch = isGamepad
            pos = const [0, -hdpx(50)]
            children = isGamepad.get()
              ? mkImageCompByDargKey(gpadHotkey)
              : {
                  rendObj = ROBJ_TEXT
                  text = hotkey
                  color = accentTitleTxtColor
                }.__update(fontBody)
          }
    ]
  }.__update(override))
)

let mkFlipBtn = @(checkWatch)
  mkButton({
    icon = flipActionIcon
    onClick = @() checkWatch.set(!checkWatch.get())
    descLocId = "hintDecalFlip"
    hasHotkeyHint = true
    hotkey = "F"
    gpadHotkey = "J:Y"
  })

let mkSelectBox = @(sideParams, twoSideIdx, hotkeys, gpadHotkey)
  function() {
    let sideIdx = twoSideIdx.get()
    return {
      watch = [twoSideIdx, isGamepad]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = sideParams.map(@(p, idx) watchElemState(function(sf) {
            let hotkey = hotkeys?[idx]
            return {
              rendObj = ROBJ_BOX
              borderWidth = hdpx(1)
              size = btnSize
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              behavior = Behaviors.Button
              onClick = @() twoSideIdx.set(idx)
              onHover = @(on) setTooltip(on ? tooltipCtor(txt(loc($"hint{p}"))) : null)
              hotkeys = hotkey == null ? null : [[ $"^{hotkey}", @() twoSideIdx.set(idx) ]]
              borderColor = btnBorderColor(sf)
              fillColor = btnFillColor(sf)
              children = [
                mkBtnImage(twoSideIcons?[idx], {
                  color = btnTxtColor(sf)
                  margin = tinyOffset
                })
                idx == sideIdx ? selectedLine : null
                hotkey == null || isGamepad.get() ? null
                  : {
                      rendObj = ROBJ_TEXT
                      text = hotkey
                      color = accentTitleTxtColor
                      pos = const [0, -hdpx(50)]
                    }.__update(fontBody)
              ]
            }
          }))
        }
        gpadHotkey == null || !isGamepad.get() ? null
          : {
              pos = const [0, -hdpx(50)]
              children = mkImageCompByDargKey(gpadHotkey)
              hotkeys = [[ $"^{gpadHotkey}",
                @() twoSideIdx.set((twoSideIdx.get() + 1) % sideParams.len()),
                loc("switchDecalSideParam") ]]
            }
      ]
    }
  }

let mkDecorHints = @(children) {
  size = [hdpx(400), btnSize[1]]
  flow = FLOW_VERTICAL
  padding = [smallPadding, midPadding]
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = defBgColor
  children
}

let decorRotationHint = @() {
  watch = isGamepad
  size = FLEX_H
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    {
      size = const [pw(55), SIZE_TO_CONTENT]
      halign = isGamepad.get() ? ALIGN_CENTER : ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = isGamepad.get()
        ? [
            mkImageCompByDargKey("J:LT")
            mkImageCompByDargKey("J:RT")
          ]
        : mkTextarea(loc("vehDecorRotationHintLeft"))
    }
    mkTextarea(loc("vehDecorRotationHintRight"), { color = accentTitleTxtColor })
  ]
}

let decorScaleHint = @() {
  watch = isGamepad
  size = FLEX_H
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    {
      size = const [pw(55), SIZE_TO_CONTENT]
      halign = isGamepad.get() ? ALIGN_CENTER : ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = isGamepad.get()
        ? [
            mkImageCompByDargKey("J:LB")
            mkImageCompByDargKey("J:RB")
          ]
        : mkTextarea(loc("vehDecorScaleHintLeft"))
    }
    mkTextarea(loc("vehDecorScaleHintRight"), { color = accentTitleTxtColor })
  ]
}

let decorConfig = {
  vehDecorator = { iconCtor = mkDecorImage, locTypeId = "decorators" }
  vehDecal = { iconCtor = mkDecalImage, locTypeId = "decals" }
}

let getDecorConfig = @(cType) decorConfig?[cType]

let mkDecorIcon = kwarg(function(cfg,
  availableCount = 0, currencies = null, onClick = null, override = {}
) {
  let params = {
    iconSize = override?.size[0] ?? defDecorSize
  }
  let { cType = null, buyData = null } = cfg
  let { price = 0, currencyId = "" } = buyData
  let hasPrice = availableCount == 0 && currencies != null
    && price > 0 && currencyId != ""
  let countObject = availableCount == 0 ? null
    : {
        rendObj = ROBJ_TEXT
        text = availableCount
        padding = smallPadding
        hplace = ALIGN_RIGHT
        vplace = ALIGN_TOP
        color = accentTitleTxtColor
      }.__update(fontSub)
  let { locTypeId = null } = getDecorConfig(cType)
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = slotSize
    valign = ALIGN_BOTTOM
    behavior = onClick != null ? Behaviors.Button : null
    onClick
    onHover = @(on) setTooltip(on
      ? tooltipCtor(txt(loc($"{locTypeId}/{cfg?.id}")))
      : null)
    children = [
      mkSlotBox(sf)
      cType == "vehDecorator"
        ? mkDecorImage(cfg, params)
        : mkDecalImage(cfg, params)
      countObject ?? mkLockedSlotPrice(sf, hasPrice, currencies, currencyId, price)
    ]
  }.__update(override))
})


let mkSkinSlider = kwarg(function(sliderWatch, locId, minVal, maxVal, setValue, step) {
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      {
        size = const [FLEX, hdpxi(15)]
        valign = ALIGN_CENTER
        children = @() {
          watch = sliderWatch
          children = mkBlockHeader(loc(locId, { value = sliderWatch.get() }))
        }
      }
      {
        size = const [FLEX, hdpxi(30)]
        children = Horiz(sliderWatch, { min = minVal, max = maxVal, step, setValue })
      }
    ]
  }
})

function mkVehicleImage(config, vehicle, squadCampaign) {
  let { gametemplate = "", isShopItem = false } = vehicle
  if (gametemplate == "")
    return null

  let override = {
    width = vehicleListCardSize[0] - smallPadding * 2
    height = vehicleListCardSize[1] - smallPadding * 2
    genOverride = {}
  }

  let skinData = getCurSkinFromTemplate(config, vehicle, squadCampaign)
  if (skinData != null)
    override.genOverride <- skinDataForIcon(skinData)

  return iconByGameTemplate(gametemplate, override)?.__update(isShopItem ? DISABLED_ITEM : {})
}

return freeze({
  getDecorName
  cropSkinName
  getDecorConfig
  mkDecorSlot
  mkDecorIcon
  mkSkinIcon
  mkBlockHeader
  mkCustGroup
  mkFlipBtn
  mkButton
  mkSelectBox
  slotSize
  slotBigSize
  closeActionIcon
  mkDecorHints
  decorScaleHint
  decorRotationHint
  slotNormalColor
  mkDecalImage
  mkDecorImage
  mkCamouflageImage
  mkSkinSlider
  mkVehicleImage
})
