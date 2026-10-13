require ecs
require DagorConsole

[es(on_appear, REQUIRE=gamemodeFriendlyFire)]
def friendly_fire_gamemode_appear(evt : Event)
  console_command("dm.dbg_friendly_fire 1")

[es(on_disappear, REQUIRE=gamemodeFriendlyFire)]
def friendly_fire_gamemode_disappear(evt : Event)
  console_command("dm.dbg_friendly_fire 0")