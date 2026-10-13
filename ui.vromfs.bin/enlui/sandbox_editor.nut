import "%ui/components/fontawesome.map.nut" as fa
import "%daeditor/components/textButton.nut" as textButton
import "DataBlock" as DataBlock
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/offline_mode.nut" import isSandboxLaunched
from "eventbus" import eventbus_subscribe
from "app" import exit_game, switch_scene
from "dagor.system" import dgs_get_settings, DBGLEVEL
from "dasevents" import EventSessionFinished, CmdEditorInvalidateAI
from "%ui/state/appState.nut" import levelLoaded, levelIsLoading, currentLevelBlk
from "%ui/style/fontsStyle.nut" import fontawesome
from "%daeditor/components/cursors.nut" import setTooltip, normal
from "%daeditor/components/window.nut" import registerWindow, showWindow, hideWindow
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%daeditor/state.nut" import editorTimeStop
from "%ui/state/editorState.nut" import editorActivness
from "%ui/editor.nut" import editorIsActive, initTemplatesGroups, initRISelect, proceedWithSavingUnsavedChanges, hideDebugButtons
from "dagor.fs" import scan_folder, mkdir, find_files, file_exists
from "%daeditor/propPanelControls.nut" import registerPerCompPropEdit
from "%ui/components/msgbox.nut" import msgboxComponent, showMsgbox
from "%ui/sandbox_playconfig.nut" import openPlayConfigDialog, backupSaveEnabled
from "%ui/sandbox_hints.nut" import showHints, hintShown, wasStartHintClosed, hintWelcomeKeepShowing
from "%ui/prefabEditorState.nut" import isPrefabTool
from "%ui/sandbox_toolbox.nut" import setToolboxShowMsgbox, resetToolbox, toolboxShown, toolboxPopup
from "%ui/ui_library.nut" import *
from "%darg/laconic.nut" import *
from "string" import regexp, startswith, endswith
from "types" import String
from "%sqstd/frp.nut" import subscribeList

const OPEN_SCENE_WINDOW_ID = "open_scene"

let isSandboxContext = @() isSandboxLaunched

let sandboxEditorEnabled = Watched(isSandboxContext())
let entity_editor = require_optional("entity_editor")

if (!sandboxEditorEnabled.get() || entity_editor==null)
  return {sandboxEditorEnabled, sandboxEditor=null}

let mkPrefabEditor = require_optional("%ui/prefabEditor.nut")
let devMode = (DBGLEVEL > 0)

let { get_scene_filepath, get_instance } = entity_editor

let levelIsNotPresent = Computed(@() (!levelLoaded.get() && !levelIsLoading.get()))

let { predefinedRIGroups } = require("%ui/sandbox_ri_groups.nut")
initRISelect("gamedata/ri_list.blk", predefinedRIGroups)
initTemplatesGroups(false)
hideDebugButtons()

let textInput = require("%ui/components/textInput.nut")
let modalWindows = require("%daeditor/components/modalWindows.nut")
let {addModalWindow, removeModalWindow, modalWindowsComponent} = modalWindows
let infoBox = @(text) showMsgbox(text)

let { hintWindow } = require("%ui/sandbox_hints.nut")
setToolboxShowMsgbox(showMsgbox)

let useSources = dgs_get_settings()?.debug.useAddonVromSrc ?? false
let getLevelsList = @() scan_folder({root="levels", vromfs = !useSources, realfs = useSources, recursive = true, files_suffix=".blk"}).sort()

const MODS_PREFABS_PATH = "content/enlisted_extra/ugm_scenes"
let getPrefabsList = @() scan_folder({root=MODS_PREFABS_PATH, vromfs = !useSources, realfs = useSources, recursive = true, files_suffix=".blk"}).sort()

console_register_command(
  @() sandboxEditorEnabled.set(!sandboxEditorEnabled.get()) ?? console_print("editor.enableSceneLoad set to", sandboxEditorEnabled.get()),
  "editor.enableSceneLoad"
)
let loadSceneLoc = loc("sandboxeditor/openScenes", "Scenes")
let scenesOpened = mkWatched(persist, "scenesOpened", false)

