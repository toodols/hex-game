-- module for serializing and deserializing game state

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server_entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local researches_mod = require(ReplicatedStorage.Shared.researches)
local unlockable_mod = require(ReplicatedStorage.Shared.unlockable)

local schema = require(script.Parent.Parent.schema)

type World = types.World
type Entity = types.Entity
type HexCell = types.HexCell
type Inventory = types.Inventory
type Schema<T> = schema.Schema<T>
type Unlockable = types.Unlockable
type PlayerData = types.PlayerData
type Rating = types.Rating
type PlayerSettings = types.PlayerSettings
type SerializingSchema<T> = schema.SerializingSchema<T>

local enum = schema.enum
local struct = schema.struct
local option = schema.option
local array = schema.array
local map = schema.map
local i32 = schema.i32
local u8 = schema.u8
local str = schema.str
local boolean = schema.boolean
local collect_by_key = schema.collect_by_key
local const = schema.const
local tagged_union = schema.tagged_union
local f64 = schema.f64
local i32_infinite = schema.i32_infinite
local u16 = schema.u16

if #util.table_keys(server_entity_mod.registry) == 0 then
	error "No entities registered in server entity registry. Likely before it has loaded."
end

local entity_types = enum "entity_types"(util.table_keys(server_entity_mod.registry))

local entity_statuses = enum "entity_statuses" {
	"lock",
	"blueprint",
	"scaffold",
	"complete",
}

