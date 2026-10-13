import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/fontawesome.map.nut" as fa
import "%enlSqGlob/userInfo.nut" as userInfo
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%ui/components/spinner.nut" as spinner
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
from "dagor.localize" import doesLocTextExist
from "%ui/components/openUrl.nut" import openUrl
from "%ui/currency/currencies.nut" import currenciesById
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontHeading1, fontHeading2, fontawesome
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/cursors.nut" import setTooltip
from "%ui/profile/decoratorPkg.nut" import mkPortraitFrame, mkNickFrame, mkExpireTime,
  PORTRAIT_SIZE, NICKFRAME_SIZE, mkRatingBlock
from "%ui/profile/decoratorState.nut" import portraitCfgAvailable, nickFramesCfgAvailable,
  buyDecorator, portraitsConfig, availPortraits, chosenPortrait, chooseDecorator,
  nickFramesConfig, availNickFrames, chosenNickFrame, decoratorInPurchase
from "%ui/style/designConst.nut" import midPadding, titleTxtColor, blurBgColor,
  bigOffset, tinyOffset, smallPadding, defBgColor, bonusColor, smallOffset,
  blurBgFillColor, panelBgColor, bigPadding
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/profile/profilePkg.nut" import borderColor, PROFILE_WIDTH
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/profile/unseenProfileState.nut" import seenDecorators, unopenedPortraits,
  unopenedNickFrames, markSeenDecorator, markDecoratorsOpened, hasUnseenPortraits,
  hasUnseenNickFrames
from "%ui/components/textButton.nut" import Regular, textColor
from "%dngscripts/platform.nut" import is_pc, is_gdk
from "%ui/profile/rankState.nut" import playerRank
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/components/msgbox.nut" import showMsgbox
from "app" import get_circuit_conf
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *
from "%ui/profile/profileState.nut" import curTabIdx


let { basePortrait } = require("%ui/components/decoratorsPresentation.nut")
let { smallUnseenBlink } = require("%ui/components/unseenComps.nut")

const PORTRAIT_WND_UID = "SelectPortraitWnd"
const NICKFRAME_WND_UID = "SelectNickFrameWnd"
const NICKFRAME_COLUMNS = 7
const PORTRAIT_COLUMNS = 6

let circuitConf = get_circuit_conf()

let changeNickUrl = circuitConf?.changeNickUrl
  ?? get_setting_by_blk_path("changeNickUrl")
  ?? "https://store.gaijin.net/profile.php?view=change_nick"

let portraitListWidth = (PORTRAIT_SIZE + midPadding) * PORTRAIT_COLUMNS
let nickFrameListWidth = (NICKFRAME_SIZE + midPadding) * NICKFRAME_COLUMNS
let hoverNickFrame = Watched("")
let waitingSpinner = spinner().__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER })

let mkCloseButtonCb = @(wndUid) @() removeModalWindow(wndUid)
let mkIcon = @(text, color) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontawesome)

let iconParam = {
  hplace = ALIGN_RIGHT
  margin = midPadding
  padding = smallPadding
  fontFxColor = Color(0,0,0)
  fontFxFactor = min(64,hdpx(64))
  fontFx = FFT_GLOW
}

function mkPortraitCost(portraitCfg) {
  let { buyData = null } = portraitCfg
  let { currencyId = "", price = 0 } = buyData
  return currencyId == "" && price <= 0 ? null
    : function() {
        let currency = currenciesById.get()?[currencyId]
        return {
          watch = currenciesById
          margin = smallPadding
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          children = currency == null ? null
            : mkCurrency({
                currency
                price
              }).__update({
                margin = midPadding
                hplace = ALIGN_CENTER
                vplace = ALIGN_BOTTOM
              })
        }
      }
}

