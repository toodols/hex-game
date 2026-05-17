-- fail fast on simple mistakes made during development

local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local server_entity_mod = require(ServerScriptService.Server.entity)
local client_entity_mod = require(ReplicatedStorage.Client.entity)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

local tests = {}

function tests.all_entities_are_registered()
	for entity_type in shared_entity_mod.registry do
		if not client_entity_mod.registry[entity_type] then
			error(("Missing client entity for %s"):format(entity_type))
		end
		if not server_entity_mod.registry[entity_type] then
			error(("Missing server entity for %s"):format(entity_type))
		end
	end
	for entity_type in client_entity_mod.registry do
		if not shared_entity_mod.registry[entity_type] then
			error(("Missing shared entity for %s"):format(entity_type))
		end
		if not server_entity_mod.registry[entity_type] then
			error(("Missing server entity for %s"):format(entity_type))
		end
	end
	for entity_type in server_entity_mod.registry do
		if not shared_entity_mod.registry[entity_type] then
			error(("Missing shared entity for %s"):format(entity_type))
		end
		if not client_entity_mod.registry[entity_type] then
			error(("Missing client entity for %s"):format(entity_type))
		end
	end
end

return tests