local item_type = enum "item_type" {
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

-- 16 bytes
local entity_id = {
	label = "entity_id",
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

local inventory: Schema<Inventory> = struct "inventory" {
	filter = struct { type = enum { "whitelist", "blacklist" }, items = map(item_type, boolean) },
	homogeneous = boolean,
	capacity = i32,
	items = array(item_type),
}

local coord = {
	label = "coord",
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
	label = "encoded_coord",
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

local icon = tagged_union "icon"({
	image = struct "icon-image" {
		type = const "image",
		image = str,
	},
	model = struct "icon-model" {
		type = const "model",
		model = str,
	},
	none = struct "icon-none" {
		type = const "none",
	},
	text = struct "icon-text" {
		type = const "text",
		text = str,
	},
}, "type")

-- 4 bytes
local team_id = u8

local player_id = i32

local research_id = enum(util.table_keys(researches_mod.researches))
research_id.label = "research_id"

local research_state = struct "research_state" {
	cost = map(item_type, i32),
	cost_is_paid = boolean,
	time = i32,
	progress = i32,
	description = str,
	name = str,
	id = research_id,
	icon = icon,
	coord = coord,
	status = enum {
		"incomplete",
		"researching",
		"complete",
	},
}

local researches = struct "researches" {
	states = collect_by_key(research_state, "id"),
	queue = array(research_id),
}

local queued_decision = tagged_union "queued_decision"({
	ability = struct {
		type = const "ability",
		ability_id = str,
		entity_id = entity_id,
		coordinates = array(coord),
	},
	-- construct = struct {
	--  type = const "construct",
	--  entity_id = entity_id,
	--  coordinates = array(coord),
	--  rotation = option(integer)
	-- },
	deconstruct = struct {
		type = const "deconstruct",
		entity_id = entity_id,
	},
	rotate_entity = struct {
		type = const "rotate_entity",
		entity_id = entity_id,
		rotation = u8,
	},
}, "type")

local effect = tagged_union "effect"({
	shield = struct {
		type = const "shield",
		health = i32,
	},
	infected = struct {
		type = const "infected",
	},
	infected_immune = struct {
		type = const "infected_immune",
	},
	regeneration = struct {
		type = const "regeneration",
	},
}, "type")

local deposit_type = enum "deposit_type" {
	"bar_deposit",
	"tar_deposit",
	"rad_deposit",
	"vit_deposit",
}

local entity: Schema<Entity> = struct "entity" {
	active = boolean,
	type = entity_types,
	coordinates = array(coord),
	id = entity_id,
	rotation = option(u8),
	health = i32_infinite,
	max_health = i32_infinite,
	head_rotation = option(u8), -- torch
	inventory = option(inventory),
	effects = array(effect),
	current_recipe = option(str),
	disguise = option(entity_id),
	deposit_type = option(deposit_type),
	enabled = boolean,
	should_output = option(u8),
	status = entity_statuses,
	primary_coordinate = coord,
	owner = team_id,
	decay = u8,
	decayable = boolean,
	is_decaying = boolean,
	is_destroyed = boolean,
	cost = option(map(item_type, i32)),
	autogenerated = option(boolean),
	charges = option(i32),
	cost_fulfilled = option(map(item_type, i32)),
	build_time = option(i32),
	researches = option(researches),
	queued_decisions = array(queued_decision),
	server_data = struct {
		requested_at = f64,
		child_relationship = option(enum { "lock", "disguise", "revived" }),
		parent = option(entity_id),
		always_visible = boolean,
		always_visible_for = map(team_id, const(true)),
		incorporeal = boolean,
	},
}

local cell_types = enum "cell_types" {
	"basic",
	"portal",
}

local cell: Schema<HexCell> = struct "cell" {
	type = cell_types,
	coordinate = coord,
	entities = map(entity_id, const(true)),
	influences = const {},
	server_data = const {
		presence = {},
		visibility = {},
	},
}

local color3 = {
	label = "color3",
	write = function(writer, data: Color3)
		writer.write_f64(data.R)
		writer.write_f64(data.G)
		writer.write_f64(data.B)
	end,
	read = function(reader)
		return Color3.new(reader.read_f64(), reader.read_f64(), reader.read_f64())
	end,
}

local color_sequence_keypoint = {
	label = "color_sequence_keypoint",
	write = function(writer, data: ColorSequenceKeypoint)
		writer.write_f64(data.Time)
		color3.write(writer, data.Value)
	end,
	read = function(reader)
		return ColorSequenceKeypoint.new(reader.read_f64(), color3.read(reader))
	end,
}

local color_sequence = {
	label = "color_sequence",
	write = function(writer, data: ColorSequence)
		writer.write_u16(#data.Keypoints)
		for _, keypoint in data.Keypoints do
			color_sequence_keypoint.write(writer, keypoint)
		end
	end,
	read = function(reader)
		local num_keypoints = reader.read_u16()
		local keypoints = {}
		for i = 1, num_keypoints do
			table.insert(keypoints, color_sequence_keypoint.read(reader))
		end
		return ColorSequence.new(keypoints)
	end,
}

local coalition_id = u8

local team_color = tagged_union "team_color"({
	color3 = struct {
		type = const "color3",
		color = color3,
	},
	color_sequence = struct {
		type = const "color_sequence",
		color_sequence = color_sequence,
	},
}, "type")

local team_data = struct "team_data" {
	id = team_id,
	name = str,
	historical_players = array(player_id),
	players = array(player_id),
	is_player_team = boolean,
	is_spectator_team = boolean,
	color = team_color,
	server_data = struct {
		creative = boolean,
		visibility = enum {
			"normal",
			"fogless",
			"perfect",
		},
	},
}

local global_configuration = struct "global_configuration" {
	decaying_enabled = boolean,
	construction_condition_enabled = boolean,
	rated = boolean,
	conclusion_enabled = boolean,
}

local quest = table.clone(schema.dynamic)
quest.label = "quest"

local turn_schedule_raw = struct "turn_schedule_raw" {
	end_time = f64,
	now = f64,
	running = boolean,
	start_time = f64,
	start_time_sync = f64,
}

local turn_schedule = {
	label = "turn_schedule",
	write = function(writer, data)
		data.now = os.clock()
		turn_schedule_raw.write(writer, data)
	end,
	read = function(reader)
		return turn_schedule_raw.read(reader)
	end,
}

local unlockable: Schema<Unlockable> = enum "unlockable"(unlockable_mod.get_unlockables())

local rating: Schema<Rating> = struct "rating" {
	mu = f64,
	sigma = f64,
}

local keybind_id = enum "keybind_id" {
	"construct",
	"skip",
	"primary_ability",
	"research",
	"show_player_list",
	"deconstruct",
	"previous_entity",
	"next_entity",
}

local player_settings: Schema<PlayerSettings> = struct "player_settings" {
	keybinds = map(keybind_id, u16),
}

local player_data: Schema<PlayerData> = struct "player_data" {
	rating = rating,
	rating_ordinal = f64,
	unlockables_owned = map(unlockable, const(true)),
	first_joined = f64,
	total_playtime = f64,
	games_played = i32,
	wins = i32,
	losses = i32,
	aborted = i32,
	settings = player_settings,
}

local coalition = struct "coalition" {
	id = coalition_id,
	name = str,
	teams = array(team_id),
}

local world_schema = struct "world" {
	entities = collect_by_key(entity, "id"),
	cells = map(encoded_coord, cell),
	teams = collect_by_key(team_data, "id"),
	coalitions = collect_by_key(coalition, "id"),
	global_configuration = global_configuration,
	neutral_team = team_id,
	spectator_team = team_id,
	turn = i32,
	highest_turn = i32,
	speed_multiplier = i32,
	speed_base = i32,
	skipped = const {},
	turn_schedule = option(turn_schedule),
	quests = collect_by_key(quest, "id"),
	player_data = map(player_id, player_data),
}

return { id = "v20260511", player_settings = player_settings, world_schema = world_schema, next = nil, migrate = nil }
