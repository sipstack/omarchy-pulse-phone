# Pulse Phone for Omarchy

SIPSTACK Pulse as a scratchpad softphone. A Pulse icon sits in your Omarchy bar;
click it and a phone-sized window slides in with your dialer, calls, SMS and
voicemail. Click again and it hides — still registered, so calls still ring.

```
┌─ omarchy bar ──────────────────────────────────────────────────┐
│  ⌂  1 2 3        Wed 14:22        󰂯  󰖩  󰕾   [󰏲]   ⏻          │
└─────────────────────────────────────────────│──────────────────┘
                                    click ───┘
                             ┌─────────────────────┐
                             │                     │   400 × 780
                             │   the Pulse web     │   floating
                             │   app, unchanged    │   borderless
                             │                     │   pinned
                             │                     │   special workspace
                             └─────────────────────┘   click again to hide
```

<!-- Before submitting to plugins.omarchy.org, replace the diagram above with a
     real screenshot: the bar icon plus the phone panel open, on a real
     Omarchy 4 desktop. Capture it with Omarchy's screenshot binding or `grim`. -->

There is no separate desktop build to keep up to date. The window renders the
live Pulse web app, so it is always current.

## Requirements

- **Omarchy 4 or newer.** The bar widget is a Quickshell plugin; Omarchy 3 used
  Waybar and cannot load it.
- **A Chromium-family default browser** — Chrome, Chromium, Brave, Edge, Vivaldi,
  Opera or Helium. This is not a preference: WebRTC is what carries the audio,
  and `webkit2gtk` ships without it, so a GTK/WebKit webview cannot place calls
  at all. Firefox has WebRTC but no `--app` window mode.
- A SIPSTACK Pulse account. [Sign up](https://www.sipstack.com/products/pulse).

External commands used: `hyprctl`, `jq`, `xdg-settings`, `xdg-mime`,
`omarchy-launch-webapp`, and optionally `wl-copy` and `gtk-update-icon-cache`.
All ship with Omarchy except `wl-copy` (`wl-clipboard`), which is only used to
hand a number to an already-open phone.

## Install

```bash
omarchy plugin add https://github.com/sipstack/omarchy-pulse-phone.git --enable
~/.config/omarchy/plugins/com.sipstack.pulse-phone/install.sh
```

The first line puts the Pulse icon in your bar. The second wires up the parts a
QML plugin cannot: the `pulse-phone` launcher on your `PATH`, the Hyprland
window rules that make the phone a floating panel, a desktop entry, and the
`tel:` / `sip:` / `callto:` link handler.

The installer backs up every file it touches (`*.pulse-phone-bak.<timestamp>`)
and never overwrites your configuration silently. Run it again any time; it is
idempotent.

Then sign in once. The session persists across reboots.

## Use

| Action | What happens |
|---|---|
| Left-click the bar icon | show / hide the phone |
| Middle-click | show the phone on the dialpad |
| Right-click | quit (drops the SIP registration) |
| `pulse-phone` | same as left-click, from a shell |
| `pulse-phone dial 4165551234` | open the dialpad with the number filled in |
| Click a phone number anywhere | opens Pulse with the number filled in |

Hiding the phone keeps it registered, so inbound calls still ring and raise a
notification. Quitting does not.

Want a keybind? Add one to `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + P", "Pulse Phone", { launch = "pulse-phone" })
```

`SUPER+ALT+P` is free in a default Omarchy install — `SUPER+P` is "Pseudo
window" and `SUPER+SHIFT+P` is Google Photos.

## Configure

| Variable | Default | Purpose |
|---|---|---|
| `PULSE_PHONE_URL` | `https://pulse.sipstack.com` | point at a different Pulse instance |
| `PULSE_PHONE_CLASS` | `pulse-phone` | window class the Hyprland rules match |

Window size and position live in `~/.config/hypr/pulse-phone.lua` — edit
`size` and `move` there and run `hyprctl reload`.

The phone runs in its own browser profile at
`~/.local/share/pulse-phone/profile`, kept separate from your everyday browsing
so that clearing cookies cannot sign you out. Microphone and notification
permissions are pre-granted for `pulse.sipstack.com` only, so you should never
see a permission prompt.

## Remove

```bash
~/.config/omarchy/plugins/com.sipstack.pulse-phone/install.sh --uninstall
omarchy plugin remove com.sipstack.pulse-phone
```

The first line removes the launcher, icon, desktop entry, URI handler and window
rules, and unhooks the `require` line from `hyprland.lua`. The second removes the
bar widget.

Your signed-in session lives in `~/.local/share/pulse-phone` and is left alone.
Delete that directory to sign out completely. Backups the installer made are
also left in place.

## Known limitations

These are deliberate, not oversights:

- **The bar icon shows no call state.** It is a launcher, not an indicator. The
  bar cannot see inside the browser window that hosts the phone, and inventing a
  status would be worse than omitting one.
- **Notifications have no Answer/Decline buttons.** Omarchy 4's notification
  card renders a single click target, so clicking an incoming-call notification
  raises the phone; you answer there.
- **Do Not Disturb silences call notifications.** Omarchy only lets its own
  `omarchy-action` sender and critical `notify-send` messages through DND. The
  phone still rings audibly if it is open.
- **Omarchy tiles Chromium windows by default.** `default/hypr/apps/browser.lua`
  tags every Chromium window `chromium-based-browser` and forces `tile = true`
  on it. `hypr/pulse-phone.lua` drops that tag so the phone can float, the same
  way Omarchy's own YouTube and Zoom rules do. If the phone ever opens as a full
  pane, that require line is missing from `hyprland.lua` — `pulse-phone status`
  will show `floating=false`.
- **Only one phone window at a time.** A second window would register a second
  SIP contact with the same instance id and silently steal the first one's
  binding. So `dial` raises the existing window and copies the number to your
  clipboard instead of opening a second one.
- **Background push is not supported on the web platform**, which is why this
  exists: keep the phone hidden rather than closed and it stays registered.

## License

MIT — see [LICENSE](LICENSE).

Pulse itself is a commercial SIPSTACK service; this repository is only the
Omarchy integration.
