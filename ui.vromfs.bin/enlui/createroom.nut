import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/checkbox.nut" as checkbox
import "matching.errors" as matching_errors
import "%ui/components/spinner.nut" as spinner
from "%enlSqGlob/game_mods_constant.nut" import MOD_FILE_URL
from "%sqstd/timers.nut" import debounce
from "eventbus" import eventbus_subscribe
from "json" import parse_json
from "%ui/state/clientState.nut" import gameLanguage
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/permissions/permissions.nut" import checkMultiplayerPermissions
from "%ui/state/roomState.nut" import createRoom
from "%ui/components/textButton.nut" import Regular
from "%ui/components/msgbox.nut" import showMsgbox
from "string" import strip
from "%ui/mpRoom/showCreateRoom.nut" import showCreateRoom
from "%ui/clusterState.nut" import oneOfSelectedClusters
from "%ui/roomSettings.nut" import groupSize, botsPopulation, botAutoSquad, scenes, scene, roomName, minPlayers
  , maxPlayers, startOffline, writeReplay
from "%ui/gameLauncher.nut" import startGame
from "app" import get_app_id, set_matching_invite_data
from "%ui/components/selectWindow.nut" import mkSelectWindow, mkOpenSelectWindowBtn
from "dagor.fs" import scan_folder, file_exists
from "game_load" import request_ugm_manifest
from "dagor.debug" import logerr
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "%ui/game_mods.nut" import getBaseFromManifestUrl, getHashesFromManifest, requestModFiles
from "statsd" import send_counter
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/style/designConst.nut" import bigPadding, sidePadding
from "%ui/gameModes/createEventRoomCfg.nut" import isModsAvailable
from "%ui/ui_library.nut" import *
from "%darg/laconic.nut" import *
from "%ui/modFiles.nut" import USER_MODS_FOLDER, MODS_EXT, isStrHash
from "%sqstd/frp.nut" import subscribeAndInit

let textInput = require("%ui/components/textInput.nut")
let comboBox = require("%ui/components/combobox.nut")

const EVENT_MOD_VROM_INFO = "mod_info_vrom_loaded"
let playersAmountList = [1, 2, 4, 8, 12, 16, 20, 24, 32, 40, 50, 64, 70, 80, 100, 128]
let groupSizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


let usePassword = nestWatched("usePassword", false)
let password = nestWatched("password", "")
let focusedField = Watched(null)
let waitingSpinner = spinner()

function createRoomCb(response) {
  if (response.error != 0) {
    roomName.set("")
    password.set("")

    showMsgbox(loc("customRoom/failCreate",
      { responce_error = matching_errors.error_string(response?.error_id ?? response.error)}))
  }
}

function availableFields() {
  return [
    roomName,
    usePassword,
    startOffline,
    (usePassword.get() ? password : null),
  ].filter(@(val) val)
}

function checkAvailableFields(){
  local isValid = true

  foreach (f in availableFields()) {
    if (typeof(f.get())=="string" && !strip(f.get()).len()) {
      anim_start(f)
      isValid = false
      break
    }
  }
  return isValid
}

let modPath = mkWatched(persist, "modPath", "")
let urlToManifest = mkWatched(persist, "urlToManifest", "")

let manifest = Watched(null)
async function requestManifest(url) {
  manifest.set(null)

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("manifest_request_receive_errors", 1, { http_code })
    log($"haven't received manifest, http_code = {http_code}")
    log_for_user("Error loading manifest for url")
    manifest.set(null)
    return
  }

  local man
  try {
    man = parse_json(body?.as_string())
  } catch(e) {
    log(e)
    log_for_user("Error loading manifest for url")
    manifest.set(null)
    return
  }
  manifest.set(man)
}

let requestModByUrl = debounce(function(v){
  if (v != "")
    requestManifest(v)
  else
    manifest.set(null)
}, 0.3)

subscribeAndInit(requestModByUrl, urlToManifest)

let baseModsFilesUrl = Computed(@() getBaseFromManifestUrl(urlToManifest.get()))
let modFilesHashes = Computed(function(){
  if (urlToManifest.get() == "" || manifest.get()==null)
    return []
  return getHashesFromManifest(manifest.get())
})
const FAILED = "FAILED"
const WAITING = "WAITING"
const SUCCESS = "SUCCESS"

let hashesStatus = Watched({})

