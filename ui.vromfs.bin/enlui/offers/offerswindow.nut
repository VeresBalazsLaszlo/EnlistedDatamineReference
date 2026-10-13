import "%ui/control/gui_buttons.nut" as JB
import "%ui/shop/viewShopItemsScene.nut" as viewShopItemsScene
import "%ui/shop/buyShopItem.nut" as buyShopItem
from "%ui/components/defcomps.nut" import txt
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/textButton.nut" import Regular, FARegular, Purchase
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, primeFlagStyle
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/soldiers/unlockSquadScene.nut" import openUnlockSquadScene
from "%ui/soldiers/model/state.nut" import curArmy, selectArmy
from "%ui/gameModes/gameModeState.nut" import currentGameMode
from "%ui/offers/offersState.nut" import visibleOffersInWindow, curOfferIdx, isSpecOffersOpened,
  hasOfferStartBtn
from "%ui/startButton.nut" import mkJoinQuickMatchButton, checkPlayAvailability, startQuickMatchFunc
from "%ui/squad/squadManager.nut" import isInSquad
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/style/designConst.nut" import smallPadding, midPadding, hoverBgColor, defBgColor,
  activeTxtColor, defTxtColor, fadedTxtColor, weakTxtColor
from "%ui/shop/shopPkg.nut" import mkShopItemView, mkShopItemPriceLine, mkProductView
from "%ui/shop/armyShopState.nut" import shopItemContentCtor
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/meta/profile.nut" import campaignsByArmy, squadsByArmies
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/state/queueState.nut" import isInQueue
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/tutorial/battleTutorial.nut" import curUnfinishedBattleTutorial
from "%ui/ui_library.nut" import *

let activatePremiumBtn = require("%ui/shop/activatePremiumBtn.nut")


const specOfferWidth = hdpx(700)
const shopItemHeight = hdpx(400)


function mkTestDriveBtn(personalOffer) {
  let { guid, testDrives, shopItemGuid, discountInPercent } = personalOffer
  return {
    halign = ALIGN_CENTER
    children = testDrives == 0 ? null
      : mkJoinQuickMatchButton("testDrive/inBattle", function() {
          let curArmyId = curArmy.get()
          let reqArmyId = shopItems.get()?[shopItemGuid].armies[0] ?? curArmyId
          if (curArmyId != reqArmyId)
            selectArmy(reqArmyId)

          isSpecOffersOpened.set(false)
          gui_scene.setTimeout(0.1, function() {
            checkPlayAvailability(guid)
            sendBigQueryUIEvent("try_offer_test_drive", null, { shopItemGuid, discountInPercent })
          })
        }, {
          hotkeys = "^J:LT"
          customInfo = {
            rendObj = ROBJ_TEXT
            color = weakTxtColor
            text = loc("testDrive/tryLeft", { count = testDrives })
          }.__update(fontSub)
        })
  }
}

function btnBlockUi() {
  let pageIdx = curOfferIdx.get()
  let totalPages = visibleOffersInWindow.get().len()
  let canPrev = pageIdx > 0
  let canNext = pageIdx < totalPages - 1
  return {
    watch = [visibleOffersInWindow, curOfferIdx]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      totalPages < 2 ? null
        : FARegular("arrow-left", @() curOfferIdx.set(pageIdx - 1), {
            key = $"prevOffer_{canPrev}"
            isEnabled = canPrev
            hotkeys = canPrev ? [["^J:LB", { description = loc("Prev offer") }]] : null
          })
      totalPages < 2 ? null
        : FARegular("arrow-right", @() curOfferIdx.set(pageIdx + 1), {
            key = $"nextOffer_{canNext}"
            isEnabled = canNext
            hotkeys = canNext ? [["^J:RB", { description = loc("Next offer") }]] : null
          })
    ]
  }
}

function mkShopItemSquads(squads) {
  if (squads.len() == 0)
    return null

  return function() {
    let campaigns = campaignsByArmy.get()
    let squadsCfg = squadsCfgById.get()
    let children = squads.map(function(squad) {
      let { armyId, id } = squad
      let squadCfg = squadsCfg?[armyId][id]
      if (squadCfg == null)
        return null

      let campaign = loc(campaigns?[armyId].title ?? "")
      let name = loc(squadCfg.titleLocId)
      return watchElemState(@(sf) {
        rendObj = sf & S_HOVER ? ROBJ_SOLID : null
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        padding = [smallPadding, midPadding]
        color = defBgColor
        behavior = Behaviors.Button
        onClick = @() openUnlockSquadScene(armyId, squadCfg, { hasTestDrive = true })
        children = [
          txt({
            text = loc("listWithDot", { text = $"{campaign} {name}" })
            color = sf & S_HOVER ? activeTxtColor : defTxtColor
          }).__update(fontSub)
          txt({
            text = loc("btn/view")
            color = sf & S_HOVER ? defTxtColor : fadedTxtColor
          }).__update(fontSub)
        ]
      })
    })

    return {
      watch = [campaignsByArmy, squadsCfgById]
      size = FLEX_H
      flow = FLOW_VERTICAL
      padding = [smallPadding, 0]
      children
    }
  }
}

let mkOfferDesc = @(descLocId, params = {}) descLocId == "" ? null
  : {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = FLEX_H
      color = activeTxtColor
      text = loc(descLocId, params)
    }.__update(fontSub)

