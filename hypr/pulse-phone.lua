-- Pulse Phone — Hyprland window rules.
--
-- Sourced from ~/.config/hypr/hyprland.lua by install.sh, which appends the
-- require AFTER `require("default.hypr.omarchy")` so these rules run last and
-- win. Hyprland 0.56 (what Omarchy 4 ships) uses the Lua config frontend, so
-- `windowrulev2` from older guides no longer exists.

-- Match by class. Chromium honours --class as the X11 WM_CLASS, but on Wayland
-- it often ignores it and derives the app_id from the URL instead, so accept
-- both shapes. Anchored, so this cannot catch another web app.
o.window("^(pulse-phone|chrome-pulse\\.sipstack\\.com__.*)$", { tag = "+pulse-phone" })

-- ⚠️ LOAD-BEARING. Omarchy's default/hypr/apps/browser.lua tags every Chromium
-- window `chromium-based-browser` using an UNANCHORED regex (`[cC]hrom(e|ium)`),
-- which matches `chrome-pulse.sipstack.com__-Default`, and then forces
-- `tile = true` on that tag. Without dropping the tag first, the phone opens as
-- a full tiled pane and the `float` below is silently overridden. Omarchy's own
-- floating web apps (YouTube, Zoom) drop the tag exactly this way.
--
-- These are separate calls on purpose: a single Lua table cannot hold two `tag`
-- keys -- the second would silently overwrite the first.
o.window({ tag = "pulse-phone" }, { tag = "-chromium-based-browser" })
o.window({ tag = "pulse-phone" }, { tag = "-default-opacity" })

o.window({ tag = "pulse-phone" }, {
  float = true,
  border_size = 0,
  opacity = "1 1",
  size = { 400, 780 },
  move = { "(monitor_w-window_w-20)", "(monitor_h*0.04)" },
  workspace = "special:pulse silent",
})
