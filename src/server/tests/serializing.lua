local HttpService = game:GetService "HttpService"
local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local action_phase = require(ServerScriptService.Server.action_phase)
local util = require(ReplicatedStorage.Shared.util)
local serializing = require(ReplicatedStorage.Shared.serializing)
local binary_encoder = require(ReplicatedStorage.Shared.serializing.binary_encoder)
local schema_mod = require(ReplicatedStorage.Shared.serializing.schema)

local presets = require(ServerScriptService.Server.presets)
local router = require(ServerScriptService.Server.router)
local cleanup = require(ServerScriptService.Server.cleanup).cleanup
local view_mod = require(ServerScriptService.Server.view)

local assert_eq = util.assert_eq
local struct = schema_mod.struct
local i32 = schema_mod.i32
local str = schema_mod.str
local boolean = schema_mod.boolean
local const = schema_mod.const
local dynamic_table = schema_mod.dynamic_table
local dynamic = schema_mod.dynamic
local array = schema_mod.array
local option = schema_mod.option
local map = schema_mod.map

function try(fun, catch)
	local ok, err = pcall(fun)
	if not ok then
		catch(err)
	end
	return err
end

local tests = {}
function tests.binary_encoder()
	local fields = {
		type = const "person",
		name = str,
		age = i32,
		alive = boolean,
		children = schema_mod.error,
	}
	local person = struct(fields)
	fields.children = option(array(person))

	local writer = binary_encoder.write()
	local sample = {
		type = "person",
		name = "John Doe",
		age = 30,
		alive = true,
		children = { {
			type = "person",
			name = "Little John",
			age = 2,
			alive = false,
		} },
	}

	i32.write(writer, 30)
	person.write(writer, sample)
	dynamic_table.write(writer, sample)
	dynamic.write(writer, sample)

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
	assert(data2.children[1].name == "Little John", "children")
	local data3 = dynamic.read(reader)
	assert_eq(data, data2)
	assert_eq(data2, data3)
end

function tests.serialize_entity_configurations()
	local world = presets.my_map()
	do
		local writer = binary_encoder.write()
		schema_mod.dynamic.write(writer, true)
		local reader = binary_encoder.read(writer.to_string())
		local result = schema_mod.dynamic.read(reader)
		assert_eq(result, true)
	end
	do
		local entity_configurations = world.entity_configurations
		local first = entity_configurations[next(entity_configurations)]
		for k, v in first do
			local writer = binary_encoder.write()
			schema_mod.dynamic.write(writer, v)
			local reader = binary_encoder.read(writer.to_string())
			local result = schema_mod.dynamic.read(reader)
			assert_eq(result, v)
		end
	end
	do
		local entity_configurations = world.entity_configurations
		local first = entity_configurations[next(entity_configurations)]
		local writer = binary_encoder.write()
		schema_mod.dynamic.write(writer, first)
		local reader = binary_encoder.read(writer.to_string())
		local result = schema_mod.dynamic.read(reader)
		assert_eq(result, first)
	end
	do
		local entity_configurations = world.entity_configurations
		local writer = binary_encoder.write()
		schema_mod.dynamic.write(writer, entity_configurations)
		local reader = binary_encoder.read(writer.to_string())
		local result = schema_mod.dynamic.read(reader)
		assert_eq(result, entity_configurations)
	end
	cleanup(world)
end

function tests.archive_world()
	-- todo
	local world = presets.my_map()

	local compressed = serializing.serialize_world(world)
	local as_json = HttpService:JSONEncode(world)
	print("World saved as", #compressed, "bytes")
	print(("Is %d%% of JSON size"):format(math.floor(#compressed / #as_json * 100)))
	local _timestamp, _decompressed_world = serializing.deserialize_world(compressed)

	cleanup(world)
end

function tests.serialize_partial_world()
	local world, teams = presets.my_map()

	local partial_world = view_mod.world_view(world, {}, {
		team = teams.team1.id,
		player = nil,
	})
	local partial_world_schema = serializing.main.partial_world
	local writer = binary_encoder.write()
	for key, schema in partial_world_schema.object do
		try(function()
			schema.write(writer, partial_world[key])
		end, function()
			print("data", partial_world[key])
			error("failed to write " .. key)
		end)
	end
	local reader = binary_encoder.read(writer.to_string())
	for key, schema in partial_world_schema.object do
		try(function()
			schema.read(reader, partial_world[key])
		end, function(err)
			print("data", partial_world[key])
			error("failed to read " .. key)
		end)
	end
	assert(partial_world.cells[next(partial_world.cells)].server_data == nil, "Server data should not be serialized")
	local compressed = serializing.serialize_partial_world(partial_world)
	local decompressed = serializing.deserialize_partial_world(compressed)
	assert_eq(partial_world, decompressed)
	cleanup(world)
end

function tests.serialize_one_entity()
	local world, teams = presets.my_map()
	local scout = (world:query_entity {
		type = "scout",
		owner = teams.team1.id,
		query_global = true,
	})[1]

	local scout_view = view_mod.entity_view(world, {}, { team = teams.team1.id }, scout)
	local writer = binary_encoder.write()
	serializing.main.entity.write(writer, scout_view)
	local reader = binary_encoder.read(writer.to_string())
	local result = serializing.main.entity.read(reader)
	assert_eq(scout_view, result)
	cleanup(world)
end

function tests.serialize_world_updates()
	local world, teams = presets.my_map()
	local partial_world = view_mod.world_view(world, {}, {
		team = teams.team1.id,
		player = nil,
	})

	local scout = (world:query_entity {
		type = "scout",
		owner = teams.team1.id,
		query_global = true,
	})[1]

	assert(scout, "Scout not found")

	local action_phase_result = action_phase.run_action_phase(world)
	local updates = action_phase_result.updates[teams.team1.id]

	local interaction_result = router.on_client_interaction(world, {
		player_team = teams.team1,
		data = {
			{
				type = "ability",
				ability_id = "attack",
				coordinate = scout.primary_coordinate,
				entity_id = scout.id,
			},
		},
		plr = nil,
	})

	for _, update in interaction_result.updates[teams.team1.id] do
		table.insert(updates, update)
	end

	assert(#updates > 0, "Updates should not be empty")

	for _, update in updates do
		local writer = binary_encoder.write()
		try(function()
			serializing.main.world_update.write(writer, update)
		end, function()
			print("data", update)
			error "failed to write update"
		end)

		local reader = binary_encoder.read(writer.to_string())
		local result = try(function()
			return serializing.main.world_update.read(reader)
		end, function()
			print("data", update)
			error "failed to read update"
		end)
		assert_eq(update, result)
	end

	local data = serializing.serialize_world_updates(updates)
	local decompressed = serializing.deserialize_world_updates(data)

	assert_eq(updates, decompressed)
	-- client_game_mod.handle_updates(client_world, decompressed)

	cleanup(world)
end

return tests
