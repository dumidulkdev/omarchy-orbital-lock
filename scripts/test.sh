#!/bin/bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"
qml_test_runner="/usr/lib/qt6/bin/qmltestrunner"

omarchy plugin validate "$root"
qmllint -I "$omarchy_path/shell" "$root/Service.qml" "$root/LockView.qml" "$root/OrbitalClock.qml"
env -u DISPLAY -u WAYLAND_DISPLAY \
  QT_QPA_PLATFORM=offscreen \
  QT_QPA_PLATFORMTHEME= \
  QT_QUICK_BACKEND=software \
  "$qml_test_runner" -input "$root/tests" -import "$omarchy_path/shell" -o -,txt
"$root/scripts/check-upstream.sh"

echo "Orbital Lock: all checks passed."
