local ReplicatedStorage = game:GetService "ReplicatedStorage"
local util = require(ReplicatedStorage.Shared.util)
local formatting = require(ReplicatedStorage.Shared.formatting)
local assert_eq = util.assert_eq

local tests = {}
function tests.formatting()
	assert_eq(
		formatting.format_text_raw(
			"I am {state.mood.value} because my hunger is {state.hunger}.",
			{ state = { hunger = 90, mood = { value = "unhappy" } } }
		),
		"I am unhappy because my hunger is 90."
	)
	assert_eq(
		formatting.format_text_raw("I am {condition?value}happy.", { condition = true, value = "NOT " }),
		"I am NOT happy."
	)
	assert_eq(
		formatting.format_text_raw("I am {condition?value}happy.", { condition = false, value = "NOT " }),
		"I am happy."
	)
	assert_eq(
		formatting.format_text_raw(
			"The sky is {condition?then_val:else_val}",
			{ condition = true, then_val = "blue", else_val = "red" }
		),
		"The sky is blue"
	)
	assert_eq(
		formatting.format_text_raw(
			"The sky is {condition?then_val:else_val}",
			{ condition = false, then_val = "blue", else_val = "red" }
		),
		"The sky is red"
	)
end

return tests
