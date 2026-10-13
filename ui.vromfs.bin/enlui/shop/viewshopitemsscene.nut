import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/soldiers/mkItemWithMods.nut" as mkItemWithMods
import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/shop/hasLootRestriction.nut" as checkLootRestriction
from "%sqstd/string.nut" import startsWith
from "%ui/components/textButton.nut" import Primary, Regular
from "%ui/shop/shopPkg.nut" import mkShopItemView, shopItemLockedMsgBox, mkShopItemImg, mkShopItemPriceLine, mkShopItemInfoBlock, getCantBuyData
from "%ui/shop/shopPackage.nut" import mkShopMsgBoxView, mkCanUseShopItemInfo
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/soldiers/model/state.nut" import curArmyData
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, purchaseIsPossible, needGoodManage
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/soldiers/components/itemDetailsComp.nut" import mkViewItemWatchDetails
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/style/designConst.nut" import midPadding, smallPadding, blurBgColor, blurBgFillColor, unitSize
from "%ui/showState.nut" import curSelectedItem, changeCameraFov
from "%ui/items/crateInfo.nut" import makeCrateToolTip
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthConfig, curGrowthProgress, curGrowthTiers, GrowthStatus
from "%ui/battleData/testDrive.nut" import mkItemTestDriveButtonUi
from "%ui/eventPass/eventItemPkg.nut" import isEventItem, has3dIcon, mkEventItemCard, eventItemImage
from "%ui/meta/profile.nut" import commonArmy
from "%ui/ui_library.nut" import *

let activatePremiumBtn = require("%ui/shop/activatePremiumBtn.nut")


const ADD_CAMERA_FOV_MIN = -20
const ADD_CAMERA_FOV_MAX = 5


let shopItem = mkWatched(persist, "shopItem", null)
let selectedKey = Computed(@() curSelectedItem.get()?.basetpl)

let shopItemWidth = 9.0 * unitSize
let shopItemHeight = 6.0 * unitSize
let itemSize = [shopItemWidth, 2.2 * unitSize]

function mkShopItemContent(sItem) {
  let crateContentWatch = shopItemContentCtor(sItem)
  return function() {
    let crateContentValue = crateContentWatch.get()
    if (crateContentValue == null)
      return { watch = crateContentWatch }

    let watch = [crateContentWatch, allItemTemplates, commonArmy]
    let { armyId, content } = crateContentValue
    let templates = allItemTemplates.get()

    let crateItems = []
    foreach (templateId, count in content?.items ?? {}) {
      let template = templates?[armyId][templateId] ?? templates?[commonArmy.get()][templateId]
      if (template != null)
        crateItems.append(mkShopItem(templateId, template, armyId).__update({ count }))
    }
    crateItems.sort(@(a, b) (a?.growthTier ?? 0) <=> (b?.growthTier ?? 0))
    if (crateItems.len() == 0)
      return { watch }

    return {
      watch
      size = FLEX_V
      padding = [midPadding, midPadding]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = blurBgColor
      fillColor = blurBgFillColor
      onAttach = @() curSelectedItem.set(crateItems[0])
      onDetach = @() curSelectedItem.set(null)
      xmbNode = XmbContainer({
        canFocus = false
        scrollSpeed = 5.0
        isViewport = true
      })
      children = makeVertScroll(
        wrap(crateItems.map(function(item) {
          let onClickCb = @(_) curSelectedItem.set(item)
          return isEventItem(item)
            ? mkEventItemCard(item, onClickCb, itemSize)
            : mkItemWithMods({
                item
                selectedKey
                selectKey = item?.basetpl
                isXmb = true
                canDrag = false
                itemSize
                onClickCb
                hideStatus = true
                isAvailable = true
              })
          }),
          {
            width = shopItemWidth
            hGap = smallPadding
            vGap = smallPadding
            hplace = ALIGN_CENTER
          }
        ),
        {
          size = FLEX_V
          needReservePlace = false
        }
      )
    }
  }
}

