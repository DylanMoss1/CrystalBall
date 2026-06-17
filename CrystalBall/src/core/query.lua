--- core/query: criteria -> JSON, the grammar Immolate's query_parse.h accepts. Pure.

return function(ctx)
	local mod = ctx.mod

	local function clause_json(cl)
		local of = {}
		for _, name in ipairs(cl.of) do
			of[#of + 1] = string.format('"%s"', name)
		end
		return string.format(
			'{"atLeast":%d,"minAnte":%d,"maxAnte":%d,"of":[%s]}',
			cl.atLeast,
			cl.minAnte,
			cl.maxAnte,
			table.concat(of, ",")
		)
	end

	local function group_json(g)
		local cls = {}
		for _, cl in ipairs(g.all) do
			cls[#cls + 1] = clause_json(cl)
		end
		return string.format('{"all":[%s]}', table.concat(cls, ","))
	end

	function mod.query_json(criteria)
		local gs = {}
		for _, g in ipairs(criteria.any) do
			gs[#gs + 1] = group_json(g)
		end
		return string.format('{"any":[%s]}', table.concat(gs, ","))
	end
end
