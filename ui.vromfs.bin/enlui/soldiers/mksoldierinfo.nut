import "%ui/soldiers/soldierEquip.ui.nut" as soldierEquipUi
import "%ui/soldiers/soldierLook.ui.nut" as soldierLookUi
import "%ui/components/mkNameBlock.nut" as mkNameBlock
from "%enlSqGlob/appInfo.nut" import isDebugBuild
from "%ui/style/designConst.nut" import smallPadding, bigPadding, soldierWndWidth
from "%ui/preset/presetEquipUi.nut" import closeEquipPresets
from "%ui/state/client_user_rights.nut" import hasClientPermission
from "%ui/components/textButton.nut" import Regular, FARegular
from "%ui/soldiers/soldierCustomizationState.nut" import isCustomizationWndOpened
from "%ui/meta/perks/perkTree.nut" import openPerkTree, openPerkList
from "%ui/helpers/metalink.nut" import getLinkedSquadGuid
from "%ui/soldiers/model/soldierPerks.nut" import notChosenPerkSoldiers
from "%ui/components/soldiersUiComps.nut" import mkAlertIcon, PERK_ALERT_SIGN
from "%ui/ui_library.nut" import *

let hasDebugSoldierLook = hasClientPermission("debug_soldier_look")
let canSwitchSoldierLook = Computed(@() hasDebugSoldierLook.get() || isDebugBuild)

let soldierLookOpened = Watched(false)
soldierLookOpened.subscribe(@(_) closeEquipPresets())

let btnStyle = {
  btnWidth = FLEX
  rendObj = ROBJ_WORLD_BLUR_PANEL
}

let mkAnimations = @(isMoveRight) [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150) * (isMoveRight ? -1 : 1), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [hdpx(150) * (isMoveRight ? 1 : -1), 0], duration = 0.2, easing = OutQuad }
]

function mkCustomButtons(curSoldierInfo) {
  let needPerkNotifier = Computed(@() curSoldierInfo.get()?.guid in notChosenPerkSoldiers.get())
  return @() {
    watch = [canSwitchSoldierLook, curSoldierInfo]
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    gap = bigPadding
    children = [
      Regular(loc("soldierAppearance"), @() isCustomizationWndOpened.set(true), btnStyle.__merge({
        isEnabled = getLinkedSquadGuid(curSoldierInfo.get()) != null
      }))
      Regular(loc("perks/tree"), @() openPerkTree(curSoldierInfo.get().guid), btnStyle.__merge({
        fgChild = {
          vplace = ALIGN_TOP
          hplace = ALIGN_RIGHT
          children = mkAlertIcon(PERK_ALERT_SIGN, needPerkNotifier)
          padding = smallPadding
        }
      }))
      FARegular("angle-right", @(event) openPerkList(event, curSoldierInfo))
      canSwitchSoldierLook.get()
        ? FARegular("address-card", @() soldierLookOpened.set(!soldierLookOpened.get()))
        : null
    ]
  }
}

let mkSoldierEquipment = kwarg(@(
  soldier, canManage, animations, selectedKeyWatch, mkDismissBtn,
  onDoubleClickCb = null, onResearchClickCb = null, dropExceptionCb = null, buttons = null
) {
  size = [soldierWndWidth, FLEX]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = FLEX_H
      animations
      transform = true
      children = mkNameBlock(soldier)
    }
    @() {
      watch = soldierLookOpened
      size = FLEX
      children = (soldierLookOpened.get() ? soldierLookUi : soldierEquipUi)({
        soldier
        canManage
        selectedKeyWatch
        onDoubleClickCb
        dropExceptionCb
        onResearchClickCb
      }, KWARG_NON_STRICT)
    }
    function() {
      let children = mkDismissBtn(soldier.get())
      return {
        watch = soldier
        size = FLEX_H
        margin = children == null ? null : [bigPadding,0,0,0]
        children
      }
    }
    buttons
  ]
})

let mkSoldierInfo = kwarg(function(
  soldierInfoWatch, isMoveRight = true, selectedKeyWatch = Watched(null),
  onDoubleClickCb = null, onResearchClickCb = null, mkDismissBtn = @(_) null,
  dropExceptionCb = null, buttons = null
) {
  let animations = mkAnimations(isMoveRight)
  local lastSoldierGuid = soldierInfoWatch.get()?.guid

  let children = mkSoldierEquipment({
    soldier = soldierInfoWatch
    canManage = true
    animations
    selectedKeyWatch
    onDoubleClickCb
    dropExceptionCb
    onResearchClickCb
    mkDismissBtn
    buttons
  })

  return function() {
    let newSoldierGuid = soldierInfoWatch.get()?.guid
    if (lastSoldierGuid != null && newSoldierGuid != lastSoldierGuid)
      anim_start("hdrAnim") 
    lastSoldierGuid = newSoldierGuid

    let watch = soldierInfoWatch
    if (soldierInfoWatch.get() == null)
      return { watch }

    return {
      watch
      size = [soldierWndWidth, FLEX]
      children
    }
  }
})

return {
  mkSoldierInfo
  mkCustomButtons
}
