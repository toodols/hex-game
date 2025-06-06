local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local openskill = require(ServerScriptService.Server.openskill)
local archive = require(ServerScriptService.Server.archive)
local base64 = require(ReplicatedStorage.Shared.base64)

type PlayerId = types.PlayerId
type PlayerData = types.PlayerData
type Rating = types.Rating
type World = types.World

local player_data_store = DataStoreService:GetDataStore "player_data"
local game_saves_store = DataStoreService:GetDataStore "game_saves"

function default_player_data(): PlayerData
	local default_rating = openskill.Rating()
	return {
		rating = default_rating,
		rating_ordinal = openskill.Ordinal(default_rating),
		unlockables_owned = {},
		first_joined = os.time(),
		total_playtime = 0,
		games_played = 0,
		wins = 0,
		losses = 0,
		aborted = 0,
	}
end

function load_world(key: string): World
	return archive.deserialize_world(base64.decode(DataStoreService:GetDataStore("saves"):GetAsync(key)))
end

function save_world(world: World, key: string)
	local data = base64.encode(archive.serialize_world(world))
	DataStoreService:GetDataStore("saves"):SetAsync(key, data)
	return data
end

function set_player_data(player_id: PlayerId, data: PlayerData)
	player_data_store:SetAsync(player_id, data)
end

function get_player_data(player_id: PlayerId): PlayerData
	return player_data_store:GetAsync(player_id) or default_player_data()
end

function update_player_data(player_id: PlayerId, update: (PlayerData) -> PlayerData)
	player_data_store:UpdateAsync(player_id, function(data: PlayerData)
		if data == nil then
			data = default_player_data()
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
	default_player_data = default_player_data,
	load_world = load_world,
	save_world = save_world,
}
