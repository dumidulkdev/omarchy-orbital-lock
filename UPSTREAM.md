# Upstream lock-service baseline

`Service.qml` began as the MIT-licensed Omarchy 4.0.1 lock service:

- Source: `/usr/share/omarchy/shell/plugins/lock/Service.qml`
- SHA-256: `3f0a265a09f7957e8f5d74666595d3136ec64899c414426190460f9e2098e701`
- Retrieved: 2026-08-26

The fork adds only plugin settings, view properties, and confirmed power-action
plumbing. PAM, fingerprint, Wayland session-lock, idle blanking, wake, preview,
and stranded-lock recovery behavior should remain synchronized with Omarchy.

Run `scripts/check-upstream.sh` after every Omarchy update. If it reports drift,
review the complete upstream diff before releasing another plugin version.
