from "%ui/hud/state/eventlog_state.nut" import MAX_EVENTS_DEFAULT
from "net" import get_sync_time

let { EventLogState } = require("%ui/hud/state/eventlog_state.nut")

let AwardLogState = class (EventLogState) {
  unAwardedScore = null
  unAwardedScoreLastInsertTime = 0
  unAwardedScoreKeepTime = 5

  constructor(persistId, clearSameTime = -1, maxActiveEvents = MAX_EVENTS_DEFAULT, ttl = 5.0, collapseByFunc=null){
    base.constructor(persistId, clearSameTime, maxActiveEvents, ttl, collapseByFunc)
    this.unAwardedScore = {}
  }

  function tryAddCachedScoreToAward(awardData) {
    let scoreId = awardData?.scoreId
    if (scoreId) {
      let score = this.unAwardedScore?[scoreId]
      if (score) {
        this.unAwardedScore.$rawdelete(scoreId)
        awardData.score <- (awardData?.score ?? 0) + score
      }
    }
  }

  function cacheUnawardedScore(awardData) {
    let score = awardData?.score ?? 0
    let scoreId = awardData?.type ?? ""
    if (score > 0 && scoreId != "") {
      this.unAwardedScore[scoreId] <- (this.unAwardedScore?[scoreId] ?? 0) + score
      this.unAwardedScoreLastInsertTime = get_sync_time()
    }
  }

  function tryApplyScore(awardData) {
    let scoreId = awardData?.type
    let score = awardData.score
    local isApplied = false
    if (scoreId) {
      this.events.mutate(function(eventsVal) {
        foreach (e in eventsVal)
          if (e?.awardData.scoreId == scoreId) {
            e.awardData.score <- (e.awardData?.score ?? 0) + score
            isApplied = true
            break
          }
      })
    }
    return isApplied
  }

  function checkClearUnAwardedCache() {
    if (this.events.get().len() == 0
      && get_sync_time() - this.unAwardedScoreLastInsertTime > this.unAwardedScoreKeepTime) {
        this.unAwardedScore.clear()
    }
  }

  function awardGroupKey(award) {
    return award?.awardData.groupKey ?? award?.awardData.type
  }

  function isEventSame(a, b) {
    return this.awardGroupKey(a) == this.awardGroupKey(b)
  }

  function groupSame(event) {
    for (local i = this.events.get().len() - 1; i >= 0; i--) {
      let eventToRemove = this.events.get()[i]
      if (this.isEventSame(eventToRemove, event)) {
        event.num <- (eventToRemove?.num ?? 1) + 1
        this.events.get().remove(i)
        break
      }
    }
  }

  function clearEvents(){
    base.clearEvents()
    this.unAwardedScore?.clear()
  }

  function pushEvent(eventExt, collapseBy=null) {
    this.checkClearUnAwardedCache()
    let awardData = eventExt?.awardData
    this.tryAddCachedScoreToAward(awardData)
    if (!(awardData?.hasAward ?? true)) {
      if (!this.tryApplyScore(awardData))
        this.cacheUnawardedScore(awardData)
      return
    }
    this.groupSame(eventExt)
    base.pushEvent(eventExt, collapseBy)
  }
}

return AwardLogState
