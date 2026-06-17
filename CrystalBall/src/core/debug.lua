--- core/debug: opt-in deck-carousel instrumentation (the "all Red Deck" repro).
--- Enable via mod.config.debug = true. Logs tagged "CrystalBall". Pins which global
--- is wrong: Back pool clobbered / viewed_back stuck / your_collection leaked.

return function(ctx)
	local mod = ctx.mod

	-- Dump the globals the deck-select sprite/label path reads; `pool` lists each Back.
	function mod.debug_deck_state(tag, pool)
		if not mod.config.debug then
			return
		end
		local vb = G.GAME and G.GAME.viewed_back
		local yc = G.your_collection
		sendInfoMessage(
			("deck_state[%s]: viewed_back=%s Back_pool=%s your_collection=%s MEMORY.deck=%s"):format(
				tag,
				vb and tostring(vb.name) or "nil",
				G.P_CENTER_POOLS.Back and #G.P_CENTER_POOLS.Back or "nil",
				(type(yc) == "table") and ("table[" .. #yc .. "]") or tostring(yc),
				tostring(G.PROFILES[G.SETTINGS.profile].MEMORY.deck)
			),
			"CrystalBall"
		)
		if pool and G.P_CENTER_POOLS.Back then
			for k, v in ipairs(G.P_CENTER_POOLS.Back) do
				sendInfoMessage(
					("  Back[%d] key=%s name=%s unlocked=%s"):format(k, tostring(v.key), tostring(v.name), tostring(v.unlocked)),
					"CrystalBall"
				)
			end
		end
	end

	-- Baseline the pool when a carousel is built; log the viewed deck on every scroll.
	local _dbg_change_viewed_back = G.FUNCS.change_viewed_back
	G.FUNCS.change_viewed_back = function(args)
		local r = _dbg_change_viewed_back(args)
		mod.debug_deck_state("scroll to_key=" .. tostring(args and args.to_key), false)
		return r
	end

	local _dbg_run_setup_option = G.UIDEF.run_setup_option
	function G.UIDEF.run_setup_option(...)
		mod.debug_deck_state("run_setup_option", true)
		return _dbg_run_setup_option(...)
	end

	local _dbg_decks_collection = create_UIBox_your_collection_decks
	function create_UIBox_your_collection_decks(...)
		mod.debug_deck_state("decks_collection", true)
		return _dbg_decks_collection(...)
	end
end