let mkSelectLine = kwarg(function(selected, textCtor = null, onSelect=null, onDClick=null){
  textCtor = textCtor ?? @(opt) opt
  return function(opt, i){
    let isSelected = Computed(@() selected.get() == opt)
    let onClick = onSelect != null ? @() onSelect?(opt) : @() selected.set(!isSelected.get() ? opt : null)
    let onDoubleClick = onDClick != null ? @() onDClick?(opt) : null
    return watchElemState(@(sf) {
      size = FLEX_H
      padding = const [hdpx(3), hdpx(10)]
      behavior = Behaviors.Button
      watch = isSelected
      onClick
      onDoubleClick
      children = txt(textCtor(opt), {color = isSelected.get() ? null : Color(190,190,190)})
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? Color(120,120,160) : (i%2) ? Color(0,0,0,120) : 0
      borderWidth = isSelected.get() ? hdpx(2) : 0
    })
  }
})


let transformLevelName = @(name) name?.replace("levels/", "").replace(".blk", "") ?? "Select level (dev only)..."

function openSelectLevel(selectedLevel, onSelect=null) {
  let key = {}
  let close = @() removeModalWindow(key)
  let mkSelectedLevel = mkSelectLine({
    selected = selectedLevel,
    onSelect = function(v) {selectedLevel.set(v); onSelect?(v); close()}
  })
  addModalWindow({key,
    children = {
      behavior = Behaviors.Button
      size = const [sw(50), sh(70)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = Color(30,30,30, 190)
      padding = hdpx(10)
      children = vflow(
        Flex()
        Gap(hdpx(10))
        txt("SELECT LEVEL", {hplace = ALIGN_CENTER})
        makeVertScroll(vflow(Size(FLEX, SIZE_TO_CONTENT), getLevelsList().map(mkSelectedLevel)))
        comp(Bottom, textButton("Close", close, {hotkeys = [["Esc"]], vplace = ALIGN_BOTTOM}))
      )
    }
  })
}

let transformPrefabName = @(name) name?.replace($"{MODS_PREFABS_PATH}/", "").replace(".blk", "") ?? "Select location..."

function openSelectPrefab(selectedPrefab, onSelect=null) {
  let key = {}
  let close = @() removeModalWindow(key)
  let mkSelectedPrefab = mkSelectLine({
    selected = selectedPrefab,
    onSelect = function(v) {selectedPrefab.set($"{MODS_PREFABS_PATH}/{v}"); onSelect?(v); close()}
  })
  addModalWindow({key,
    children = {
      behavior = Behaviors.Button
      size = const [sw(30), sh(60)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = Color(30,30,30, 190)
      padding = hdpx(10)
      children = vflow(
        Flex()
        Gap(hdpx(10))
        txt("SELECT LOCATION", {hplace = ALIGN_CENTER})
        makeVertScroll(vflow(Size(FLEX, SIZE_TO_CONTENT), getPrefabsList().map(transformPrefabName).map(mkSelectedPrefab)))
        comp(Bottom, textButton("Close", close, {hotkeys = [["Esc"]], vplace = ALIGN_BOTTOM}))
      )
    }
  })
}


const MODS_TO_EDIT_FOLDER = "userGameMods"
const DEF_SCENE_FILENAME = "scene.blk"

const BACKUPSAVE_TIME = 300.0 
function sandboxBackupSave() {
  if (backupSaveEnabled.get() && levelLoaded.get() && !levelIsLoading.get() && editorIsActive.get()) {
    let path = get_scene_filepath()
    if (startswith(path, $"{MODS_TO_EDIT_FOLDER}/") && endswith(path, $"/{DEF_SCENE_FILENAME}")) {
      let modName = path.slice(MODS_TO_EDIT_FOLDER.len()+1, path.len()-DEF_SCENE_FILENAME.len()-1)
      let pathSave = $"{MODS_TO_EDIT_FOLDER}/backup.{modName}.scene.blk"
      print($"Backup saving scene to {pathSave}")
      get_instance().saveMainSceneCopy(pathSave, "backup")
    }
  }
}

gui_scene.setInterval(BACKUPSAVE_TIME, sandboxBackupSave)

let convertToPath = @(v) v.split("/").slice(1)
function convertToModAndScene(v) {
  if (!(v instanceof String))
    return v
  let path = convertToPath(v)
  return {mod = path[0], scene="/".join(path.slice(1))}
}

function loadScene(modAndScene) {
  if (modAndScene==null)
    return
  let {mod, scene} = convertToModAndScene(modAndScene)
  console_command("daEd4.open 0")
  switch_scene($"{MODS_TO_EDIT_FOLDER}/{mod}/{scene}", null, {
    modId = mod
  })
}
function loadSceneWithSavingUnsavedChanges(modAndScene) {
  if (modAndScene==null)
    return
  proceedWithSavingUnsavedChanges(showMsgbox, @() loadScene(modAndScene))
}

let selectedScene = Watched()

let mkOpenSceneRow = mkSelectLine({
  selected = selectedScene, textCtor = @(ms) $"{ms.mod}/{ms.scene ?? ""}",
  onDClick = @(opt) opt?.scene != null ? loadSceneWithSavingUnsavedChanges(opt) : null
})

if (devMode) {
  registerPerCompPropEdit("level__blk", function(params){
    let selectedLevel = Watched(params?.obj)
    let eid = params.eid
    function onSelect(v){
      if ((eid ?? ecs.INVALID_ENTITY_ID) != ecs.INVALID_ENTITY_ID)
        ecs.obsolete_dbg_set_comp_val(eid, "level__blk", v)
      infoBox("Save and than load scene to make changes visible and reload location")
    }
    return @() {
      watch = selectedLevel
      children = textButton(transformLevelName(selectedLevel.get()),
        @() openSelectLevel(selectedLevel, onSelect))
    }
  })
}

let availableModsAndScenes = mkWatched(persist, "availableModsAndScenes", [])

function scanForModsAndScene(){
  let files = scan_folder({root=MODS_TO_EDIT_FOLDER, vromfs = false, realfs = true, recursive = true, files_suffix=DEF_SCENE_FILENAME})
    .map(convertToPath)
    .filter(@(v) v.len()==2 && v[1] == DEF_SCENE_FILENAME)
  let modsAndScenes = files.map(function(path) {
      return {mod = path[0], scene=path[1]}
    })
  return modsAndScenes.sort(@(a,b) a.mod<=>b.mod)
}

let updateScenes = @() availableModsAndScenes.set(scanForModsAndScene())
const newSceneUID = "new_scene"

function mkSimpleBlk(data){
  let blk = DataBlock()
  assert (typeof data != "array", "currently not supported arrays, add if needed")
  foreach (k, v in data){
    if (typeof v == "table") {
      blk[k] <- mkSimpleBlk(v)
    }
    else {
      blk[k] <- v
    }
  }
  return blk
}

let validNewSceneNameRegExp = regexp(@"[a-z,A-Z,0-9,_]*")
function isNewSceneNameValid(name) {
  return validNewSceneNameRegExp.match(name)
}

function openNewSceneWnd(){
  let sceneName = Watched("")
  let sceneNameComp = textInput(sceneName, {onAttach = @(elem) set_kb_focus(elem)})
  let close = @() removeModalWindow(newSceneUID)
  let selectedLevel = Watched(null)
  let selectedPrefab = Watched(null)
  let selectLevel = @() openSelectLevel(selectedLevel, @(_) selectedPrefab.set(null))
  let selectPrefab = @() openSelectPrefab(selectedPrefab, @(_) selectedLevel.set(null))

  let isSceneCreateAllowed = Computed(@() sceneName.get()!=null && isNewSceneNameValid(sceneName.get())
                                          && (selectedLevel.get()!=null || selectedPrefab.get()!=null))
  function createScene(name){
    if (name==null || name.len()<=0) {
      infoBox($"No mod name entered")
      return
    }
    let path = $"{MODS_TO_EDIT_FOLDER}/{name}"
    let folderExists = find_files($"{MODS_TO_EDIT_FOLDER}/*").findvalue(@(v) v.name==name)!=null
    if (folderExists){
      infoBox($"Folder or file '{name}' already exists in {MODS_TO_EDIT_FOLDER}")
      return
    }
    if (file_exists($"{path}/{DEF_SCENE_FILENAME}")){
      infoBox($"File '{DEF_SCENE_FILENAME}' already exists in {path}")
      return
    }
    local blk = null
    if (selectedPrefab.get()!=null){
      blk = DataBlock()
      try
        blk.load($"{selectedPrefab.get()}")
      catch(e)
        blk = null
    }
    else{
      try
        blk = mkSimpleBlk({entity = {_template="level", ["level__blk"] = selectedLevel.get()}})
      catch(e)
        blk = null
    }

    if (blk==null){
      infoBox($"Failed to obtain scene data")
      return
    }
    let res = mkdir(path)
    if (!res){
      infoBox($"Could not create '{name}'")
      return
    }
    let scenePath = $"{path}/{DEF_SCENE_FILENAME}"
    blk.saveToTextFile(scenePath)
    updateScenes()
    loadScene(scenePath)
    close()
  }
  addModalWindow({
    key = newSceneUID
    children = vflow(
      Button
      RendObj(ROBJ_SOLID)
      Padding(hdpx(10))
      Colr(30,30,30)
      Gap(hdpx(10))
      txt("CREATE NEW SCENE MOD", {hplace = ALIGN_CENTER})
      devMode ? (@() {watch = selectedLevel, children = textButton(transformLevelName(selectedLevel.get()), selectLevel)}) : null
      @() {watch = selectedPrefab, children = textButton(transformPrefabName(selectedPrefab.get()), selectPrefab)}
      vflow(Size(FLEX, SIZE_TO_CONTENT), txt("Mod name:"), sceneNameComp)
      hflow(
        textButton("Cancel", close, {hotkeys=[["Esc"]]})
        @() {
          watch = isSceneCreateAllowed
          children = isSceneCreateAllowed.get() ? textButton("Create", @() createScene(sceneName.get()))
                                                : textButton("Create", @() null, {off=true})
        }
      )
    )
  })
}

let configBtnBlack = textButton(
  fa["wrench"],
  @() openPlayConfigDialog(modalWindows),
  {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,255)}}})

