-- .luacheckrc for BetterNSTTS (WoW Addon)
-- Run: luacheck BetterNSTTS/

std = "lua51"  -- WoW runs Lua 5.1

-- Coding style rules
codes = true
unused_args = false   -- Blizzard event handlers require specific signatures
redefine = "warning"