function purchaseBtnUi() {
  let shopItemData = shopItem.get()
  let { offerContainer = "", requirements = {} } = shopItemData
  if (offerContainer.len() > 0)
    return null

  let army = curArmyData.get()
  let growths = curGrowthState.get()
  let growthCfg = curGrowthConfig.get()
  let grTiers = curGrowthProgress.get()
  let grTierCfg = curGrowthTiers.get()
  let templates = allItemTemplates.get()

  let lockData = getCantBuyData(army, requirements, growths, growthCfg,
    grTiers, grTierCfg, templates)

  let btnCtor = lockData != null ? Regular : Primary
  let crateContent = shopItemContentCtor(shopItemData)
  let countWatched = Watched(1)
  let description = crateContent ? mkCanUseShopItemInfo(crateContent) : null

  return {
    watch = [
      curArmyData, curGrowthState, curGrowthConfig, curGrowthProgress,
      curGrowthTiers, allItemTemplates, shopItem, purchaseIsPossible
    ]
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = FLEX_H
    children = !purchaseIsPossible.get() ? null
      : btnCtor(loc("btn/buy"),
          function() {
            if (lockData != null)
              return shopItemLockedMsgBox(lockData, @() shopItem.set(null))

            shopItem.set(null)
            checkLootRestriction(
              function() {
                buyShopItem({
                  shopItem = shopItemData
                  activatePremiumBtn
                  productView = mkShopMsgBoxView(shopItemData, crateContent, countWatched)
                  description
                  countWatched
                })
                needGoodManage.set(true)
              },
              {
                itemView = mkShopItemImg(shopItemData.image, {
                  size = const [fsh(40), fsh(24)]
                })
                description
              },
              crateContent
            )
          },
          {
            hotkeys = [["^J:Y"]]
            minWidth = pw(100)
          }
      )
  }
}

function mkShopItemInfo(item) {
  let crateContent = shopItemContentCtor(item)
  return makeCrateToolTip(crateContent, "", FLEX_H)
}

let mkCrateContent = @(sItem) function() {
  let crateContentWatch = shopItemContentCtor(sItem)
  return {
    watch = [crateContentWatch, curSelectedItem]
    size = FLEX_H
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = blurBgFillColor
    children = mkShopItemInfoBlock(crateContentWatch)
  }
}

function testDriveBtn() {
  let watch = curSelectedItem
  let item = curSelectedItem.get()
  if (item == null || isEventItem(item))
    return { watch }

  return {
    watch
    hplace = ALIGN_CENTER
    children = mkItemTestDriveButtonUi(item)
  }
}

function eventItemPreview() {
  let watch = curSelectedItem
  if (has3dIcon(curSelectedItem.get()))
    return { watch }
  return {
    watch
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = eventItemImage(curSelectedItem.get())
  }
}

let shopItemsScene = @() {
  watch = [safeAreaBorders, shopItem]
  size = const [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.get()
  behavior = [DngBhv.MenuCameraControl, Behaviors.TrackMouse]
  onMouseWheel = function(mouseEvent) {
    changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
  }
  children = shopItem.get() == null ? null : [
    mkHeader({
      
      textLocId = startsWith(shopItem.get()?.guid, "starter_pack")
        ? "shop/content"
        : "shop/possibleContent"
      closeButton = closeBtnBase({ onClick = @() shopItem.set(null) })
    })
    {
      size = FLEX
      children = [
        {
          size = FLEX_V
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            function() {
              let watch = [shopItem, curArmyData, curGrowthState, curGrowthProgress]
              if (shopItem.get() == null)
                return { watch }

              let { growthId = "", growthTierId = "" } = shopItem.get()?.requirements
              let gr = curGrowthState.get()

              let isGrowthAllowed = growthId == ""
                || (gr?[growthId].status ?? GrowthStatus.UNAVAILABLE) == GrowthStatus.REWARDED

              let tr = curGrowthProgress.get()
              let isGrTierAllowed = growthTierId == ""
                || (tr?[growthTierId].status ?? GrowthStatus.UNAVAILABLE) == GrowthStatus.COMPLETED

              let isLocked = !isGrowthAllowed || !isGrTierAllowed
              return {
                watch
                size = FLEX_H
                flow = FLOW_VERTICAL
                children = [
                  {
                    size = [FLEX, shopItemHeight]
                    children = mkShopItemView({ shopItem = shopItem.get(), isLocked })
                  }
                  mkShopItemPriceLine(shopItem.get(), null, false, false)
                ]
              }
            }
            mkCrateContent(shopItem.get())
            mkShopItemContent(shopItem.get())
            mkShopItemInfo(shopItem.get())
            purchaseBtnUi
          ]
        }
        {
          size = FLEX
          halign = ALIGN_RIGHT
          valign = ALIGN_BOTTOM
          children = [
            testDriveBtn
            mkViewItemWatchDetails(curSelectedItem)
            eventItemPreview
          ]
        }
      ]
    }
  ]
}

shopItem.subscribe(function(val) {
  if (val == null) {
    sceneWithCameraRemove(shopItemsScene)
    return
  }
  sceneWithCameraAdd(shopItemsScene, "shop_items")
})

if (shopItem.get() != null)
  sceneWithCameraAdd(shopItemsScene, "shop_items")

return @(val) shopItem.set(val)
