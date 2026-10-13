import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/items/itemsMapping.nut" as rewardsItemMapping
import "%ui/components/spinner.nut" as spinner
import "%ui/components/mkWindowTab.nut" as mkWindowTab
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/style/designConst.nut" import midPadding, smallPadding, defInsideBgColor, defTxtColor, blurBgFillColor, activeTxtColor, maxContentWidth
  , airBgColor, opaqueBgColor
from "%ui/components/textButton.nut" import Regular
from "%ui/usermail/usermailState.nut" import letters, requestLetters, takeLetterReward, isRequest, closeUsermailWindow, isUsermailWndOpened, selectedLetterIdx
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/battlepass/rewardsPkg.nut" import mkSeasonTime, prepareRewards, mkRewardBlock
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/ui_library.nut" import *

const mailPadding = hdpx(15)
const mailmidPadding = hdpx(40)
const MAIL_WND_WIDTH = fsh(100)
let waitingSpinner = spinner()

let listBgColor = @(sf, isSelected) isSelected ? opaqueBgColor
  : sf & S_HOVER ? defInsideBgColor
  : blurBgFillColor
let listTxtColor = @(sf, isSelected) isSelected ? activeTxtColor
  : sf & S_HOVER ? Color(200,200,200)
  : defTxtColor

let noMessagesTitle = {
  rendObj = ROBJ_TEXT
  size = FLEX_H
  halign = ALIGN_CENTER
  color = activeTxtColor
  text = loc("mail/no_messages")
}.__update(fontBody)

let expiredReward = @() showMsgbox({
  text = loc("mail/rewardExpired"),
  buttons = [{ text = loc("Ok"), isCurrent = true }]
})

function mkRewards(rewards, hasReceived = true) {
  if (rewards.len() == 0)
    return null

  return @() {
    watch = rewardsItemMapping
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = prepareRewards(rewards, rewardsItemMapping.get())
      .map(@(reward) mkRewardBlock(reward, hasReceived))
  }
}

function messageRow(message, idx) {
  let { text, guid, cTime, isReceived = false, endTime = 0, rewards = [] } = message
  let canReceive = Computed(@() !isReceived && (endTime == 0 || endTime > serverTime.get()))
  let isSelected = Computed(@() selectedLetterIdx.get() == idx)
  return watchElemState(function(sf) {
    if (cTime > serverTime.get())
      return null
    let cb = canReceive.get() ? @() takeLetterReward(guid) : expiredReward
    return {
      rendObj = ROBJ_SOLID
      watch = [selectedLetterIdx, canReceive, isSelected]
      size = FLEX_H
      behavior = Behaviors.Button
      flow = FLOW_VERTICAL
      padding = mailPadding
      onClick = @() selectedLetterIdx.set(idx)
      gap = mailmidPadding
      clipChildren = true
      color = listBgColor(sf, isSelected.get())
      children = [
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          children = [
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              size = FLEX_H
              textOverflowY = TOVERFLOW_LINE
              text = loc(text)
              color = listTxtColor(sf, isSelected.get())
            }.__update(fontBody)
            !isReceived ? mkSeasonTime(endTime) : null
          ]
        }
        rewards.len() == 0 ? null : {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          valign = ALIGN_BOTTOM
          gap = midPadding
          children = [
            mkRewards(rewards, isReceived)
            isReceived ? null : Regular(loc("mainmenu/receive"), cb)
          ]
        }
      ]
    }
  })
}


let backBtn = Regular(loc("BackBtn"), closeUsermailWindow, {
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
})

let lettersBlock = @(lettrs) lettrs.len() <= 0 ? noMessagesTitle
  : makeVertScroll(
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = {
        rendObj = ROBJ_SOLID
        size = const [FLEX, hdpx(2)]
        color = airBgColor
      }
      children = lettrs.map(@(val, idx) messageRow(val, idx))
    },
    {
      size = FLEX
      styling = thinStyle
    }
)

function centralBlock(){
  let children = []
  if (letters.get().len() > 0)
    children.append(lettersBlock(letters.get()))
  else if (!isRequest.get())
    children.append(noMessagesTitle)
  if (isRequest.get())
    children.append(waitingSpinner)
  return {
    watch = [letters, isRequest]
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = isRequest.get() ? waitingSpinner : lettersBlock(letters.get())
  }
}

let mailTab = {
  id = "mailTab"
  locId = "mail/mailTab"
  content = centralBlock
}

let topBlock = mkWindowTab(loc(mailTab.locId), @() null, true)

let mailWindow = {
  size = const [MAIL_WND_WIDTH, FLEX]
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  padding = const [fsh(5), 0]
  gap = hdpx(25)
  flow = FLOW_VERTICAL
  children = [
    topBlock
    centralBlock
    backBtn
  ]
}

function openMailWindow(){
  requestLetters()
  sceneWithCameraAdd(mailWindow, "events")
}

if (isUsermailWndOpened.get())
  openMailWindow()

isUsermailWndOpened.subscribe(@(v) v ? openMailWindow() : sceneWithCameraRemove(mailWindow))
