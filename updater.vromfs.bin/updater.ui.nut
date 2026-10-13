from "daRg" import *
from "frp" import Watched

let { eventbus_subscribe } = require("eventbus")
let { loc } = require("dagor.localize")

let updaterModule = require("contentUpdater")
let { start_updater, UPDATER_EVENT_STAGE, UPDATER_EVENT_PROGRESS, UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH,
  UPDATER_CHECKING_FAST, UPDATER_CHECKING, UPDATER_DOWNLOADING_YUP, UPDATER_RESPATCH, UPDATER_DOWNLOADING,
  UPDATER_PURIFYING, UPDATER_COPYING } = updaterModule

// The updater runs before the regular game UI: fonts or localization may be
// missing or broken here. Without fonts the statuses are drawn as pseudo-text
// (vector canvas strokes, english only), so the user is never left with a
// bare spinner.
let fontsOk = ("is_fonts_available" in updaterModule) ? updaterModule.is_fonts_available() : true

const spinnerSize = sh(8)

let spinnerPic = Picture("!gear.svg:{0}:{0}:K".subst(spinnerSize, spinnerSize))

const statusColor = Color(200, 200, 200)

let updaterStage = Watched(null)
let updaterProgress = Watched(null)
let updaterError = Watched(null)

// The updater can spend minutes retrying unavailable servers; the status
// line must tell the user what the game is doing all that time
let STATUSES = {
  connecting = {
    locKey = "updater/connectingToUpdateServers", locDef = "Connecting to update servers"
    fallback = "CONNECTING TO UPDATE SERVERS"
  }
  checking = {
    locKey = "updater/checkingFiles", locDef = "Checking game files"
    fallback = "CHECKING GAME FILES"
  }
  receiving = {
    locKey = "updater/receivingUpdateInfo", locDef = "Receiving update information"
    fallback = "RECEIVING UPDATE INFORMATION"
  }
  downloading = {
    locKey = "updater/downloadingUpdate", locDef = "Downloading update"
    fallback = "DOWNLOADING UPDATE"
  }
  applying = {
    locKey = "updater/applyingUpdate", locDef = "Applying update"
    fallback = "APPLYING UPDATE"
  }
  problem = {
    locKey = "updater/updateProblem", locDef = "Update problem, retrying"
    fallback = "UPDATE PROBLEM RETRYING"
  }
}

function statusIdFor(stage, err) {
  if (err != null)
    return "problem"
  if (stage == UPDATER_CHECKING_FAST || stage == UPDATER_CHECKING)
    return "checking"
  if (stage == UPDATER_DOWNLOADING_YUP)
    return "receiving"
  if (stage == UPDATER_DOWNLOADING)
    return "downloading"
  if (stage == UPDATER_RESPATCH || stage == UPDATER_PURIFYING || stage == UPDATER_COPYING)
    return "applying"
  return "connecting"
}

// Stroke skeletons of A-Z on a 0..100 grid (top-left origin), each letter an
// array of [x1, y1, x2, y2] lines. Enough to spell the fallback statuses.
let PSEUDO_LETTERS = {
  A = [[0,100,50,0],[50,0,100,100],[20,60,80,60]]
  B = [[0,0,0,100],[0,0,80,0],[80,0,90,25],[90,25,80,50],[0,50,80,50],[80,50,100,75],[100,75,80,100],[0,100,80,100]]
  C = [[100,10,50,0],[50,0,0,20],[0,20,0,80],[0,80,50,100],[50,100,100,90]]
  D = [[0,0,0,100],[0,0,60,0],[60,0,100,25],[100,25,100,75],[100,75,60,100],[60,100,0,100]]
  E = [[100,0,0,0],[0,0,0,100],[0,100,100,100],[0,50,70,50]]
  F = [[100,0,0,0],[0,0,0,100],[0,50,70,50]]
  G = [[100,10,50,0],[50,0,0,20],[0,20,0,80],[0,80,50,100],[50,100,100,90],[100,90,100,55],[100,55,60,55]]
  H = [[0,0,0,100],[100,0,100,100],[0,50,100,50]]
  I = [[20,0,80,0],[50,0,50,100],[20,100,80,100]]
  J = [[100,0,100,80],[100,80,60,100],[60,100,20,100],[20,100,0,80]]
  K = [[0,0,0,100],[100,0,0,50],[0,50,100,100]]
  L = [[0,0,0,100],[0,100,100,100]]
  M = [[0,100,0,0],[0,0,50,45],[50,45,100,0],[100,0,100,100]]
  N = [[0,100,0,0],[0,0,100,100],[100,100,100,0]]
  O = [[25,0,75,0],[75,0,100,25],[100,25,100,75],[100,75,75,100],[75,100,25,100],[25,100,0,75],[0,75,0,25],[0,25,25,0]]
  P = [[0,100,0,0],[0,0,80,0],[80,0,100,15],[100,15,100,40],[100,40,80,55],[80,55,0,55]]
  Q = [[25,0,75,0],[75,0,100,25],[100,25,100,75],[100,75,75,100],[75,100,25,100],[25,100,0,75],[0,75,0,25],[0,25,25,0],[65,70,100,100]]
  R = [[0,100,0,0],[0,0,80,0],[80,0,100,15],[100,15,100,40],[100,40,80,55],[80,55,0,55],[40,55,100,100]]
  S = [[100,5,20,0],[20,0,0,20],[0,20,20,45],[20,45,80,55],[80,55,100,80],[100,80,80,100],[80,100,0,95]]
  T = [[0,0,100,0],[50,0,50,100]]
  U = [[0,0,0,80],[0,80,25,100],[25,100,75,100],[75,100,100,80],[100,80,100,0]]
  V = [[0,0,50,100],[50,100,100,0]]
  W = [[0,0,20,100],[20,100,50,55],[50,55,80,100],[80,100,100,0]]
  X = [[0,0,100,100],[100,0,0,100]]
  Y = [[0,0,50,45],[100,0,50,45],[50,45,50,100]]
  Z = [[0,0,100,0],[100,0,0,100],[0,100,100,100]]
}

