import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/colorize.nut" as colorize
import "%ui/components/checkbox.nut" as checkbox
import "%ui/components/spinner.nut" as spinner
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/vehDecorUtils.nut" import getBaseVehicleSkin, decalToString, skinDetailsToParams,
  skinDetailsToViewParams, getVehSkinById, getVehSkins,
  VEH_AGE_MIN, VEH_SCALE_MIN, VEH_ROTATION_MIN, VEH_AGE_MAX, VEH_SCALE_MAX, VEH_ROTATION_MAX
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/defcomps.nut" import txt, noteTextArea
from "vehicle_decals" import SaveVehicleDecals
from "%sqstd/math.nut" import ceil, PI
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/vehicles/vehiclesListState.nut" import selectVehParams, viewVehicle, isCustomizeWndOpen, closeCustomizeWnd, vehicleClear
from "%ui/currency/premium.nut" import hasPremium
from "%ui/components/textButton.nut" import Regular
from "%ui/currency/currencies.nut" import currenciesList
from "%ui/currency/currenciesComp.nut" import currencyBtn
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/vehicles/customizePkg.nut" import mkDecorSlot, mkDecorIcon, mkBlockHeader, mkCustGroup, slotSize, mkSkinIcon, mkFlipBtn
  , mkSelectBox, mkButton, closeActionIcon, mkDecorHints, decorScaleHint, decorRotationHint, slotNormalColor
  , slotBigSize, mkDecalImage, mkDecorImage, cropSkinName, mkSkinSlider, getDecorName
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/components/mkCampaignSelector.nut" import mkOutfitsListButton
from "%ui/soldiers/model/state.nut" import curSquad, armySquadsById
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/soldiers/model/config/outfitConfig.nut" import getSquadCamo
from "%ui/vehicles/vehDecorState.nut" import getCamoList, vehCamouflageCfg, unsuitableSkinsById
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN, camoCampaignsByArmies
from "%ui/vehicles/customizeState.nut" import customizationParams, lastOpenedGroupName,
  getDecorBelongText, curDecorCfgByType, viewVehCustSchemes, customizationSort, buyApplyDecorators,
  selectedCamouflage, applyDecorator, applyCamouflage, availVehDecorByTypeId, showUniqueDetails,
  uniqueDetailsAvailable, curCamouflageId, viewVehCamouflage, curOwnCamoList, selectedCampaign,
  selectedDecorator, startUsingDecor, stopUsingDecal, vehDecorLimits, mirrorDecal, twoSideDecal,
  viewVehDecorByType, viewVehCustLimits, closeDecoratorsList, isPurchasing, notPurchased,
  skinParamsToDetails, ageSlider, scaleSlider, rotationSlider, hasCampaigns, vehCamouflageObj,
  applySkinData
from "%ui/style/designConst.nut" import midPadding, tinyOffset, smallOffset, smallPadding, accentTitleTxtColor, defTxtColor, defBgColor, panelBgColor
from "%ui/vehicles/decorViewer.nut" import onDecalMouseMove, onDecalMouseWheel, applyUsingDecal, applyUsingDecor, setSkinScale, setSkinCondition, setSkinRotation
from "%ui/vehicles/dmViewer.nut" import closeDmViewerMode
from "dasevents" import SaveVehicleDecor
from "%ui/helpers/metalink.nut" import getFirstLinkByType, getLinkedArmyName
from "%ui/soldiers/model/squadInfoState.nut" import isSquadRented
from "%ui/meta/servProfile.nut" import squads
from "%ui/soldiers/components/squadsComps.nut" import showRentedSquadLimitsBox
from "%ui/featureFlags.nut" import hasSkinCustomizer
from "%ui/showState.nut" import changeCameraFov
from "%ui/battlepass/bpWindowState.nut" import openBPwindow
from "%ui/battlepass/bpState.nut" import combinedUnlocks, seasonIndex
from "%ui/items/itemsPresentation.nut" import rewardsPresentation
from "%ui/ui_library.nut" import *

let popupsState = require("%ui/popup/popupsState.nut")
const CAMO_TYPE = "vehCamouflage"
const ADD_CAMERA_FOV_MIN = -25
const ADD_CAMERA_FOV_MAX = 45

enum SIDE_PARAMS {
  ONE_SIDE = "DecalSingleSide"
  TWO_SIDE = "DecalTwoSided"
  TWO_SIDE_MIRRORED = "DecalTwoSidedMirr"
}

let sideParams = [
  SIDE_PARAMS.ONE_SIDE,
  SIDE_PARAMS.TWO_SIDE,
  SIDE_PARAMS.TWO_SIDE_MIRRORED
]

let isMirrorMode = mkWatched(persist, "isMirrorMode", false)
let twoSideIdx = mkWatched(persist, "twoSideIdx", 0)

const SLOTS_IN_ROW = 4

let iconSpaceWidth = SLOTS_IN_ROW * slotSize[0] + (SLOTS_IN_ROW - 1) * midPadding
let waitingSpinner = spinner()

local hasCamoChanges = false







function setValue(watch, val) {
  watch.set(val)
  hasCamoChanges = true
}

