local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local util = require(ReplicatedStorage.Shared.util)
local formatting = require(ReplicatedStorage.Shared.formatting)
local coords = require(ReplicatedStorage.Shared.coords)
local OpenSkill = require(ServerScriptService.Server.openskill)

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

function tests.openskill()
	local alice = OpenSkill.Rating()
	local bob = OpenSkill.Rating()
	local charlie = OpenSkill.Rating()

	-- charlie always loses
	for i = 1, 10 do
		OpenSkill.Rate { { alice }, { bob, charlie } }
		OpenSkill.Rate { { alice, bob }, { charlie } }
		OpenSkill.Rate { { bob }, { alice } }
		OpenSkill.Rate { { bob }, { alice, charlie } }
		OpenSkill.Rate { { alice }, { bob, charlie } }
	end

	local alice_ordinal = OpenSkill.Ordinal(alice)
	local bob_ordinal = OpenSkill.Ordinal(bob)
	local charlie_ordinal = OpenSkill.Ordinal(charlie)

	assert(bob_ordinal > alice_ordinal, "bob should be better than alice")
	assert(alice_ordinal > charlie_ordinal, "alice should be better than charlie")
	assert(bob_ordinal > charlie_ordinal, "bob should be better than charlie")
end

return tests
