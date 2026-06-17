--- ui/editor: filter editor -- a list of clause rows (jokers + ante window + atLeast),
--- all ANDed. Also owns the mod-config tab and the Mods-menu tab reorder.

return function(ctx)
	local mod = ctx.mod
	local build_joker_line = ctx.build_joker_line
	local save_config = ctx.save_config

	local MIN_ANTE, MAX_ANTE = 1, 39
	local ROWS_PER_PAGE = 3 -- clause rows per section
	local PREVIEW_SCALE = 0.72 -- joker-line card scale in the rows

	mod._editor_page = 1 -- current section

	local function clamp(v, lo, hi)
		return math.max(lo, math.min(v or lo, hi))
	end

	-- A small labelled action button (Edit / Delete / Add row). disabled => greyed + inert.
	local function ui_button(text, colour, button_fn, ref, disabled)
		return {
			n = G.UIT.C,
			config = { align = "cm", padding = 0.05 },
			nodes = {
				{
					n = G.UIT.C,
					config = {
						ref_table = ref,
						align = "cm",
						padding = 0.1,
						r = 0.08,
						minw = 1.7,
						minh = 0.7,
						hover = not disabled,
						shadow = not disabled,
						colour = disabled and G.C.UI.BACKGROUND_INACTIVE or colour,
						one_press = not disabled or nil,
						button = not disabled and button_fn or nil,
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = text,
								colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT,
								scale = 0.5,
								shadow = true,
							},
						},
					},
				},
			},
		}
	end

	-- Would (kind,delta) breach a bound? Recomputed live by crystalball_arrow_vis.
	local function arrow_disabled(cl, kind, delta)
		local njokers = math.max(1, #cl.jokers)
		local minA = clamp(cl.minAnte, MIN_ANTE, MAX_ANTE)
		local maxA = clamp(cl.maxAnte, MIN_ANTE, MAX_ANTE)
		local atL = clamp(cl.atLeast, 1, njokers)
		if kind == "minante" then
			return delta < 0 and minA <= MIN_ANTE or (delta > 0 and minA >= maxA)
		elseif kind == "maxante" then
			return delta < 0 and maxA <= minA or (delta > 0 and maxA >= MAX_ANTE)
		else -- numjokers
			return delta < 0 and atL <= 1 or (delta > 0 and atL >= njokers)
		end
	end

	-- A < or > stepper arrow. Stays live always (crystalball_step clamps, so a press at a
	-- bound no-ops); crystalball_arrow_vis greys it in place, avoiding a full rebuild.
	local function step_arrow(glyph, cl, kind, delta, disp)
		local dis = arrow_disabled(cl, kind, delta)
		return {
			n = G.UIT.C,
			config = {
				align = "cm",
				r = 0.1,
				minw = 0.4,
				minh = 0.55,
				padding = 0.04,
				hover = true,
				shadow = true,
				colour = dis and G.C.UI.BACKGROUND_INACTIVE or G.C.RED,
				one_press = true,
				button = "crystalball_step",
				func = "crystalball_arrow_vis",
				ref_table = { cl = cl, kind = kind, delta = delta, disp = disp },
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = glyph,
						scale = 0.42,
						colour = dis and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT,
						shadow = true,
					},
				},
			},
		}
	end

	-- A labelled [< value >] stepper. The value live-binds to disp[kind] so crystalball_step
	-- can update one field without rebuilding the overlay.
	local function stepper(label, cl, kind, disp)
		return {
			n = G.UIT.C,
			config = { align = "cm", padding = 0.1 },
			nodes = {
				{
					n = G.UIT.R,
					config = { align = "cm" },
					nodes = { { n = G.UIT.T, config = { text = label, scale = 0.36, colour = G.C.UI.TEXT_LIGHT } } },
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.02 },
					nodes = {
						step_arrow("<", cl, kind, -1, disp),
						{
							n = G.UIT.C,
							config = {
								align = "cm",
								minw = 0.75,
								minh = 0.55,
								r = 0.1,
								colour = G.C.RED,
								emboss = 0.1,
								padding = 0.05,
							},
							nodes = {
								{
									n = G.UIT.R,
									config = { align = "cm" },
									nodes = {
										{
											n = G.UIT.T,
											config = {
												ref_table = disp,
												ref_value = kind,
												scale = 0.42,
												colour = G.C.UI.TEXT_LIGHT,
												shadow = true,
											},
										},
									},
								},
							},
						},
						step_arrow(">", cl, kind, 1, disp),
					},
				},
			},
		}
	end

	-- One clause row: joker preview (left) beside the controls (right; steppers over
	-- Edit/Delete).
	local function build_clause_row(cl, idx)
		local has = #cl.jokers > 0
		local njokers = math.max(1, #cl.jokers)
		local minA = clamp(cl.minAnte, MIN_ANTE, MAX_ANTE)
		local maxA = clamp(cl.maxAnte, MIN_ANTE, MAX_ANTE)
		local atL = clamp(cl.atLeast, 1, njokers)
		-- "Num matches": ">=N", or "All" when it equals the joker count. \226\137\165 = U+2265.
		local num_text = (atL >= #cl.jokers and has) and "All" or ("\226\137\165" .. atL)
		-- Live display strings keyed by stepper `kind`; crystalball_step mutates them.
		local disp = { minante = tostring(minA), maxante = tostring(maxA), numjokers = num_text }
		local line_node = has and { n = G.UIT.O, config = { object = build_joker_line(cl.jokers, false, PREVIEW_SCALE) } }
			or { n = G.UIT.T, config = { text = localize("k_none"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT } }
		return {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, minw = 8 },
			nodes = {
				{
					n = G.UIT.C,
					config = {
						align = "cm",
						minh = PREVIEW_SCALE * G.CARD_H,
						minw = 2,
						r = 0.1,
						colour = G.C.UI.TRANSPARENT_DARK,
						padding = 0.05,
					},
					nodes = { line_node },
				},
				{
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05 },
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.03 },
							nodes = {
								stepper("Min ante", cl, "minante", disp),
								stepper("Max ante", cl, "maxante", disp),
								stepper("Num matches", cl, "numjokers", disp),
							},
						},
						{
							n = G.UIT.R,
							config = { align = "cm", padding = 0.03 },
							nodes = {
								ui_button("Edit", G.C.BLUE, "crystalball_edit_clause", { idx = idx }),
								ui_button("Delete", G.C.RED, "crystalball_delete_clause", { idx = idx }),
							},
						},
					},
				},
			},
		}
	end

	-- Build + show the editor. `instant` suppresses the slide-in (for in-place re-renders
	-- after a stepper press).
	function mod.show_filter_editor(instant)
		local contents = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = {
					{
						n = G.UIT.T,
						config = { text = "Seed filter (all rows must match)", scale = 0.6, colour = G.C.UI.TEXT_LIGHT },
					},
				},
			},
		}
		local total = #mod.config.clauses
		local num_pages = math.max(1, math.ceil(total / ROWS_PER_PAGE))
		mod._editor_page = clamp(mod._editor_page, 1, num_pages)
		local first = (mod._editor_page - 1) * ROWS_PER_PAGE + 1
		local last = math.min(total, mod._editor_page * ROWS_PER_PAGE)

		-- Section flicker (< >): only when rows span more than one page.
		if num_pages > 1 then
			local pages = {}
			for i = 1, num_pages do
				pages[i] = localize("k_page") .. " " .. i .. "/" .. num_pages
			end
			contents[#contents + 1] = {
				n = G.UIT.R,
				config = { align = "cm", padding = 0.02 },
				nodes = {
					create_option_cycle({
						options = pages,
						current_option = mod._editor_page,
						cycle_shoulders = true,
						opt_callback = "crystalball_editor_page",
						w = 2.5,
						scale = 0.7,
						no_pips = true,
						focus_args = { snap_to = true, nav = "wide" },
					}),
				},
			}
		end

		-- Wrap rows so the inter-row gap = the container's padding (the engine inserts the
		-- PARENT's padding between children), not each row's.
		local rows = {}
		for i = first, last do
			rows[#rows + 1] = build_clause_row(mod.config.clauses[i], i)
		end
		contents[#contents + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.13 }, nodes = rows }
		contents[#contents + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.03 },
			nodes = { ui_button("+ Add row", G.C.GREEN, "crystalball_add_clause", nil) },
		}
		G.FUNCS.overlay_menu({
			definition = create_UIBox_generic_options({ back_func = "exit_overlay_menu", contents = contents }),
			config = instant and { offset = { x = 0, y = 0 } } or nil,
		})
	end

	-- Stepper: nudge a field by +-1 (clamped), persist, rebuild. The rebuild re-arms the
	-- pressed one_press arrow (the live `disp` update alone leaves the button latched).
	G.FUNCS.crystalball_step = function(e)
		local r = e and e.config and e.config.ref_table
		local cl = r and r.cl
		if not cl then
			return
		end
		local disp = r.disp
		if r.kind == "minante" then
			cl.minAnte = clamp((cl.minAnte or MIN_ANTE) + r.delta, MIN_ANTE, cl.maxAnte or MAX_ANTE)
			if disp then
				disp.minante = tostring(cl.minAnte)
			end
		elseif r.kind == "maxante" then
			cl.maxAnte = clamp((cl.maxAnte or MAX_ANTE) + r.delta, cl.minAnte or MIN_ANTE, MAX_ANTE)
			if disp then
				disp.maxante = tostring(cl.maxAnte)
			end
		elseif r.kind == "numjokers" then
			cl.atLeast = clamp((cl.atLeast or 1) + r.delta, 1, math.max(1, #cl.jokers))
			if disp then
				disp.numjokers = (cl.atLeast >= #cl.jokers and #cl.jokers > 0) and "All" or ("\226\137\165" .. cl.atLeast)
			end
		end
		save_config()
		mod.show_filter_editor(true)
	end

	-- Per-frame: grey a stepper arrow (and glyph) when its move would breach a bound.
	G.FUNCS.crystalball_arrow_vis = function(e)
		local r = e.config.ref_table
		if not (r and r.cl) then
			return
		end
		local dis = arrow_disabled(r.cl, r.kind, r.delta)
		e.config.colour = dis and G.C.UI.BACKGROUND_INACTIVE or G.C.RED
		local glyph = e.children and e.children[1]
		if glyph and glyph.config then
			glyph.config.colour = dis and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT
		end
	end

	G.FUNCS.crystalball_editor_page = function(args)
		if not args or not args.cycle_config then
			return
		end
		mod._editor_page = args.to_key
		mod.show_filter_editor(true)
	end

	G.FUNCS.crystalball_edit_clause = function(e)
		local idx = e and e.config and e.config.ref_table and e.config.ref_table.idx
		if idx then
			mod.show_joker_picker(idx)
		end
	end

	G.FUNCS.crystalball_delete_clause = function(e)
		local idx = e and e.config and e.config.ref_table and e.config.ref_table.idx
		if idx then
			table.remove(mod.config.clauses, idx)
			save_config()
			mod.show_filter_editor(true)
		end
	end

	-- Add an empty clause and pick its jokers; jump to the section holding the new row.
	G.FUNCS.crystalball_add_clause = function(_)
		mod.config.clauses[#mod.config.clauses + 1] = ctx.new_clause()
		mod._editor_page = math.ceil(#mod.config.clauses / ROWS_PER_PAGE)
		mod.show_joker_picker(#mod.config.clauses)
	end

	-- Mod config tab (Mods > Crystal Ball > Config): a button into the editor.
	function mod.config_tab()
		return {
			n = G.UIT.ROOT,
			config = { align = "cm", padding = 0.1, colour = G.C.CLEAR },
			nodes = {
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = #mod.config.clauses .. " filter row(s) set",
								scale = 0.5,
								colour = G.C.UI.TEXT_LIGHT,
							},
						},
					},
				},
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0.1 },
					nodes = {
						UIBox_button({
							label = { "Edit seed filter" },
							button = "crystalball_open_editor",
							colour = G.C.BLUE,
							minw = 4,
							minh = 0.8,
							scale = 0.5,
						}),
					},
				},
			},
		}
	end

	G.FUNCS.crystalball_open_editor = function(_)
		-- Our editor's Back exits straight to the menu, never through exit_mods (the only
		-- place SMODS clears G.ACTIVE_MOD_UI). A dangling flag poisons SMODS.collection_pool
		-- -> the deck carousel filters to our deckless mod -> every deck resolves to Red.
		-- Drop it here: opening the editor means we've left the mod-collection context.
		G.ACTIVE_MOD_UI = nil
		mod._editor_page = 1
		mod.show_filter_editor()
	end

	-- Reorder our Mods-menu tabs: Config first, description relabelled "About". Steamodded
	-- has no per-mod hook, so intercept the single create_tabs call it makes while rendering
	-- OUR mod, then restore the global so other mods are untouched.
	local _orig_create_UIBox_mods = create_UIBox_mods
	function create_UIBox_mods(args)
		if G.ACTIVE_MOD_UI ~= mod then
			return _orig_create_UIBox_mods(args)
		end
		SMODS.LAST_SELECTED_MOD_TAB = "config" -- land on Config on each (re)open
		local _orig_create_tabs = create_tabs
		create_tabs = function(opts)
			create_tabs = _orig_create_tabs -- single call; restore before delegating
			local tabs = opts and opts.tabs
			if tabs and tabs[1] then
				tabs[1].label = "About" -- description tab is always first
				local config_label = localize("b_config")
				for i = 2, #tabs do
					if tabs[i].label == config_label then
						table.insert(tabs, 1, table.remove(tabs, i)) -- Config to front
						break
					end
				end
			end
			return _orig_create_tabs(opts)
		end
		local ok, res = pcall(_orig_create_UIBox_mods, args)
		create_tabs = _orig_create_tabs -- restore even if create_tabs was never called
		if not ok then
			error(res)
		end
		return res
	end
end
