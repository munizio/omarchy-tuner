// RainViewer tile URLs and manifest parsing.
// Adapted from eduardodallecort/omarchy-weather-radar (MIT).
// API: https://www.rainviewer.com/api/weather-maps-api.html

.pragma library

var MANIFEST_URL = "https://api.rainviewer.com/public/weather-maps.json"
var MAX_RADAR_ZOOM = 7
var MIN_RADAR_ZOOM = 3
var MAX_MAP_ZOOM = 10
var NEXRAD_SCHEME = 5

function tileUrl(host, framePath, size, zoom, x, y, colorScheme, smooth, snow) {
  if (!host || !framePath) return ""
  return host + framePath + "/" + size + "/" + zoom + "/" + x + "/" + y
    + "/" + colorScheme + "/" + (smooth ? 1 : 0) + "_" + (snow ? 1 : 0) + ".png"
}

function parseManifest(raw) {
  var text = String(raw || "").trim()
  if (text === "") return null

  var data
  try {
    data = JSON.parse(text)
  } catch (e) {
    return null
  }
  if (!data || typeof data.host !== "string" || !data.radar) return null

  var past = normalizeFrames(data.radar.past)
  if (past.length === 0) return null

  var nowcast = normalizeFrames(data.radar.nowcast)
  return {
    host: data.host,
    past: past,
    nowcast: nowcast,
    frames: past.concat(nowcast)
  }
}

function normalizeFrames(list) {
  if (!Array.isArray(list)) return []
  var frames = []
  for (var i = 0; i < list.length; i++) {
    var frame = list[i]
    if (!frame || typeof frame.path !== "string" || frame.path === "") continue
    var time = Number(frame.time)
    if (!isFinite(time) || time <= 0) continue
    frames.push({ time: time, path: frame.path })
  }
  frames.sort(function(a, b) { return a.time - b.time })
  return frames
}

function formatFrameTime(epochSeconds) {
  if (!epochSeconds) return ""
  var date = new Date(epochSeconds * 1000)
  return pad(date.getHours()) + ":" + pad(date.getMinutes())
}

function pad(value) {
  return value < 10 ? "0" + value : String(value)
}
