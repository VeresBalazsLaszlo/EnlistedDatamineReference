import "%ui/soldiers/starterPackPromoWnd.nut" as starterPack
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/shop/viewShopItemsScene.nut" as viewShopItemsScene
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%ui/shop/buySquadWindow.nut" as buySquadWindow
from "%ui/components/mkDotPaginator.nut" import mkDotPaginator
from "%ui/shop/shopItemClick.nut" import shopItemClick, isShopItemComposite
from "%ui/components/textButton.nut" import Regular
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/soldiers/model/state.nut" import curArmyData
from "%ui/components/scrollbar.nut" import makeVertScroll, styling
from "%ui/offers/offersState.nut" import offersByShopItem
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, curUnseenAvailShopGuids
from "%ui/components/unseenComponents.nut" import blinkUnseen, unblinkUnseen
from "%ui/shop/unseenShopItems.nut" import markShopItemSeen, markShopItemOpened
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/shop/shopState.nut" import mkShopState, curGroupIdx, curFeaturedIdx, chapterIdx
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/designConst.nut" import defTxtColor, largePadding, smallPadding, midPadding, darkTxtColor, mainContentOffset, titleTxtColor, hoverSlotBgColor
from "%ui/shop/shopPackage.nut" import mkBaseShopItem, mkLowerShopItem, lowerSlotSize, mkShopFeatured, mkDiscountBar
from "%ui/shop/shopPkg.nut" import getCantBuyData
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthProgress, curGrowthConfig, curGrowthTiers
from "%ui/ui_library.nut" import *

function mkShopGroup(group, isSelected, onClick) {
  let text = utf8ToUpper(loc(group.locId ?? $"shopGroup/{group.id}"))

  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    fillColor = sf & S_HOVER ? hoverSlotBgColor : 0
    borderColor = Color(255,255,255)
    borderWidth = isSelected ? [0,0,smallPadding,0] : 0
    size = const [SIZE_TO_CONTENT, hdpx(46)]
    behavior = Behaviors.Button
    onClick
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
      active = "ui/enlist/button_action"
    }
    padding = [smallPadding, largePadding]
    maxWidth = fsh(69)
    minWidth = hdpx(62)
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXT
      text
      color = sf & S_HOVER
        ? darkTxtColor
        : isSelected ? titleTxtColor : defTxtColor
    }.__update(fontBody)
  })
}
let shopGroupTxtHgt = calc_str_box({rendObj = ROBJ_TEXT text= "H"})[1]

const SWITCH_SEC = 8.0

const contentWidth = min(sw(90), fsh(142))

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let paginatorTimer = Watched(SWITCH_SEC)

let featuredPaginator = mkDotPaginator("featured", curFeaturedIdx, largePadding, paginatorTimer)

const VIEWED_SECONDS = 5

let locSpecialOffer = loc("specialOfferShort")

let mkDiscount = @(discount) mkDiscountBar({
  rendObj = ROBJ_TEXT
  text = discount > 0 ? $"-{discount}%" : locSpecialOffer
  color = darkTxtColor
}.__update(fontSub)).__update({
  vplace = ALIGN_TOP
  pos = [0, -shopGroupTxtHgt]
})

function unseenGuids(goods, unseenVal) {
  let res = []
  foreach (item in goods) {
    let { guid } = item
    if (guid in unseenVal)
      res.append(guid)
  }
  return res
}

