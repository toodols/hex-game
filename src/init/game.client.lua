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
require(ReplicatedStorage.Shared.effect_impls)

local structures = require(ReplicatedStorage.Shared.structures)

type World = types.World
type WorldUpdate = types.WorldUpdate

local world_data = get_world_data_remote:InvokeServer()
local world = world_mod.new_world_from_data(structures.deserialize_partial_world(world_data))
_G.world = world
game_mod.render_world(world)

local update_queue = {}
local processing = false
local connection = world_updates_remote.OnClientEvent:Connect(function(updates_binary: string)
	local updates = structures.deserialize_world_updates(updates_binary)
	table.insert(update_queue, updates)
	if not processing then
		processing = true
		while #update_queue > 0 do
			local first = table.remove(update_queue, 1)
			game_mod.handle_updates(world, first)
		end
		processing = false
	end
end)

local ui = init_game_ui(world)
world.ui = ui

game_mod.start_animations(world)

function cleanup()
	connection:Disconnect()
	game_mod.destroy_world_instances(world)
	ui.destroy()
end
