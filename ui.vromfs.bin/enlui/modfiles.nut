from "%enlSqGlob/game_mods_constant.nut" import MOD_FILE_URL
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "dagor.fs" import scan_folder, file_exists
from "io" import file
from "statsd" import send_counter
from "%ui/ui_library.nut" import *

const USER_MODS_FOLDER = "userGameMods"
const MODS_EXT =".vromfs.bin"

const FILE_REQUESTED = 0
const FILE_ERROR = 1

function checkModFileByHash(hash){
  if (!file_exists($"{USER_MODS_FOLDER}/{hash}{MODS_EXT}"))
    return false
  return true
}

let isStrHash = @(hash) hash.len()==64

function getFiles(){
  let res = {}
  let files = scan_folder({root=USER_MODS_FOLDER, vromfs = false, realfs = true, recursive = false, files_suffix=MODS_EXT})
  foreach (f in files){
    let hash = f.slice(USER_MODS_FOLDER.len()+1, -MODS_EXT.len())
    if (!isStrHash(hash))
      continue
    res[hash] <- true
  }
  return res
}
let receivedFiles = Watched(getFiles())

let requestedFiles = Watched({})
function setHashError(hash){
  requestedFiles.mutate(function(v) {
      v[hash] <- FILE_ERROR 
   })
}

async function downloadFileByHash(hash){
  const ERROR_MSG = "ERROR in file request"
  let url = MOD_FILE_URL.subst(hash)

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("file_mod_receive_errors", 1, { http_code })
    log(ERROR_MSG, "http_code =", http_code)
    setHashError(hash)
    return
  }

  try {
    
    let resultFile = file($"{USER_MODS_FOLDER}/{hash}.vromfs.bin", "wb+")
    resultFile.writeblob(body)
    resultFile.close()
    receivedFiles.modify(@(v) v.rawset(hash, true))
    requestedFiles.mutate(function(v) {
      if (hash in v)
        v.$rawdelete(hash)
     })
  }
  catch(e){
    log(ERROR_MSG, e)
    setHashError(hash)
  }
}

function requestFilesByHashes(hashes){
  foreach (hash_ in hashes){
    let hash = hash_
    if (hash in receivedFiles.get())
      continue
    else {
      let v = clone receivedFiles.get()
      if (hash in v)
        v.$rawdelete(hash)
      receivedFiles.set(v)
    }
    if (checkModFileByHash(hash))
      receivedFiles.modify(@(v) v.rawset(hash, true))
    if (requestedFiles.get() ?[hash] == FILE_REQUESTED)
      continue
    requestedFiles.mutate(@(v) v[hash]<-FILE_REQUESTED)
    downloadFileByHash(hash)
  }
}


return {
  USER_MODS_FOLDER
  MODS_EXT
  receivedFiles
  requestedFiles
  requestFilesByHashes
  isStrHash
}