function mkOfferShopItem(personalOffer, shopItem, ownSquads) {
  if (shopItem == null)
    return null

  let { squads = [], armies = [] } = shopItem
  let {
    descLocId = "", testDrives = 0, shopItemGuid = "", discountInPercent = 0
  } = personalOffer

  let armiesBlock = {
    flow = FLOW_HORIZONTAL
    children = armies.map(@(armyId) mkArmyIcon(armyId, hdpx(36)))
  }
  let squadsToBuy = []
  let squadsToShow = []
  foreach (squad in squads) {
    let armyOwnedSquads = ownSquads?[squad.armyId] ?? {}
    if (armyOwnedSquads.findvalue(@(s) s.squadId == squad.id) == null)
      squadsToBuy.append(squad)
    else if (testDrives > 0)
      squadsToShow.append(squad)
  }

  let crateContent = shopItemContentCtor(shopItem)
  let squadToBuyBlock = mkShopItemSquads(squadsToBuy)
  let squadToShowBlock = mkShopItemSquads(squadsToShow)
  let descBlock = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = midPadding
    gap = midPadding
    children = [
      mkOfferDesc(descLocId)
      squadsToBuy.len() == 0 ? null
        : {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              mkOfferDesc("offer/squadAnnounce", { count = squadsToBuy.len() })
              squadToBuyBlock
            ]
          }
      squadsToShow.len() == 0 ? null
        : {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              mkOfferDesc("offer/ownedSquadHeader")
              squadToShowBlock
            ]
          }
    ]
  }
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      {
        size = const [FLEX, shopItemHeight]
        children = [
          mkShopItemView({
            shopItem
            crateContent
            onCrateViewCb = @() viewShopItemsScene(shopItem)
          })
          armiesBlock
        ]
      }
      mkShopItemPriceLine(shopItem, personalOffer)
      descBlock
      {
        size = const [FLEX, fsh(5)]
        children = [
          Regular(loc("Close"), @() isSpecOffersOpened.set(false), {
            hotkeys = [[$"^{JB.B} | Esc"]]
          })
          Purchase(loc("btn/buy"), function() {
              buyShopItem({
                shopItem
                activatePremiumBtn
                productView = mkProductView(shopItem)
                pOfferGuid = personalOffer?.guid
              })
              sendBigQueryUIEvent("try_buy_offer", null, { shopItemGuid, discountInPercent})
            },
            {
              hplace = ALIGN_RIGHT
              hotkeys = [[$"^J:X | Enter"]]
            }
          )
        ]
      }
      function() {
        let watch = [
          isInQueue, isInSquad, curUnfinishedBattleTutorial, currentGameMode, hasOfferStartBtn
        ]
        let isTutorialMode = curUnfinishedBattleTutorial.get() != null
        let isPracticeMode = currentGameMode.get()?.isLocal
        return {
          watch
          flow = FLOW_HORIZONTAL
          gap = midPadding
          hplace = ALIGN_CENTER
          children = [
            isInQueue.get() || isInSquad.get() || isTutorialMode || isPracticeMode
              ? null
              : mkTestDriveBtn(personalOffer)
            !hasOfferStartBtn.get() ? null
              : mkJoinQuickMatchButton("START", function() {
                isSpecOffersOpened.set(false)
                startQuickMatchFunc()
              })
          ]
        }
      }
    ]
  }
}


function curOfferUi() {
  let offer = visibleOffersInWindow.get()?[curOfferIdx.get()]
  let allShopItems = shopItems.get()
  let ownSquads = squadsByArmies.get()
  return {
    watch = [visibleOffersInWindow, curOfferIdx, squadsByArmies, shopItems]
    size = const [fsh(130), FLEX]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = offer == null ? null
      : {
          rendObj = ROBJ_SOLID
          size = const [specOfferWidth, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          color = defBgColor
          children = [
            { size = [FLEX, midPadding] }
            mkHeaderFlag({
              rendObj = ROBJ_TEXT
              text = utf8ToUpper(loc("specialOfferHeader"))
              padding = const [fsh(2), fsh(3)]
            }.__update(fontBody), primeFlagStyle)
            {
              size = FLEX_H
              padding = midPadding
              children = mkOfferShopItem(offer, allShopItems[offer.shopItemGuid], ownSquads)
            }
          ]
        }
  }
}

let offerWindow = @() {
  watch = safeAreaBorders
  rendObj = ROBJ_WORLD_BLUR
  size = FLEX
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.get()
  halign = ALIGN_CENTER
  color = hoverBgColor
  children = [
    curOfferUi
    btnBlockUi
  ]
}

function open() {
  sceneWithCameraAdd(offerWindow, "researches")
}

function close() {
  sceneWithCameraRemove(offerWindow)
}

if (isSpecOffersOpened.get())
  open()

visibleOffersInWindow.subscribe(function(list) {
  if (list.len() == 0)
    isSpecOffersOpened.set(false)
})
isSpecOffersOpened.subscribe(@(v) v ? open() : close())

return function(specOffer) {
  curOfferIdx.set(visibleOffersInWindow.get().indexof(specOffer) ?? 0)
  hasOfferStartBtn.set(false)
  isSpecOffersOpened.set(true)
}
