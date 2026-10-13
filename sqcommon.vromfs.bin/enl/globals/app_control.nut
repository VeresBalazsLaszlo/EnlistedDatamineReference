import "%dngscripts/ecs.nut" as ecs
from "app" import exit_game, switch_scene_and_update
from "dasevents" import EventGameSessionFinished
from "dagor.fs" import file_exists
from "dagor.system" import dgs_get_settings


let { disableMenu } = require("offline_mode.nut")

let menuScene = dgs_get_settings()?["scene"] ?? "gamedata/scenes/campaigns_menu_squad_diorama_scene.blk"
local useCustomMenuScene = false

let currentUserMenuModId = dgs_get_settings()?.menu.modId ?? ""
let userMenuSceneFile = dgs_get_settings()?.menu.scene ?? ""
if (userMenuSceneFile && file_exists(userMenuSceneFile)) {
  useCustomMenuScene = true

  println($"useCustomMenuScene = {useCustomMenuScene}, currentUserMenuModId = '{currentUserMenuModId}', userMenuSceneFile = '{userMenuSceneFile}'")
}

function switch_to_menu_scene() {
  if (disableMenu) {
    exit_game()
    return
  }
  ecs.g_entity_mgr.broadcastEvent(EventGameSessionFinished())
  println($"useCustomMenuScene={useCustomMenuScene}, userMenuSceneFile = '{userMenuSceneFile}'")
  switch_scene_and_update((useCustomMenuScene && file_exists(userMenuSceneFile)) ? userMenuSceneFile : menuScene)
}

return freeze({
  switch_to_menu_scene
  getUseCustomMenuScene = @() useCustomMenuScene
  setUseCustomMenuScene  = @(val) useCustomMenuScene=val
  getCustomMenuSceneFile = @() userMenuSceneFile
})