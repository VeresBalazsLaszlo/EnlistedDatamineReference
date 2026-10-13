import "%ui/userstats/serverTime.nut" as serverTime
import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/meta/clientApi.nut" import usermail_check, usermail_list, usermail_take_reward, usermail_reset_reward
from "%ui/state/appState.nut" import isInBattleState
from "eventbus" import eventbus_subscribe, eventbus_send
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/notifications/matchingNotifications.nut" import subscribe
from "%ui/ui_library.nut" import *

const MAX_AMOUNT = 20
const MAX_LIFETIME = 30 * 24 * 60 * 60
const soundNewMail = "ui/enlist/notification"

let letters = mkWatched(persist, "letters", [])
let lastTime = mkWatched(persist, "lastTime", 0)

let isRequest = Watched(false)
let isUsermailWndOpened = mkWatched(persist, "isUsermailWndOpened", false)
let selectedLetterIdx = mkWatched(persist, "selectedLetterIdx", -1)
let unseenLettersCount = mkWatched(persist, "unseenLettersCount", 0)

serverTime.subscribe(function(ts) {
  if (ts <= 0)
    return
  serverTime.unsubscribe(callee())
  lastTime.set(ts - MAX_LIFETIME)
})

function markUnseenLetters(count) {
  if (isRequest.get())
    return
  unseenLettersCount.set(count)
  if (!isInBattleState.get())
    sound_play(soundNewMail)
}

function onCheckMail(result) {
  isRequest.set(false)
  let { newMailCount = 0 } = result
  if (newMailCount > 0)
    markUnseenLetters(newMailCount)
}

function checkNewMail() {
  if (isRequest.get())
    return
  isRequest.set(true)
  usermail_check(lastTime.get(), onCheckMail)
}

let isDataReady = keepref(Computed(@() userInfo.get() != null && lastTime.get() > 0))
isDataReady.subscribe(function(value) {
  if (value)
    checkNewMail()
})

eventbus_subscribe("matching.notify_new_mail", @(...) checkNewMail())
subscribe("profile", @(event) event?.func == "newmail" ? checkNewMail() : null)

function closeUsermailWindow() {
  isUsermailWndOpened.set(false)
  unseenLettersCount.set(0)
  selectedLetterIdx.set(-1)
}

function onLettersUpdate(result) {
  isRequest.set(false)
  let { usermail = [] } = result
  if (usermail.len() == 0)
    return

  letters.mutate(function(list) {
    foreach (letter in usermail) {
      let idx = list.findindex(@(prev) prev.guid == letter.guid)
      if (idx == null)
        list.append(letter)
      else
        list[idx] = letter
    }
    list.sort(@(a, b) b.cTime <=> a.cTime)
  })
}

function requestLetters(forceUpdate = false) {
  if (isRequest.get())
    return

  isRequest.set(true)
  let ts = lastTime.get()
  lastTime.set(serverTime.get())
  usermail_list(forceUpdate ? 0 : ts, MAX_AMOUNT, onLettersUpdate)
}

function takeLetterReward(guid) {
  if (isRequest.get())
    return

  isRequest.set(true)
  usermail_take_reward(guid, onLettersUpdate)
}


console_register_command(@() requestLetters(true), "usermail.request")
console_register_command(takeLetterReward, "usermail.getReward")
console_register_command(@() usermail_reset_reward(onLettersUpdate), "usermail.resetReward")
console_register_command(
  function(reward) {
    let letter = {
      guid = serverTime.get()
      text = $"New mail received, mail in mailbox № {letters.get().len() + 1}"
      cTime = serverTime.get()
    }
    if (reward != null && reward.tointeger() > 0)
      letter.__update({
        reward
        endTime = serverTime.get() + 1000
      })
    letters.mutate(@(v) v.insert(0, letter))
    eventbus_send("matching.notify_new_mail", null)
  },
  "usermail.newMail"
)

return {
  letters
  requestLetters
  takeLetterReward
  isRequest
  isUsermailWndOpened
  selectedLetterIdx
  closeUsermailWindow
  unseenLettersCount
}