function applyCampaignToCamo(enableCampaigns, campaign) {
  let { guid = null } = viewVehicle.get()
  if (guid != null)
    applySkinData(curCamouflageId.get(), guid, enableCampaigns, campaign)
  hasCamoChanges = false
}

function setHasCampaigns(val) {
  applyCampaignToCamo(!val, 
    val ? COMMON_CAMPAIGN : selectedCampaign.get())

  hasCampaigns.set(val) 
}

function setCurCampaign(val) {
  if (hasCamoChanges)
    applyCampaignToCamo(false, selectedCampaign.get())

  selectedCampaign.set(val)
}

function applyCamoOnClose() {
  if (!hasCamoChanges)
    return

  applyCampaignToCamo(!hasCampaigns.get(),
    hasCampaigns.get() ? selectedCampaign.get() : COMMON_CAMPAIGN)
}

function mkCamouflageCustomizer() {
  return {
    size = [iconSpaceWidth - midPadding - slotBigSize[0], slotBigSize[1]]
    flow = FLOW_VERTICAL
    gap = 2 * smallPadding
    padding = [0, midPadding]
    valign = ALIGN_CENTER
    children = [
      mkSkinSlider({
        locId = "camouflage/condition"
        sliderWatch = ageSlider
        minVal = VEH_AGE_MIN
        maxVal = VEH_AGE_MAX
        step = 1
        setValue = function(v) {
          setSkinCondition(v / 100.0)
          setValue(ageSlider, v.tointeger())
        }
      })
      mkSkinSlider({
        locId = "camouflage/scale"
        sliderWatch = scaleSlider
        minVal = VEH_SCALE_MIN
        maxVal = VEH_SCALE_MAX
        step = 4
        setValue = function(v) {
          setSkinScale(v / 100.0)
          setValue(scaleSlider, v.tointeger())
        }
      })
      mkSkinSlider({
        locId = "camouflage/rotation"
        sliderWatch = rotationSlider
        minVal = VEH_ROTATION_MIN
        maxVal = VEH_ROTATION_MAX
        step = 2
        setValue = function(v) {
          let valToSave = v.tointeger()
          let valToShow = valToSave * PI / VEH_ROTATION_MAX
          setSkinRotation(valToShow)
          setValue(rotationSlider, valToSave)
        }
      })
    ]
  }
}

function curSquadCamo(squadInfo, armySquadsInfo, lookCfg) {
  if (squadInfo == null)
    return ""

  let armyId = getLinkedArmyName(squadInfo)
  let { squadId } = squadInfo
  return getSquadCamo(armyId, squadId, armySquadsInfo, lookCfg)
}

viewVehCamouflage.subscribe(function(curCamo) {
  let { details = "", hasUnique = false } = curCamo

  let { age, scale, rotation } = skinDetailsToParams(details)
  ageSlider.set(age)
  scaleSlider.set(scale)
  rotationSlider.set(rotation)

  if (uniqueDetailsAvailable.get())
    showUniqueDetails.set(hasUnique)
})

curCamouflageId.subscribe(function(_) { 
  if (!isCustomizeWndOpen.get())
    return

  defer(function() {
    let { age, scale, rotation } = skinDetailsToViewParams(skinParamsToDetails.get())
    setSkinCondition(age)
    setSkinScale(scale)
    setSkinRotation(rotation)
  })
})

function loadFromVehCamo(_) {
  
  
  selectedCampaign.set(
    curSquadCamo(curSquad.get(), armySquadsById.get(), gameProfileLookCfg.get()))
  let { isCommon = true } = vehCamouflageObj.get()
  hasCampaigns.set(!isCommon)
}

let popupWidth = slotSize[0] * SLOTS_IN_ROW + midPadding * (SLOTS_IN_ROW - 1)
function mkCampaigns() {

  let campaignsList = Computed(function() {
    let squadInfo = curSquad.get()
    let armyId = getLinkedArmyName(squadInfo)
    return camoCampaignsByArmies.get()?[armyId] ?? {}
  })

  let campaign = Computed(function() {
    let selected = selectedCampaign.get()
    return selected != COMMON_CAMPAIGN && selected in campaignsList.get()
      ? selected
      : curSquadCamo(curSquad.get(), armySquadsById.get(), gameProfileLookCfg.get())
  })

  return function() {
    let watch = [hasCampaigns, campaignsList]
    if (campaignsList.get().len() <= 1)
      return { watch }

    return {
      watch
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = [
        checkbox(hasCampaigns, {
            rendObj = ROBJ_TEXT
            color = defTxtColor
            text = loc("decorator/enableCampaigns")
          }.__update(fontSub),
          {
            setValue = @(v) setHasCampaigns(v)
            textOnTheLeft = true
          })
        {
          size = FLEX_H
          children = mkOutfitsListButton(
            campaignsList,
            null ,
            campaign,
            setCurCampaign,
            {
              btnWidth = FLEX
              btnHeight = hdpxi(35),
              label = null
              isEnabled = hasCampaigns.get()
              popupWidth
            })
        }
      ]
    }
  }
}

