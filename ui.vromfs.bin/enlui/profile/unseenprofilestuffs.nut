from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/defcomps.nut" import txt
from "%ui/components/msgbox.nut" import showMessageWithContent, removeMsgboxByUid
from "%ui/meta/servProfile.nut" import decorators, medals, wallposters, vehDecorators, notifiers
from "%ui/profile/medalsPkg.nut" import mkMedalCard
from "%ui/profile/medalsState.nut" import medalsCfg
from "%ui/profile/decoratorPkg.nut" import mkPortraitIcon, mkNickFrame, PORTRAIT_SIZE
from "%ui/profile/decoratorState.nut" import decoratorsCfgByType
from "%ui/style/designConst.nut" import midPadding, titleTxtColor, tinyOffset, idleBgColor
from "%ui/meta/clientApi.nut" import mark_seen_objects
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/unlocks/dailyRewardsState.nut" import specialUnlockToReceive
from "%ui/userstats/unlocksState.nut" import activeUnlocks
from "%ui/profile/wallpostersState.nut" import wallpostersCfg
from "%ui/profile/wallpostersPkg.nut" import mkWallposter
from "%ui/vehicles/vehDecorState.nut" import vehCamouflageCfg
from "%ui/vehicles/customizePkg.nut" import getDecorConfig, getDecorName, mkCamouflageImage
from "%ui/soldiers/model/newItemsToShow.nut" import NotifyStatus
from "%ui/components/wndManager.nut" import registerWnd, Wnd, WndEvents
from "%ui/components/wndPermissionFlags.nut" import canShowNewItems, autoClose
from "%ui/ui_library.nut" import *

const UNSEEN_STUFF_WINDOW_UID = "unseenProfileMsgbox"

let unseenSize = [fsh(80), fsh(50)]

let unseenProfileStuffs = Computed(function() {
  let { portrait = {}, nickFrame = {} } = decoratorsCfgByType.get()

  let decoratorsOwned = decorators.get()
  let medalsConfig = medalsCfg.get()
  let medalsOwned = medals.get()
  let wallpostersOwned = wallposters.get()
  let vehDecoratorsOwned = vehDecorators.get()
  let camouflageCfg = vehCamouflageCfg.get()

  let portraits = []
  let nickFrames = []
  let unseenMedals = []
  let unseenWallposters = []
  let vehDecors = []
  let camouflages = []

  foreach (guid, notifier in notifiers.get()) {
    if (notifier.status != NotifyStatus.NEW)
      continue

    if (guid in medalsOwned) {
      let medal = medalsOwned[guid]
      unseenMedals.append(medal.__merge(medalsConfig?[medal.id] ?? {}))
    }
    else if (guid in portrait && guid in decoratorsOwned)
      portraits.append(decoratorsOwned[guid].__merge(portrait[guid]))
    else if (guid in nickFrame && guid in decoratorsOwned)
      nickFrames.append(decoratorsOwned[guid].__merge(nickFrame[guid]))
    else if (guid in wallpostersOwned)
      unseenWallposters.append(wallpostersOwned[guid])
    else if (guid in vehDecoratorsOwned)
      vehDecors.append(vehDecoratorsOwned[guid])
    else {
      let camoCfg = camouflageCfg.findvalue(@(cfg) guid in cfg)
      if (camoCfg != null)
        camouflages.append(camoCfg[guid].__merge({ guid }))
    }
  }

  unseenMedals.sort(@(a, b) (b?.weight ?? 0) <=> (a?.weight ?? 0))

  let res = {}.__update(
    portraits.len() > 0 || nickFrames.len() > 0 ? { portraits, nickFrames } : {},
    unseenMedals.len() > 0 ? { unseenMedals } : {},
    unseenWallposters.len() > 0 ? { unseenWallposters } : {},
    vehDecors.len() > 0 ? { vehDecors } : {},
    camouflages.len() > 0 ? { camouflages } : {})

  return res.len() == 0 ? null : res
})

let mkUnseenBlock = @(locId, children = null, fn = null, container = null)
  (children?.len() ?? 0) == 0
    ? null
    : function() {
      let { congratulationLangId = "" } = activeUnlocks.get()?[specialUnlockToReceive.get()].meta
      return {
        watch = [activeUnlocks, specialUnlockToReceive]
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = tinyOffset
        halign = ALIGN_CENTER
        children = [
          congratulationLangId == "" ? null : {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc(congratulationLangId)
            halign = ALIGN_CENTER
            color = titleTxtColor
            onDetach = @() specialUnlockToReceive.set(null)
          }.__update(fontBody)
          txt({
            text = loc(locId)
            color = titleTxtColor
          }).__update(fontBody)
          container?(children, fn)
        ]
      }
    }

let wrapParams = {
  width = unseenSize[0]
  halign = ALIGN_CENTER
  hGap = midPadding
  vGap = midPadding
}

let vehDecorOverride = { iconSize = PORTRAIT_SIZE - 2 * midPadding }

