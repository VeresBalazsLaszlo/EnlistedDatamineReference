from "string" import strip
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

let appBgImages = (get_setting_by_blk_path("bgImage") ?? "")
  .split(";")
  .map(strip)
  .filter(@(v) v!="")

return freeze({
  appBgImages
})
