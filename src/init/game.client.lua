-- game.client.lua

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local get_hex_grid_data_remote = ReplicatedStorage:FindFirstChild "GetHexGridDataRemote" :: RemoteFunction
local grid_updates_remote = ReplicatedStorage:FindFirstChild "GridUpdatesRemote" :: RemoteEvent
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local game_mod = require(ReplicatedStorage.Client.game)
local init_game_ui = require(ReplicatedStorage.Client.ui.game).init_ui
local types = require(ReplicatedStorage.Shared.types)
type HexGrid = types.HexGrid
type GridUpdate = types.GridUpdate

local grid_data = get_hex_grid_data_remote:InvokeServer()
local grid = hex_grid_mod.new_grid_from_data(grid_data)

print(grid_data)
game_mod.render_grid(grid)

local connection = grid_updates_remote.OnClientEvent:Connect(function(updates: { GridUpdate })
	game_mod.handle_updates(grid, updates)
end)

local ui = init_game_ui(grid)

game_mod.start_animations(grid)

function cleanup()
	connection:Disconnect()
	game_mod.destroy_grid_instances(grid)
	ui.destroy()
end
