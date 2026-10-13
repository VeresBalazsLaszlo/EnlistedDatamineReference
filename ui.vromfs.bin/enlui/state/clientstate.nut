from "app" import get_app_id
from "dagor.localize" import getCurrentLanguage, getForceLanguage, setLanguageToSettings

let appId = get_app_id()

function initForceLanguage() {
  let forceLanguage = getForceLanguage()
  if (forceLanguage != "")
    setLanguageToSettings(forceLanguage)
}
initForceLanguage()

let gameLanguage = getCurrentLanguage()
let isChineseLanguage = gameLanguage.tolower().contains("chinese")
let isJapaneseLanguage = gameLanguage.tolower().contains("japanese")

return {
  appId
  gameLanguage
  isChineseLanguage
  isJapaneseLanguage
}
