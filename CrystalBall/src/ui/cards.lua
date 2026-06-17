--- ui/cards: joker-row primitives shared by the picker (clickable) and editor (preview).
--- ctx out: toggle_highlight, make_sel_card, build_joker_line, SEL_SCALE

return function(ctx)
	local mod = ctx.mod

	local SEL_SCALE = 0.78 -- selection-line card scale
	ctx.SEL_SCALE = SEL_SCALE -- picker sizes its rack to this
	local SEL_LIMIT = 10 -- selection-line capacity (line compresses; no hard cap)
	local SEL_SPAN = 6.5 -- selection-line width in card-widths: < SEL_LIMIT so cards pack tight

	-- Single-highlight a card within a group, toggling off if re-clicked. holder[field]
	-- tracks the current highlight. Drives Card:highlight directly -- the CardArea path
	-- only runs for joker/hand areas and reaches into run-only G.jokers (nil => crash).
	local function toggle_highlight(card, holder, field)
		local cur = holder[field]
		if cur and cur ~= card then
			cur:highlight(false)
		end
		if card.highlighted then
			card:highlight(false)
			holder[field] = nil
		else
			card:highlight(true)
			holder[field] = card
		end
	end
	ctx.toggle_highlight = toggle_highlight

	-- A selection-line card for a center. Spawns at (x, y) so it animates in from there.
	-- interactive => highlights on click to surface the Remove button.
	local function make_sel_card(center, x, y, interactive, scale)
		scale = scale or SEL_SCALE
		local card = Card(x or 0, y or 0, scale * G.CARD_W, scale * G.CARD_H, nil, center, {
			bypass_discovery_center = true,
			bypass_discovery_ui = true,
		})
		if interactive then
			card.crystalball_sel = true
			card.states.click.can = true
			card.click = function(self)
				toggle_highlight(self, mod, "_sel_highlighted")
			end
		end
		return card
	end
	ctx.make_sel_card = make_sel_card

	-- A joker-row CardArea from center keys. Always title_2 (a passive collection row) to
	-- dodge the run-only joker-area paths. clickable => Remove on click; else static preview.
	function ctx.build_joker_line(keys, clickable, scale)
		scale = scale or SEL_SCALE
		-- Clickable line keeps a fixed capacity (cards stream in); preview sizes to content.
		local n = #keys
		local cap = clickable and SEL_LIMIT or math.max(1, n)
		-- title_2's exactly-2-cards branch packs at 25%/75%, overlapping at width 2 -- widen
		-- to 3 for n==2. Preview width caps at 5 cards (cards then compress, row stops growing).
		local PREVIEW_MAX_SPAN = 5
		local span = clickable and SEL_SPAN or (n == 2 and 3 or math.max(1, math.min(n, PREVIEW_MAX_SPAN)))
		local area = CardArea(0, 0, span * scale * G.CARD_W, scale * G.CARD_H, {
			card_limit = cap,
			card_w = scale * G.CARD_W,
			type = "title_2",
			highlight_limit = 0,
		})
		for _, key in ipairs(keys) do
			local center = G.P_CENTERS[key]
			if center then
				area:emplace(make_sel_card(center, nil, nil, clickable, scale))
			end
		end
		return area
	end
end
