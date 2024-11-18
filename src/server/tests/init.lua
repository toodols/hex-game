local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client_tests = require(script.client)
local server_tests = require(script.server)
local util = require(ReplicatedStorage.Shared.util)

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
				local success, err_or_val = pcall(test)
				total += 1
				if success then
					print(`[Test {total} - {full_name}]`, "passed in", math.floor((os.clock() - test_t0) * 1000), "ms")
					successes += 1
				else
					warn(`[Test {total} - {full_name}]`, "failed:", err_or_val)
				end
			end
		end
	end
	run_tests_recursive({
		server = server_tests,
		client = client_tests,
	})

	if successes == total then
		print(`{successes} / {total} tests passed. Completed in {math.floor((os.clock() - tests_t0) * 1000)}ms`)
	else
		warn(`{successes} / {total} tests passed. Completed in {math.floor((os.clock() - tests_t0) * 1000)}ms`)
	end
end

return {
	run_tests = run_tests,
	scout_attack_each_other = server_tests.scout_attack_each_other,
	deconstruct_stockpile = server_tests.deconstruct_stockpile,
	chatgpt_didnt_grift_me = server_tests.chatgpt_didnt_grift_me,
	extractor_filling_stockpile = server_tests.extractor_filling_stockpile,
	stockpile_filters = server_tests.stockpile_filters,
}
