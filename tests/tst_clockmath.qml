import QtQuick
import QtTest
import ".." as Plugin
import "../ClockMath.js" as ClockMath
import "../Config.js" as PluginConfig

TestCase {
  name: "OrbitalLock"

  function test_angles() {
    var date = new Date(2026, 7, 26, 15, 30, 15, 500)
    compare(Math.round(ClockMath.secondAngle(date) * 10) / 10, -93)
    compare(Math.round(ClockMath.minuteAngle(date) * 100) / 100, -181.55)
    compare(ClockMath.normalizeAngle(-90), 270)
    compare(ClockMath.angularDistance(350, 10), 20)
  }

  function test_hour_text() {
    compare(ClockMath.hourText(new Date(2026, 7, 26, 0, 0, 0), "24"), "00")
    compare(ClockMath.hourText(new Date(2026, 7, 26, 0, 0, 0), "12"), "12")
    compare(ClockMath.hourText(new Date(2026, 7, 26, 15, 0, 0), "12"), "03")
  }

  function test_visible_edge_alignment() {
    var date = new Date(2026, 7, 26, 3, 3, 3, 0)
    var minuteMarker = 3 * 6 + ClockMath.visibleEdgeRotation(ClockMath.minuteAngle(date))
    var secondMarker = 3 * 6 + ClockMath.visibleEdgeRotation(ClockMath.secondAngle(date))
    compare(Math.round(minuteMarker * 10) / 10, 89.7)
    compare(secondMarker, 90)
  }

  function test_config_defaults() {
    var settings = PluginConfig.normalize({})
    compare(settings.backgroundMode, "wallpaper")
    compare(settings.dimOpacity, 0.48)
    compare(settings.screenBlankSeconds, 300)
    compare(settings.hourFormat, "24")
    verify(settings.showSecondsRing)
    verify(settings.showPowerActions)
  }

  function test_config_validation() {
    var settings = PluginConfig.normalize({
      backgroundMode: "unknown",
      dimOpacity: 4,
      screenBlankSeconds: 7200,
      hourFormat: "12",
      showSecondsRing: false,
      showPowerActions: "false",
      identityLabel: "  term node  "
    })
    compare(settings.backgroundMode, "wallpaper")
    compare(settings.dimOpacity, 0.85)
    compare(settings.screenBlankSeconds, 3600)
    compare(settings.hourFormat, "12")
    verify(!settings.showSecondsRing)
    verify(!settings.showPowerActions)
    compare(settings.identityLabel, "term node")
  }
}
