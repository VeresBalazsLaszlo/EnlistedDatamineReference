from "%ui/ui_library.nut" import *

from "auth" import status_string_full, YU2_OK
from "%sqstd/underscore.nut" import deep_clone

function status_cb(cb) {
  return function(result) {
    if (result?.status != YU2_OK) {
      result = deep_clone(result)
      result.error <- status_string_full(result.status)
    }
    cb(result)
  }
}

return {
  status_cb
}
