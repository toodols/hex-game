local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local themes = require(ReplicatedStorage.Client.ui.themes)

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local researches_mod = require(ReplicatedStorage.Shared.researches)

type EntityId = types.EntityId
type World = types.World

function RequiredResearch(props: {
	entity_id: EntityId,
	LayoutOrder: number?,
})
	local context = React.useContext(MainContext)
	local world: World = context.world
	local entity = hooks.use_synced_entity(props.entity_id)
	local entity_config = world.entity_configurations[entity.type]

	if entity_config.required_research == nil or #entity_config.required_research == 0 then
		return nil
	end

	local cells = util.table_map(entity.coordinates, function(coord)
		return world:get_cell(coord)
	end)
	local researches = researches_mod.get_cells_researches(world, cells, entity.owner)
	local required_list = {}
	for _, research_id in entity_config.required_research do
		if not researches[research_id] then
			table.insert(required_list, research_id)
		end
	end

	if #required_list == 0 then
		return nil
	end

	return React.createElement(
		"TextLabel",
		themes.theme_description {
			Text = `Required research: {table.concat(
				util.table_map(required_list, function(id)
					return researches_mod.researches[id].name
				end),
				", "
			)}`,
			TextColor3 = Color3.fromRGB(255, 0, 0),
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = props.LayoutOrder,
			AutomaticSize = Enum.AutomaticSize.Y,
		}
	)
end

return {
	RequiredResearch = RequiredResearch,
}