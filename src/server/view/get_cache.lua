local ServerScriptService = game:GetService "ServerScriptService"
local server_types = require(ServerScriptService.Server.types)

type ViewTarget = server_types.ViewTarget
type ViewContext = server_types.ViewContext
type ViewCache = server_types.ViewCache

local nil_key = "nil"
function get_cache(context: ViewContext, serialize_target: ViewTarget): ViewCache
	local team = serialize_target.team or nil_key
	local player = serialize_target.player or nil_key
	if context[team] == nil then
		context[team] = {}
	end
	if context[team][player] == nil then
		context[team][player] = {
			entities = {},
		}
	end
	return context[team][player]
end

return {
	get_cache = get_cache,
}
