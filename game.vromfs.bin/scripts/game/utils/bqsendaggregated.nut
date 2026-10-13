from "dagor.debug" import logerr

let { send_event_bq_with_header = null } = require_optional("bigquery")

function bqCreate() {
  return []
}

function bqAppend(bqRequestHolder, queue, data) {
  bqRequestHolder.append({ queue, data })
}

function bqSend(bqRequestHolder) {
  if (send_event_bq_with_header == null) {
    logerr("Missing bigquery module. Allowed on dedicated only.")
    return
  }

  foreach (request in bqRequestHolder) {
    let { queue, data } = request
    send_event_bq_with_header?(queue, data)
  }
  bqRequestHolder.clear()
}

return {
  bqCreate
  bqAppend
  bqSend
}