let mkCamouflage = @(camoCfg) {
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = const [PORTRAIT_SIZE, PORTRAIT_SIZE]
      padding = midPadding
      borderColor = idleBgColor
      children = mkCamouflageImage(camoCfg, vehDecorOverride)
    }
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc($"skin/{camoCfg?.id}")
      maxWidth = PORTRAIT_SIZE * 1.5
      halign = ALIGN_CENTER
      color = titleTxtColor
    }.__update(fontBody)
  ]
}

function mkVehDecor(vehDecor) {
  let { cType } = vehDecor
  let { iconCtor = null } = getDecorConfig(cType)
  if (iconCtor == null)
    return null

  return {
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_BOX
        borderWidth = hdpx(1)
        size = const [PORTRAIT_SIZE, PORTRAIT_SIZE]
        padding = midPadding
        borderColor = idleBgColor
        children = iconCtor(vehDecor, vehDecorOverride)
      }
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = getDecorName(vehDecor)
        maxWidth = PORTRAIT_SIZE * 1.5
        halign = ALIGN_CENTER
        color = titleTxtColor
      }.__update(fontBody)
    ]
  }
}

let mkPortrait = @(portraitCfg) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  size = const [PORTRAIT_SIZE, PORTRAIT_SIZE]
  borderColor = idleBgColor
  children = mkPortraitIcon(portraitCfg)
}

let nickFrameCb = @(nickFrameCfg) mkNickFrame(nickFrameCfg?.viewCb)

function mkMedal(medal) {
  let { bgImage = null, stackImages = [] } = medal
  return mkMedalCard(bgImage, stackImages, PORTRAIT_SIZE)
}

let isMarkSeenInProgress = Watched(false)

function markSeen() {
  let unseen = unseenProfileStuffs.get()
  if (isMarkSeenInProgress.get() || unseen == null)
    return

  let guids = []
  foreach (itemCollection in unseen)
    itemCollection.each(@(v) guids.append(v.guid))

  if (guids.len() > 0) {
    isMarkSeenInProgress.set(true)
    mark_seen_objects(guids, @(_) isMarkSeenInProgress.set(false))
  }
}

let withWrap = @(children, fn) wrap(children.map(fn), wrapParams)

let wallposterContainer = @(posters, fn) function() {
  let wpCfgs = wallpostersCfg.get()
  return {
    watch = wallpostersCfg
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    children = posters.map(function(wallposter) {
      let wpCfg = wpCfgs.findvalue(@(wp) wp.id == wallposter.tpl)
      return wpCfg == null ? null : fn(wpCfg)
    })
  }
}

let unseenItemsConfig = [
  {
    id = "portraits"
    locId = "unseenPortraitsTitle"
    fn = mkPortrait
  }
  {
    id = "nickFrames"
    locId = "unseenNickFramesTitle"
    fn = nickFrameCb
  }
  {
    id = "vehDecors"
    locId = "unseenVehDecorsTitle"
    fn = mkVehDecor
  }
  {
    id = "camouflages"
    locId = "vehCamouflageHeader"
    fn = mkCamouflage
  }
  {
    id = "unseenMedals"
    locId = "unseenMedalsTitle"
    fn = mkMedal
  }
  {
    id = "unseenWallposters"
    locId = "unseenWallpostersTitle"
    fn = mkWallposter
    container = wallposterContainer
  }
]

let mkUnseenContent = @(allItems, override = {}) {
  flow = FLOW_VERTICAL
  size = FLEX_H
  gap = tinyOffset
  vplace = ALIGN_TOP
  children = unseenItemsConfig.map(function(cfg) {
    let { id = "", locId = "", fn = @(_) null, container = withWrap } = cfg
    return mkUnseenBlock(locId, allItems?[id], fn, container)
  })
}.__update(override)

function open() {
  showMessageWithContent({
    uid = UNSEEN_STUFF_WINDOW_UID
    content = function() {
      let allItems = unseenProfileStuffs.get()
      let {
        portraits = [], nickFrames = [], vehDecors = [], unseenMedals = [],
        unseenWallposters = [], camouflages = []
      } = allItems
      let total = portraits.len() + nickFrames.len() + unseenMedals.len()
        + vehDecors.len() + camouflages.len()

      let hasScroll = total > (unseenSize[0] / PORTRAIT_SIZE) * 2
        || (unseenWallposters.len() > 2)
      return {
        watch = unseenProfileStuffs
        size = hasScroll ? unseenSize : [unseenSize[0], SIZE_TO_CONTENT]
        children = hasScroll
          ? makeVertScroll(mkUnseenContent(allItems), { styling = thinStyle })
          : mkUnseenContent(allItems, { vplace = ALIGN_CENTER })
      }
    }
    buttons = [{
      text = loc("Ok"), isCurrent = true, isCancel = true, action = markSeen
    }]
  })
}

function close() {
  removeMsgboxByUid(UNSEEN_STUFF_WINDOW_UID)
}

let needOpenWindow = registerWnd({
  dataWatch = Computed(@() unseenProfileStuffs.get() != null)
  showWatch = canShowNewItems
  closeWatch = autoClose
  name = Wnd.PROFILE_ITEMS
  order = [Wnd.ITEMS]
  handlers = { [WndEvents.SUPPRESS] = markSeen }
})
needOpenWindow.subscribe(@(v) v ? open() : close())
