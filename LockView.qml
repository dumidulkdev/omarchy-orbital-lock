import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import "ClockMath.js" as ClockMath

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintAuthenticating: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property var settings: ({})
  property bool previewMode: false
  property bool sessionSecure: false
  property bool powerActionRunning: false
  property string powerFailureMessage: ""
  property var currentTime: new Date()
  property string pendingPowerAction: ""

  readonly property bool compact: width / Math.max(1, height) < 1.35
  readonly property real uiScale: Math.max(0.62, Math.min(1.5, Math.min(width / 1920, height / 1080)))
  readonly property color foreground: Color.lock.text
  readonly property color muted: Color.lock.placeholder
  readonly property color surface: Color.lock.background
  readonly property bool wallpaperEnabled: settings.backgroundMode !== "solid"
  readonly property string identityText: settings.identityLabel && settings.identityLabel.length > 0
    ? settings.identityLabel.toUpperCase()
    : String(Quickshell.env("USER") || Quickshell.env("LOGNAME") || "USER").toUpperCase()
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property bool fingerprintReading: fingerprintConfigured && fingerprintAuthenticating && !authenticatingPassword

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()
  signal powerActionRequested(string action)

  function alphaColor(colorValue, opacity) {
    return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
  }

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  function requestPower(action) {
    if (previewMode || !sessionSecure || powerActionRunning) return
    if (pendingPowerAction === action) {
      pendingPowerAction = ""
      powerConfirmationTimer.stop()
      powerActionRequested(action)
      return
    }

    pendingPowerAction = action
    powerConfirmationTimer.restart()
    wakeRequested()
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: if (inputEnabled) Qt.callLater(forcePasswordFocus)
  onFailureMessageChanged: if (failureMessage.length > 0) failureShake.restart()

  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  Timer {
    interval: 33
    repeat: true
    running: root.visible
    onTriggered: root.currentTime = new Date()
  }

  Timer {
    id: powerConfirmationTimer
    interval: 5000
    repeat: false
    onTriggered: root.pendingPowerAction = ""
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground && root.wallpaperEnabled ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.wallpaperEnabled && root.loadBackground && wallpaper.status === Image.Ready
      blur: 1
      blurMax: 96
      blurMultiplier: 1.2
      saturation: -0.35
      contrast: -0.08
    }

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, root.settings.dimOpacity)
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: {
        root.wakeRequested()
        root.forcePasswordFocus()
      }
      onPositionChanged: root.wakeRequested()
    }

    OrbitalClock {
      id: orbitalClock
      z: 2
      width: root.compact ? Math.min(parent.width * 1.2, parent.height * 0.84) : Math.min(parent.width * 0.62, parent.height * 1.3)
      height: width
      x: root.compact ? (parent.width - width) / 2 : -width * 0.49
      y: root.compact ? -height * 0.2 : (parent.height - height) / 2
      currentTime: root.currentTime
      foreground: root.foreground
      muted: root.muted
      showSecondsRing: root.settings.showSecondsRing
      authenticating: root.authenticatingPassword
      hourFormat: root.settings.hourFormat
    }

    Column {
      id: datePanel
      z: 3
      width: root.compact ? parent.width * 0.86 : Math.min(560 * root.uiScale, parent.width * 0.46)
      x: (parent.width - width) / 2
      y: root.compact ? parent.height * 0.43 : (parent.height - implicitHeight) / 2
      spacing: 8 * root.uiScale

      Text {
        width: parent.width
        text: Qt.formatDate(root.currentTime, "dd MMM yyyy").toUpperCase()
        color: root.muted
        font.family: Style.font.family
        font.pixelSize: 15 * root.uiScale
        font.letterSpacing: 4 * root.uiScale
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        text: Qt.formatDate(root.currentTime, "dddd").toUpperCase()
        color: root.foreground
        font.family: Style.font.family
        font.pixelSize: 22 * root.uiScale
        font.weight: Font.Bold
        font.letterSpacing: 8 * root.uiScale
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Row {
      id: powerRow
      z: 5
      visible: root.settings.showPowerActions
      anchors.right: parent.right
      anchors.rightMargin: 64 * root.uiScale
      anchors.top: parent.top
      anchors.topMargin: 46 * root.uiScale
      spacing: 22 * root.uiScale
      opacity: root.previewMode || !root.sessionSecure ? 0.45 : 1

      Text {
        text: "OMARCHY"
        color: root.foreground
        font.family: Style.font.family
        font.pixelSize: 11 * root.uiScale
        font.weight: Font.Bold
        font.letterSpacing: 3 * root.uiScale
      }

      ActionLabel {
        label: root.pendingPowerAction === "reboot" ? "CONFIRM REBOOT" : "REBOOT"
        active: root.pendingPowerAction === "reboot"
        enabled: !root.previewMode && root.sessionSecure && !root.powerActionRunning
        onTriggered: root.requestPower("reboot")
      }

      ActionLabel {
        label: root.pendingPowerAction === "shutdown" ? "CONFIRM SHUTDOWN" : "SHUTDOWN"
        active: root.pendingPowerAction === "shutdown"
        enabled: !root.previewMode && root.sessionSecure && !root.powerActionRunning
        onTriggered: root.requestPower("shutdown")
      }
    }

    Column {
      id: identityPanel
      z: 4
      width: Math.min(430 * root.uiScale, parent.width * 0.86)
      x: root.compact ? (parent.width - width) / 2 : parent.width - width - 72 * root.uiScale
      y: parent.height - implicitHeight - 68 * root.uiScale
      spacing: 9 * root.uiScale
      transform: Translate { id: failureOffset }

      Text {
        width: parent.width
        text: root.identityText
        color: root.foreground
        font.family: Style.font.family
        font.pixelSize: 19 * root.uiScale
        font.weight: Font.Bold
        font.letterSpacing: 7 * root.uiScale
        horizontalAlignment: Text.AlignRight
      }

      Text {
        width: parent.width
        visible: root.fingerprintConfigured
        text: root.authenticatingPassword
          ? "PASSWORD CHECK IN PROGRESS"
          : (root.fingerprintReading ? "SCANNING FINGERPRINT — OR TYPE YOUR KEY" : "TOUCH SENSOR OR TYPE YOUR KEY")
        color: root.authenticatingPassword || root.fingerprintReading ? root.foreground : root.muted
        opacity: root.authenticatingPassword ? authPulse.value : 1
        font.family: Style.font.family
        font.pixelSize: 10 * root.uiScale
        font.letterSpacing: 2 * root.uiScale
        horizontalAlignment: Text.AlignRight
      }

      Rectangle {
        id: passwordField
        width: parent.width
        height: 62 * root.uiScale
        radius: height / 2
        color: root.alphaColor(root.surface, 0.28)
        border.width: Math.max(1, 1.5 * root.uiScale)
        border.color: root.errorState ? Color.lock.borderError : root.alphaColor(root.foreground, root.authenticatingPassword ? 0.55 : 0.2)

        Rectangle {
          id: typingPulse
          anchors.centerIn: parent
          width: parent.width
          height: parent.height
          radius: height / 2
          color: "transparent"
          border.width: Math.max(1, 1.5 * root.uiScale)
          border.color: root.alphaColor(root.foreground, 0.7)
          opacity: 0
          scale: 0.9
          transformOrigin: Item.Center

          ParallelAnimation {
            id: typingPulseAnimation
            NumberAnimation {
              target: typingPulse
              property: "scale"
              from: 0.9
              to: 1.16
              duration: 420
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: typingPulse
              property: "opacity"
              from: 0.72
              to: 0
              duration: 420
              easing.type: Easing.OutCubic
            }
          }
        }

        TextInput {
          id: passwordInput
          property int lastTextLength: 0
          anchors.fill: parent
          anchors.leftMargin: (root.fingerprintConfigured ? 82 : 28) * root.uiScale
          anchors.rightMargin: 28 * root.uiScale
          horizontalAlignment: TextInput.AlignRight
          verticalAlignment: TextInput.AlignVCenter
          activeFocusOnPress: true
          enabled: root.inputEnabled && !root.authenticatingPassword
          readOnly: root.authenticatingPassword
          echoMode: TextInput.Password
          passwordCharacter: "✦"
          passwordMaskDelay: 0
          color: root.foreground
          selectionColor: Color.lock.selection
          selectedTextColor: root.foreground
          font.family: Style.font.family
          font.pixelSize: 16 * root.uiScale
          font.letterSpacing: 8 * root.uiScale
          cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
          cursorDelegate: Rectangle {
            width: 2 * root.uiScale
            color: root.foreground
            visible: passwordInput.cursorVisible
          }

          onTextChanged: {
            if (!root.syncingPasswordText) root.passwordTextEdited(text)
            if (text.length > passwordInput.lastTextLength && root.inputEnabled && !root.authenticatingPassword) {
              typingPulseAnimation.restart()
            }
            passwordInput.lastTextLength = text.length
            if (text.length > 0) root.wakeRequested()
            if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
          }

          onAccepted: {
            var submitted = root.passwordText
            root.passwordTextEdited("")
            if (submitted.length > 0) root.submitPassword(submitted)
          }

          Keys.onPressed: function(event) {
            root.wakeRequested()
            if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              root.passwordTextEdited("")
              event.accepted = true
            }
          }
        }

        Item {
          id: fingerprintIndicator
          objectName: "fingerprintIndicator"
          anchors.left: parent.left
          anchors.leftMargin: 20 * root.uiScale
          anchors.verticalCenter: parent.verticalCenter
          width: 42 * root.uiScale
          height: width
          visible: root.fingerprintConfigured
          property real scanPhase: 0

          Rectangle {
            anchors.centerIn: parent
            width: parent.width * (0.68 + fingerprintIndicator.scanPhase * 0.58)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.max(1, 1.2 * root.uiScale)
            border.color: root.foreground
            opacity: root.fingerprintReading
              ? Math.sin(fingerprintIndicator.scanPhase * Math.PI) * 0.48
              : 0
          }

          Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.78
            height: width
            radius: width / 2
            color: root.alphaColor(root.foreground, root.fingerprintReading ? 0.09 : 0.035)
            border.width: Math.max(1, root.uiScale)
            border.color: root.alphaColor(root.foreground, root.fingerprintReading ? 0.42 : 0.13)
          }

          Text {
            anchors.centerIn: parent
            text: "󰈷"
            color: root.fingerprintReading ? root.foreground : root.muted
            opacity: root.fingerprintReading
              ? 0.72 + Math.sin(fingerprintIndicator.scanPhase * Math.PI) * 0.28
              : 0.72
            font.family: Style.font.family
            font.pixelSize: 23 * root.uiScale
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: 180 } }
          }

          NumberAnimation {
            target: fingerprintIndicator
            property: "scanPhase"
            from: 0
            to: 1
            duration: 1100
            loops: Animation.Infinite
            running: root.fingerprintReading
            easing.type: Easing.InOutSine
            onStopped: fingerprintIndicator.scanPhase = 0
          }
        }

        Text {
          anchors.fill: passwordInput
          text: root.previewMode ? "LOCK PREVIEW" : (root.authenticatingPassword ? "CHECKING KEY" : (root.failureMessage.length > 0 ? root.failureMessage.toUpperCase() : "WAITING FOR KEY"))
          visible: passwordInput.text.length === 0
          color: root.errorState ? Color.lock.textError : root.muted
          font.family: Style.font.family
          font.pixelSize: 11 * root.uiScale
          font.letterSpacing: 3 * root.uiScale
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
      }

      Text {
        width: parent.width
        text: root.powerFailureMessage.length > 0 ? root.powerFailureMessage.toUpperCase() : "SESSION LOCKED"
        color: root.powerFailureMessage.length > 0 ? Color.lock.textError : root.muted
        font.family: Style.font.family
        font.pixelSize: 9 * root.uiScale
        font.letterSpacing: 3 * root.uiScale
        horizontalAlignment: Text.AlignRight
      }
    }

    Item { id: authPulse; property real value: 1 }

    SequentialAnimation {
      loops: Animation.Infinite
      running: root.authenticatingPassword
      NumberAnimation { target: authPulse; property: "value"; from: 1; to: 0.42; duration: 450; easing.type: Easing.InOutSine }
      NumberAnimation { target: authPulse; property: "value"; from: 0.42; to: 1; duration: 450; easing.type: Easing.InOutSine }
    }

    SequentialAnimation {
      id: failureShake
      NumberAnimation { target: failureOffset; property: "x"; from: 0; to: -10 * root.uiScale; duration: 45 }
      NumberAnimation { target: failureOffset; property: "x"; to: 10 * root.uiScale; duration: 70 }
      NumberAnimation { target: failureOffset; property: "x"; to: -6 * root.uiScale; duration: 60 }
      NumberAnimation { target: failureOffset; property: "x"; to: 0; duration: 45 }
    }
  }

  component ActionLabel: Item {
    id: actionRoot
    property string label: ""
    property bool active: false
    property bool enabled: true
    signal triggered()
    width: actionText.implicitWidth
    height: actionText.implicitHeight

    Text {
      id: actionText
      text: actionRoot.label
      color: actionRoot.active || actionMouse.containsMouse ? root.foreground : root.muted
      font.family: Style.font.family
      font.pixelSize: 11 * root.uiScale
      font.weight: actionRoot.active ? Font.Bold : Font.Normal
      font.letterSpacing: 3 * root.uiScale
      Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
      id: actionMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: actionRoot.enabled
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: actionRoot.triggered()
    }
  }
}
