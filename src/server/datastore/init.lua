local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local openskill = require(ServerScriptService.Server.openskill)
local structures = require(ServerScriptService.Server.structures)
local base64 = require(ReplicatedStorage.Shared.base64)

type PlayerId = types.PlayerId
type PlayerData = types.PlayerData
type Rating = types.Rating
type World = types.World
type PlayerSettings = types.PlayerSettings

local player_data_store = DataStoreService:GetDataStore "player_data"
local game_saves_store = DataStoreService:GetDataStore "game_saves"

function default_settings(): PlayerSettings
	return {
		keybinds = {},
	}
end

function with_default_player_data(value): PlayerData
	value = value or {}
	value.rating = value.rating or openskill.Rating()
	value.rating_ordinal = value.rating_ordinal or openskill.Ordinal(value.rating)
	value.unlockables_owned = value.unlockables_owned or {}
	value.first_joined = value.first_joined or os.time()
	value.total_playtime = value.total_playtime or 0
	value.games_played = value.games_played or 0
	value.wins = value.wins or 0
	value.losses = value.losses or 0
	value.aborted = value.aborted or 0
	value.settings = value.settings or default_settings()
	return value
end

function load_world(key: string): World
	local timestamp, world =
		structures.deserialize_world(base64.decode(DataStoreService:GetDataStore("saves"):GetAsync(key)))
	return world
end

function save_world(world: World, key: string)
	local data = base64.encode(structures.serialize_world(world))
	DataStoreService:GetDataStore("saves"):SetAsync(key, data)
	return data
end

function set_player_data(player_id: PlayerId, data: PlayerData)
	player_data_store:SetAsync(player_id, data)
end

function get_player_data(player_id: PlayerId): PlayerData
	return with_default_player_data(player_data_store:GetAsync(player_id))
end

function update_player_data(player_id: PlayerId, update: (PlayerData) -> PlayerData)
	player_data_store:UpdateAsync(player_id, function(data: PlayerData)
		if data == nil then
			data = with_default_player_data()
		end
		return update(data)
	end)
end

function update_rating(player_id: PlayerId, new_rating: Rating)
	update_player_data(player_id, function(data)
		data.rating = new_rating
		data.rating_ordinal = openskill.Ordinal(new_rating)
		return data
	end)
end

function increment_games_played(player_id: PlayerId)
	update_player_data(player_id, function(data)
		data.games_played = data.games_played + 1
		return data
	end)
end

return {
	get_player_data = get_player_data,
	set_player_data = set_player_data,
	update_player_data = update_player_data,
	update_rating = update_rating,
	increment_games_played = increment_games_played,
	default_player_data = with_default_player_data,
	load_world = load_world,
	save_world = save_world,
}
