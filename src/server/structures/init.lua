local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local binary_encoder = require(script.binary_encoder)
local versions = require(script.versions)

type World = types.World
type PlayerSettings = types.PlayerSettings
type PlayerData = types.PlayerData

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
	if version == nil then
		error(("unknown version id %s"):format(version_id))
	end

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
	if version == nil then
		error(("unknown version id %s"):format(version_id))
	end
	return version.player_data.read(reader)
end

return {
	serialize_world = serialize_world,
	deserialize_world = deserialize_world,

	serialize_player_data = serialize_player_data,
	deserialize_player_data = deserialize_player_data,
}
