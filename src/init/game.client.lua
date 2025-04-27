-- game.client.lua

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local get_world_data_remote = ReplicatedStorage:FindFirstChild "GetWorldDataRemote" :: RemoteFunction
local world_updates_remote = ReplicatedStorage:FindFirstChild "WorldUpdatesRemote" :: RemoteEvent
local world_mod = require(ReplicatedStorage.Shared.world)
local game_mod = require(ReplicatedStorage.Client.game)
local init_game_ui = require(ReplicatedStorage.Client.ui.game).init_ui
local types = require(ReplicatedStorage.Shared.types)
require(ReplicatedStorage.Client.entity_impls)
require(ReplicatedStorage.Shared.entity_impls)

print(require(ReplicatedStorage.Client.entity).registry)
print(require(ReplicatedStorage.Shared.entity).registry)

type World = types.World
type WorldUpdate = types.WorldUpdate

local world_data = get_world_data_remote:InvokeServer()
local world = world_mod.new_world_from_data(world_data)

game_mod.render_world(world)

local connection = world_updates_remote.OnClientEvent:Connect(function(updates: { WorldUpdate })
	game_mod.handle_updates(world, updates)
end)

local ui = init_game_ui(world)

game_mod.start_animations(world)

function cleanup()
	connection:Disconnect()
	game_mod.destroy_world_instances(world)
	ui.destroy()
end