async function reqFileHeaders(hash){
  let url = MOD_FILE_URL.subst(hash)

  let markUnavailable = function() {
    if (modFilesHashes.get().contains(hash))
      hashesStatus.mutate(@(v) v[hash]<-FAILED)
    else if (hash in hashesStatus.get())
      hashesStatus.mutate(@(v) v.$rawdelete(hash))
  }

  let response = await httpFetch({ method = "HEAD", url })
  let { status = -1, http_code = 0 } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("file_request_receive_errors", 1, { http_code })
    log($"couldn't get file '{hash}' data from live, http_code = {http_code}")
    markUnavailable()
    return
  }
  hashesStatus.mutate(@(v) v[hash] <- SUCCESS)
}

function setCurHashesStatus(hashes){
  let res = clone hashesStatus.get()
  foreach (hash in hashes){
    if (res?[hash] == WAITING || res?[hash] == SUCCESS)
      continue
    if (!isStrHash(hash)) {
      res[hash] <- FAILED
      continue
    }
    if (hash not in res)
      res[hash] <- WAITING
    reqFileHeaders(hash)
  }
  let toDelete = []
  foreach (hash, value in res){
    if (!hashes.contains(hash)) {
      if (!(value==SUCCESS || value==WAITING))
        toDelete.append(hash)
    }
  }
  toDelete.each(@(v) res.$rawdelete(v))
  hashesStatus.set(res)
}
subscribeAndInit(setCurHashesStatus, modFilesHashes)

let curModHashesStatus = Computed(@() hashesStatus.get().filter(@(v) v == FAILED).len()>0
  ? FAILED
  : hashesStatus.get().filter(@(v) v == WAITING || v == null).len()>0
    ? WAITING
    : SUCCESS
)
let curModHashesOk = Computed(@() curModHashesStatus.get() == SUCCESS)
let curModHashesWaiting = Computed(@() curModHashesStatus.get() == WAITING)


let receivedModInfos = Watched({})

function jsonSafeParse(v){
  if (v=="")
    return null
  try{
   return parse_json(v)
  }
  catch(e) {
    logerr(e)
    return null
  }

}

const noModeInfo = {NoModeInfo=null}
eventbus_subscribe(EVENT_MOD_VROM_INFO, function(info) {
  if (info?.result!=1)
    return
  let { manifestStr, contentId, modFiles, sceneBlkFound, vromfs } = info
  receivedModInfos.modify(@(v) v.rawset(vromfs, {
    manifestFromFile = jsonSafeParse(manifestStr)
    contentId
    modFiles
    sceneBlkFound
    vromfs
  }))
})

function getFname(mpath){
  local filename = mpath
  let pathSplit = mpath.split("/")
  if (pathSplit.len()!=1) {
    filename = pathSplit[pathSplit.len()-1]
  }
  return filename
}

let NOUSE = @(...) null

function getModInfo(mpath) {
  if (mpath == "")
    return noModeInfo
  if (!file_exists(mpath))
    return noModeInfo
  let mod = receivedModInfos.get()?[mpath]
  let {contentId=null, vromfs=null, manifestFromFile=null, sceneBlkFound=false} = mod
  local titles = manifest?.title_localizations ?? {}
  titles = titles.__merge({title = manifestFromFile?.title ?? contentId})
  let title = titles?[gameLanguage] ?? titles?.title ?? contentId
  let fname = getFname(mpath).slice(0, -MODS_EXT.len())

  let sceneInMode = sceneBlkFound ? "scene.blk" : null
  if (contentId==null || sceneInMode==null || vromfs==null) {
    return noModeInfo
  }
  let pathToStart = $"?{vromfs}?*?{sceneInMode}"
  return {contentId, sceneInMode, pathToStart, title, titles, fname}
}

let allModInfos = Computed(@() receivedModInfos.get().map(@(_, v) getModInfo(v)))

let modInfo = Computed(function(){
  if (urlToManifest.get() != "")
    NOUSE(receivedModInfos.get()?[modPath.get()])
  return getModInfo(modPath.get())
})

let requestUgmForCurMod = debounce(function() {
    let mpath = modPath.get()
    request_ugm_manifest(mpath, EVENT_MOD_VROM_INFO)
  }, 0.1)

modPath.subscribe(@(_) requestUgmForCurMod())
requestUgmForCurMod()

function modName(v) {
  if ((v??"")=="")
    return loc("NO MODE")
  else{
    return (getModInfo(v)?.title ?? $"!incorect file! {getFname(v)}")
  }
}

let modPathToStart = Computed(function() {
  if (modInfo.get() == noModeInfo)
    return ""
  return modInfo.get()?.pathToStart ?? ""
})

let isSelectedModCorrect = Computed(function(){
  return (modInfo.get()?.pathToStart!=null) || modInfo.get() == noModeInfo
})

