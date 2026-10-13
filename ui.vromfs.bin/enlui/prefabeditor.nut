import "%ui/components/fontawesome.map.nut" as fa
import "%daeditor/components/textButton.nut" as textButton
import "%daeditor/components/closeButton.nut" as closeButton
import "%daeditor/components/nameFilter.nut" as nameFilter
import "%dngscripts/ecs.nut" as ecs
from "dasevents" import PrefabSaveEvent, PrefabCreateFromSelectedEvent, AddSelectedToPrefabEvent, PrefabSpawnEvent, PrefabSelectParentEvent, PrefabSelectObjectsEvent, PrefabShatterSelectedEvent
from "%ui/prefabEditorState.nut" import isPrefabTool, selectedPrefabs, selectedPrefab, selectedPrefabObjects, selectedNoPrefabs, prefabsLibrary, getPrefabsInLibrary
from "%daeditor/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "das.prefab" import is_prefab_name_valid, make_prefab_path
from "%daeditor/components/style.nut" import colors
from "%daeditor/components/text.nut" import dtext as txt
from "%daeditor/state.nut" import showTemplateSelect
from "%ui/style/fontsStyle.nut" import fontawesome
from "%daeditor/components/cursors.nut" import setTooltip
from "system" import remove
from "dagor.fs" import file_exists, mkdir
from "%darg/ui_imports.nut" import *

let textInput = require("%daeditor/components/textInput.nut")
let scrollbar = require("%daeditor/components/scrollbar.nut")
let daEditor = require_optional("daEditorEmbedded")
let {DE4_MODE_SELECT=null} = daEditor
let entity_editor = require_optional("entity_editor")

showTemplateSelect.subscribe(@(v) isPrefabTool.modify(@(val) val && !v))
isPrefabTool.subscribe(function(v) {
  if (showTemplateSelect.get() && v)
    daEditor?.setEditMode(DE4_MODE_SELECT)
  showTemplateSelect.modify(@(val) val && !v)
})


let selectedItem = Watched(null)
let filterText = Watched("")
let newPrefabName = Watched("")
let isNewPrefabNameValid = Computed(@() is_prefab_name_valid(newPrefabName.get() ?? ""))

let scrollHandler = ScrollHandler()

function scrollByName(text) {
  scrollHandler.scrollToChildren(function(desc) {
    return ("prefab_name" in desc) && desc.prefab_name.contains(text)
  }, 2, false, true)
}

function scrollBySelection() {
  scrollHandler.scrollToChildren(function(desc) {
    return ("prefab_name" in desc) && desc.prefab_name==selectedItem.get()
  }, 2, false, true)
}

let filter = nameFilter(filterText, {
  placeholder = "Filter by name"

  onChange = function(text) {
    filterText.set(text)

    if (selectedItem.get() && text.len()>0 && selectedItem.get().tolower().contains(text.tolower()))
      scrollBySelection()
    else if (text.len())
      scrollByName(text)
    else
      scrollBySelection()
  }

  onEscape = @() set_kb_focus(null)

  onReturn = @() set_kb_focus(null)

  onClear = function() {
    filterText.set("")
    set_kb_focus(null)
  }
})

function doSelectPrefab(prefab_name) {
  selectedItem.set(prefab_name)
  ecs.g_entity_mgr.broadcastEvent(PrefabSpawnEvent({name=prefab_name}))
}

function listRow(prefab_name, idx) {
  let stateFlags = Watched(0)

  return function() {
    let isSelected = selectedItem.get() == prefab_name

    local color
    if (isSelected) {
      color = colors.Active
    } else {
      color = (stateFlags.get() & S_TOP_HOVER) ? colors.GridRowHover : colors.GridBg[idx % colors.GridBg.len()]
    }

    return {
      rendObj = ROBJ_SOLID
      size = FLEX_H
      color = color
      behavior = Behaviors.Button
      prefab_name

      watch = stateFlags
      onClick = @() selectedItem.modify(@(v) v != prefab_name ? prefab_name : null)
      onDoubleClick = @() doSelectPrefab(prefab_name)
      onElemState = @(sf) stateFlags.set(sf & S_TOP_HOVER)

      children = {
        rendObj = ROBJ_TEXT
        text = prefab_name
        color = Color(235, 235, 235)
        margin = fsh(0.5)
      }
    }
  }
}


