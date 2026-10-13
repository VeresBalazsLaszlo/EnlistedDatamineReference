require ecs
require strings
require AnimV20
require GeomNodeTree


def apply_gore_to_human(eid : EntityId; is_gore_enabled : bool)
  if is_gore_enabled
    addSubTemplate(eid, "human_broken_bones")
  else
    removeSubTemplate(eid, "human_broken_bones")

def apply_violence_to_attachable_wear(eid : EntityId; is_gore_enabled : bool; is_blood_enabled : bool)
  if is_gore_enabled
    addSubTemplate(eid, "attachable_wear_broken_bones_data")
  else
    removeSubTemplate(eid, "attachable_wear_broken_bones_data")

  if is_blood_enabled
    addSubTemplate(eid, "attachable_wear_projective_wounds_data")
  else
    removeSubTemplate(eid, "attachable_wear_projective_wounds_data")


[es(tag=gameClient, on_appear, REQUIRE=human)]
def apply_violence_settings_to_humans(evt : Event; eid : EntityId)
  query() <| $ [es] (isGoreEnabled : bool)
    apply_gore_to_human(eid, isGoreEnabled)

[es(tag=gameClient, on_appear, REQUIRE=attachableBrokenBonesWear, before=preload_projective_wounds_index_es)]
def apply_violence_settings_to_attachable_wear(evt : Event; eid : EntityId)
  query() <| $ [es] (isGoreEnabled : bool; isBloodEnabled : bool)
    apply_violence_to_attachable_wear(eid, isGoreEnabled, isBloodEnabled)


[es(tag=gameClient, track=isGoreEnabled, track=isBloodEnabled)]
def violence_settings_changed_es(evt : Event; isGoreEnabled : bool; isBloodEnabled : bool)
  query() <| $ [es(REQUIRE=human)] (eid : EntityId)
    apply_gore_to_human(eid, isGoreEnabled)
  query() <| $ [es(REQUIRE=attachableBrokenBonesWear)] (eid : EntityId)
    apply_violence_to_attachable_wear(eid, isGoreEnabled, isBloodEnabled)


[es(tag=render, on_appear, after=apply_violence_settings_to_attachable_wear)]
def preload_projective_wounds_index_es(evt : Event;
                                       animchar : AnimcharBaseComponent;
                                       var projective_wounds__allowedSkeletonNodes : IntList&)
  for i in range(animchar.nodeTree.nodeCount)
    let nodeName = *animchar.nodeTree |> geomtree_getNodeName(i)
    if -1 != nodeName |> find("Bip01")
      projective_wounds__allowedSkeletonNodes |> push(i)
