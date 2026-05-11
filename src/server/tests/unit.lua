local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local util = require(ReplicatedStorage.Shared.util)
local formatting = require(ReplicatedStorage.Shared.formatting)
local coords = require(ReplicatedStorage.Shared.coords)
local OpenSkill = require(ServerScriptService.Server.openskill)
local binary_encoder = require(ServerScriptService.Server.structures.binary_encoder)
local schema = require(ServerScriptService.Server.structures.schema)

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

	OpenSkill.Rate({ { alice }, { bob } }, { rank = { 0, 0 } })

	local alice_new_ordinal = OpenSkill.Ordinal(alice)
	local bob_new_ordinal = OpenSkill.Ordinal(bob)
	assert(alice_new_ordinal > alice_ordinal, "alice's ordinal should go up")
	assert(bob_new_ordinal < bob_ordinal, "bob's ordinal should go down")
end

function tests.binary_encoder()
	local struct = schema.struct
	local i32 = schema.i32
	local str = schema.str
	local boolean = schema.boolean
	local const = schema.const
	local dynamic_table = schema.dynamic_table

	local person = struct {
		type = const "person",
		name = str,
		age = i32,
		alive = boolean,
	}
	local writer = binary_encoder.write()
	i32.write(writer, 30)
	local sample = {
		type = "person",
		name = "John Doe",
		age = 30,
		alive = true,
	}
	person.write(writer, sample)
	dynamic_table.write(writer, sample)
	local text = writer.to_string()
	local reader = binary_encoder.read(text)
	assert(i32.read(reader) == 30, "number")
	local data = person.read(reader)
	assert(data.type == "person", "type")
	assert(data.name == "John Doe", "name")
	assert(data.age == 30, "age")
	assert(data.alive == true, "alive")
	local data2 = dynamic_table.read(reader)
	assert(data2.type == "person", "type")
	assert(data2.name == "John Doe", "name")
	assert(data2.age == 30, "age")
	assert(data2.alive == true, "alive")
end

return tests
