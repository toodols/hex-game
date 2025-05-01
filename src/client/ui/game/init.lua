local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ContextActionService = game:GetService "ContextActionService"

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])
local types = require(ReplicatedStorage.Shared.types)
local selection_manager_mod = require(script.selection_manager)

local Main = require(script.main).Main

type World = types.World

function init_ui(world: World, root_instance_: ScreenGui?)
	local root_instance = root_instance_
	if root_instance == nil then
		root_instance = Instance.new "ScreenGui"
		root_instance.Name = "MainGui"
		root_instance.ResetOnSpawn = false
		root_instance.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		root_instance.IgnoreGuiInset = true
		root_instance.Parent = Players.LocalPlayer:WaitForChild "PlayerGui"
	end
	local root = ReactRoblox.createRoot(root_instance)
	local selection_manager = selection_manager_mod.new_selection_manager(world)

	local render_stepped_connection
	local update = function()
		root:render(React.createElement(Main, {
			world = world,
			selection_mode_stack = selection_manager.selection_mode_stack,
		}))
	end

	if RunService:IsClient() then
		render_stepped_connection = selection_manager_mod.render_stepped(world, selection_manager, update)
		selection_manager_mod.bind_select_cell(world, selection_manager, update)
	end

	update()

	return {
		root = root,
		update = update,
		selection_mode_stack = selection_manager.selection_mode_stack,
		destroy = function()
			if RunService:IsClient() then
				render_stepped_connection:Disconnect()
				ContextActionService:UnbindAction "select_cell"
				root:unmount()
			end
		end,
	}
end

return {
	init_ui = init_ui,
}