function mkCamouflage(cParams, template, camouflage, skinToBuy, currencies) {
  let id = skinToBuy?.id ?? camouflage?.skinId
  let { curCustType = "", curSlotIdx = -1 } = cParams
  let isSelected = curCustType == CAMO_TYPE && curSlotIdx == 0
  let { gametemplate } = template
  let skin = getVehSkinById(gametemplate, id)
  let baseSkin = getBaseVehicleSkin(gametemplate) ?? {}
  let { locId = null, objTexReplace = baseSkin } = skin
  let baseSkinId = cropSkinName(baseSkin.findvalue(@(_) true))
  let skinId = cropSkinName(objTexReplace.findvalue(@(_) true))
  let isBase = skinId == baseSkinId
  let skinLocId = locId ?? (isBase ? "skin/baseSkinName" : ($"skin/{skinId ?? "baseSkinName"}"))

  let decorator = skinId == null ? null : { id = skinId }
  let { buyData = null } = skinToBuy
  return {
    flow = FLOW_VERTICAL
    gap = midPadding
    padding = midPadding
    rendObj = ROBJ_SOLID
    color = panelBgColor
    children = [
      mkBlockHeader(loc("vehCamouflageHeader"))
      mkCampaigns()
      noteTextArea(loc(skinLocId)).__update({
        size = FLEX_H
        margin = [0, smallPadding]
        color = accentTitleTxtColor
      }.__update(fontSub))
      @() {
        watch = hasSkinCustomizer
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          mkDecorSlot(decorator, isSelected, false, function() {
            if (!isPurchasing.get())
              customizationParams.set({
                curCustType = CAMO_TYPE
                curSlotIdx = 0
              })
          }, null, buyData, currencies, slotBigSize)
          hasSkinCustomizer.get() ? mkCamouflageCustomizer() : null
        ]
      }
    ]
  }
}

function removeDecorator(vehGuid, cType, slotIdx) {
  notPurchased.mutate(function(cust) {
    let decoratorsList = clone (cust?[cType] ?? [])
    let idxToDelete = decoratorsList.findindex(@(v) v.slotIdx == slotIdx)
    if (idxToDelete != null)
      decoratorsList.remove(idxToDelete)
    cust[cType] <- decoratorsList
  })
  if (vehGuid != null)
    applyDecorator("", vehGuid, cType, "", slotIdx, false)
}

let mkCustomize = kwarg(
  function(decorators, scheme, slotParams, decoratorsCfg, hasPrem, decoratorsToBuy, currencies) {
    let { curCustType = "", curSlotIdx = -1 } = slotParams
    let { custType = "", slotsNum = 0, premSlotsNum = 0 } = scheme
    let total = slotsNum + premSlotsNum
    let available = hasPrem ? total : slotsNum
    let rows = ceil(total.tofloat() / SLOTS_IN_ROW).tointeger()
    return total == 0 ? null
      : {
          flow = FLOW_VERTICAL
          gap = midPadding
          padding = midPadding
          children = [mkBlockHeader(loc($"{custType}Header"))]
            .extend(array(rows).map(@(_row, rowIdx) {
              flow = FLOW_HORIZONTAL
              gap = midPadding
              children = array(SLOTS_IN_ROW).map(function(_column, columnIdx) {
                let sIdx = rowIdx * SLOTS_IN_ROW + columnIdx
                let isSelected = curCustType == custType && curSlotIdx == sIdx
                let hasLocked = sIdx >= available
                let decorator = decoratorsToBuy.findvalue(@(d) d.slotIdx == sIdx)
                  ?? decorators.findvalue(@(d) d.slotIdx == sIdx)
                let { buyData = null } = decorator
                function onClick() {
                  if (!isPurchasing.get())
                    customizationParams.set({
                      curCustType = custType
                      curSlotIdx = sIdx
                    })
                }
                local onRemove = null
                if (decorator != null) {
                  let { cType, slotIdx, id = null, vehGuid = null } = decorator
                  onRemove = function() {
                    if (id in decoratorsCfg) {
                      removeDecorator(vehGuid, cType, slotIdx)
                      return
                    }

                    let { belongId = "" } = decorator.cfg
                    showMsgbox({
                      text = "{0}\n\n{1}".subst(
                        getDecorBelongText(belongId),
                        loc("decorator/removeWarning")
                      )
                      buttons = [
                        {
                          text = loc("Yes"), isCurrent = true,
                          action = @() removeDecorator(vehGuid, cType, slotIdx)
                        }
                        {
                          text = loc("Cancel"), isCancel = true,
                          customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
                        }
                      ]
                    })
                  }
                }

                return sIdx >= total ? null
                  : mkDecorSlot(decorator, isSelected, hasLocked, onClick,
                      onRemove, buyData, currencies)
              })
            }))
        }
  })

let curVehSkins = Computed(function() {
  let { gametemplate = null } = viewVehicle.get()
  if (gametemplate == null)
    return null

  let exclusions = unsuitableSkinsById.get()
  return getVehSkins(gametemplate)
    .filter(function(skin) {
      let { id = "" } = skin
      return !(exclusions?[id][gametemplate] ?? false)
    })
})

function clearNotPurchased() {
  notPurchased.set({})
}