function prefabInfoBlock() {
  let prefab = selectedPrefab.get()
  let prefabText = selectedPrefabs.get().len() == 0 ? "Prefab not selected in scene"
                                                    : prefab
                                                      ? $"Prefab: {prefab.name} (#{prefab.eid})"
                                                      : $"Prefabs: {selectedPrefabs.get().len()} selected"
  return {
    flow = FLOW_VERTICAL
    watch = [selectedPrefabs, selectedPrefab, selectedPrefabObjects, selectedNoPrefabs]
    size = FLEX_H
    margin = const [0, 0, 0, hdpx(25)]
    children = [
      txt(prefabText, {
        fontSize = hdpx(16)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size = FLEX_H
      })
      txt($"Prefab objects: {selectedPrefabObjects.get().len()}", {
        fontSize = hdpx(16)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size = FLEX_H
      })
      txt($"Selected entities (not prefabs): {selectedNoPrefabs.get().len()}", {
        fontSize = hdpx(16)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        size = FLEX_H
      })
    ]
  }
}

function mkPrefabFolder() {
  if (!mkdir("userPrefabs")) {
    logerr("Failed to create userPrefabs folder. Prefabs can't be saved")
    return false
  }
  return true
}

function prefabSaveAndShatterBlock() {
  let res = { watch = [selectedPrefabObjects, selectedPrefabs] }
  if (selectedPrefabObjects.get().len() == 0 && selectedPrefabs.get().len() == 0)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    size = FLEX_H
    children = [
      textButton("Save", function() {
        if (!mkPrefabFolder())
          return

        foreach (eid in selectedPrefabObjects.get().keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSaveEvent({}))
        foreach (eid in selectedPrefabs.get().keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSaveEvent({}))
        gui_scene.resetTimeout(0.2, @() prefabsLibrary.set(getPrefabsInLibrary()))
      }, {onHover = @(on) setTooltip(on ? "Save selected in scene prefabs to files, replacing previous content" : null)})
      textButton("Shatter", @() ecs.g_entity_mgr.broadcastEvent(PrefabShatterSelectedEvent({})), {onHover = @(on) setTooltip(on ? "Detach prefab objects from prefabs in scene / decompose prefabs" : null)})
      textButton("Delete", function() {
        foreach (eid in selectedPrefabObjects.get().keys())
          ecs.g_entity_mgr.destroyEntity(eid)
        foreach (eid in selectedPrefabs.get().keys())
          ecs.g_entity_mgr.destroyEntity(eid)
        gui_scene.resetTimeout(0.2, @() prefabsLibrary.set(getPrefabsInLibrary()))
      }, {onHover = @(on) setTooltip(on ? "Delete prefabs or prefab objects from scene" : null)})
      selectedPrefabObjects.get().len() == 0 && selectedPrefabs.get().len() != 0 ? textButton("Select", function() {
        entity_editor?.get_instance()?.selectEntities([])
        foreach (eid in selectedPrefabs.get().keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSelectObjectsEvent({}))
      }, {onHover = @(on) setTooltip(on ? "Select all prefab objects entities of selected prefab(s) in scene" : null)}) : null
      selectedPrefabObjects.get().len() != 0 ? textButton("Parent", function() {
        entity_editor?.get_instance()?.selectEntities([])
        foreach (eid in selectedPrefabObjects.get().keys())
          ecs.g_entity_mgr.sendEvent(eid, PrefabSelectParentEvent({}))
      }, {onHover = @(on) setTooltip(on ? "Select parent prefab(s) in scene and deselect other entities" : null)}) : null
    ]
  })
}

