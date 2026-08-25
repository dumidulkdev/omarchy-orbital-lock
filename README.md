# Orbital Lock

A theme-aware Omarchy 4 lock screen with smoothly rotating minute and second
rings, an hour readout inside the orbit, and a centered date. It keeps Omarchy's
native PAM, fingerprint, idle, and Wayland session-lock implementation and
replaces only the presentation layer.

When an enrolled fingerprint reader is available, the password pill shows a
fingerprint icon with a scanning halo driven by the live fingerprint PAM state.

The composition is visually inspired by qylock's GPL-3.0 Clockwork/Orbital skin
by Darkkal44. Orbital Lock is an original QML implementation and includes none
of qylock's code, fonts, or assets.

## Install

```bash
omarchy plugin add https://github.com/dumidulkdev/omarchy-orbital-lock.git --enable
```

Enabling this plugin disables `omarchy.lock`. Disabling or removing it restores
the stock lock screen automatically:

```bash
omarchy plugin disable dumidu.orbital-lock
omarchy plugin remove dumidu.orbital-lock
```

## Preview

Preview while the desktop is unlocked:

```bash
omarchy-shell lock preview
```

Click anywhere to close the preview. The preview simulates the fingerprint scan
animation, but authentication, password submission, and power actions remain
disabled. Do not edit or update lock-plugin QML while the session is actually
locked.

## Settings

Settings live inline with the plugin entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "dumidu.orbital-lock",
  "backgroundMode": "wallpaper",
  "dimOpacity": 0.48,
  "screenBlankSeconds": 300,
  "hourFormat": "24",
  "showSecondsRing": true,
  "showPowerActions": true,
  "identityLabel": ""
}
```

- `backgroundMode`: `wallpaper` or `solid`
- `dimOpacity`: `0` through `0.85`
- `screenBlankSeconds`: seconds after locking before displays power off; `5` through `3600` (default: `300`)
- `hourFormat`: `24` or `12`
- `showSecondsRing`: show the outer seconds ring
- `showPowerActions`: show reboot and shutdown actions
- `identityLabel`: custom lower-right label; empty uses the current username

Reboot and shutdown require two clicks within five seconds and are available
only after Wayland confirms that the session is securely covered.

## Development

```bash
scripts/test.sh
omarchy-shell lock preview
```

The upstream lock service is security-sensitive. `scripts/check-upstream.sh`
alerts maintainers when the installed Omarchy service no longer matches the
reviewed baseline documented in `UPSTREAM.md`.

## License

MIT. Omarchy portions retain their upstream MIT terms. See `LICENSE` and
`UPSTREAM.md`.