function buildShopUi() {
  let {
    curShopItemsByGroup,
    curShopDataByGroup,
    curFeaturedByGroup,
    switchGroup,
    autoSwitchNavigation
  } = mkShopState()

  let switchGroupKey = mkHotkey("X | J:X", switchGroup)

  function shopNavigationUi() {
    let dataByGroup = curShopDataByGroup.get()
    return {
      watch = [curShopItemsByGroup, curShopDataByGroup, curGroupIdx, isGamepad]
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      gap = largePadding
      children = curShopItemsByGroup.get().map(function(group, idx) {
        let { hasUnseen = false, unopened = [], discount = 0, showSpecialOffer = false } = dataByGroup?[group.id]
        let hasDiscount = !group?.hideDiscountTabs && (discount > 0 || showSpecialOffer)
        return {
          valign = ALIGN_CENTER
          children = [
            mkShopGroup(group, curGroupIdx.get() == idx, function() {
              curFeaturedIdx.set(0)
              chapterIdx.set(-1)
              curGroupIdx.set(idx)
              markShopItemOpened(curArmyData.get()?.guid, unopened)
            })
            {
              size = FLEX
              padding = [0, 0, midPadding, 0]
              halign = ALIGN_RIGHT
              children = [
                !hasUnseen ? null
                  : unopened.len() > 0 ? blinkUnseen
                  : unblinkUnseen
                hasDiscount ? mkDiscount(discount) : null
              ]
            }
          ]
        }
      })
      .append(isGamepad.get() ? switchGroupKey : null)
    }
  }

  function shopItemAction(sItem, content, isLocked) {
    let { items = {} } = content
    if (items.len() > 0 && !sItem?.isStarterPack && isLocked) {
      viewShopItemsScene(sItem)
      return
    }

    shopItemClick(sItem)
  }

  function mkShopItemCard(sItem, idx, offers, army, growths, grTiers, cb, curGroup,
    isFeatured = false, isNarrow = false
  ) {
    if (sItem == null)
      return null

    let itemGuid = sItem?.guid
    let { guid = "" } = army
    let crateContent = shopItemContentCtor(sItem)

    let { requirements = null } = sItem
    let offer = offers?[itemGuid]
    let squad = sItem?.squads[0]

    let hasNotifier = Computed(@() curUnseenAvailShopGuids.get()?[itemGuid] ?? false)
    function hoverCb(on) {
      if (hasNotifier.get())
        hoverHoldAction("markSeenShopItem", { guid, itemGuid },
          @(v) markShopItemSeen(v.guid, v.itemGuid))(on)
    }
    let unseenComp = @() {
      watch = hasNotifier
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      children = hasNotifier.get() ? unblinkUnseen : null
    }

    return function() {
      let growthCfg = curGrowthConfig.get()
      let grTierCfg = curGrowthTiers.get()
      let templates = allItemTemplates.get()

      let lockData = getCantBuyData(army, requirements, growths, growthCfg,
        grTiers, grTierCfg, templates)

      let { lockTxt = "" } = lockData
      let content = crateContent == null ? null : crateContent.get()?.content
      let clickCb = @() cb(sItem, content, lockData != null)

      let infoCb = sItem?.isStarterPack ? @() starterPack.set(sItem)
        : squad == null || lockData != null || isShopItemComposite(sItem) ? null
        : @() buySquadWindow({
            shopItem = sItem
            armyId = squad.armyId
            squadId = squad.id
          })

      let itemCtor = isFeatured ? mkShopFeatured
        : isNarrow ? mkLowerShopItem
        : mkBaseShopItem
      let itemView = itemCtor(idx, guid, sItem, offer, content, templates, lockTxt, clickCb,
        hoverCb, null, infoCb, unseenComp, curGroup)
      return {
        key = itemGuid
        watch = [crateContent, allItemTemplates, curGrowthConfig, curGrowthTiers]
        children = itemView
      }
    }
  }


  let mkFeatured = @(army, growths, grTiers, featured, offers, curGroup) {
    children = [
      function() {
        let sItem = featured?[curFeaturedIdx.get()] ?? featured?[0]
        return {
          watch = curFeaturedIdx
          children = mkShopItemCard(sItem, 0, offers, army, growths, grTiers,
            shopItemAction, curGroup, true)
        }
      }
      {
        size = FLEX_H
        padding = smallPadding
        vplace = ALIGN_BOTTOM
        children = featuredPaginator(featured.len())
      }
    ]
  }

  let backButtonUi = freeze({
    size = lowerSlotSize
    children = Regular(loc("mainmenu/btnBack"), @() chapterIdx.set(-1), {
      size = FLEX
      xmbNode = XmbNode()
    })
  })

  function unseenItemsForGroup(group) {
    let { goods, chapters } = group
    return {
      unseenList = unseenGuids(goods, curUnseenAvailShopGuids.get())
      chapters = chapters == null ? null
        : chapters.map(@(chapter) unseenGuids(chapter.goods, curUnseenAvailShopGuids.get()))
    }
  }

  
  
  let curTabUnseen = Computed(function() {
    let army = curArmyData.get()
    let curGroup = curShopItemsByGroup.get()?[curGroupIdx.get()]
    let key = $"{army?.guid}/{curGroupIdx.get()}/{chapterIdx.get()}"
    if (army == null || curGroup == null)
      return { key, armyGuid = null, guids = [], hasDelay = false }
    let { chapters = null, autoseenDelay = false } = curGroup
    local guids = []
    if (chapters == null || chapterIdx.get() >= 0) {
      let unseen = unseenItemsForGroup(curGroup)
      guids = (unseen?.chapters[chapterIdx.get()] ?? unseen?.unseenList) ?? []
    }
    return { key, armyGuid = army.guid, guids, hasDelay = autoseenDelay }
  })

  local viewedTab = null

  function leaveViewedTab() {
    let t = viewedTab
    if (t == null || t.guids.len() == 0)
      return
    if (!t.hasDelay || serverTime.get() - t.enteredTs > VIEWED_SECONDS)
      defer(@() markShopItemSeen(t.armyGuid, t.guids))
  }

  function onShopView(next) {
    if (viewedTab == null || viewedTab.key != next.key) {
      leaveViewedTab()
      viewedTab = next.__merge({ enteredTs = serverTime.get() })
    }
    else {
      viewedTab.guids = next.guids
      viewedTab.hasDelay = next.hasDelay
    }
  }

  let watch = freeze([
    curShopItemsByGroup, curFeaturedByGroup, curGroupIdx, chapterIdx,
    offersByShopItem, curArmyData, curGrowthState, curGrowthProgress
  ])

  let xmbNode = XmbContainer({
    canFocus = false
    scrollSpeed = 10.0
    isViewport = true
  })

  function contentUi() {
    let curGroup = curShopItemsByGroup.get()?[curGroupIdx.get()]
    let { id = "", goods = [], chapters = null } = curGroup

    let featured = curFeaturedByGroup.get()?[id] ?? []
    let army = curArmyData.get()
    if ((goods.len() == 0 && chapters == null && featured.len() == 0) || army == null)
      return {
        watch
        xmbNode
        rendObj = ROBJ_TEXT
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        color = defTxtColor
        size = FLEX
        text = loc("shop/emptyTab")
      }.__update(fontBody)

    let offers = offersByShopItem.get()
    let growths = curGrowthState.get()
    let grTiers = curGrowthProgress.get()

    let shopContent = chapters != null || featured.len() == 0 ? []
      : [mkFeatured(army, growths, grTiers, featured, offers, curGroup)]

    if (chapters == null)
      shopContent.extend(goods.map(@(sItem, idx)
        mkShopItemCard(sItem, idx, offers, army, growths, grTiers, shopItemAction, curGroup)))
    else if (chapterIdx.get() < 0)
      shopContent.extend(chapters.map(@(chapter, idx)
        mkShopItemCard(chapter.container, idx, offers, army, growths,
          grTiers, @(...) chapterIdx.set(idx), curGroup, false, true))
            .filter(@(i) i != null))
    else
      shopContent
        .append(backButtonUi)
        .extend(chapters[chapterIdx.get()].goods.map(@(sItem, idx)
          mkShopItemCard(sItem, idx, offers, army, growths, grTiers,
            shopItemAction, curGroup, false, true)))

    return {
      watch
      xmbNode
      hplace = ALIGN_CENTER
      size = const [contentWidth, FLEX]
      children = makeVertScroll(
        wrap(shopContent, {
          width = contentWidth
          vGap = largePadding
          hGap = largePadding
        })
        {
          size = FLEX
          rootBase = {
            behavior = Behaviors.Pannable
            wheelStep = 1
          }
          styling = scrollStyle
        }
      )
    }
  }

  return {
    size = FLEX
    margin = [mainContentOffset,0,0,0]
    onAttach = function() {
      autoSwitchNavigation()
      curTabUnseen.subscribe(onShopView)
      onShopView(curTabUnseen.get())
    }
    onDetach = function() {
      curTabUnseen.unsubscribe(onShopView)
      leaveViewedTab()
      viewedTab = null
    }
    flow = FLOW_VERTICAL
    gap = largePadding
    children = [
      shopNavigationUi
      contentUi
    ]
  }
}

return {
  buildShopUi
}