const PREFAB_CREATE_MODAL_ID = "PREFAB_CREATE_MODAL_ID"
function prefabCreateFromSelectedBlock() {
  let watch = selectedNoPrefabs
  return selectedNoPrefabs.get().len() == 0 ? { watch }
    : {
        watch
        flow = FLOW_HORIZONTAL
        size = FLEX_H
        children = textButton("Create prefab from selected entities", @() addModalWindow({
          key = PREFAB_CREATE_MODAL_ID
          size = FLEX
          onClick = @() null
          children = {
            flow = FLOW_VERTICAL
            behavior = Behaviors.Button
            rendObj = ROBJ_SOLID
            size = const [hdpx(400), hdpx(150)]
            padding = hdpx(10)
            margin = hdpx(20)
            color = Color(30, 30, 30)
            children = [
              txt("CREATE PREFAB", {
                hplace = ALIGN_CENTER
              })
              {
                flow = FLOW_VERTICAL
                size = FLEX_H
                children = [
                  txt("New prefab name:")
                  textInput(newPrefabName, {onAttach = @(elem) set_kb_focus(elem)})
                ]
              }
              {
                flow = FLOW_HORIZONTAL
                hplace = ALIGN_CENTER
                children = [
                  textButton("Cancel", @() removeModalWindow(PREFAB_CREATE_MODAL_ID), {hotkeys=[["Esc"]]})
                  @() {
                    watch = isNewPrefabNameValid
                    children = isNewPrefabNameValid.get()
                      ? textButton("Create", function() {
                        if (!mkPrefabFolder())
                          return
                        ecs.g_entity_mgr.broadcastEvent(PrefabCreateFromSelectedEvent({name=newPrefabName.get(), save=true}))
                        removeModalWindow(PREFAB_CREATE_MODAL_ID)
                        newPrefabName.set("")
                        gui_scene.resetTimeout(0.2, @() prefabsLibrary.set(getPrefabsInLibrary()))
                      })
                      : null
                  }
                ]
              }
            ]
          }
        })
      )}
}

function addSelectedObjectsToPrefab() {
  let res = { watch = [selectedNoPrefabs, selectedPrefab] }
  if (selectedNoPrefabs.get().len() == 0 || selectedPrefab.get() == null)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    size = FLEX_H
    children = [
      textButton("Add selected entities to prefab entity", @() ecs.g_entity_mgr.sendEvent(selectedPrefab.get().eid, AddSelectedToPrefabEvent({})))
    ]
  })
}

function mkDialogRoot() {
  function listContent() {
    let rows = []
    local idx = 0
    foreach (prefab in prefabsLibrary.get())
      if (filterText.get().len() == 0 || prefab.tolower().contains(filterText.get().tolower()))
        rows.append(listRow(prefab, idx++))

    return {
      watch = [prefabsLibrary, selectedItem, filterText]
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = rows
      behavior = Behaviors.Button
    }
  }

  let scrollList = scrollbar.makeVertScroll(listContent, {
    scrollHandler
    rootBase = class {
      size = FLEX
      onAttach = @() scrollBySelection()
    }
  })


  function doClose() {
    isPrefabTool.set(false)
    filterText.set("")
  }

  function doDeleteSelected() {
    let filename = make_prefab_path(selectedItem.get())
    if (file_exists(filename))
      remove(filename)
    selectedItem.set(null)
    prefabsLibrary.set(getPrefabsInLibrary())
  }

  return {
    size = const [sw(17), sh(75)]
    hplace = ALIGN_LEFT
    vplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = colors.ControlBg
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    key = "prefab_editor"
    padding = fsh(0.5)
    gap = fsh(0.5)
    children =  [
      {
        flow = FLOW_HORIZONTAL
        size = FLEX_H
        children = [
          txt("PREFABS", {
            fontSize = hdpx(15)
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            size = FLEX_H
            margin = const [0, 0, 0, hdpx(5)]
          })
          closeButton(doClose)
        ]
      }
      prefabInfoBlock
      prefabSaveAndShatterBlock
      prefabCreateFromSelectedBlock
      addSelectedObjectsToPrefab
      {
        flow = FLOW_HORIZONTAL
        size = FLEX_H
        children = [
          txt("Prefabs (*.blk in 'userPrefabs' folder)", {
            fontSize = hdpx(15)
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            size = FLEX_H
            margin = const [0, 0, 0, hdpx(5)]
          })
          textButton(fa["refresh"], @() prefabsLibrary.set(getPrefabsInLibrary()), {textStyle = {normal = fontawesome}})
        ]
      }
      filter
      {
        size = FLEX
        children = scrollList
      }
      txt("Click to select, double click to spawn")
      @() {
        flow = FLOW_HORIZONTAL
        watch = selectedItem
        size = FLEX_H
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          textButton("Close", doClose)
          selectedItem.get() != null ? textButton("Delete prefab", doDeleteSelected, {onHover = @(on) setTooltip(on ? "Delete file of selected prefab in list from 'userPrefabs' folder" : null)}) : null
        ]
      }
    ]
  }
}


return mkDialogRoot
