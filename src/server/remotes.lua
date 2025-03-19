local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type WorldUpdate = types.WorldUpdate
type World = types.World

local world_updates_remote = Instance.new "RemoteEvent"
world_updates_remote.Parent = ReplicatedStorage
world_updates_remote.Name = "WorldUpdatesRemote"

local get_world_data_remote = Instance.new "RemoteFunction"
get_world_data_remote.Parent = ReplicatedStorage
get_world_data_remote.Name = "GetWorldDataRemote"

local client_interaction_remote = Instance.new "RemoteEvent"
client_interaction_remote.Parent = ReplicatedStorage
client_interaction_remote.Name = "ClientInteractionRemote"

return {
	world_updates_remote = world_updates_remote,
	get_world_data_remote = get_world_data_remote,
	client_interaction_remote = client_interaction_remote,
}
