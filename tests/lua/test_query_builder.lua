-- Golden regression tests for the Lua query-builder: mod.config.clauses (the UI
-- model) -> the JSON string Immolate's query_parse.h consumes. This is the exact
-- contract between the mod and the searcher, so it is pinned byte-for-byte.
--
-- Run: lua tests/lua/test_query_builder.lua   (cwd = repo root)

local repo_root = os.getenv("CB_REPO_ROOT") or "."
local load_mod = dofile(repo_root .. "/tests/lua/balatro_stub.lua")
local mod = load_mod(repo_root)

local T = dofile(repo_root .. "/tests/lua/harness.lua").new()
local check = T.check

-- Drives the real pipeline: set the UI model, build the criteria table, serialize.
local function json_of(clauses)
	mod.config.clauses = clauses
	return mod.query_json(mod.build_criteria())
end

-- 1. No clauses -> an empty AND group (matches everything; mod.has_filter gates this).
check("empty clauses", json_of({}), '{"any":[{"all":[]}]}')

-- 2. Single clause, single joker -- the shipped default shape.
check(
	"single blueprint ante 1-8",
	json_of({ { jokers = { "j_blueprint" }, minAnte = 1, maxAnte = 8, atLeast = 1 } }),
	'{"any":[{"all":[{"atLeast":1,"minAnte":1,"maxAnte":8,"of":["Blueprint"]}]}]}'
)

-- 3. atLeast is clamped to the joker count (5 -> 2).
check(
	"atLeast clamped to joker count",
	json_of({ { jokers = { "j_blueprint", "j_brainstorm" }, minAnte = 2, maxAnte = 4, atLeast = 5 } }),
	'{"any":[{"all":[{"atLeast":2,"minAnte":2,"maxAnte":4,"of":["Blueprint","Brainstorm"]}]}]}'
)

-- 4. Two clauses are ANDed within the single group, in order.
check(
	"two ANDed clauses",
	json_of({
		{ jokers = { "j_blueprint" }, minAnte = 1, maxAnte = 1, atLeast = 1 },
		{ jokers = { "j_brainstorm" }, minAnte = 3, maxAnte = 8, atLeast = 1 },
	}),
	'{"any":[{"all":['
		.. '{"atLeast":1,"minAnte":1,"maxAnte":1,"of":["Blueprint"]},'
		.. '{"atLeast":1,"minAnte":3,"maxAnte":8,"of":["Brainstorm"]}'
		.. ']}]}'
)

-- 5. Empty-joker clauses are dropped by build_criteria (only #jokers>0 survives).
check(
	"empty-joker clause skipped",
	json_of({
		{ jokers = {}, minAnte = 1, maxAnte = 1, atLeast = 1 },
		{ jokers = { "j_blueprint" }, minAnte = 1, maxAnte = 1, atLeast = 1 },
	}),
	'{"any":[{"all":[{"atLeast":1,"minAnte":1,"maxAnte":1,"of":["Blueprint"]}]}]}'
)

-- 6. atLeast defaults to the joker count when nil.
check(
	"atLeast defaults to joker count",
	json_of({ { jokers = { "j_blueprint", "j_brainstorm" }, minAnte = 1, maxAnte = 1 } }),
	'{"any":[{"all":[{"atLeast":2,"minAnte":1,"maxAnte":1,"of":["Blueprint","Brainstorm"]}]}]}'
)

-- 7. Keys absent from JOKER_NAMES map to nil and are dropped (build_criteria does
-- of[#of+1] = JOKER_NAMES[key]); a trailing unknown leaves a one-item clause. The
-- picker only ever stores known keys, so this just pins the builder's own behaviour.
check(
	"unknown joker key dropped",
	json_of({ { jokers = { "j_blueprint", "j_not_a_real_joker" }, minAnte = 1, maxAnte = 1, atLeast = 1 } }),
	'{"any":[{"all":[{"atLeast":1,"minAnte":1,"maxAnte":1,"of":["Blueprint"]}]}]}'
)

T.finish()
