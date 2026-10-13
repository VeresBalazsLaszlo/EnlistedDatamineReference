import "%ui/control/gui_buttons.nut" as JB
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
from "%ui/components/textButton.style.nut" import TextNormal, TextHover, textMargin
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/style/colors.nut" import HighlightFailure
from "%ui/style/buttonsStyle.nut" import purchaseButtonStyle
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/currency/currencies.nut" import currenciesById, currenciesBalance
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/purchaseMsgBox.nut" import buyCurrencyText, currencyImage
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/researches/researchesState.nut" import buySquadLevel, buySquadMaxLevel, curSquadProgress
from "%ui/ui_library.nut" import *

let { openShopByCurrencyId } = require("%ui/currency/purchaseMsgBox.nut")


const CURRENCY_ID = "EnlistedGold"

let mkBuyCurrencyBtn = @(currency, action) {
  text = @(_textComp, _params, handler, group, sf)
    textButtonTextCtor(buyCurrencyText(currency, sf), fontHeading2, handler, group, sf)
  action
  customStyle = { hotkeys = [[$"^{JB.A} | Esc"]] }
}

function showNotEnoughMoney(needMoreCurrency) {
  let currency = currenciesById.get()?[CURRENCY_ID]

  showMessageWithContent({
    content = {
      flow = FLOW_HORIZONTAL
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("shop/notEnoughCurrency", { priceDiff = needMoreCurrency })
        }.__update(fontHeading2, { color = HighlightFailure })
        currencyImage(currency)
      ]
    }
    buttons = [
      mkBuyCurrencyBtn(currency, @() openShopByCurrencyId?[CURRENCY_ID]())
      {
        text = loc("Cancel")
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}

let mkBuyButton = @(txt, currency, action) {
  text = @(_textField, params, handler, group, sf)
    textButtonTextCtor({
      children = {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        margin = textMargin
        children = mkTextRow(txt,
          @(text) {
            rendObj = ROBJ_TEXT
            color = sf & S_HOVER ? TextHover : TextNormal
            text
          }.__update(fontBody),
          {
            ["{cost}"] = mkCurrency( 
              currency.__update({ 
                txtStyle = {
                  color = sf & S_HOVER ? TextHover : TextNormal
                }.__update(fontBody)
              }))
          })
      }
    }, params, handler, group, sf)
  action
  customStyle = purchaseButtonStyle
}

function onSuccessCb(isSuccess) {
  if (!isSuccess)
    return
  sound_play("ui/purchase_level_squad")
}

function buyLevelsMsgbox() {
  let { level = 0, levelCost = 0, maxLevel = 0, maxLevelCost = 0 } = curSquadProgress.get()

  let needMoneyToBuyLevel = levelCost - (currenciesBalance.get()?[CURRENCY_ID] ?? 0)
  let buyLevelAction = needMoneyToBuyLevel <= 0
    ? @() buySquadLevel(onSuccessCb)
    : @() showNotEnoughMoney(needMoneyToBuyLevel)

  let needMoneyToBuyMaxLevel = maxLevelCost - (currenciesBalance.get()?[CURRENCY_ID] ?? 0)
  let buyMaxLevelAction = needMoneyToBuyMaxLevel <= 0
    ? @() buySquadMaxLevel(onSuccessCb)
    : @() showNotEnoughMoney(needMoneyToBuyMaxLevel)

  let buttons = []

  if (level + 1 < maxLevel)
    buttons.append(mkBuyButton(loc("squad/buyLevel", { level = level + 2 }), {
      currency = currenciesById.get()?[CURRENCY_ID]
      price = levelCost
      fullPrice = levelCost
    }, buyLevelAction))

  buttons.append(mkBuyButton(loc("squad/buyMaxLevel", { level = maxLevel + 1 }), {
    currency = currenciesById.get()?[CURRENCY_ID]
    price = maxLevelCost
    fullPrice = maxLevelCost
  }, buyMaxLevelAction))

  buttons.append({
    text = loc("Cancel")
    isCancel = true
    customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
  })

  showMessageWithContent({
    content = {
      size = const [sw(90), fsh(32)]
      children = [
        {
          rendObj = ROBJ_TEXT
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          text = loc("buy/squadLevelConfirm")
        }.__update(fontHeading2)
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = currenciesWidgetUi
        }
      ]
    }
    buttons
  })
}

return buyLevelsMsgbox
