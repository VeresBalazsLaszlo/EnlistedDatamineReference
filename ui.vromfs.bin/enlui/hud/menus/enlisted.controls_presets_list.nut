import "dainput2" as dainput
from "%dngscripts/platform.nut" import platformId, is_steam_deck

let export = {
  ps4 = [
    "config/enlisted.default~ps4"
    "config/enlisted.updated~ps4"
    "config/enlisted.gyro~ps4"
  ]
  ps5 = [
    "config/enlisted.default~ps5"
    "config/enlisted.updated~ps5"
    "config/enlisted.gyro~ps5"
  ]
  win32 = [
    "config/enlisted.default"
    
    "config/enlisted.updated"
  ]
  win64 = [
    "config/enlisted.default"
    
    "config/enlisted.updated"
  ]
  linux64 = [
    "config/enlisted.default"
    "config/enlisted.updated"
  ]
  xboxOne = [
    "config/enlisted.default~xboxOne"
    "config/enlisted.updated~xboxOne"

  ]
  xboxScarlett = [
    "config/enlisted.default~xboxScarlett"
    "config/enlisted.updated~xboxScarlett"
  ]
  steamdeck = [
    "config/enlisted.default~steamdeck"
  ]
}

let controlsPlatformId = is_steam_deck ? "steamdeck" : platformId

if (export?[controlsPlatformId] == null)
  export[controlsPlatformId] <- [dainput.get_default_preset_prefix()]
return freeze(export)
