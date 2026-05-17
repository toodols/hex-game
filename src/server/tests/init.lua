local client_tests = require(script.client)
local default_tests = require(script.default)
local unit_tests = require(script.unit)
local misc_tests = require(script.misc)
local sanity_tests = require(script.sanity)
local serializing_tests = require(script.serializing)

function run_tests()
	local total = 0
	local successes = 0

	local tests_t0 = os.clock()
	local function run_tests_recursive(tests, namespace)
		for name, test in tests do
			local full_name = if namespace then namespace .. "/" .. name else name
			if type(test) == "table" then
				run_tests_recursive(test, full_name)
			else
				local test_t0 = os.clock()
				local success, err_or_val = xpcall(test, function(err)
					warn(`[Test {total} - {full_name}]`, "failed:", err, debug.traceback())
				end)
				total += 1
				if success then
					print(`[Test {total} - {full_name}]`, "passed in", math.floor((os.clock() - test_t0) * 1000), "ms")
					successes += 1
				end
			end
		end
	end

	_G.is_testing = true
	run_tests_recursive {
		default = default_tests,
		client = client_tests,
		unit = unit_tests,
		misc = misc_tests,
		sanity = sanity_tests,
		serializing = serializing_tests,
	}
	_G.is_testing = nil

	if successes == total then
		print(`{successes} / {total} tests passed. Completed in {math.floor((os.clock() - tests_t0) * 1000)}ms`)
	else
		warn(`{successes} / {total} tests passed. Completed in {math.floor((os.clock() - tests_t0) * 1000)}ms`)
	end
end

return {
	run_tests = run_tests,
	default = default_tests,
	client = client_tests,
	unit = unit_tests,
}
