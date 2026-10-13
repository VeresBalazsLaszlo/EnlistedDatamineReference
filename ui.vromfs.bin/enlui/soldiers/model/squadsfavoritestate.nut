from "%ui/options/onlineSettings.nut" import settings
from "%ui/ui_library.nut" import *


const FAVORITE = "squad_favorite"

let favoriteSquads = Computed(@() settings.get()?[FAVORITE])

function addFavorite(squadId) {
  settings.mutate(function(v) {
    let current = FAVORITE in v ? (clone v[FAVORITE]) : {}
    current[squadId] <- true
    v[FAVORITE] <- current
  })
}

function removeFavorite(squadId) {
  settings.mutate(function(v) {
    let current = clone v[FAVORITE]
    current.$rawdelete(squadId)
    v[FAVORITE] <- current
  })
}

return {
  favoriteSquads
  addFavorite
  removeFavorite
}
