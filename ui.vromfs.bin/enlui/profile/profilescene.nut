import "%ui/control/gui_buttons.nut" as JB
import "%ui/profile/boostersUi.nut" as boostersUi
import "%ui/profile/playerCardUi.nut" as playerCardUi
import "%ui/components/mkWindowTab.nut" as mkWindowTab
import "%ui/components/spinner.nut" as spinner
import "%ui/profile/medalsUi.nut" as medalsUi
import "%ui/profile/replayCardUi.nut" as replayCardUi
import "%ui/profile/ranksUi.nut" as ranksUi
import "%ui/unlocks/achievementsBlockUI.nut" as achievementsBlockUI
import "%ui/unlocks/weeklyUnlocksUi.nut" as weeklyUnlocksUi
import "%ui/profile/wallpostersUi.nut" as wallpostersUi

from "%sqstd/string.nut" import utf8ToUpper
from "%ui/profile/profileState.nut" import isProfileOpened, isRanksInfoVisible, curTabIdx
from "%ui/profile/medalsState.nut" import hasMedals
from "%ui/unlocks/taskListState.nut" import achievementsList, hasAchievementsReward, receiveTaskRewardsAll
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/profile/wallpostersState.nut" import isWpHidden, wpIdSelected
from "%ui/style/designConst.nut" import transpBgColor, darkBgColor, defBgColor, bigPadding, midPadding, smallPadding, accentTitleTxtColor
  , activeTxtColor, darkTxtColor
from "%ui/profile/unseenProfileState.nut" import hasUnseenMedals, hasUnopenedMedals, hasUnseenDecorators, hasUnopenedDecorators, hasUnseenWallposters, hasUnopenedWallposters
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/unlocks/weeklyUnlocksState.nut" import weeklyTasks, saveFinishedWeeklyTasks
from "%ui/replay/replaySettings.nut" import isReplayTabHidden
from "%ui/components/unseenComps.nut" import BLINK, NO_BLINK
from "%ui/unlocks/unseenUnlocksState.nut" import hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
from "%ui/profile/rankState.nut" import rankStatusText, hasRankReward
from "%ui/userstats/userstat.nut" import unlockRewardsInProgress
from "%ui/ui_library.nut" import *
from "%ui/hud/state/replay_state.nut" import isReplay


const WND_UID = "profileWindow"


let waitingSpinner = spinner()

function mkBtnGetAllRewards(data) {
  let showBtnWatch = Computed(function() {
    local count = 0
    foreach (u in data.get()) {
      if (u.hasReward)
        ++count
      if (count > 1)
        return true
    }
    return false
  })

  return function() {
    if (!showBtnWatch.get())
      return {watch = showBtnWatch}

    return {
      watch = [showBtnWatch, unlockRewardsInProgress]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = unlockRewardsInProgress.get().len() > 0
        ? waitingSpinner
        : Primary(loc("bp/getAllReward"), @() receiveTaskRewardsAll(data.get()), {
            hotkeys = [["^J:X | Enter | Space", { skip = true }]]
          })
    }
  }
}


let txtColor = @(sf, color) sf & S_ACTIVE ? activeTxtColor
  : sf & S_HOVER ? darkTxtColor
  : color


let mkTabText = @(txt, override) {
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(txt)
}.__update(fontBody, override)

let mkTabNote = @(txt, override) {
  pos = const [0, -hdpx(8)]
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(txt)
}.__update(fontSub, override)


let tabsList = [
  {
    id = "playerCard"
    locId = "profile/playerCardTab"
    content = playerCardUi
    unseenMarkType = Computed(@() hasUnopenedDecorators.get() ? BLINK
      : hasUnseenDecorators.get() ? NO_BLINK
      : null)
  }
  {
    id = "ranks"
    mkTitleComponent = @(sf, _isSelected) @() {
      watch = rankStatusText
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      margin = const [fsh(1), fsh(2)]
      children = [
        mkTabText(loc("profile/ranksTab"), { color = txtColor(sf, activeTxtColor) })
        mkTabNote(rankStatusText.get(), { color = txtColor(sf, accentTitleTxtColor) })
      ]
    }
    unseenMarkType = Computed(@() hasRankReward.get() ? NO_BLINK : null)
    content = ranksUi
  }
  {
    id = "medals"
    locId = "profile/medalsTab"
    content = medalsUi
    hideWatch = Computed(@() !hasMedals.get())
    unseenMarkType = Computed(@() !hasUnseenMedals.get() ? null
      : hasUnopenedMedals.get() ? BLINK
      : NO_BLINK)
  }
  {
    id = "wallpapers"
    locId = "profile/wallpaperTab"
    content = wallpostersUi
    hideWatch = isWpHidden
    unseenMarkType = Computed(@() !hasUnseenWallposters.get() ? null
      : hasUnopenedWallposters.get() ? "blink"
      : "noBlink")
  }
  {
    id = "boosters"
    locId = "profile/boostersTab"
    content = boostersUi
  }
  {
    id = "achievements"
    mkTitleComponent = @(sf, _isSelected) function() {
      let finished = achievementsList.get().reduce(@(s, u) u.isCompleted ? s + 1 : s, 0)
      let statusTxt = $"{finished}/{achievementsList.get().len()}"
      return {
        watch = achievementsList
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        margin = const [fsh(1), fsh(2)]
        children = [
          mkTabText(loc("profile/achievementsTab"), { color = txtColor(sf, activeTxtColor) })
          mkTabNote(statusTxt, { color = txtColor(sf, accentTitleTxtColor) })
        ]
      }
    }
    content = achievementsBlockUI
    unseenMarkType = Computed(@() !hasAchievementsReward.get() ? null
      : hasUnopenedAchievements.get() ? "blink"
      : "noBlink")
    additional = @() mkBtnGetAllRewards(achievementsList)
  }
  {
    id = "weeklyTasks"
    mkTitleComponent = @(sf, _isSelected) function() {
      local total = 0
      local finished = 0
      foreach (task in weeklyTasks.get())
        if (task?.activity.active ?? false) {
          total++
          if (task.isCompleted)
            finished++
        }
      return {
        watch = weeklyTasks
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        margin = const [fsh(1), fsh(2)]
        children = [
          mkTabText(loc("profile/weeklyTasks"), { color = txtColor(sf, activeTxtColor) })
          mkTabNote($"{finished}/{total}", { color = txtColor(sf, accentTitleTxtColor) })
        ]
      }
    }
    content = weeklyUnlocksUi
    unseenMarkType = Computed(@() !hasUnseenWeeklyTasks.get() ? null
      : hasUnopenedWeeklyTasks.get() ? "blink"
      : "noBlink")
    additional = @() mkBtnGetAllRewards(weeklyTasks)
  }
  {
    id = "replay"
    locId = "replay/records"
    content = replayCardUi
    hideWatch = isReplayTabHidden
  }
]

