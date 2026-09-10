-- Pulse Phone — Hyprland window rules.
--
-- Sourced from ~/.config/hypr/hyprland.lua by install.sh. Hyprland 0.56 (what
-- Omarchy 4 ships) uses the Lua config frontend, so `windowrulev2` from older
-- guides no longer exists -- rules are `o.window(match, props)`.
--
-- The phone lives on a special workspace so it behaves like a dropdown: a
-- click on the bar icon toggles it, and it stays registered to SIP while
-- hidden. Shape follows Omarchy's own default/hypr/apps/pip.lua.

o.window({ class = "pulse-phone" }, { tag = "+pulse-phone" })

o.window({ tag = "pulse-phone" }, {
  tag = "-default-opacity",
  float = true,
  border_size = 0,
  size = { 400, 780 },
  move = { "(monitor_w-window_w-20)", "(monitor_h*0.04)" },
  workspace = "special:pulse silent",
})
