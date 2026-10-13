from "%ui/state/login_state.nut" import isLoggedIn

const path = "%ui/chat/dirty_words"
let dirtyWordsFilter = require($"{path}/dirty_words.nut")
let { init, continueInitAfterLogin } = dirtyWordsFilter

init([
  require($"{path}/dirty_words_english.nut"),
  require($"{path}/dirty_words_russian.nut"),
  require($"{path}/dirty_words_japanese.nut"),
])

isLoggedIn.subscribe(@(v) v ? continueInitAfterLogin() : null)

return dirtyWordsFilter