function onNickFrameClick(nickFrameCfg, isEnabled) {
  let { guid = "", buyData = null, viewCb = null } = nickFrameCfg

  if (isEnabled) {
    removeModalWindow(NICKFRAME_WND_UID)
    if ((chosenNickFrame.get()?.guid ?? "") != guid)
      chooseDecorator("nickFrame", guid)
    return
  }

  let { currencyId = "", price = 0 } = buyData
  if (currencyId != "" && price > 0) {
    purchaseMsgBox({
      price
      currencyId
      description = loc("buyNickFrameConfirm")
      productView = mkNickFrame(viewCb)
      purchase = @() buyDecorator(guid, price)
      alwaysShowCancel = true
      srcComponent = "buy_decorator"
    })
    return
  }

  let locId = $"decorator/{nickFrameCfg.guid}/tip"
  showMsgbox(doesLocTextExist(locId) ? loc(locId) : loc("decorator/eventRewardTip"))
}

function mkTooltip(decorator) {
  let locId = $"decorator/{decorator.guid}/tip"
  let { currencyId = "", price = 0 } = decorator?.buyData
  return doesLocTextExist(locId) ? loc(locId)
    : currencyId != "" && price > 0 ? loc("decorator/canBeBoughtTip")
    : loc("decorator/eventRewardTip")
}

function nickFrameListUi() {
  let userName = userInfo.get()?.nameorig ?? ""
  let availList = availNickFrames.get()
  let nickFrameList = [null].extend(nickFramesCfgAvailable.get())
  let chosenGuid = chosenNickFrame.get()?.guid ?? ""
  let curPurchase = decoratorInPurchase.get()
  let unseen = seenDecorators.get()?.unseen ?? {}
  let chosen = nickFrameList.findvalue(@(v) v?.guid == chosenGuid)
  return {
    watch = [
      chosenNickFrame, nickFramesCfgAvailable, availNickFrames,
      userInfo, seenDecorators, decoratorInPurchase
    ]
    size = [nickFrameListWidth, FLEX]
    flow = FLOW_VERTICAL
    gap = bigPadding
    margin = [0,0,bigOffset,0]
    onAttach = @() hoverNickFrame.set(chosen?.viewCb(userName) ?? userName)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("selectNickFrameTitle")
        padding = [0, 0, tinyOffset, 0]
        hplace = ALIGN_CENTER
      }.__update(fontHeading2)
      @() {
        watch = hoverNickFrame
        hplace = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXT
          key = hoverNickFrame.get()
          text = hoverNickFrame.get()
          padding = [0, 0, tinyOffset, 0]
          color = titleTxtColor
          transform = true
          animations = [
            { prop = AnimProp.translate, from = [-hdpx(250), 0], to = [0, 0],
              duration = 0.15, play = true, easing = InOutCubic }
            { prop = AnimProp.translate, from = [0, 0], to = [hdpx(250), 0],
              duration = 0.15, playFadeOut = true }
            { prop = AnimProp.opacity, from = 0, to = 1,
              duration = 0.15, play = true, easing = InOutCubic }
            { prop = AnimProp.opacity, from = 1, to = 0,
              duration = 0.15, playFadeOut = true }
          ]
        }.__update(fontHeading1)
      }
      makeVertScroll({
        size = FLEX_H
        children = wrap(nickFrameList.map(function(nickFrameCfg) {
          let guid = nickFrameCfg?.guid ?? ""
          let receivedData = guid == ""
            ? null : availList.findvalue(@(n) n.guid == guid)

          let isSelected = guid == chosenGuid
          let isEnabled = guid == "" || receivedData != null
          let expireTime = receivedData?.expireTime ?? 0
          let isUnseen = guid in unseen
          return {
            size = const [NICKFRAME_SIZE, NICKFRAME_SIZE]
            children = [
              watchElemState(function(sf) {
                let addIcon = !isEnabled ? fa["lock"]
                  : isSelected ? fa["check"]
                  : null
                let iconColor = isSelected ? bonusColor : borderColor(sf, isEnabled)
                return {
                  behavior = Behaviors.Button
                  xmbNode = XmbNode()
                  onClick = @() onNickFrameClick(nickFrameCfg, isEnabled)
                  onHover = function(on) {
                    hoverNickFrame.set((on ? nickFrameCfg : chosen)?.viewCb(userName) ?? userName)
                    if (!isEnabled)
                      setTooltip(on ? mkTooltip(nickFrameCfg) : null)
                    if (isUnseen)
                      hoverHoldAction("merkSeenDecorator", guid, @(v) markSeenDecorator(v))(on)
                  }
                  children = [
                    mkNickFrame(nickFrameCfg?.viewCb, borderColor(sf, isEnabled), borderColor(sf))
                    mkIcon(addIcon, iconColor).__update(iconParam)
                  ]
                }
              })
              !isEnabled ? mkPortraitCost(nickFrameCfg)
                : expireTime > 0 ? mkExpireTime(expireTime)
                : null
              curPurchase != guid ? null
                : spinner().__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER })
              !isUnseen ? null : smallUnseenNoBlink
            ]
          }
        }), {
          width = nickFrameListWidth
          hGap = midPadding
          vGap = midPadding
        })}, {
          styling = thinStyle
          xmbNode = XmbContainer({
            canFocus = false
            scrollSpeed = 5.0
            isViewport = true
          })
        }
      )
    ]
  }
}

