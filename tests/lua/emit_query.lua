-- Emits the query JSON the mod would write to request.txt, built by the REAL
-- mod.build_criteria/query_json. Lets the Python pipeline test chain the actual
-- Lua builder into the watcher + Immolate (true cross-language e2e).
--
-- Run: lua tests/lua/emit_query.lua <keys-csv> <minAnte> <maxAnte> <atLeast>
--   e.g. lua tests/lua/emit_query.lua j_blueprint 1 8 1

local repo_root = os.getenv("CB_REPO_ROOT") or "."
local load_mod = dofile(repo_root .. "/tests/lua/balatro_stub.lua")
local mod = load_mod(repo_root)

local keys_csv = assert(arg[1], "need joker keys (comma-separated center keys)")
local minAnte = tonumber(arg[2]) or 1
local maxAnte = tonumber(arg[3]) or 1
local atLeast = tonumber(arg[4])

local jokers = {}
for k in keys_csv:gmatch("[^,]+") do
	jokers[#jokers + 1] = k
end

mod.config.clauses = { { jokers = jokers, minAnte = minAnte, maxAnte = maxAnte, atLeast = atLeast } }
io.write(mod.query_json(mod.build_criteria()))
