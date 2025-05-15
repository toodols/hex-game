-- module for serializing and deserializing game state

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server_entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local serializing = require(script.serialize)
local coords_mod = require(ReplicatedStorage.Shared.coords)

type World = types.World
type Entity = types.Entity
type HexCell = types.HexCell
type Inventory = types.Inventory
type Schema<T> = serializing.Schema<T>

local enum = serializing.enum
local struct = serializing.struct
local option = serializing.option
local array = serializing.array
local map = serializing.map
local integer = serializing.integer
local str = serializing.string
local boolean = serializing.boolean
local debug_size = serializing.debug_size
local collect_by_key = serializing.collect_by_key

local entity_types = serializing.enum(util.table_keys(server_entity_mod.registry))

local statuses = serializing.enum {
	"blueprint",
	"scaffold",
	"complete",
}
local item_type = serializing.enum {
	"bar",
	"tar",
	"rad",
	"vit",
	"tek",
	"pow",
	"dye",
	"goo",
	"zap",
}

local entity_id = {
	write = function(writer, data)
		local inner = data:match "{([%x%-]+)}"
		local hex = inner:gsub("-", "")
		for i = 1, 16 do
			local byte = tonumber(hex:sub((i - 1) * 2 + 1, i * 2), 16)
			writer.write_u8(byte)
		end
	end,

	read = function(reader)
		local bytes = {}
		for i = 1, 16 do
			table.insert(bytes, string.format("%02x", reader.read_u8()))
		end
		return string.format(
			"{%s-%s-%s-%s-%s}",
			table.concat(bytes, "", 1, 4),
			table.concat(bytes, "", 5, 6),
			table.concat(bytes, "", 7, 8),
			table.concat(bytes, "", 9, 10),
			table.concat(bytes, "", 11, 16)
		)
	end,
}

local inventory_schema: Schema<Inventory> = struct {
	items = array(item_type),
}

local coord = {
	write = function(writer, data)
		writer.write_i8(data[1])
		writer.write_i8(data[2])
	end,
	read = function(reader)
		local x = reader.read_i8()
		local y = reader.read_i8()
		return { x, y, -x - y }
	end,
}

local encoded_coord = {
	write = function(writer, data)
		local decoded = coords_mod.decode_coord(data)
		writer.write_i8(decoded[1])
		writer.write_i8(decoded[2])
	end,

	read = function(reader)
		local x = reader.read_i8()
		local y = reader.read_i8()
		return coords_mod.encode_coord { x, y, -x - y }
	end,
}

local entity_schema: Schema<Entity> = struct {
	type = entity_types,
	id = entity_id,
	status = statuses,
	health = integer,
	max_health = integer,
	primary_coordinate = coord,
	coordinates = array(coord),
	inventory = option(inventory_schema),
	decay = option(integer),
	is_destroyed = option(boolean),
	rotation = option(integer),
	cost = option(map(item_type, integer)),
	cost_fulfilled = option(map(item_type, integer)),
	build_time = option(integer),
}

local team_id = integer
local player_id = integer

local cell_types = enum {
	"basic",
	"portal",
	"bar_deposit",
	"tar_deposit",
	"rad_deposit",
	"vit_deposit",
}

local cell_schema = struct {
	type = cell_types,
	coordinate = coord,
	-- entities = array(entity_id),
}

local team_data = struct {
	id = team_id,
	name = str,
	players = array(player_id),
	is_player_team = boolean,
	is_spectator_team = boolean,
}

local global_configuration = struct {
	decaying_enabled = boolean,
}

local quest_schema = {}

local world_schema = struct {
	entities = collect_by_key(entity_schema, "id"),
	cells = map(encoded_coord, cell_schema),
	teams = array(team_data),
	global_configuration = global_configuration,
	turn = integer,
	highest_turn = integer,
	speed_multiplier = integer,
	speed_base = integer,
	quests = collect_by_key(quest_schema, "id"),
}

function serialize_world(world: World): string
	local writer = serializing.write()
	world_schema.write(writer, world)
	return writer.to_string()
end

function deserialize_world(data: string): World
	local reader = serializing.read(data)
	local world = world_schema.read(reader)
	return world
end

return {
	serialize_world = serialize_world,
	deserialize_world = deserialize_world,
}
