from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "%dngscripts/platform.nut" import is_console, is_steam_deck

let defaultValue = is_console || is_steam_deck

let biggerFontsState = nestWatched(
  "biggerFontsState", get_setting_by_blk_path("highReadabilityEnabled") ?? defaultValue
)
let biggerFontsStateUpdate = @(v) biggerFontsState.set(v)


return {
  biggerFontsState
  biggerFontsStateUpdate
}
