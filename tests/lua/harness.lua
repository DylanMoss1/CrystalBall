-- Tiny TAP-ish assert harness shared by the Lua tests.
--   local T = dofile(".../harness.lua").new()
--   T.check("name", got, want)   -- equality
--   T.ok("name", cond)           -- truthiness
--   T.match("name", str, pat)    -- string.match
--   T.finish()                   -- prints the plan, exits nonzero on any failure
local M = {}

function M.new()
	local self = { failures = 0, count = 0 }

	function self.check(name, got, want)
		self.count = self.count + 1
		if got ~= want then
			self.failures = self.failures + 1
			io.write(("not ok %d - %s\n  want: %s\n   got: %s\n"):format(self.count, name, tostring(want), tostring(got)))
		else
			io.write(("ok %d - %s\n"):format(self.count, name))
		end
	end

	function self.ok(name, cond)
		self.check(name, cond and true or false, true)
	end

	function self.match(name, str, pat)
		self.check(name .. " ~ /" .. pat .. "/", str and str:match(pat) ~= nil, true)
	end

	function self.finish()
		io.write(("\n1..%d  (%d failed)\n"):format(self.count, self.failures))
		os.exit(self.failures == 0 and 0 or 1)
	end

	return self
end

return M