let getFullScenePath = @(ms) $"{MODS_TO_EDIT_FOLDER}/{ms.mod}/{ms.scene}"
let getCurScene = @() availableModsAndScenes.get().findvalue(@(v) getFullScenePath(v) == get_scene_filepath())

let selScenesWindow = registerWindow({
  id = OPEN_SCENE_WINDOW_ID
  onAttach = updateScenes
  windowStyle = {fillColor = Color(40,40,40,120)}
  content = @() {
    flow  = FLOW_VERTICAL
    size = FLEX
    gap  = hdpx(2)
    watch = [availableModsAndScenes, levelIsNotPresent]
    onAttach = @() selectedScene.set(getCurScene())
    halign = ALIGN_CENTER
    children = [
      hflow( Gap(hdpx(5)), VACenter, Size(FLEX, SIZE_TO_CONTENT), Padding(hdpx(5),hdpx(5)), RendObj(ROBJ_SOLID), Colr(60,60,90),
        txt(loadSceneLoc),
        txt($"(list of <modName>/{DEF_SCENE_FILENAME} in '{MODS_TO_EDIT_FOLDER}' folder)"),
        comp(Flex()),
        textButton(fa["refresh"], updateScenes, {textStyle = {normal = fontawesome}})
      )
      makeVertScroll(
        vflow(Padding(hdpx(4)), Size(FLEX SIZE_TO_CONTENT), RendObj(ROBJ_SOLID), Colr(0,0,0,50),
          availableModsAndScenes.get().map(mkOpenSceneRow)
        )
      )
      hflow(
        Size(FLEX, SIZE_TO_CONTENT)
        levelIsNotPresent.get() ? null : textButton("Cancel", @() scenesOpened.set(false), {hotkeys = [["Esc"]]})
        textButton("New Scene", @() proceedWithSavingUnsavedChanges(showMsgbox, openNewSceneWnd))
        comp(Flex())
        @() {
          watch = selectedScene
          flow = FLOW_HORIZONTAL
          children = selectedScene.get()?.scene != null ? [
            configBtnBlack
            textButton("Load", @() scenesOpened.set(false) ?? loadSceneWithSavingUnsavedChanges(selectedScene.get()), {hotkeys = [["Enter"]]})
          ] : null
        }
      )
    ]
  }
})