let openFrameWnd = @(key, content) addModalWindow({
  key
  size = FLEX
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  onClick = @() null
  children = @() {
    watch = safeAreaBorders
    size = FLEX
    margin = safeAreaBorders.get()
    halign = ALIGN_CENTER
    children = {
      size = const [PROFILE_WIDTH, FLEX]
      flow = FLOW_VERTICAL
      margin = [bigOffset, 0]
      padding = [bigOffset, bigPadding]
      halign = ALIGN_CENTER
      rendObj = ROBJ_WORLD_BLUR
      fillColor = panelBgColor
      children = [
        content
        Regular(loc("Ok"), mkCloseButtonCb(key), {
          hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
        })
      ]
    }
  }
})


function onPortraitClick(portraitCfg, isEnabled) {
  let { guid = "", buyData = null } = portraitCfg

  if (isEnabled) {
    removeModalWindow(PORTRAIT_WND_UID)
    if ((chosenPortrait.get()?.guid ?? "") != guid)
      chooseDecorator("portrait", guid)
    return
  }

  let { currencyId = "", price = 0 } = buyData
  if (currencyId != "" && price > 0) {
    purchaseMsgBox({
      price
      currencyId
      description = loc("buyPortraitConfirm")
      productView = mkPortraitFrame(portraitCfg)
      purchase = @() buyDecorator(guid, price)
      alwaysShowCancel = true
      srcComponent = "buy_decorator"
    })
    return
  }

  let locId = $"decorator/{portraitCfg.guid}/tip"
  showMsgbox(doesLocTextExist(locId) ? loc(locId) : loc("decorator/eventRewardTip"))
}


function portraitListUi() {
  let availList = availPortraits.get()
  let portraitList = [basePortrait].extend(portraitCfgAvailable.get())
  let curPurchase = decoratorInPurchase.get()
  let unseen = seenDecorators.get()?.unseen ?? {}
  let chosenGuid = chosenPortrait.get()?.guid ?? ""
  return {
    watch = [portraitCfgAvailable, availPortraits, decoratorInPurchase, seenDecorators, chosenPortrait]
    size = [portraitListWidth, FLEX]
    flow = FLOW_VERTICAL
    gap = midPadding
    margin = [0,0,bigOffset,0]
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("selectPortraitTitle")
        padding = [0, 0, tinyOffset, 0]
        hplace = ALIGN_CENTER
      }.__update(fontHeading2)
      makeVertScroll({
        size = FLEX_H
        children = wrap(portraitList.map(function(portraitCfg) {
          let { guid = "" } = portraitCfg
          let isSelected = guid == chosenGuid
          let receivedData = guid == ""
            ? null : availList.findvalue(@(p) p.guid == guid)

          let isEnabled = guid == "" || receivedData != null
          let expireTime = receivedData?.expireTime ?? 0
          let isUnseen = guid in unseen
          let onClick = @() onPortraitClick(portraitCfg, isEnabled)
          function onHover(on) {
            if (!isEnabled)
              setTooltip(on ? mkTooltip(portraitCfg) : null)
            if (isUnseen)
              hoverHoldAction("merkSeenDecorator", guid, @(v) markSeenDecorator(v))(on)
          }
          let icon = !isEnabled ? fa["lock"]
            : isSelected ? fa["check"]
            : null

          return {
            children = [
              mkPortraitFrame(portraitCfg, isEnabled, onClick, onHover, icon)
              !isEnabled ? mkPortraitCost(portraitCfg)
                : expireTime > 0 ? mkExpireTime(expireTime, {
                    rendObj = ROBJ_SOLID
                    color = defBgColor
                  })
                : null
              curPurchase == guid ? waitingSpinner : null
              isUnseen ? smallUnseenNoBlink : null
            ]
          }
        }), {
          width = portraitListWidth
          hGap = midPadding
          vGap = midPadding
        })}, {
          styling = thinStyle
          xmbNode = XmbContainer({
            canFocus = false
            scrollSpeed = 5.0
            isViewport = true
          })
        }
      )
    ]
  }
}


