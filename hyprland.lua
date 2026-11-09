-- Neon Foundry — Hyprland window chrome: the glow under the focused window.
--
-- A theme's hyprland.lua is Lua that Hyprland runs at login, so the theme
-- repository does not carry it, and Omarchy drops every *.lua from a theme it
-- cloned from git anyway. install.sh copies this file into a linked theme as
-- hyprland.lua, where Omarchy treats the theme as the user's own and loads it.
-- The gradient border does not depend on it: that is hyprland_active_border in
-- the theme's colors.toml and reaches every install. What is here and nowhere
-- else is the glow, which no template can express.

local active_border_color = {
  colors = { "rgba(c8ff00ee)", "rgba(31e5ffee)", "rgba(ff2e8bee)" },
  angle = 45,
}
local inactive_border_color = {
  colors = { "rgba(27292daa)", "rgba(0e0f12aa)" },
  angle = 45,
}
-- The glow carries the same three stops on the same 45-degree sweep as the
-- border, so the corner that is magenta on the border is magenta underneath it
-- too. A flat accent here clashes: the bottom-right ends up pink over green.
local active_shadow_color = {
  colors = { "rgba(c8ff0033)", "rgba(31e5ff33)", "rgba(ff2e8b33)" },
  angle = 45,
}
local inactive_shadow_color = "rgba(06070977)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    shadow = {
      enabled = true,
      range = 8,
      render_power = 3,
      color = active_shadow_color,
      color_inactive = inactive_shadow_color,
    },
  },
})
