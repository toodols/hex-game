local ServerScriptService = game:GetService "ServerScriptService"
local server_types = require(ServerScriptService.Server.types)

type SerializeTarget = server_types.SerializeTarget
type SerializationContext = server_types.SerializationContext
type SerializingCache = server_types.SerializingCache

local nil_key = "nil"
function get_cache(context: SerializationContext, serialize_target: SerializeTarget): SerializingCache
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
