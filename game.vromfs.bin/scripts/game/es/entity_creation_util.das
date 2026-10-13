require ecs
require math.base
require DagorRandom

[es(on_appear)]
def float_randomize_on_appear(evt : Event;
                              eid : EntityId;
                              on_appear__randomizeFloatCompNames : StringList;
                              on_appear__randomizeFloatCompRanges : Point2List)
  for nameStr, valueRange in on_appear__randomizeFloatCompNames, on_appear__randomizeFloatCompRanges
    peek(nameStr) <| $(name)
      let nameHash = ecs_hash(name)
      set(eid, name, nameHash, rnd_float(valueRange.x, valueRange.y))
