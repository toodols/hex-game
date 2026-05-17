local ReplicatedStorage = game:GetService "ReplicatedStorage"
local util = require(ReplicatedStorage.Shared.util)
local formatting = require(ReplicatedStorage.Shared.formatting)
local coords = require(ReplicatedStorage.Shared.coords)

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

function tests.sector()
	local r = 0
	local sector120 = util.table_join(
		coords.into_set(coords.sector({ 0, 0, 0 }, r, 1)),
		coords.into_set(coords.sector({ 0, 0, 0 }, r - 1, 1))
	)
	assert_eq(
		sector120,
		coords.into_set {
			{ 0, 0, 0 },
			{ 0, 1, -1 },
			{ -1, 1, 0 },
			{ -1, 0, 1 },
		}
	)
end

function tests.rotate_coord()
	assert_eq(coords.rotate_coord({ 0, 0, 0 }, 1), { 0, 0, 0 })
	assert_eq(coords.rotate_coord({ -1, 1, 0 }, 1), { 0, 1, -1 })
	assert_eq(coords.rotate_coord({ 1, -1, 0 }, 1), { 0, -1, 1 })
	assert_eq(coords.rotate_coord({ 0, 1, -1 }, 1), { 1, 0, -1 })
	assert_eq(coords.rotate_coord({ 0, 4, -4 }, 3), { 0, -4, 4 })
	assert_eq(coords.rotate_coord({ 0, 4, -4 }, 0), { 0, 4, -4 })
	assert_eq(coords.rotate_coord({ 1, 2, -3 }, 1), { 3, -1, -2 })
end

function tests.fit_coords()
	local triangle = { { 0, 0, 0 }, { 1, 0, 0 }, {} }
end

return tests
