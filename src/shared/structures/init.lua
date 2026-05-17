local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local binary_encoder = require(script.binary_encoder)
local versions = require(script.versions)

type World = types.World
type PlayerSettings = types.PlayerSettings
type PlayerData = types.PlayerData
type WorldUpdate = types.WorldUpdate
type PartialWorld = types.PartialWorld

local main = versions.main

function serialize_world(world: World): string
	local writer = binary_encoder.write()
	writer.write_string(versions.main.id)
	local timestamp = DateTime.now().UnixTimestampMillis
	writer.write_f64(timestamp)
	main.world_schema.write(writer, world)
	return writer.to_string()
end

function deserialize_world(data: string): (number, World)
	local reader = binary_encoder.read(data)
	local version_id = reader.read_string()
	local version = versions[version_id]
	assert(version ~= nil, `version {version_id} is nil`)
	local timestamp = reader.read_f64()
	local world = version.world_schema.read(reader)
	return timestamp, world
end

function serialize_player_data(player_settings: PlayerData): string
	assert(player_settings ~= nil, "player_settings is nil")
	local writer = binary_encoder.write()
	writer.write_string(versions.main.id)
	main.player_data.write(writer, player_settings)
	return writer.to_string()
end
function deserialize_player_data(data: string): PlayerData
	assert(data ~= nil, "data is nil")
	assert(data ~= "", "data is empty")
	local reader = binary_encoder.read(data)
	local version_id = reader.read_string()
	local version = versions[version_id]
	assert(version ~= nil, `version {version_id} is nil`)
	return version.player_data.read(reader)
end

function serialize_world_updates(updates: { WorldUpdate }): string
	local writer = binary_encoder.write()
	main.world_updates.write(writer, updates)
	return writer.to_string()
end

function deserialize_world_updates(data: string): { WorldUpdate }
	local reader = binary_encoder.read(data)
	return main.world_updates.read(reader)
end

function serialize_partial_world(world: PartialWorld): string
	local writer = binary_encoder.write()
	main.partial_world.write(writer, world)
	return writer.to_string()
end

function deserialize_partial_world(data: string): PartialWorld
	local reader = binary_encoder.read(data)
	return main.partial_world.read(reader)
end

return {
	main = main,
	validate_player_settings = main.player_data.validate,

	serialize_world = serialize_world,
	deserialize_world = deserialize_world,

	serialize_player_data = serialize_player_data,
	deserialize_player_data = deserialize_player_data,

	serialize_world_updates = serialize_world_updates,
	deserialize_world_updates = deserialize_world_updates,

	serialize_partial_world = serialize_partial_world,
	deserialize_partial_world = deserialize_partial_world,
}
