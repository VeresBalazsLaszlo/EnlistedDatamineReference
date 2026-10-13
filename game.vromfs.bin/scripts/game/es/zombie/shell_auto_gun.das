require ecs
require ecs.safe
require app
require common_shooter.es.human.human_gun_common
require NetPropsRegistry
require DngWeapon
require math
require math.base
require DagorMathUtils
require DagorRandom
require DaWeaponProps
require enlisted.events_enlisted
require AnimV20
require GeomNodeTree
require DagorMath


def shell_auto_gun_spawn_shell(transform : float3x4;
                               on_create__spawnActivatedShellBlk : string;
                               startVel : float3;
                               on_create__addShellTemplate : das_string const?;
                               on_create__spawnShellTimer : float = -1.0f;
                               ownerEid : EntityId = INVALID_ENTITY_ID;
                               target : EntityId = INVALID_ENTITY_ID)
  using() <| $(var shell_props : ShellPropIds#)
    shell_props.shellId = int16(register_net_props(on_create__spawnActivatedShellBlk, "shell"))
    shell_props.damageId = int16(register_net_props(on_create__spawnActivatedShellBlk, "damage"))
    shell_props.ballisticsId = int16(register_net_props(on_create__spawnActivatedShellBlk, "ballistics")) //item.shell
    var timer = 0.0
    if on_create__spawnShellTimer < 0.0
      detonation_get_props(int(shell_props.shellId)) <| $(detonationProps : DetonationProps)
        timer = detonationProps.timer
    else
      timer = on_create__spawnShellTimer
    shell_entity_get_props(int(shell_props.shellId)) <| $(shellEntityProp : ShellEntityTypeProps)
      var physTemplName = shellEntityProp |> shell_entity_props_get_physTemplName()

      if on_create__addShellTemplate != null
        let shellTemplateName = *on_create__addShellTemplate |> string()
        physTemplName = add_sub_template_name(physTemplName, shellTemplateName)

      create_shell_entity(physTemplName, transform, startVel,
                          ownerEid, shell_props, /*gun_props_id*/ -1,
                          /*launchTime*/ get_sync_time(),
                          /*explTime*/ get_sync_time() + timer,
                          /*in_active*/ true,
                          /*clientSide*/ false,
                          /*rethrowerEid*/ INVALID_ENTITY_ID,
                          target)

[es(tag=server, REQUIRE=shell_auto_gun)]
def shell_auto_gun_on_update_es(info : ParallelUpdateFrameDelayed;
                                shell_auto_gun__nodeIndex : int;
                                shell_auto_gun__spawnActivatedShellBlk : string;
                                shell_auto_gun__speedRange : float2;
                                shell_auto_gun__addShellTemplate : das_string const?;
                                shell_auto_gun__spawnShellTimer : float = -1.0f;
                                shell_auto_gun__ownerEid : EntityId = INVALID_ENTITY_ID;
                                shell_auto_gun__xAngleRange : float2;
                                shell_auto_gun__yAngleRange : float2;
                                shell_auto_gun__periodTime : float;
                                shell_auto_gun__spawn_count : int = 1;
                                var shell_auto_gun__activateNextTime : float&)
  if shell_auto_gun__activateNextTime > info.curTime
    return
  var tm : float3x4
  var useShootTarget = false
  var posToTarget = float3()
  var target = INVALID_ENTITY_ID
  query(shell_auto_gun__ownerEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                             walker_agent__priorityTarget : EntityId;
                                             shell_auto_gun__shootTarget : Tag const?)
    *animchar.nodeTree |> geomtree_getNodeWtmScalar(shell_auto_gun__nodeIndex, tm)
    if shell_auto_gun__shootTarget != null
      useShootTarget = true
      target = walker_agent__priorityTarget
      query(walker_agent__priorityTarget) <| $ [es] (human__aimTm : float3x4)
        posToTarget = human__aimTm[3]
  tm |> orthonormalize()
  for _ in range(shell_auto_gun__spawn_count)
    var angles = useShootTarget ? dir_to_angles(normalize(posToTarget - tm[3])) : dir_to_angles(tm[1])
    let randomXAng = rnd_float(deg_to_rad(shell_auto_gun__xAngleRange.x), deg_to_rad(shell_auto_gun__xAngleRange.y))
    angles.x += randomXAng
    let randomYAng = rnd_float(deg_to_rad(shell_auto_gun__yAngleRange.x), deg_to_rad(shell_auto_gun__yAngleRange.y))
    angles.y += randomYAng
    let dir = angles_to_dir(angles)
    let randomSpeed = rnd_float(shell_auto_gun__speedRange.x, shell_auto_gun__speedRange.y)
    let vel = randomSpeed * dir
    shell_auto_gun_spawn_shell(tm, shell_auto_gun__spawnActivatedShellBlk, vel, shell_auto_gun__addShellTemplate, shell_auto_gun__spawnShellTimer, shell_auto_gun__ownerEid, target)
  shell_auto_gun__activateNextTime = info.curTime + shell_auto_gun__periodTime

[es(on_appear, REQUIRE_NOT=deadEntity)]
def zombie_giant_boss_init_abilitity_activate(evt : Event;
                                              zombie_giant_boss_shell__templateName : string)
  var shellSpawnerTemplate = getTemplateByName(zombie_giant_boss_shell__templateName)
  if shellSpawnerTemplate != null
    let shellBlk = getTemplateComponent(*shellSpawnerTemplate, "shell_auto_gun__spawnActivatedShellBlk") ?? ""
    if shellBlk != ""
      register_net_props(shellBlk, "shell")
      register_net_props(shellBlk, "damage")
      register_net_props(shellBlk, "ballistics")

[es(tag=server, track=zombie_ability__activated, REQUIRE_NOT=deadEntity)]
def zombie_giant_boss_on_abilitity_activate(evt : Event;
                                            eid : EntityId;
                                            animchar aka boss_animchar : AnimcharBaseComponent;
                                            zombie_giant_boss_shell__speedRange : float2;
                                            zombie_giant_boss_shell__xAngleRange : float2;
                                            zombie_giant_boss_shell__yAngleRange : float2;
                                            zombie_giant_boss__activation_delay_time : float;
                                            zombie_giant_boss_shell__periodTime : float;
                                            zombie_giant_boss_shell__spawn_count : int;
                                            zombie_giant_boss_shell__nodeName : string;
                                            zombie_giant_boss_shell__templateName : string;
                                            zombie_ability__activated : bool;
                                            var zombie_giant_boss_shell__itemEid : EntityId&)
  if !zombie_ability__activated
    destroyEntity(zombie_giant_boss_shell__itemEid)
    return

  let boss_head__nodeIndex = *boss_animchar.nodeTree |> geomtree_findNodeIndex(zombie_giant_boss_shell__nodeName)
  if boss_head__nodeIndex < 0
    return

  let zombie_giant_boss_shell__activateNextTime = get_sync_time() + zombie_giant_boss__activation_delay_time

  zombie_giant_boss_shell__itemEid = createEntity(zombie_giant_boss_shell__templateName) <| $(var init)
    set(init, "shell_auto_gun__ownerEid", eid)
    set(init, "shell_auto_gun__nodeIndex", boss_head__nodeIndex)
    set(init, "shell_auto_gun__xAngleRange", zombie_giant_boss_shell__xAngleRange)
    set(init, "shell_auto_gun__yAngleRange", zombie_giant_boss_shell__yAngleRange)
    set(init, "shell_auto_gun__speedRange", zombie_giant_boss_shell__speedRange)
    set(init, "shell_auto_gun__activateNextTime", zombie_giant_boss_shell__activateNextTime)
    set(init, "shell_auto_gun__periodTime", zombie_giant_boss_shell__periodTime)
    set(init, "shell_auto_gun__spawn_count", zombie_giant_boss_shell__spawn_count)


[es(tag=server, REQUIRE_NOT=deadEntity, on_disappear)]
def zombie_giant_boss_on_disappear(evt : Event;
                                   zombie_giant_boss_shell__itemEid : EntityId)
  if !!zombie_giant_boss_shell__itemEid
    destroyEntity(zombie_giant_boss_shell__itemEid)
