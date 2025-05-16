local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type World = types.World
type HexCell = types.HexCell
type TeamId = types.TeamId
type ResearchItem = types.ResearchItem
type ResearchId = types.ResearchId
type EntityId = types.EntityId
type ResearchState = types.ResearchState

-- All researches
local researches = {
	--[[
	Example:
	["turret"] = {
		icon = { type = "model", model = "Entities/Turret" },
		name = "Dagger",
		description = "Allows construction of {entity.turret}",
		cost = { bar = 4 },
		time = 1,
	},
	]]
	proxy = {
		icon = {
			type = "model",
			model = "Entities/Proxy",
		},
		name = "Proxy",
		description = "Allows construction of {entity.proxy}",
		cost = {
			tek = 2,
			vit = 1,
		},
		time = 2,
	},
	heart = {
		icon = {
			type = "model",
			model = "Entities/Heart",
		},
		name = "Monarch",
		description = "Allows construction of {entity.heart}",
		cost = {
			tek = 4,
			tar = 1,
		},
		time = 3,
	},
	vault = {
		icon = {
			type = "model",
			model = "Entities/Vault",
		},
		name = "Vault",
		description = "Allows construction of {entity.vault}",
		cost = {
			tek = 2,
			bar = 2,
		},
		time = 2,
	},
	taunt = {
		icon = {
			type = "model",
			model = "Entities/Taunt",
		},
		name = "Taunt",
		description = "Allows construction of {entity.taunt}",
		cost = {
			tek = 1,
			pow = 1,
		},
		time = 1,
	},
	create_rad = {
		icon = {
			type = "model",
			model = "Items/Rad",
		},
		name = "Inspiration",
		description = "{entity.heart} begins producing 1 {item.rad} every 2 turns.",
		cost = {
			bar = 5,
		},
		time = 2,
	},
	fountain = {
		icon = {
			type = "model",
			model = "Entities/Fountain",
		},
		name = "Fountain",
		description = "Allows construction of {entity.fountain}",
		cost = {
			bar = 2,
			tek = 2,
		},
		time = 2,
	},
}

--- Gets all researches on any of the cells for a team
function get_cells_researches(world: World, cells: { HexCell }, team: TeamId): { [ResearchId]: boolean }
	local researches_set: { [ResearchId]: boolean } = {}

	local influences: { [EntityId]: true } = {}
	for _, cell in cells do
		for entity_id in cell.influences do
			influences[entity_id] = true
		end
	end

	for entity_id in influences do
		local entity = world.entities[entity_id]
		if not entity then
			continue
		end
		if entity.researches ~= nil then
			for research_id, state: ResearchItem in entity.researches.states do
				if state.status == "complete" then
					researches_set[research_id] = true
				end
			end
		end
	end
	return researches_set
end

function research_item(props): ResearchItem
	local preset = researches[props.id] or {}
	return {
		precondition = props.precondition or function()
			return true
		end,
		coord = props.coord,
		status = props.status or "incomplete",
		icon = preset.icon,
		id = props.id,
		progress = 0,
		name = preset.name or "",
		description = preset.description or "",
		time = preset.time or 0,
		cost = preset.cost or {},
		cost_is_paid = false,
	} :: ResearchItem
end

return {
	get_cells_researches = get_cells_researches,
	research_item = research_item,
	researches = researches,
}