let mkEditButton = @(locId, action, hotkeys)
  Regular(@(_textField, params, handler, group, sf)
    textButtonTextCtor({
      margin = [0, smallOffset]
      flow = FLOW_HORIZONTAL
      gap = midPadding
      children = [
        mkIcon(fa["pencil"], textColor(sf) )
        {
          rendObj = ROBJ_TEXT
          text = loc(locId)
          color = textColor(sf)
        }.__update(fontSub)
      ]
    }, params, handler, group, sf), action, { hotkeys }
  )


let mkChangeNickFrameBtn = @(hasUnseen, hasUnopened) {
  children = [
    mkEditButton("profile/changeNameDecorator",
      function onClick() {
        markDecoratorsOpened(unopenedNickFrames.get().map(@(v) v.guid))
        openFrameWnd(NICKFRAME_WND_UID, nickFrameListUi)
      }, [["^J:X"]])
    hasUnopened ? smallUnseenBlink
      : hasUnseen ? smallUnseenNoBlink
      : null
  ]
}


function nickNameUi() {
  let chosenGuid = chosenNickFrame.get()?.guid
  let userName = userInfo.get()?.nameorig ?? ""
  let nickFrame = nickFramesConfig.get().findvalue(@(p) p.guid == chosenGuid)
  let nickName = nickFrame?.viewCb(userName) ?? userName
  return {
    watch = [ userInfo, chosenNickFrame, nickFramesConfig ]
    size = const [SIZE_TO_CONTENT, FLEX]
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXT
      text = nickName
      color = titleTxtColor
    }.__update(fontBody)
  }
}


function portraitUi() {
  let chosenGuid = chosenPortrait.get()?.guid
  let portraitCfg = portraitsConfig.get().findvalue(@(p) p.guid == chosenGuid) ?? basePortrait
  function onClick() {
    markDecoratorsOpened(unopenedPortraits.get().map(@(v) v.guid))
    openFrameWnd(PORTRAIT_WND_UID, portraitListUi)
  }
  let hasUnseen = hasUnseenPortraits.get()
  let hasUnopened = unopenedPortraits.get().len() > 0
  return {
    watch = [chosenPortrait, portraitsConfig, hasUnseenPortraits, unopenedPortraits]
    children = [
      mkPortraitFrame(portraitCfg, true, onClick,
        @(on) setTooltip(on ? loc("profile/changePortraitDecorator") : null), fa["pencil"])
      !hasUnseen ? null
        : hasUnopened ? smallUnseenBlink
        : smallUnseenNoBlink
    ]
  }
}


function nickNameButtonsUi() {
  let hasUnseen = hasUnseenNickFrames.get()
  let hasUnopened = unopenedNickFrames.get().len() > 0
  return {
    watch = [ hasUnseenNickFrames, unopenedNickFrames ]
    size = const [SIZE_TO_CONTENT, FLEX]
    flow = FLOW_VERTICAL
    gap = midPadding
    valign = ALIGN_CENTER
    children = [
      nickNameUi
      mkChangeNickFrameBtn(hasUnseen, hasUnopened)
      !is_pc || is_gdk || isChineseVersion ? null
        : mkEditButton("profile/changeNick", @() openUrl(changeNickUrl), [["^J:Y"]])
    ]
  }
}


let decoratorBlock = {
  size = const [FLEX, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    portraitUi
    nickNameButtonsUi
  ]
}


return {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  padding = bigPadding
  rendObj = ROBJ_SOLID
  color = blurBgFillColor
  children = [
    decoratorBlock
    mkRatingBlock(playerRank, @() curTabIdx.set(1))
  ]
}
