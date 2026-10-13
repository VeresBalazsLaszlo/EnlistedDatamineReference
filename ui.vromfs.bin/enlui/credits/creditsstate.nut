from "dagor.fs" import read_text_from_file, scan_folder
from "%dngscripts/platform.nut" import is_gdk, is_xbox, is_console
from "%enlSqGlob/appInfo.nut" import isDebugBuild
from "%ui/ui_library.nut" import *


let logC = with_prefix("[CREDITS] ")

const CREDITS_PATH = "credits"
const SECTION_DIVIDER = "==== "
const TEXT_LIMIT = 50000

local isCreditsDataPresent = false

let creditsConfig = Watched(null) 
let isCreditsConfigLoaded = Computed(@() creditsConfig.get() != null)
let creditsData = Watched([]) 
let curIndex = Watched(0)
let curPage = Watched(0)

let curCredits = Computed(@() creditsData.get()?[curIndex.get()])
let totalPages = Computed(@() curCredits.get()?.texts.len() ?? 0)
let isCurCreditsLoading = Computed(@() isCreditsConfigLoaded.get() && curCredits.get() == null)

let curDocument = Computed(function() {
  let { heading = null, texts = [] } = curCredits.get()
  let text = texts?[curPage.get()] ?? ""
  return heading ? $"{heading}{text}" : text
})

let checkFiles = const {
  ["license-enlisted"]     = !isDebugBuild && !is_gdk && !is_xbox,
  ["license-enlisted-dev"] = isDebugBuild && !is_gdk && !is_xbox,
  ["license-enlisted-gdk"] = is_gdk || is_xbox,
  ["license-cefprocess"]   = !is_console,
}

let isAvailable = @(name) checkFiles?[name] ?? true

function initCredits() {
  if (isCreditsConfigLoaded.get())
    return

  let fileList = scan_folder({
    root = CREDITS_PATH
    vromfs = true
    realfs = isDebugBuild
    recursive = true
  })

  let size = fileList.len()
  if (size == 0) {
    logC("Credits folder is empty")
    return
  }

  logC($"Credits folder scanned, files: {size}")
  let config = []
  let sliceFrom = CREDITS_PATH.len() + 1
  foreach (file in fileList) {
    let name = file.slice(sliceFrom)
    if (isAvailable(name))
      config.append({
        file
        name
        locId = $"credits/{name}"
      })
  }

  creditsConfig.set(config)
  isCreditsDataPresent = true
}

function openCredits(index) {
  let cfg = creditsConfig.get()?[index]
  if (!cfg)
    return

  if (creditsData.get()?[index] != null) {
    curIndex.set(index)
    curPage.set(0)
    return
  }

  let { file } = cfg
  let text = read_text_from_file(file)
  if (!text) {
    logC($"Empty credits file '{file}'")
    return
  }

  local heading, texts = [], start = 0, current = (text.indexof(SECTION_DIVIDER) ?? -1)
  if (current > 0) {
    heading = text.slice(0, current)
    start = current
  }
  while (current >= 0) {
    current = text.indexof(SECTION_DIVIDER, current + SECTION_DIVIDER.len()) ?? -1
    if (current < 0) {
      texts.append(text.slice(start, text.len()))
    }
    else if (current - start > TEXT_LIMIT) {
      texts.append(text.slice(start, current))
      start = current
    }
  }

  if (texts.len() == 0) {
    logC($"Credits file '{file}' is empty after parsing")
    return
  }

  logC($"Credits file '{file}' loaded at index {index}")
  creditsData.mutate(function(arr) {
    if (arr.len() <= index)
      arr.resize(index + 1, null)
    arr[index] = {
      heading
      texts
    }
  })
  curIndex.set(index)
  curPage.set(0)
}

function resetCredits() {
  creditsData.set([])
}

initCredits()

return {
  isCreditsDataPresent
  isCreditsConfigLoaded
  isCurCreditsLoading
  creditsConfig
  curIndex
  curPage
  totalPages
  curDocument
  openCredits
  resetCredits
}