function doCreateRoomImpl() {
  let isValid = checkAvailableFields()

  if (isValid) {
    let offline = startOffline.get()
    local scenePath = scene.get()?.id ?? ""
    local mod = ""
    local modTitles = {}

    if (scenePath == "") {
      log("room is not selected")
      return
    }

    if (manifest.get() != null && urlToManifest.get()!="" && curModHashesOk.get()){
      try{
        log("title_localizations", manifest.get()?.title_localizations)
        modTitles = {title = manifest.get()?.title ?? "untitled"}
        mod = manifest?.title ?? urlToManifest.get()
      }
      catch(e)
        log_for_user(e)
    }
    else if (isSelectedModCorrect.get() && modInfo.get() != noModeInfo){
      scenePath = modPathToStart.get()
      mod = modInfo.get()?.contentId ?? ""
      modTitles = modInfo.get()?.titles ?? {}
    }
    let params = {
      public = {
        maxPlayers = maxPlayers.get()
        roomName = strip(roomName.get())
        scene = urlToManifest.get() == "" ? scenePath : ""
        cluster = oneOfSelectedClusters.get()
        appId = get_app_id()
        groupSize = groupSize.get()
        
        baseModsFilesUrl = baseModsFilesUrl.get()
        modTitles
        modHash = ";".join(modFilesHashes.get() ?? [])
        mod
      },
      lobby_template = "dev-lobby"
    }
    if (usePassword.get() && password.get())
      params.password <- strip(password.get())
    if (botsPopulation.get() > 0)
      params.public.botpop <- botsPopulation.get()

    if (botAutoSquad.get())
      params.public.botAutoSquad <- botAutoSquad.get()

    if (writeReplay.get())
      params.public.writeReplay <- true

    if (!offline){
      createRoom(params, createRoomCb)
    }
    else {
      set_matching_invite_data({ mode_info = params.public })
      if (manifest.get() != null) {
        if (curModHashesOk.get()){
          let modFileName = modFilesHashes.get()?[0]
          requestModFiles([modFileName], baseModsFilesUrl.get(), function(vroms){
            let blob = vroms?[0]
            if (blob==null) {
              showMsgbox(loc("Mod files haven't been downloaded or incorrect"))
              return
            }
            startGame({scene = "scene.blk", modFile = blob})
          })
        }
        else
          showMsgbox(loc("Mod files haven't been downloaded"))
      }
      else if (isSelectedModCorrect.get() && modPath.get()!=""){
        startGame({scene = "scene.blk", modFile = modPath.get()})
      }
      else {
        startGame({scene = scenePath})
      }
    }
  }
}

function doCreateRoom() {
  checkMultiplayerPermissions(function(have_permission) {
    if (!have_permission) {
      log("no permissions to create lobby")
      return
    }
    doCreateRoomImpl()
  })
}

function makeFormItemHandlers(field) {
  return {
    onFocus = @() focusedField.set(field)
    onBlur = @() focusedField.set(null)
    onAttach = function(elem) {
      let focusOn = focusedField.get()
      if (focusOn && field == focusOn)
        set_kb_focus(elem)
    }

    onReturn = doCreateRoom
  }
}

function formText(params) {
  let options = {
    placeholder = params?.placeholder ?? ""
  }.__update(params, makeFormItemHandlers(params.state))
  return textInput(params.state, options)
}


function formCheckbox(params={}) {
  return checkbox(params.state, params?.name, makeFormItemHandlers(params.state))
}

let titletxt = @(title){
  rendObj = ROBJ_TEXT
  text = title
  color = Color(180,180,180)
  size = FLEX_H
}.__update(fontSub)

let formComboWithTitle = @(watch, values, title) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  margin = hdpx(2)
  valign = ALIGN_CENTER
  children = [
    titletxt(title)
    {
      size = [fontH(650), fontH(180)]
      hplace = ALIGN_RIGHT
      halign = ALIGN_RIGHT
      children = comboBox(watch, values)
    }
  ]
}.__update(fontBody)

let humanTitle = @(scn) (scn?.title ?? "_untitled_").replace(".blk", "")


let filterSceneStr = Watched("")
let filteredScenes = Computed( function() {
  let fltr = (filterSceneStr.get() ?? "").tolower()
  if (fltr=="")
    return scenes.get()
  else
    return scenes.get().filter(@(v) (v?.title ?? "").tolower().contains(fltr) || (v?.id ?? "").tolower().contains(fltr))
})