function actionsOnClose() {
  closeCustomizeWnd()
  clearNotPurchased()
  selectedCamouflage.set(null)
  applyCamoOnClose()
  showUniqueDetails.set(false)
}

function close() {
  let itemCount = notPurchased.get().reduce(@(r, v) r + v.len(), 0)
  if (itemCount > 0) {
    showMsgbox({
      text = loc("msg/leaveCustomizationConfirm")
      buttons = [
        { text = loc("Yes"),
          action = actionsOnClose,
          isCurrent = true }
        { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
    return
  }
  actionsOnClose()
}

function closeForced() {
  customizationParams.set(null)
  selectedCamouflage.set(null)
  viewVehicle.set(null)
  vehicleClear()
  showUniqueDetails.set(false)
}

let backButtonParams = {
  margin = midPadding
  hotkeys = [[ $"^{JB.B} | Esc", { description = loc("BackBtn") }]]
}

let mkBackBtn = @() Regular(loc("BackBtn"), close, backButtonParams)
let mkBackBtnForced = @() Regular(loc("BackBtn"), closeForced, backButtonParams)

function removeNotPurchasedCamouflage() {
  if (CAMO_TYPE in notPurchased.get())
    notPurchased.mutate(@(cust) cust.$rawdelete(CAMO_TYPE))
}

function addNotPurchasedCamouflage(id, buyData) {
  notPurchased.mutate(function(cust) {
    cust.vehCamouflage <- { id, buyData, details = "", cType = CAMO_TYPE, slotIdx = 0 }
  })
}

const buyProductBorderColor = Color(80,80,80,200)
const buyProductColor = Color(20,20,20,200)
const buyProductSlotWidth = hdpx(300)
let buyProductWndWidth = 3 * buyProductSlotWidth + 2 * midPadding
let buyProductParams = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
}

let mkBuyProduct = @(icon, header, name) {
  size = const [buyProductSlotWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = midPadding
  rendObj = ROBJ_SOLID
  color = buyProductColor
  children = [
    {
      size = slotSize
      padding = smallPadding
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      borderColor = buyProductBorderColor
      children = icon
    }
    {
      size = FLEX
      flow = FLOW_VERTICAL
      margin = [midPadding, 0]
      gap = smallPadding
      children = [
        mkBlockHeader(header)
        noteTextArea(name).__update({
          size = FLEX_H
          margin = [0, smallPadding]
          color = accentTitleTxtColor
        }.__update(fontSub))
      ]
    }
  ]
}

function massBuyProductViewUi() {
  let res = {
    watch = [viewVehicle, notPurchased, curDecorCfgByType]
  }

  let vehicle = viewVehicle.get()
  let { gametemplate = null } = vehicle
  if (gametemplate == null)
    return res

  let { vehCamouflage = null, vehDecorator = [], vehDecal = [] } = notPurchased.get()
  let children = []
  if (vehCamouflage != null) {
    let skin = getVehSkinById(gametemplate, vehCamouflage.id)
    let { locId = null, objTexReplace = (getBaseVehicleSkin(gametemplate) ?? {}) } = skin
    let skinId = cropSkinName(objTexReplace.values()?[0])
    let skinTxt = loc(locId ?? ($"skin/{skinId ?? "baseSkinName"}"))
    let icon = mkDecalImage({ id = skinId })
    children.append(mkBuyProduct(icon, loc("vehCamouflageChooseHeader"), skinTxt))
  }

  if (vehDecal.len() > 0)
    children.extend(vehDecal.map(@(d)
      mkBuyProduct(mkDecalImage(d), loc("vehDecalChooseHeader"), getDecorName(d))
    ))

  if (vehDecorator.len() > 0)
    children.extend(vehDecorator.map(@(d)
      mkBuyProduct(mkDecorImage(d), loc("vehDecoratorChooseHeader"), getDecorName(d))
    ))

  let hasWrap = children.len() > 3
  return res.__update({
    children = hasWrap
      ? wrap(children, {
          width = buyProductWndWidth
          hGap = midPadding
          vGap = midPadding
        })
      : children
  }, hasWrap ? {} : buyProductParams)
}

function mkPurchaseBtn(notPurchasedVal) {
  let { vehCamouflage = null, vehDecorator = [], vehDecal = [] } = notPurchasedVal
  let decoratorsList = [].extend(vehDecorator, vehDecal)
  let price = decoratorsList.reduce(@(r, v) r + v.buyData.price,
    (vehCamouflage?.buyData.price ?? 0))

  return price <= 0 ? null
    : currencyBtn({
        btnText = loc("btn/buy")
        currencyId = "EnlistedGold"
        price
        cb = function() {
          purchaseMsgBox({
            title = loc("buyVehDecorConfirm")
            productView = massBuyProductViewUi
            price
            currencyId = "EnlistedGold"
            purchase = function() {
              let vehGuid = viewVehicle.get()?.guid
              let decoratorsCfgList = decoratorsList.map(@(d) {
                cType = d.cType
                id = d.id
                slotIdx = d.slotIdx
                price = d.buyData.price
                details = d?.details ?? ""
              })
              let camouflage = {
                id = vehCamouflage?.id ?? ""
                price = vehCamouflage?.buyData.price
                details = skinParamsToDetails.get()
                hasUnique = showUniqueDetails.get()
                isCommon = !hasCampaigns.get()
                campaignId = hasCampaigns.get() ? selectedCampaign.get() : COMMON_CAMPAIGN
              }
              buyApplyDecorators(decoratorsCfgList, camouflage, vehGuid, price)
              clearNotPurchased()
            }
            alwaysShowCancel = true
            srcComponent = "mass_buy_decor"
          })
        }
        style = ({
          margin = midPadding
          hotkeys = [["^J:Y", { description = { skip = true }}]]
        })
      })
}

function findCamoBPIndex(camoId) {
  foreach (i, r in combinedUnlocks.get()) {
    if (r?.rewards[camoId] != null)
      return i
  }

  return null
}

function bpButton() {
  let watch = [curCamouflageId, combinedUnlocks]
  let id = curCamouflageId.get()
  let { bpSeason = null } = rewardsPresentation?[id]
  if (bpSeason != seasonIndex.get())
    return { watch }

  return {
    watch
    flow = FLOW_HORIZONTAL
    children = Regular(loc("btn/gotoBattlepass"), function() {
      let index = findCamoBPIndex(id)
      openBPwindow(index)
    }, { margin = midPadding })
  }
}

function customizeSlotsUi() {
  let slotParams = customizationParams.get()
  let camouflage = viewVehCamouflage.get()
  let currencies = currenciesList.get()

  let notPurchasedVal = notPurchased.get()
  let { vehCamouflage = null } = notPurchasedVal
  let vehicle = viewVehicle.get()
  let camouflageSlot = vehicle != null && curVehSkins.get().len() > 0
    ? mkCamouflage(slotParams, vehicle, camouflage, vehCamouflage, currencies)
    : null

  let { vehDecal = null, vehDecorator = null } = viewVehCustSchemes.get()
  let decorCfgByType = curDecorCfgByType.get()
  let decorators = viewVehDecorByType.get()
  return {
    watch = [
      viewVehCustSchemes, customizationParams, viewVehDecorByType, viewVehCamouflage, viewVehicle,
      hasPremium, curVehSkins, curDecorCfgByType, notPurchased, currenciesList
    ]
    size = FLEX_V
    flow = FLOW_VERTICAL
    gap = tinyOffset
    children = [
      { size = FLEX }
      camouflageSlot
      mkCustomize({
        decorators = decorators?.vehDecorator ?? {}
        scheme = vehDecorator
        slotParams
        decoratorsCfg = decorCfgByType?.vehDecorator ?? {}
        hasPrem = hasPremium.get()
        decoratorsToBuy = notPurchasedVal?.vehDecorator ?? []
        currencies
      })
      mkCustomize({
        decorators = decorators?.vehDecal ?? {}
        scheme = vehDecal
        slotParams
        decoratorsCfg = decorCfgByType?.vehDecal ?? {}
        hasPrem = hasPremium.get()
        decoratorsToBuy = notPurchasedVal?.vehDecal ?? []
        currencies
      })
      !uniqueDetailsAvailable.get() ? null
        : checkbox(showUniqueDetails, {
            rendObj = ROBJ_TEXT
            color = defTxtColor
            text = loc("decorator/uniqueDetails")
          }.__update(fontSub),
          {
            setValue = @(v) setValue(showUniqueDetails, v)
            textOnTheLeft = true
          })
      {
        size = FLEX_V
        flow = FLOW_HORIZONTAL
        valign = ALIGN_BOTTOM
        children = [
          mkBackBtn()
          mkPurchaseBtn(notPurchasedVal)
          bpButton
        ]
      }
    ]
  }
}

let wrapParams = {
  width = iconSpaceWidth
  hGap = midPadding
  vGap = midPadding
}

let emptyList = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = FLEX_H
  padding = midPadding
  halign = ALIGN_CENTER
  color = defBgColor
  children = txt(loc("msg/listIsEmpty")).__update(fontSub)
}

function mkGroupIcons(groupIconsList, vehGuid, curCustType,
  curSlotIdx, currencies, ownDecorators, isOnlyOwned
) {
  let children = []
  foreach (iconCfg in groupIconsList) {
    let cfg = clone iconCfg
    let { id } = cfg
    let freeDecorators = (ownDecorators?[id] ?? {})
      .filter(@(d) d.id == id
        && (d.vehGuid == "" || d.vehGuid == vehGuid )
        && (d.slotIdx == -1 || d.slotIdx == curSlotIdx))

    let isAbsent = freeDecorators.len() == 0
    let isUnavailable = (cfg?.buyData.price ?? 0) == 0
    if (isAbsent && (isUnavailable || isOnlyOwned))
      continue

    let onClick = curCustType != ""
      ? function() {
          let { cType, subType } = cfg
          let limit = vehDecorLimits.get()?[cType][subType] ?? 0
          if (limit > 0) {
            let count = (viewVehCustLimits.get()?[cType] ?? {})
              .reduce(@(res, sType, slot) sType == subType && slot != curSlotIdx ? res + 1 : res, 0)
            let notPurchasedCount = (notPurchased.get()?[cType] ?? [])
              .reduce(@(res, val) val.subType == subType ? res + 1 : res, 0)
            if (count + notPurchasedCount >= limit) {
              showMsgbox(loc("msg/vehDecorOverlimits", {
                limit = colorize(accentTitleTxtColor, limit)
                id = colorize(accentTitleTxtColor, loc($"decals/category/{subType}"))
              }))
              return
            }
          }
          startUsingDecor(curSlotIdx, cfg)
        }
      : @() null
    children.append(mkDecorIcon({
      cfg, currencies, onClick, availableCount = freeDecorators.len()
    }))
  }

  return children.len() == 0 ? emptyList
    : {
        size = FLEX_H
        children = wrap(children, wrapParams)
      }
}

let mkCustomizeList = @(groupName, hasOpened, onClick, availCount, limit, count, groupIcons = null) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    mkCustGroup(groupName, hasOpened, onClick, availCount, limit, count)
    groupIcons
  ]
}

let mkCustomizationList = @(curCustType, content, onlyOwned = null) {
  size = FLEX_V
  padding = [smallOffset,midPadding,0,midPadding]
  children = {
    key = $"{curCustType}_customization"
    size = FLEX_V
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [iconSpaceWidth, SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = smallOffset
        padding = smallPadding
        valign = ALIGN_CENTER
        color = slotNormalColor
        children = [
          mkBlockHeader(loc($"{curCustType}ChooseHeader"))
          { size = FLEX }
          onlyOwned == null ? null
            : checkbox(onlyOwned, { text = loc("onlyAvailable") }.__update(fontSub), {
                setValue = @(_) onlyOwned.set(!onlyOwned.get())
                textOnTheLeft = true
              })
          mkButton({
            icon = closeActionIcon
            onClick = function() {
              selectedCamouflage.set(null)
              closeDecoratorsList()
            }
            descLocId = "Close"
            hotkey = "Esc"
            gpadHotkey = JB.B
            override = {
              size = hdpx(36)
              padding = smallPadding
            }
          })
        ]
      }
    ].append(makeVertScroll(content, { styling = thinStyle }))
    transform = true
    animations = [{
      prop = AnimProp.translate, from = [iconSpaceWidth, 0], to = [0, 0],
      play = true, duration = 0.5, easing = OutCubic
    }]
  }
}

