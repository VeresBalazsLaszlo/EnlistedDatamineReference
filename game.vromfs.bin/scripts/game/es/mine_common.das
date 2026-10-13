module mine_common shared
require ecs
require ecs.safe
require NetPropsRegistry

def detonate_mine(mine_eid : EntityId; mineActivatorTemplate : string; owner : EntityId; tm : float3x4; delay = 0.)
  createEntity(mineActivatorTemplate) <| $(var init : ComponentsInitializer)
    set(init, "ownerEid", owner)
    set(init, "transform", tm)
    set(init, "activator__weaponEid", mine_eid)
    set(init, "activator__spawnShellDelay", delay)

// This function ensures that the shell props will be registered
// before the first explosion happens that uses on_create__spawnActivatedShellBlk
def preinit_activator_shell_props(activator_template_name : string)
  let activatorTemplate = getTemplateByName(activator_template_name)
  if activatorTemplate == null
    return
  let shellBlk = getTemplateComponent(*activatorTemplate, "on_create__spawnActivatedShellBlk") ?? ""
  if !empty(shellBlk)
    register_net_props(shellBlk, "shell")
    register_net_props(shellBlk, "damage")
    register_net_props(shellBlk, "ballistics")