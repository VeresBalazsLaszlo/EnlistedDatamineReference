from "das.human_weap" import remove_item_from_weap_to_inventory
from "das.inventory" import drop_weap_from_slot, drop_gear_from_slot
from "%ui/ui_library.nut" import *

console_register_command(function(weaponSlotName) {drop_weap_from_slot(weaponSlotName)},
  "inventory.drop_weap_from_slot")

console_register_command(function(equipmentSlotName) {drop_gear_from_slot(equipmentSlotName)},
  "inventory.drop_gear_from_slot")

console_register_command(function(weaponSlotName, weapModSlotName) {remove_item_from_weap_to_inventory(weaponSlotName, weapModSlotName)},
  "inventory.remove_item_from_weap")
