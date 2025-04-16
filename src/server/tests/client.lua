local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local client_game_mod = require(ReplicatedStorage.Client.game)
local game_ui = require(ReplicatedStorage.Client.ui.game)
local presets = require(ServerScriptService.Server.presets)
local cleanup = require(ServerScriptService.Server.cleanup).cleanup

local tests = {}

function tests.render_world()
	local world = presets.my_map()
	client_game_mod.render_world(world)
	client_game_mod.step_animations(world)
	client_game_mod.destroy_world_instances(world)
	cleanup(world)
end

function tests.render_ui()
	local world = presets.my_map()
	local ui = game_ui.init_ui(world, Instance.new "Folder")

	ui.destroy()
	cleanup(world)
end

return tests