let mkDecoratorsList = @(curCustType, curSlotIdx, onlyOwned) function() {
  let res = {
    watch = [
      curDecorCfgByType, lastOpenedGroupName, viewVehicle, vehDecorLimits,
      currenciesList, availVehDecorByTypeId, onlyOwned, viewVehCustLimits
    ]
  }

  let vehGuid = viewVehicle.get()?.guid
  let ownDecorators = availVehDecorByTypeId.get()?[curCustType] ?? {}
  let currencies = currenciesList.get()
  let custCfg = curDecorCfgByType.get()?[curCustType] ?? {}
  if (custCfg.len() == 0)
    return res

  let cfgLimits = vehDecorLimits.get()?[curCustType] ?? {}
  let vehLimits = viewVehCustLimits.get()?[curCustType] ?? {}
  let groupsList = custCfg
    .reduce(@(r, v) v.subType == "" ? r : r.__merge({ [v.subType] = true }), {})
    .keys()
    .sort(@(a, b) a <=> b)

  let openedGroup = lastOpenedGroupName.get()
  let groupIconsList = custCfg.values()
    .filter(@(cfg) cfg.subType == openedGroup)
    .sort(customizationSort)

  let onlyOwnedVal = onlyOwned.get()
  let content = groupsList.len() == 0 ? null
    : {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = midPadding
        children = groupsList.map(function(groupName) {
          let hasOpened = openedGroup == groupName
          let groupIcons = hasOpened
            ? mkGroupIcons(groupIconsList, vehGuid, curCustType, curSlotIdx,
                currencies, ownDecorators, onlyOwnedVal)
            : null
          let onGroupClick = @() lastOpenedGroupName.set(hasOpened ? "" : groupName)
          let availCount = custCfg
            .filter(@(v) v.subType == groupName).values()
            .reduce(function(r, v) {
              let list = (ownDecorators?[v.id] ?? {})
                .filter(@(d) (d.vehGuid == "" || d.vehGuid == vehGuid)
                  && (d.slotIdx == -1 || d.slotIdx == curSlotIdx))
              return r + list.len()
            }, 0)

          let limit = cfgLimits?[groupName] ?? 0
          let count = vehLimits.reduce(@(acc, id, slot)
            id == groupName && slot != curSlotIdx ? acc + 1 : acc, 0)
          return mkCustomizeList(groupName, hasOpened, onGroupClick,
            availCount, limit, count, groupIcons)
        })
      }
  return res.__update(mkCustomizationList(curCustType, content, onlyOwned))
}