function switchTab(delta){
  let tabsListAmount = tabsList.len()
  local newIdx = curTabIdx.get()
  for (local i = 0; i < tabsListAmount; ++i) {
    newIdx += delta
    if (newIdx < 0)
      newIdx = tabsListAmount - 1
    else if (newIdx >= tabsListAmount)
      newIdx = 0
    let { hideWatch = null } = tabsList?[newIdx]
    if (!hideWatch?.get()) {
      curTabIdx.set(newIdx)
      return
    }
  }

  isProfileOpened.set(false)
}

let nextTab = @() switchTab(1)
let prevTab = @() switchTab(-1)

function onHideTabChanged(_) {
  let { hideWatch = null } = tabsList[curTabIdx.get()]
  if (hideWatch && hideWatch.get()) {
    switchTab(-1)
  }
}

function hideTabsSubscribe(subscribe) {
  let action = subscribe ? "subscribe" : "unsubscribe"
  foreach (tab in tabsList) {
    let { hideWatch = null } = tab
    if (hideWatch) {
      hideWatch[action](onHideTabChanged)
    }
  }
}

let tabsUi = @() {
  watch = isGamepad
  rendObj = ROBJ_SOLID
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  color = defBgColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  onAttach = @() hideTabsSubscribe(true)
  onDetach = @() hideTabsSubscribe(false)
  hotkeys = [["Tab", nextTab], ["L.Shift Tab", prevTab]]
  children = tabsList.map(function(tab, idx) {
    let hideWatch = tab?.hideWatch
    let isActive = Computed(@() curTabIdx.get() == idx)
    return function() {
      let isHidden = hideWatch && hideWatch.get()
      return {
        watch = [hideWatch, isActive]
        children = isHidden ? null
          : mkWindowTab(
              tab?.mkTitleComponent ?? loc(tab?.locId ?? ""),
              @() curTabIdx.set(idx),
              isActive.get(),
              {skipDirPadNav=true},
              tab?.unseenMarkType ?? Watched(null)
            )
      }
    }
  }).insert(0, isGamepad.get() ? mkHotkey("^J:LB", prevTab) : null)
    .append(isGamepad.get() ? mkHotkey("^J:RB", nextTab) : null)
}

function backAction() {
  if (wpIdSelected.get() != null) {
    wpIdSelected.set(null)
    return
  }
  if (isRanksInfoVisible.get()) {
    isRanksInfoVisible.set(false)
    return
  }
  isProfileOpened.set(false)
}

let tabsContentUi = @() {
  watch = [curTabIdx, isGamepad]
  size = FLEX
  flow = FLOW_VERTICAL
  gap = bigPadding
  padding = [midPadding, 0]
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  children = [
    tabsList[curTabIdx.get()].content
    {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      margin = [0, bigPadding]
      children = [
        tabsList[curTabIdx.get()]?.additional()
        isGamepad.get() ? null : Regular(loc("BackBtn"), backAction, { margin = 0 })
      ]
    }
  ]
}

let profileWindow = @() {
  watch = safeAreaBorders
  size = FLEX
  margin = safeAreaBorders.get()
  halign = ALIGN_CENTER
  onAttach = saveFinishedWeeklyTasks
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn"), action = backAction} ]]
  children = {
    size = FLEX
    flow = FLOW_VERTICAL
    margin = const [hdpx(50), hdpx(150)]
    rendObj = ROBJ_SOLID
    color = darkBgColor
    children = [
      tabsUi
      tabsContentUi
    ]
  }
}

function open() {
  addModalWindow({
    key = WND_UID
    size = FLEX
    rendObj = ROBJ_WORLD_BLUR
    fillColor = transpBgColor
    onClick = @() null
    children = profileWindow
  })
}

function close() {
  removeModalWindow(WND_UID)
}

if (isProfileOpened.get())
  open()

isProfileOpened.subscribe(@(v) v ? open() : close())
isReplay.subscribe(function(v) {
  if (v)
    isProfileOpened.set(false)
})

console_register_command(@() isProfileOpened.set(true), "ui.profileScene")

return function(tabId = "") {
  if (tabId != "") {
    let idx = tabsList.findindex(@(tab) tab.id == tabId)
    if (idx != null)
      curTabIdx.set(idx)
  }
  isProfileOpened.set(true)
}
