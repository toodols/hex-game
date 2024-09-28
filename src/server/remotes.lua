local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type GridUpdate = types.GridUpdate
type HexGrid = types.HexGrid

local grid_updates_remote = Instance.new "RemoteEvent"
grid_updates_remote.Parent = ReplicatedStorage
grid_updates_remote.Name = "GridUpdatesRemote"

local get_hex_grid_data_remote = Instance.new "RemoteFunction"
get_hex_grid_data_remote.Parent = ReplicatedStorage
get_hex_grid_data_remote.Name = "GetHexGridDataRemote"

local client_interaction_remote = Instance.new "RemoteEvent"
client_interaction_remote.Parent = ReplicatedStorage
client_interaction_remote.Name = "ClientInteractionRemote"

return {
	grid_updates_remote = grid_updates_remote,
	get_hex_grid_data_remote = get_hex_grid_data_remote,
	client_interaction_remote = client_interaction_remote,
}
