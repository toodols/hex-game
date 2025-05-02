local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type World = types.World
type HexCell = types.HexCell
type TeamId = types.TeamId
type ResearchState = types.ResearchState
type ResearchId = types.ResearchId
type EntityId = types.EntityId

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
		if entity.type == "laboratory" then
			for research_id, state: ResearchState in entity.researches.states do
				if state.status == "complete" then
					researches_set[research_id] = true
				end
			end
		end
	end
	return researches_set
end

function research_state(props): ResearchState
	return {
		precondition = props.precondition or function()
			return true
		end,
		coord = props.coord,
		status = props.status or "incomplete",
		icon = props.icon,
		id = props.id,
		progress = 0,
		name = props.name or "",
		description = props.description or "",
		time = props.time or 0,
		cost = props.cost or {},
	} :: ResearchState
end

function create_researches(): { [ResearchId]: ResearchState }
	return {
		turret = research_state {
			coord = { -1, 0, 1 },
			id = "turret",
			name = "Dagger",
			description = "Allows construction of {entity.turret}",
			icon = {
				type = "model",
				model = "Entities/Turret",
			},
			cost = {
				bar = 4,
			},
			time = 1,
		},
		proxy = research_state {
			coord = { -1, 1, 0 },
			id = "proxy",
			name = "Proxy",
			description = "Allows construction of {entity.proxy}",

			icon = {
				type = "model",
				model = "Entities/Proxy",
			},
			cost = {
				tek = 4,
			},
			time = 2,
		},
		-- extractor_boost = research_state {
		-- 	coord = { 1, 0, -1 },
		-- 	id = "extractor_boost",
		-- 	name = "Boosted Spout",
		-- 	icon = {
		-- 		type = "model",
		-- 		model = "Entities/Extractor",
		-- 	},
		-- 	description = "{entity.extractor} create up to +1 items when adjacent to a {entity.generator}.",
		-- 	cost = {
		-- 		tek = 6,
		-- 	},
		-- 	time = 2,
		-- 	-- precondition = function(_world, ent)
		-- 	-- 	return ent.researches.states.turret.status ~= "complete"
		-- 	-- end,
		-- },
		heart = research_state {
			coord = { 0, -1, 1 },
			id = "heart",
			name = "Monarch",
			icon = {
				type = "model",
				model = "Entities/Heart",
			},
			description = "Allows construction of {entity.heart}",
			cost = {
				tek = 10,
			},
			time = 3,
		},
		vault = research_state {
			coord = { 1, -1, 0 },
			id = "vault",
			name = "Vault",
			icon = {
				type = "model",
				model = "Entities/Vault",
			},
			description = "Allows construction of {entity.vault}",
			cost = {
				tek = 3,
			},
			time = 2,
		},
		taunt = research_state {
			coord = { 0, 1, -1 },
			id = "taunt",
			name = "Taunt",
			icon = {
				type = "model",
				model = "Entities/Taunt",
			},
			description = "Allows construction of {entity.taunt}",
			cost = {
				tek = 3,
			},
			time = 2,
		},
	}
end
local researches = create_researches()

return {
	get_cells_researches = get_cells_researches,
	researches = researches,
	create_researches = create_researches,
}
