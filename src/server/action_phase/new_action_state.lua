local ServerScriptService = game:GetService "ServerScriptService"
local server_types = require(ServerScriptService.Server.types)
type ActionState = server_types.ActionState

function new_action_state(): ActionState
	return {
		systems = {},
		system_by_entity_id = {},
		system_by_cell = {},
		will_be_destroyed_entities = {},
	}
end

return {
	new_action_state = new_action_state,
}