function chooseSkin(skinData, vehGuid, ownCamoList = []) {
  if (skinData == null) {
    removeNotPurchasedCamouflage()
    applyCamouflage("", vehGuid)
    return
  }

  let { id } = skinData
  let hasOwned = ownCamoList.contains(id)

  selectedCamouflage.set(skinData.__merge({
    hasOwned
    details = skinParamsToDetails.get()
  }))
  if (hasOwned) {
    removeNotPurchasedCamouflage()
    applyCamouflage(id, vehGuid)
    return
  }

  if ((skinData?.buyData.price ?? 0) > 0)
    addNotPurchasedCamouflage(id, skinData.buyData)
  else
    removeNotPurchasedCamouflage()
}

function camouflageListUi() {
  let watch = [
    viewVehicle, curCamouflageId, vehCamouflageCfg, curOwnCamoList, currenciesList, curVehSkins
  ]

  let ownCamoList = curOwnCamoList.get()
  let skinsList = getCamoList(viewVehicle.get(), vehCamouflageCfg.get(),
    curVehSkins.get(), ownCamoList, rewardsPresentation, seasonIndex.get())
  if (skinsList.len() == 0)
    return { watch }

  let { guid, gametemplate } = viewVehicle.get()
  let currencies = currenciesList.get()
  let camouflageId = curCamouflageId.get()
  let skinsObjects = skinsList
    .sort(@(a, b) (a?.buyData.price ?? 0) <= 0 <=> (b?.buyData.price ?? 0) <= 0
      || (a?.buyData.price ?? 0) <=> (b?.buyData.price ?? 0)
      || a.id <=> b.id)
    .map(function(skinData) {
      let { id, hasOwned } = skinData
      let isSelected = camouflageId == id
      return mkSkinIcon(skinData, isSelected, hasOwned, currencies,
        @() chooseSkin(skinData, guid, ownCamoList))
    })

  let baseSkinData = { objTexReplace = getBaseVehicleSkin(gametemplate) }
  let skinsBlock = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_RIGHT
    children = skinsObjects.len() == 0 ? null
      : [
          mkSkinIcon(baseSkinData, camouflageId == null, true, currencies,
            @() chooseSkin(null, guid))
        ].extend(skinsObjects)
  }
  return { watch }.__update(mkCustomizationList(CAMO_TYPE, skinsBlock))
}


