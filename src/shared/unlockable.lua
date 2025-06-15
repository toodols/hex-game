local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ReplicatedStorage.Shared.entity)

type PlayerData = types.PlayerData
type Unlockable = types.Unlockable

function player_has_unlockable(player_data: PlayerData, requirement: { Unlockable })
	if requirement == nil then
		warn "requirement is nil"
		return true
	end
	for _, unlockable in requirement do
		if not player_data.unlockables_owned[unlockable] then
			return false
		end
	end
	return true
end

-- defines available unlockables based on dependents
local unlockables: { [Unlockable]: { weight: number, dependencies: { Unlockable } } } = {
	anima = {
		weight = 1,
		dependencies = {},
	},
	vault = {
		weight = 1,
		dependencies = {},
	},
}

local computed_unlockables = nil
--- gets all unlockables that are used, including unobtainable ones
function get_unlockables(): { Unlockable }
	if computed_unlockables == nil then
		computed_unlockables = {}
		for _, entity_configuration in entity_mod.registry do
			for _, unlockable in entity_configuration.required_unlockable do
				if table.find(computed_unlockables, unlockable) == nil then
					table.insert(computed_unlockables, unlockable)
				end
			end
		end
	end
	return computed_unlockables
end

return {
	player_has_unlockable = player_has_unlockable,
	get_unlockables = get_unlockables,
	unlockables = unlockables,
}
