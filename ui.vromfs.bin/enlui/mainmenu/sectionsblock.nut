import "%ui/control/gui_buttons.nut" as JB
import "%ui/mainMenu/profileInfoBlock.nut" as profileInfoBlock
from "%ui/mainMenu/sectionsState.nut" import sectionsSorted, curSection, trySwitchSection, tryBackSection, sectionsGeneration, Section
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/designConst.nut" import largePadding, midPadding, navHeight
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/components/mkTab.nut" import mkTab, backgroundMarker
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkWatchedButton
from "%ui/researches/researchesState.nut" import selectedTable
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/ui_library.nut" import *

let { armySelectUi } = require("%ui/soldiers/army_select.ui.nut")

let getFirstSectionId = @() sectionsSorted.findvalue(@(v) v != null)?.id
let isFirstSection = Computed(@() curSection.get() == getFirstSectionId())

let goToFirstSection = {
  key ="back"
  hotkeys = [[$"^{JB.B} | Esc", {
    action = @() tryBackSection(getFirstSectionId())
    description = loc("BackBtn")
  }]]
}

let sectionsHotkeys = @() {
  watch = isFirstSection
  children = isFirstSection.get() ? null : goToFirstSection
}

function changeTab(delta, isLooped = false) {
  let filtered = sectionsSorted.filter(@(val) val?.selectable ?? true)
  let next_idx = (filtered.findindex(@(val) val.id == curSection.get()) ?? 0) + delta
  let total = filtered.len()
  let tabId = filtered[ isLooped
    ? ((next_idx + total) % total)
    : clamp(next_idx, 0, total - 1)
  ].id
  trySwitchSection(tabId)
}

let changeTabWrap = @(delta) changeTab(delta, true)

let maintabs = {
  size = FLEX_V
  valign = ALIGN_BOTTOM
  halign = ALIGN_LEFT
  hplace = ALIGN_LEFT
  children = [
    @() {
      watch = sectionsGeneration
      size = FLEX_V
      flow = FLOW_HORIZONTAL
      gap = midPadding
      halign = ALIGN_LEFT
      valign = ALIGN_BOTTOM
      hplace = ALIGN_LEFT
      children = sectionsSorted.map(function(section){
        let action = section?.onClickCb ?? @() trySwitchSection(section.id)
        return mkTab(section, action, curSection)
      })
    }
    backgroundMarker
  ]
}

let pageBySection = {
  [Section.MAIN] = Tutorial.MAIN,
  [Section.GROWTH] = Tutorial.RESEARCH,
}

let curScreenPage = Computed(function() {
  let section = curSection.get()

  let page = pageBySection?[section]
  if (page)
    return page

  if (section == Section.RESEARCHES && selectedTable.get() == 0)
    return Tutorial.UPGRADES

  return null
})

let jbwrap = @(children) { children, padding = const [hdpx(10),0,0,0]}
let lb = jbwrap(mkHotkey("^J:LB", @() changeTab(-1)))
let rb = jbwrap(mkHotkey("^J:RB", @() changeTab(1)))

let sectionsUi = @() {
  size = FLEX
  watch = isGamepad
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = largePadding
  children = [
    isGamepad.get() ? lb : null
    maintabs
    isGamepad.get() ? rb : null
    {
      hotkeys = [
        ["^Tab", @() changeTabWrap(1)],
        ["^L.Shift Tab | R.Shift Tab", @() changeTabWrap(-1)]
      ]
    }
    {
      vplace = ALIGN_BOTTOM
      children = mkWatchedButton(curScreenPage)
    }
  ]
}


let navHeader = {
  size = FLEX_H
  halign = ALIGN_CENTER
  children = [
    {
      size = [FLEX, navHeight]
      flow = FLOW_HORIZONTAL
      children = [
        sectionsUi
        profileInfoBlock
        sectionsHotkeys
      ]
    }
    armySelectUi
  ]
}

return navHeader
