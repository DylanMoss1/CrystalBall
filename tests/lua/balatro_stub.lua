-- Minimal Balatro / Steamodded env to load crystal_ball.lua under plain lua/luajit
-- (no game). Stubs only enough to LOAD and run the non-UI logic (query builder +
-- handshake state machine); UI overlays load but go unused.
--   exposes:  CB_FS   in-memory FS (path -> contents) backing love.filesystem
--   usage:    local mod = dofile("balatro_stub.lua")("/abs/repo/root"[, preset_config])

-- is_native_windows() reads jit.os; plain lua has no `jit`. Shim it Linux-shaped to
-- force the watcher path deterministically (luajit already reports "Linux" here).
if not rawget(_G, "jit") then
	jit = { os = "Linux" }
end

return function(repo_root, preset_config)
	local function noop() end

	-- Recursive auto-table: any field read yields another callable auto-table, so
	-- deep constant reads (G.C.UI.TEXT_LIGHT) and unset callbacks (G.FUNCS.foo())
	-- never error. Assignments rawset, so the mod's own G.FUNCS.x = fn still wins.
	local function auto()
		return setmetatable({}, {
			__index = function(t, k)
				local v = auto()
				rawset(t, k, v)
				return v
			end,
			__call = noop,
		})
	end

	-- In-memory filesystem backing love.filesystem, exposed for assertions.
	CB_FS = {}

	local mod = { config = preset_config or {} }

	SMODS = {
		current_mod = mod,
		-- Mod-relative paths resolve against the repo root (main_file is at
		-- CrystalBall/src/crystal_ball.lua).
		load_file = function(p)
			return assert(loadfile(repo_root .. "/" .. p), "stub load_file: " .. p)
		end,
		save_mod_config = noop,
	}

	love = {
		filesystem = {
			getSaveDirectory = function()
				return "/tmp/crystalball-test-save"
			end,
			createDirectory = noop,
			write = function(path, data)
				CB_FS[path] = data
			end,
			read = function(path)
				return CB_FS[path]
			end,
			remove = function(path)
				CB_FS[path] = nil
			end,
		},
	}

	-- Engine globals the file wraps/reads. auto() covers G.C/G.UIT constants, the
	-- G.FUNCS/G.UIDEF callback tables, and Card/Game method wrapping.
	G = auto()
	Card = auto()
	Game = auto()

	-- Free globals referenced or wrapped at load time (must exist before the
	-- file reads them into `_orig_*` locals).
	function create_UIBox_mods() end
	function create_tabs() end
	function create_UIBox_your_collection_decks() end
	function create_UIBox_generic_options() end
	function create_option_cycle() end
	function UIBox_button() end
	function DynaText() end
	function CardArea() end
	function attention_text() end
	function localize()
		return ""
	end
	function sendInfoMessage() end
	function play_sound() end
	function get_joker_win_sticker() end
	function INIT_COLLECTION_CARD_ALERTS() end

	dofile(repo_root .. "/CrystalBall/src/crystal_ball.lua")
	return mod
end
