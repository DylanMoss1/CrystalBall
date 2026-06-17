--- Crystal Ball: find a seed matching structured criteria, then start a run on it.
---
--- Entry point only -- wires single-purpose modules sharing state through `ctx`
--- (explicit DI, not globals). Load order = dependency order: a module loads after
--- whatever ctx fields it reads.
---   core/  search logic, no UI: config, query, handshake, run, debug
---   ui/    overlays: overlay, cards, picker, editor

local mod = SMODS.current_mod

local SRC = "CrystalBall/src/"
local function load(path)
	return assert(SMODS.load_file(path))()
end

-- Balatro center key ("j_blueprint") -> Immolate enum name ("Blueprint").
local JOKER_NAMES = load(SRC .. "joker_names.lua")

local ctx = { mod = mod, joker_names = JOKER_NAMES }

load(SRC .. "core/config.lua")(ctx) -- ctx.new_clause, ctx.save_config
load(SRC .. "core/query.lua")(ctx) -- mod.query_json
load(SRC .. "ui/overlay.lua")(ctx) -- ctx.toast, ctx.show_waiting_overlay
load(SRC .. "core/handshake.lua")(ctx) -- mod.request_seed, mod.poll
load(SRC .. "ui/cards.lua")(ctx) -- ctx.make_sel_card, build_joker_line, toggle_highlight
load(SRC .. "ui/picker.lua")(ctx) -- mod.show_joker_picker
load(SRC .. "ui/editor.lua")(ctx) -- mod.show_filter_editor, mod.config_tab
load(SRC .. "core/run.lua")(ctx) -- engine hooks
load(SRC .. "core/debug.lua")(ctx) -- opt-in instrumentation
