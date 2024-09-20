local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local presets = require(ServerScriptService.Server.presets)
local client_game_mod = require(ReplicatedStorage.Client.game)
local game_ui = require(ReplicatedStorage.Client.ui.game)
local tests = {}

function tests.render_grid()
	local grid = presets.my_map()
	client_game_mod.render_grid(grid)
	client_game_mod.destroy_grid_instances(grid)
end

function tests.render_ui()
	local grid = presets.my_map()
	local ui = game_ui.init_ui(grid, Instance.new "Folder")
	ui.destroy()
end

return tests
