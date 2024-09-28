local client_tests = require(script.client)
local server_tests = require(script.server)

function run_tests()
	local total = 0
	local successes = 0

	local tests_t0 = DateTime.now().UnixTimestampMillis
	local function run_tests_recursive(tests, namespace)
		for name, test in tests do
			local full_name = if namespace then namespace .. "/" .. name else name
			if type(test) == "table" then
				run_tests_recursive(test, full_name)
			else
				local test_t0 = DateTime.now().UnixTimestampMillis
				local success, err_or_val = pcall(test)
				total += 1
				if success then
					print("Test", full_name, "passed in", DateTime.now().UnixTimestampMillis - test_t0, "ms")
					successes += 1
				else
					warn("Test", full_name, "failed:", err_or_val)
				end
			end
		end
	end
	run_tests_recursive {
		server = server_tests,
		client = client_tests,
	}

	print(
		`{successes} / {total} tests passed. {math.floor(100 * successes / total)}% success rate. Completed in {DateTime.now().UnixTimestampMillis - tests_t0}ms`
	)
end

return {
	run_tests = run_tests,
	scout_attack_each_other = server_tests.scout_attack_each_other,
	deconstruct_stockpile = server_tests.deconstruct_stockpile,
	chatgpt_didnt_grift_me = server_tests.chatgpt_didnt_grift_me,
	extractor_filling_stockpile = server_tests.extractor_filling_stockpile,
}
