local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local systems_mod = require(ServerScriptService.Server.systems)

type World = types.World
type ActionState = server_types.ActionState
type System = server_types.SystemExtended

function create_systems(world: World, action_state: ActionState)
	local systems = {}
	local system_by_entity_id = {}
	local system_by_cell = {}
	for _, system_data in systems_mod.compute_systems(world) do
		local system = {
			entities = system_data.entities,
			cells = system_data.cells,
			overflow_items = {},
			power = 0,
			team = world.entities[next(system_data.entities) :: any].owner,
		} :: System

		for entity_id in system.entities do
			system_by_entity_id[entity_id] = system
		end
		for cell in system.cells do
			if system_by_cell[cell] then
				warn("another system already occupies this cell", system, system_by_cell[cell])
			end
			system_by_cell[cell] = system
		end
		table.insert(systems, system)
	end
	world.systems = systems
	action_state.systems = systems
	action_state.system_by_entity_id = system_by_entity_id
	action_state.system_by_cell = system_by_cell
end

return {
	create_systems = create_systems,
}
