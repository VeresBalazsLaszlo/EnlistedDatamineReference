from "%sqstd/functools.nut" import *
import "%dngscripts/ecs.nut" as ecs
let {app_is_offline_mode} = require("%enlSqGlob/offline_mode.nut")
let {exit_game, connect_to_session, switch_scene, get_matching_invite_data} = require("app")
let {get_arg_value_by_name, dgs_get_settings, get_all_arg_values_by_name} = require("dagor.system")
let isDedicated = require_optional("dedicated") != null
let { logerr } = require("dagor.debug")
let {EventOnGameAppStarted} = require("gameevents")
let Log = require("%sqstd/log.nut")
let {MOD_BY_VERSION_URL} = require("%enlSqGlob/game_mods_constant.nut")
let log = Log().with_prefix("[GAME LOAD] ")
let {downloadMod, getModStartInfo} = require("%enlSqGlob/modsDownloadManager.nut")


function on_gameapp_started() {
  let settings = dgs_get_settings()
  local connect = isDedicated ? [] : get_all_arg_values_by_name("connect")
  if (!(connect.len() > 0 || isDedicated || settings?.disableMenu || app_is_offline_mode())) {
    switch_scene("gamedata/scenes/empty.blk") 
    return
  }

  let inviteData = get_matching_invite_data()
  log("inviteData", inviteData)
  let modId = inviteData?.mode_info.modId ?? ""
  let modVersion = inviteData?.mode_info.modVersion ?? "1"
  let modUrl = modId != "" ? MOD_BY_VERSION_URL.subst(modId, modVersion) : ""

  if (connect.len() > 0) {
    if (modId == "")
      connect_to_session({host_urls = connect})
    else {
      downloadMod(modUrl, function(manifest, contents) {
        let modStartInfo = getModStartInfo(manifest, contents)
        log("modStartInfo", modStartInfo)
        connect_to_session({host_urls = connect}, {modId}.__update(modStartInfo))
      }, function(error_msg, http_code) {
        logerr($"Failed to download mode /*{modUrl}*/ error = /*{error_msg}*/, http: /*{http_code}*/")
        exit_game()
      })
    }
  } else {
    let scene = get_arg_value_by_name("scene") ?? settings?.scene
    local importScenes = inviteData?.mode_info.imports
    if (importScenes==null){
      importScenes = get_all_arg_values_by_name("importScene")
      importScenes =  importScenes.len()>0 ? importScenes : null
    }

    if (modId=="") {
      log($"no mod found, starting with scene = {scene}, importScenes = {",".join(importScenes ?? [])}")
      switch_scene(scene, importScenes)
    }
    else {
      downloadMod(modUrl, function(manifest, contents) {
        let modStartInfo = getModStartInfo(manifest, contents)
        log("modStartInfo", modStartInfo)
        switch_scene(modStartInfo.scene, importScenes, {modId}.__update(modStartInfo))
      }, function(error_msg, http_code) {
        logerr($"Failed to download mode /*{modUrl}*/ error = /*{error_msg}*/, http: /*{http_code}*/")
        exit_game()
      })
    }
  }
}

ecs.register_es("on_gameapp_started_es",
  {
    [EventOnGameAppStarted] = on_gameapp_started,
  })
