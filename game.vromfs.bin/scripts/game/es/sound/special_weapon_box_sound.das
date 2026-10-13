require ecs


[es(tag=sound, on_appear, track=paid_loot__alreadyUsed, REQUIRE=specialWeaponBoxSound)]
def special_weapon_box_sound(evt : Event;
                             paid_loot__alreadyUsed : bool;
                             var sound_control__allowSound : bool&)
  sound_control__allowSound = !paid_loot__alreadyUsed
