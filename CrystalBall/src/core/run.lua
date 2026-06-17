--- core/run: engine hooks -- start a seeded run, pump the poller, intercept new runs.
--- ctx in: show_waiting_overlay

return function(ctx)
	local mod = ctx.mod
	local show_waiting_overlay = ctx.show_waiting_overlay

	function mod.start_seeded_run(seed)
		if not seed or seed == "" then
			return false
		end
		if G.STAGE == G.STAGES.RUN then
			G:delete_run()
		end
		G:start_run({ stake = mod.config.stake, seed = seed:upper() })
		return true
	end

	-- Pump the handshake poller every frame.
	local game_update = Game.update
	function Game:update(dt)
		game_update(self, dt)
		mod.poll()
	end

	-- Intercept blank-seed, non-challenge runs: defer, search, let mod.poll resume the
	-- real start_run once a seed comes back.
	mod._orig_start_run = G.FUNCS.start_run
	G.FUNCS.start_run = function(e, args)
		args = args or {}
		local have_target = mod.config.intercept_new_run and mod.has_filter()
		if have_target and not args.seed and not args.challenge then
			if mod.resolving then
				return -- already searching; ignore re-clicks
			end
			mod.deferred = { e = e, args = args }
			mod.resolving = true
			mod.request_seed(mod.build_criteria())
			show_waiting_overlay() -- modal Cancel button; closed by on_resolved
			return
		end
		return mod._orig_start_run(e, args)
	end
end
