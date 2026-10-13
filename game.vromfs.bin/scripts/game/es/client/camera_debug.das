options no_aot
options no_global_variables = false
require ecs
require ecs.common
require player
require DagorConsole
require DagorSystem
require game.utils.hero
require game.events_game
require math
require math.base
require DngCamera
require DagorFiles
require DagorDataBlock

var g_tps_angle = 0.0

[console_cmd(name="player.tps_angle")]
def player_tps_angle(ang : float = 0.0)
  g_tps_angle = ang
  if ang == 0.0
    console_print("TPS angle reset (camera behind)")
  else
    console_print("TPS camera angle {ang} deg")

[es(tag=render, REQUIRE=isTpsView, after=shooter_cam_update_tm_es, before=after_camera_sync)]
def dev_tps_angle_cam_es(info : UpdateStageInfoAct;
                         camera__active : bool;
                         camera__target : EntityId;
                         var transform aka camera_transform : float3x4&;
                         var camera__accuratePos : DPoint3&)
  if !camera__active || g_tps_angle == 0.0
    return
  query(camera__target) <| $ [es] (camera__look_at : DPoint3)
    var rotTm : float3x4
    let up = float3(0, 1, 0)
    make_tm(up, g_tps_angle * (PI / 180.0), rotTm)
    let curPos = DPoint3(camera_transform[3])
    let offset = float3(curPos - camera__look_at)
    let rotatedOffset = rotate(rotTm, offset)
    let newPos = camera__look_at + DPoint3(rotatedOffset)
    camera_transform = rotTm * camera_transform
    camera_transform[3] = float3(newPos)
    camera__accuratePos = newPos



[console_cmd(name="player.enable_tps_camera")]
def player_enable_tps_camera()
  find_query() <| $ [es(REQUIRE=hero)] (var camNames : Array; human_anim__vehicleSelected : EntityId)
    if find_index(camNames, "dev_tps_cam") < 0
      push(camNames, "dev_tps_cam")
    query(human_anim__vehicleSelected) <| $ [es] (var camNames : Array)
      if find_index(camNames, "dev_tps_tankcam") < 0
        push(camNames, "dev_tps_tankcam")
    return true

  sendEvent(get_local_player_eid(), CmdSwitchCamera())

[console_cmd(name="plane.enable_tps_camera")]
def plane_enable_tps_camera()
  find_query() <| $ [es(REQUIRE=hero)] (human_anim__vehicleSelected : EntityId)
    query(human_anim__vehicleSelected) <| $ [es] (var camNames : Array)
      if find_index(camNames, "plane_tps_cam") < 0
        push(camNames, "plane_tps_cam")
    return true

  sendEvent(get_local_player_eid(), CmdSwitchCamera())

[console_cmd(name="camera.blk_tm")]
def copy_camera_itm_cmd()
  find_query() <| $ [es] (eid : EntityId; camera__active : bool; transform : float3x4)
    if camera__active
      let s = "[[{transform[0]}] [{transform[1]}] [{transform[2]}] [{transform[3]}]]"
      console_print("{getEntityTemplateName(eid)} tm: {s}")
      set_clipboard_ansi_text(s)
      return true
    return false


[console_cmd(name="camera.save")]
def console_camera_save(slot = "slot0")
  var cameraTm = IDENT_TM
  let cameraFound = find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      cameraTm = transform
      return true
    return false
  if !cameraFound
    console_print("No active cameras found.")
    return

  let filename = "cameraPositions.blk"
  using() <| $(var cameraPositions : DataBlock)
    var fileStat : DagorStat
    if df_stat(filename, fileStat) >= 0
      datablock_load(cameraPositions, filename)
    cameraPositions |> datablock_remove_block(slot)
    datablock_add_block(cameraPositions, slot) <| $(cameraSlot)
      cameraSlot |> add("tm", cameraTm)
    datablock_save_to_text_file(cameraPositions, filename)


[console_cmd(name="camera.restore")]
def console_camera_restore(slot = "slot0")
  var cameraTm = IDENT_TM
  let filename = "cameraPositions.blk"
  using() <| $(var cameraPositions : DataBlock)
    var fileStat : DagorStat
    if df_stat(filename, fileStat) >= 0
      datablock_load(cameraPositions, filename)
      datablock_get_block(cameraPositions, slot) <| $(cameraSlot)
        if datablock_param_exists(cameraSlot, "tm", -1)
          cameraTm = datablock_getTm(cameraSlot, "tm", IDENT_TM)
          set_cam_itm(cameraTm)


[console_cmd(name="camera.fov")]
def console_camera_fov(new_fov = -1.0)
  let cameraFound = find_query() <| $ [es] (camera__active : bool; var fov aka camera_fov : float&)
    if camera__active
      if new_fov > 0.0
        camera_fov = new_fov
        console_print("Camera FOV changed to {camera_fov}.")
      else
        console_print("Camera FOV is {camera_fov}.")
      return true
    return false

  if !cameraFound
    console_print("No active cameras with FOV found.")


[console_cmd(name="camera.dir")]
def console_camera_dir(dir_1 = 2.0; dir_2 = 2.0; dir_3 = 2.0)
  var cameraTm = IDENT_TM
  let cameraFound = find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      cameraTm = transform
      return true
    return false
  if !cameraFound
    console_print("No active cameras found.")
    return

  var cameraDir = cameraTm[2]
  if dir_1 > 1.0 && dir_2 > 1.0 && dir_3 > 1.0
    console_print("Camera dir {cameraDir.x} {cameraDir.y} {cameraDir.z}")
    set_clipboard_ansi_text("{cameraDir.x}, {cameraDir.y}, {cameraDir.z}")
    return
  elif dir_2 > 1.0 && dir_3 > 1.0
    cameraDir.y = dir_1
  elif dir_3 > 1.0
    cameraDir.x = dir_1
    cameraDir.z = dir_2
  else
    cameraDir.x = dir_1
    cameraDir.y = dir_2
    cameraDir.z = dir_3

  cameraTm[2] = cameraDir
  cameraTm[0] = cross(float3(0.0, 1.0, 0.0), cameraTm[2])
  cameraTm[1] = cross(cameraTm[2], cameraTm[0])
  cameraTm |> orthonormalize()
  set_cam_itm(cameraTm)


[console_cmd(name="camera.set_offset")]
def console_camera_set_offset(offset_x, offset_y, offset_z : float)
  let cameraFound = find_query() <| $ [es] (camera__active : bool; var shooter_cam__offset : float3&)
    if camera__active
      shooter_cam__offset = float3(offset_x, offset_y, offset_z)
      return true
    return false
  if !cameraFound
    console_print("No active cameras with shooter_cam__offset found.")
    return


[console_cmd(name="camera.tm")]
def console_camera_tm()
  let cameraFound = find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      console_print("Camera tm {transform}")
      set_clipboard_ansi_text("{transform}")
      return true
    return false
  if !cameraFound
    console_print("No active cameras found.")
    return


[console_cmd(name="camera.speed")]
def console_camera_speed(speed = -1.0)
  if speed < 0.0
    let speeds = get_free_cam_speeds()
    console_print("Default speed: {speeds.x}\nCurrent speed: {speeds.y}\nTurbo scale: {speeds.z}")
  else
    query() <| $ [es(REQUIRE=free_cam)] (var free_cam__move_speed : float&)
      free_cam__move_speed = speed