let filterOnlyOwned = Watched(false)
function customizeListUi() {
  let { curCustType = "", curSlotIdx = -1 } = customizationParams.get()
  return {
    watch = customizationParams
    size = FLEX_V
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    hplace = ALIGN_RIGHT
    children = curCustType == "" ? null
      : curCustType == CAMO_TYPE ? camouflageListUi
      : mkDecoratorsList(curCustType, curSlotIdx, filterOnlyOwned)
  }
}

function isVehicleOwnedByRentedSquad(vehicle) {
  let squadGuid = getFirstLinkByType(vehicle, "curVehicle")
  return squadGuid != null && isSquadRented(squads.get()?[squadGuid])
}

let mkUseDecalBlock = @(applyCb, cancelModeCb, padding) {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = smallOffset
  padding
  margin = midPadding
  behavior = [DngBhv.MenuCameraControl, Behaviors.Button]
  onClick = function() {
    if (isVehicleOwnedByRentedSquad(viewVehicle.get())) {
      showRentedSquadLimitsBox()
      cancelModeCb()
      return
    }
    applyCb()
  }
  eventPassThrough = true
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    {
      hotkeys = [[
        $"^J:LB", @() onDecalMouseWheel({ shiftKey = true, button = -2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:RB", @() onDecalMouseWheel({ shiftKey = true, button = 2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:LT", @() onDecalMouseWheel({ altKey = true, button = -2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:RT", @() onDecalMouseWheel({ altKey = true, button = 2 })
      ]]
    }
    mkDecorHints([decorScaleHint, decorRotationHint])
    mkFlipBtn(isMirrorMode)
    mkSelectBox(sideParams, twoSideIdx, ["S", "T", "M"], "J:X")
    mkButton({
      icon = closeActionIcon
      onClick = cancelModeCb
      descLocId = "Close"
      hotkey = "Esc"
      gpadHotkey = JB.B
      hasHotkeyHint = true
    })
  ]
}

let mkUseDecorBlock = @(applyCb, cancelModeCb, padding) {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = smallOffset
  padding
  margin = midPadding
  behavior = [DngBhv.MenuCameraControl, Behaviors.Button]
  onClick = function() {
    if (isVehicleOwnedByRentedSquad(viewVehicle.get())) {
      showRentedSquadLimitsBox()
      cancelModeCb()
      return
    }
    applyCb()
  }
  eventPassThrough = true
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    {
      hotkeys = [[
        $"^J:LT", @() onDecalMouseWheel({ altKey = true, button = -2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:RT", @() onDecalMouseWheel({ altKey = true, button = 2 })
      ]]
    }
    mkDecorHints([decorRotationHint])
    mkButton({
      icon = closeActionIcon
      onClick = cancelModeCb
      descLocId = "Close"
      hotkey = "Esc"
      gpadHotkey = JB.B
      hasHotkeyHint = true
    })
  ]
}

isMirrorMode.subscribe(@(v) mirrorDecal(v))
twoSideIdx.subscribe(function(v) {
  if (sideParams[v] == SIDE_PARAMS.ONE_SIDE)
    twoSideDecal(false, false)
  else if (sideParams[v] == SIDE_PARAMS.TWO_SIDE)
    twoSideDecal(true, false)
  else if (sideParams[v] == SIDE_PARAMS.TWO_SIDE_MIRRORED)
    twoSideDecal(true, true)
})

function onVehicleZoom(mouseEvent) {
  changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
}

function customizeScene() {
  let { skin = null } = selectVehParams.get()
  let isDecoration = selectedDecorator.get() != null
  if (isDecoration)
    return {
      watch = [safeAreaBorders, selectedDecorator, isPurchasing]
      size = FLEX
      margin = [0, 0, smallOffset, 0]
      behavior = [
        Behaviors.ProcessPointingInput 
        Behaviors.TrackMouse 
      ]
      onPointerMove = onDecalMouseMove
      onMouseWheel = onDecalMouseWheel
      children = selectedDecorator.get().cType == "vehDecorator" ? mkUseDecorBlock(
            applyUsingDecor,
            stopUsingDecal,
            safeAreaBorders.get()
          )
        : mkUseDecalBlock(
            applyUsingDecal,
            stopUsingDecal,
            safeAreaBorders.get()
          )
    }

  return {
    watch = [safeAreaBorders, selectedDecorator, isPurchasing, selectVehParams]
    size = FLEX
    padding = safeAreaBorders.get()
    margin = [0, 0, smallOffset, 0]
    behavior = [Behaviors.TrackMouse, DngBhv.MenuCameraControl]
    onMouseWheel = onVehicleZoom
    onAttach = loadFromVehCamo
    children = skin != null
      ? {
          size = FLEX_V
          valign = ALIGN_BOTTOM
          children = mkBackBtnForced()
        }
      : [
          customizeSlotsUi
          isPurchasing.get() ? waitingSpinner : null
          customizeListUi
        ]
  }
}


function onSaveVehicleDecals(decors_info) {
  let vehGuid = viewVehicle.get()?.guid
  let decoratorCfg = selectedDecorator.get()
  let { id = null, cType = null, buyData = null, subType = null } = decoratorCfg
  let { curSlotIdx = -1 } = customizationParams.get()

  stopUsingDecal()
  if (id == null || curSlotIdx == -1)
    return

  let decalsData = decors_info.findvalue(@(d) d.slot == curSlotIdx)
  if (decalsData == null)
    return

  let { guid = null } = (availVehDecorByTypeId.get()?[cType][id] ?? {})
    .findvalue(@(d) d.id == id && d.vehGuid == "" && d.slotIdx == -1)

  if (guid != null) {
    closeDecoratorsList()
    let decalString = decalToString(decalsData, cType)
    applyDecorator(guid, vehGuid, cType, decalString, curSlotIdx, showUniqueDetails.get())
    return
  }

  let { price = 0 } = buyData
  if (price <= 0) {
    showMsgbox(loc("alternativeDecalReceivingWay"))
    return
  }

  notPurchased.mutate(function(cust) {
    if (cType == null)
      return
    let decorators = clone (cust?[cType] ?? [])
    let idxToDelete = decorators.findindex(@(v) v.slotIdx == curSlotIdx)
    if (idxToDelete != null)
      decorators.remove(idxToDelete)
    decorators.append({
      cType
      subType
      buyData
      id
      slotIdx = curSlotIdx
      details = decalToString(decalsData, cType)
    })
    cust[cType] <- decorators
  })
  closeDecoratorsList()
}

ecs.register_es("decal_es", {
  [SaveVehicleDecals] = @(evt, _eid, _comp) onSaveVehicleDecals(evt?[0].getAll() ?? [])
}, {}, {tags = "server"})

ecs.register_es("decor_save_es", {
  [SaveVehicleDecor] = function(_eid, comp) {
    if (!comp.decor__canAttach) {
      popupsState.addPopup({
        id = "vehicle_decor_place_error"
        text = loc("msg/vehDecorCantPlaceHere")
        styleName = "error"
      })
      return
    }

    onSaveVehicleDecals([{
      template = comp.node_attached__template
      nodeName = comp.node_attached__nodeName
      relativeTm = comp.node_attached__localTm
      slot = comp.decor__id
    }])
  }
},
{
  comps_ro = [
    ["node_attached__localTm", ecs.TYPE_MATRIX],
    ["node_attached__template", ecs.TYPE_STRING],
    ["node_attached__nodeName", ecs.TYPE_STRING],
    ["decor__id", ecs.TYPE_INT],
    ["decor__canAttach", ecs.TYPE_BOOL]
  ],
}, {tags = "server"})

function open() {
  let { skin = null } = selectVehParams.get()
  clearNotPurchased()
  closeDmViewerMode()
  customizationParams.set(skin == null ? null
    : {
        curCustType = CAMO_TYPE
        curSlotIdx = 0
      })
  selectedCamouflage.set(skin)
  sceneWithCameraAdd(customizeScene, "vehicles")
}


if (isCustomizeWndOpen.get())
  open()

isCustomizeWndOpen.subscribe(function(v) {
  if (v)
    open()
  else
    sceneWithCameraRemove(customizeScene)
})
