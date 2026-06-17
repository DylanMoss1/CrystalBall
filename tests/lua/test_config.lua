-- Regression tests for the mod's config logic: has_filter (the gate that decides
-- whether a blank-seed run is intercepted) and the one-time migration of the old
-- single-list shape (target_jokers) into the clause list.
--
-- Run: lua tests/lua/test_config.lua   (cwd = repo root)

local repo_root = os.getenv("CB_REPO_ROOT") or "."
local load_mod = dofile(repo_root .. "/tests/lua/balatro_stub.lua")
local T = dofile(repo_root .. "/tests/lua/harness.lua").new()

local mod = load_mod(repo_root)

-- has_filter: false with no clauses, false with only empty clauses, true once any
-- clause has a joker.
mod.config.clauses = {}
T.check("has_filter empty", mod.has_filter(), false)

mod.config.clauses = { { jokers = {}, minAnte = 1, maxAnte = 1, atLeast = 1 } }
T.check("has_filter empty clause", mod.has_filter(), false)

mod.config.clauses = { { jokers = { "j_blueprint" }, minAnte = 1, maxAnte = 1, atLeast = 1 } }
T.check("has_filter with joker", mod.has_filter(), true)

-- Migration: a config carrying the legacy target_jokers (and no clauses) is loaded
-- into exactly one clause requiring all of them, and target_jokers is cleared.
local migrated = load_mod(repo_root, { target_jokers = { "j_blueprint", "j_brainstorm" } })
T.check("migration: one clause", #migrated.config.clauses, 1)
local cl = migrated.config.clauses[1]
T.check("migration: jokers preserved", table.concat(cl.jokers, ","), "j_blueprint,j_brainstorm")
T.check("migration: atLeast = count", cl.atLeast, 2)
T.check("migration: minAnte", cl.minAnte, 1)
T.check("migration: maxAnte", cl.maxAnte, 1)
T.check("migration: target_jokers cleared", migrated.config.target_jokers, nil)

-- Migration is skipped when clauses already exist (no clobber).
local kept = load_mod(repo_root, {
	clauses = { { jokers = { "j_joker" }, minAnte = 2, maxAnte = 3, atLeast = 1 } },
	target_jokers = { "j_blueprint" },
})
T.check("no migration when clauses present", kept.config.clauses[1].jokers[1], "j_joker")

T.finish()
