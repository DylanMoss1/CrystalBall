--- ui/overlay: the "searching" modal + toast.
--- ctx out: toast, show_waiting_overlay

return function(ctx)
	local mod = ctx.mod

	function ctx.toast(text, hold)
		attention_text({ text = text, scale = 0.8, hold = hold or 3, cover = G.ROOM_ATTACH, align = "cm" })
	end

	-- Modal shown while searching. no_esc forces exit through Cancel, so closing always
	-- cancels (esc would only hide it, leaving the seed to start a run later). Styled to
	-- match the attention_text toasts: an animated DynaText title, in an overlay_menu so
	-- it can host the button.
	function ctx.show_waiting_overlay()
		local title = DynaText({
			string = { "Finding seed..." },
			colours = { G.C.UI.TEXT_LIGHT },
			shadow = true,
			float = true,
			silent = true,
			pop_in = 0,
			pop_in_rate = 4,
			scale = 0.9,
		})
		G.FUNCS.overlay_menu({
			config = { no_esc = true },
			definition = {
				n = G.UIT.ROOT,
				config = { align = "cm", padding = 0.3, r = 0.1, colour = G.C.GREY, minw = 6, minh = 3 },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.2, minh = 1 },
						nodes = {
							{ n = G.UIT.O, config = { object = title } },
						},
					},
					{
						n = G.UIT.R,
						config = { align = "cm", padding = 0.1 },
						nodes = {
							UIBox_button({
								label = { "Cancel" },
								button = "crystalball_cancel",
								colour = G.C.RED,
								minw = 3,
								minh = 0.7,
								scale = 0.5,
							}),
						},
					},
				},
			},
		})
	end

	-- Cancel: abandon the in-flight search, back to the main menu.
	G.FUNCS.crystalball_cancel = function(_)
		mod.pending = nil
		mod.deferred = nil
		mod.resolving = false
		G.FUNCS.exit_overlay_menu()
	end
end