let prefabsBtn = textButton(
    loc("sandboxeditor/prefabs", "Prefabs"),
    function() { isPrefabTool.set(!isPrefabTool.get()); setTooltip(null) },
    {hotkeys = [["L.Ctrl K | R.Ctrl K"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) setTooltip(on ? "Entity prefabs (Ctrl+K)" : null)})

let toolboxBtn = textButton(
    loc("sandboxeditor/toolbox", "Toolbox"),
    function() { toolboxShown.set(!toolboxShown.get()); setTooltip(null) },
    {hotkeys = [["L.Ctrl F | R.Ctrl F"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) setTooltip(on && !toolboxShown.get() ? "Set of game editing tools (Ctrl+F)" : null)})

let restartBtn = textButton(
    loc("sandboxeditor/restart", "Restart"),
    @() proceedWithSavingUnsavedChanges(showMsgbox, @() loadScene(get_scene_filepath()), "You have unsaved changes. How do you want to restart?",
                                                                                         "Do you want to restart?"),
    {hotkeys = [["L.Ctrl !L.Alt R | R.Ctrl !R.Alt R"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) setTooltip(on ? "Restart scene (Ctrl+R)" : null)})

let openScenesToEditBtn = textButton(
    loadSceneLoc,
    @() scenesOpened.set(!scenesOpened.get()),
    {hotkeys = [["L.Ctrl O | R.Ctrl O"]], boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) setTooltip(on ? "Load or create new scene (Ctrl+O)" : null)})

let configBtn = textButton(
    fa["wrench"],
    @() openPlayConfigDialog(modalWindows),
    {hotkeys = [["L.Ctrl G | R.Ctrl G"]], textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) setTooltip(on ? "Sandbox Config (Ctrl+G)" : null)})

function quitSandboxEditor() {
  proceedWithSavingUnsavedChanges(showMsgbox,
    function() {
      console_command("daEd4.open 0")
      exit_game()
    },
    "You have unsaved changes in Sandbox. How do you want to exit?",
    "Do you want to exit Sandbox?")
}

eventbus_subscribe("sandbox_editor.quit", @(...) quitSandboxEditor())

let quitBtn = textButton(
    fa["close"],
    @() quitSandboxEditor(),
    {textStyle = {normal = fontawesome}, boxStyle = {normal = {fillColor = Color(0,0,0,80)}},
     onHover = @(on) setTooltip(on ? "Quit" : null)})


let worldRenderQuery = ecs.SqQuery("worldRendererInited", {comps_rq=["world_renderer_tag"]})
let worldRender = Watched(worldRenderQuery.perform(@(...) true) ?? false)
let worldRenderInited = Computed(@() worldRender.get() || (currentLevelBlk.get()!=null && levelLoaded.get()))
ecs.register_es("worldRendererInited", {onInit = @(...) worldRender.set(true), onDestroy = @(...) worldRender.set(false)},
  {comps_rq=["world_renderer_tag"]}
)
function openScenesIfNeeded(){
  if (worldRenderInited.get() && !levelIsLoading.get()) {
    if (currentLevelBlk.get() == null)
      scenesOpened.set(true)
    else {
      scenesOpened.set(false)
      resetToolbox()
      showHints()
    }
  }
}
subscribeList(openScenesIfNeeded, worldRenderInited, levelIsLoading)
openScenesIfNeeded()

let transformCurSceneName = @(name) name?.replace($"{MODS_TO_EDIT_FOLDER}/", "").replace($"/{DEF_SCENE_FILENAME}", "") ?? "Untitled"
let levelIsLoadedAndEditorIsActive = Computed(@() levelLoaded.get() && editorIsActive.get())

scenesOpened.subscribe(function(v) {
  if (v) {
    showWindow(OPEN_SCENE_WINDOW_ID)
  } else {
    hideWindow(OPEN_SCENE_WINDOW_ID)
  }
})

function sandboxEditor() {
  let sceneName = transformCurSceneName(get_scene_filepath())
  let sceneNameBtn = {
    pos = const [0, hdpx(7)]
    behavior = Behaviors.Button
    onClick = @() null
    children = txt(sceneName)
  }

  return {
    size = FLEX
    watch = [levelIsLoadedAndEditorIsActive, scenesOpened, hintShown, editorIsActive, levelLoaded, levelIsLoading, levelIsNotPresent, toolboxShown,
             isPrefabTool, editorActivness]
    children = [
      levelLoaded.get() && !editorIsActive.get() ? txt("F12 to open editor", {padding = hdpx(10), hplace = ALIGN_CENTER}) : null,
      {
        cursor = normal
        size = SIZE_TO_CONTENT
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        children = [
          levelIsLoadedAndEditorIsActive.get() ? sceneNameBtn : null,
          levelIsLoadedAndEditorIsActive.get() ? toolboxBtn : null,
          levelIsLoadedAndEditorIsActive.get() ? prefabsBtn : null,
          levelIsLoadedAndEditorIsActive.get() ? restartBtn : null,
          levelIsLoadedAndEditorIsActive.get() || levelIsNotPresent.get() ? openScenesToEditBtn : null,
          levelIsLoadedAndEditorIsActive.get() ? { size = const [0, SIZE_TO_CONTENT] } : null,
          levelIsLoadedAndEditorIsActive.get() ? configBtn : null,
          levelIsLoadedAndEditorIsActive.get() || levelIsNotPresent.get() ? quitBtn : null
        ]
      },
      (levelIsLoadedAndEditorIsActive.get() && toolboxShown.get()) ? toolboxPopup : null,
      scenesOpened.get() && !levelLoaded.get() ? selScenesWindow : null,
      wasStartHintClosed() ? null : @() {
        watch = [editorIsActive, levelLoaded]
        children = (!levelLoaded.get() || editorIsActive.get() || (!hintWelcomeKeepShowing.get() && !hintShown.get())) ? null : hintWindow
      },
      modalWindowsComponent,
      msgboxComponent,
      editorActivness.get() && isPrefabTool.get() ? mkPrefabEditor() : null 
    ]
  }.__update((!editorIsActive.get() && levelIsNotPresent.get()) || hintShown.get() ? {cursor = normal} : {})
}

ecs.register_es("sandbox_session_finish_es",
  {
    [EventSessionFinished] = function(_eid, _c){
      if (!isSandboxContext())
        return

      gui_scene.resetTimeout(3.3, function(){
        proceedWithSavingUnsavedChanges(showMsgbox, function(){
          local curScene = get_scene_filepath()
          if (curScene!=null)
            loadScene(curScene)
        }, "Game session has finished. You have unsaved changes. How do you want to reload the scene?",
          "Game session has finished. Do you want to reload the scene?")
      })
    }
  }
)

editorIsActive.subscribe(function(isActive) {
  editorTimeStop.set(isActive)
  ecs.g_entity_mgr.broadcastEvent(CmdEditorInvalidateAI())

  if (isActive) {
    
    gui_scene.clearTimer(sandboxBackupSave)
    gui_scene.setInterval(BACKUPSAVE_TIME, sandboxBackupSave)
  }
})

return {sandboxEditorEnabled, sandboxEditor}