const pseudoH = sh(1.8)
let pseudoW = (pseudoH * 0.62).tointeger()
const pseudoLineW = sh(0.16) < 2 ? 2 : sh(0.16)

function mkPseudoLetter(segments) {
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    size = [pseudoW, pseudoH]
    lineWidth = pseudoLineW
    color = statusColor
    fillColor = Color(0, 0, 0, 0)
    commands = segments.map(@(s) [VECTOR_LINE, s[0], s[1], s[2], s[3]])
  }
}

function mkPseudoText(text) {
  let chars = []
  for (local i = 0; i < text.len(); i++) {
    let ch = text.slice(i, i + 1)
    if (ch in PSEUDO_LETTERS)
      chars.append(mkPseudoLetter(PSEUDO_LETTERS[ch]))
    else
      chars.append({ size = [pseudoW, pseudoH] })
  }
  return {
    flow = FLOW_HORIZONTAL
    gap = (pseudoW * 0.45).tointeger()
    children = chars
  }
}

// built once: the six statuses are fixed strings
let pseudoStatuses = {}
foreach (id, st in STATUSES)
  pseudoStatuses[id] <- mkPseudoText(st.fallback)

function status() {
  let id = statusIdFor(updaterStage.get(), updaterError.get())

  if (!fontsOk) {
    return {
      watch = [updaterStage, updaterError]
      children = pseudoStatuses[id]
    }
  }

  return {
    watch = [updaterStage, updaterError]
    rendObj = ROBJ_TEXT
    text = loc(STATUSES[id].locKey, STATUSES[id].locDef)
    fontSize = sh(2.5)
    color = statusColor
  }
}

function progress() {
  let size = [sw(100)-sh(50)-sh(20), sh(2)]

  if (updaterProgress.get() == null) {
    return {
      size = size
      watch = updaterProgress
    }
  }

  return {
    watch = updaterProgress
    size = size
    rendObj = ROBJ_SOLID
    color = Color(91, 103, 150,120)

    halign = ALIGN_LEFT

    children = {
      rendObj = ROBJ_SOLID
      size = [pw(updaterProgress.get()), flex()]
      color = Color(200,200,200,100)
    }
  }
}


let spinner = {
  rendObj = ROBJ_IMAGE
  size = const [spinnerSize, spinnerSize]
  image = spinnerPic
  color = Color(200,200,200)

  transform = {}

  animations = [
    { prop=AnimProp.rotate, from=0, to=360, duration=3, play=true, loop=true }
  ]
}


function Root() {
  return {
    size = flex()

    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM

    padding = sh(15)

    // the scene is drawn over the animated splash: a soft scrim keeps the
    // status readable on bright splash areas
    children = {
      rendObj = ROBJ_SOLID
      color = Color(0, 0, 0, 110)
      padding = sh(2)

      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = sh(5)

      children = [
        spinner
        status
        progress
      ]
    }
  }
}


let updaterEvents = {
  [UPDATER_EVENT_STAGE]    = function(evt) {
    updaterError.set(null) // a new stage means the updater makes progress again
    updaterStage.set(evt?.stage)
  },
  [UPDATER_EVENT_PROGRESS] = @(evt) updaterProgress.set(evt?.percent),
  [UPDATER_EVENT_FINISH]   = @(_evt) null,
  [UPDATER_EVENT_ERROR]    = @(evt) updaterError.set(evt?.error),
}


const ContentUpdaterEventId = "daNetGameUpdater.event"


eventbus_subscribe(ContentUpdaterEventId, function (evt) {
  let {eventType} = evt
  updaterEvents?[eventType](evt)
})


// Start the Content Updater
print("Start the updater")
start_updater(ContentUpdaterEventId)


return Root