let openScenesMenu = mkSelectWindow({
  uid = "scenes_selector",
  optionsState = filteredScenes,
  state = scene,
  title = loc("SELECT SCENE"),
  filterPlaceHolder=loc("filter scene")
  filterState = filterSceneStr
  mkTxt = humanTitle
  titleStyle = fontHeading2
})

let selectSceneBtn = mkOpenSelectWindowBtn(scene, loc("Current scene"), openScenesMenu, humanTitle)

let gameMods = Watched([])

let resultGameMods = Computed(function(){
  let res = [""]
  let infos = allModInfos.get()

  foreach (m in gameMods.get()){
    if (m in infos){
      res.append(m)
    }
  }
  return res
})
let filterMods = Watched("")

let openModsWindow = mkSelectWindow({
  uid = "MODS_WND"
  optionsState = resultGameMods,
  state = modPath,
  title = loc("select game mod from 'userMods' folder"),
  filterPlaceHolder=loc("filter mods")
  filterState = filterMods
  onAttach = function() {
    let mods = scan_folder({root=USER_MODS_FOLDER, vromfs = false, realfs = true, recursive = false, files_suffix=MODS_EXT})
    gameMods.set(mods)
    foreach (m in mods) {
      request_ugm_manifest(m, EVENT_MOD_VROM_INFO)
    }
  }
  titleStyle = fontHeading2
  mkTxt = modName
})

let selectModBtn = mkOpenSelectWindowBtn(modPath, loc("local game mod"), openModsWindow, modName)
let gameBtnHgt = calc_comp_size(selectModBtn)[1]

let urlToManifestComp = textInput(urlToManifest, {placeholder = loc("URL of manifest")})

let closeRoomBtn = Regular(loc("Close"), function() {showCreateRoom.set(false)}, {hotkeys=[[$"^{JB.B} | Esc"]]})
let createRoomBtn = Regular(loc("Create"), doCreateRoom, {hotkeys=[["^J:X"]]})

function createRoomWnd() {
  local selectScene = {size=[0, gameBtnHgt]}
  if (urlToManifest.get() != "" && manifest.get() != null)
    selectScene = titletxt(manifest.get()?.title)
  else if (modPathToStart.get() == "" && modPath.get() == "")
    selectScene = selectSceneBtn
  return {
    watch = [usePassword, urlToManifest, modPathToStart, modPath, manifest, isModsAvailable]
    size = const [fsh(60), SIZE_TO_CONTENT]
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = sidePadding
    key = "create-room"
    children = [
      {
        flow = FLOW_VERTICAL
        size = FLEX_H
        children = [
          urlToManifest.get() == "" && isModsAvailable.get() ? selectModBtn : {size=[0, gameBtnHgt]},
          modPath.get() == "" && isModsAvailable.get() ? urlToManifestComp : null,
          selectScene,
          formComboWithTitle(minPlayers, playersAmountList, loc("players to start")),
          formComboWithTitle(maxPlayers, playersAmountList, loc("Max players")),
          formComboWithTitle(botsPopulation, [0].extend(playersAmountList), loc("Bots population")),
          formCheckbox({state=botAutoSquad, name=loc("customRoom/botAutoSquad", "Fill the group with bots.")}),
          formComboWithTitle(groupSize, groupSizes, loc("Group size")),
          formText({state=roomName, placeholder = loc("customRoom/roomName_placeholder")}),
          modPath.get() == "" ? formCheckbox({state=startOffline, name=loc("customRoom/startOffline")}) : titletxt(loc("customRoom/startOffline")),
          {
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            size = FLEX_H
            valign = ALIGN_CENTER
            minHeight = hdpx(67)
            children = [
              formCheckbox({state=usePassword, name=loc("customRoom/usePassword")}),
              usePassword.get()
                ? formText({state=password placeholder=loc("password_placeholder","password") password="\u25CF"})
                : null
            ]
          },
          formCheckbox({state=writeReplay, name=loc("customRoom/writeReplay")})
        ]
      }
      function() {
        let children = [closeRoomBtn]
        if (modInfo.get()==noModeInfo)
          children.append(createRoomBtn)
        else if (!isSelectedModCorrect.get())
          children.append(txt(loc("incorrectMod")))
        else if (startOffline.get() || curModHashesOk.get())
          children.append(createRoomBtn)

        if (curModHashesWaiting.get())
          children.append(waitingSpinner)
        else if (!curModHashesOk.get())
          children.append(txt(loc("modFilesAreNotAvailableOnline")))

        return {
          watch = [isSelectedModCorrect, modInfo, curModHashesOk, curModHashesWaiting, startOffline]
          size = SIZE_TO_CONTENT
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children
        }
      }
    ]
  }
}

return createRoomWnd
