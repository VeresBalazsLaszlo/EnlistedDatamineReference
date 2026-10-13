from "%ui/navState.nut" import doesSceneExist, scenesListGeneration
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/growth/growthState.nut" import reqGrowthId, setCurGrowthTier
from "%ui/ui_library.nut" import *

enum Section {
  MAIN = "soldiers"
  RESEARCHES = "researches"
  GROWTH = "growth"
  SHOP = "shop"
  STORE = "store"
  EVENT = "event"
}

let curSection = mkWatched(persist, "curSection")
let sectionsGeneration = mkWatched(persist, "sectionsGeneration", 0)
let isMainMenuVisible = Watched(false)
let sectionsSorted = []

let curSectionDetails = Computed(function() {
  let section = doesSceneExist(scenesListGeneration.get(), sectionsGeneration.get()) || sectionsSorted.len()==0
    ? null
    : sectionsSorted.findvalue(@(s) s?.id == curSection.get())
  if (section==null)
    return null
  return {camera=section.camera }
})

function setSectionsSorted(sections){
  let found = {}
  foreach (k, v in sections) {
    if (v?.id==null)
      v.id<-k
    if (v.id in found){
      assert(false, "id of sections should be unique")
      v.id<-k
    }
    found[v.id] <- null
  }
  sectionsSorted.clear()
  sectionsSorted.extend(sections)
  if (!sectionsSorted.findvalue(@(s) s?.id == curSection.get()))
    curSection.set(sectionsSorted?[0].id)
  sectionsGeneration.modify(@(v) v + 1)
}

function setCurSection(id) {
  let section = sectionsSorted.findvalue(@(s) s?.id == id)
  if (section == null)
    return
  curSection.set(id)
}

function jumpToArmyGrowth(growthId = null) {
  reqGrowthId.set(growthId)
  setCurSection(Section.GROWTH)
}

function jumpToArmyGrowthTier(growthTier) {
  setCurGrowthTier(growthTier)
  setCurSection(Section.GROWTH)
}

function jumpToResearches() {
  setCurSection(Section.RESEARCHES)
}

let hasMainSectionOpened = Computed(@() curSection.get() == Section.MAIN)

function trySwitchSection(sectionId) {
  let { onExitCb = @() true } = sectionsSorted.findvalue(@(s) s?.id == curSection.get())
  if (onExitCb()) {
    setCurSection(sectionId)
    sound_play("ui/enlist/button_click")
  }
}

function tryBackSection(sectionId) {
  let { onBackCb = @() true } = sectionsSorted.findvalue(@(s) s?.id == curSection.get())
  if (onBackCb())
    trySwitchSection(sectionId)
}

return {
  Section
  curSection = Computed(@() curSection.get())
  curSectionDetails
  sectionsSorted
  sectionsGeneration
  setSectionsSorted
  setCurSection
  isMainMenuVisible

  jumpToArmyGrowth
  jumpToArmyGrowthTier
  jumpToResearches

  hasMainSectionOpened
  trySwitchSection
  tryBackSection
}
