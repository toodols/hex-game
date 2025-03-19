local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local themes = require(ReplicatedStorage.Client.ui.themes)
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner
local world_mod = require(ReplicatedStorage.Shared.world)

type CubicCoordinate = types.CubicCoordinate
type World = types.World

local function clear_show_cells(context)
	util.table_extract(context.selection_mode_stack, function(selection_mode)
		return selection_mode.type == "show_cells"
	end)
end

function into_instance_set(world: World, coords: { CubicCoordinate })
	local set = {}
	for _, coord in coords do
		local instance = world.cell_instance_map[coords.encode_coord(coord)]
		if not instance then
			continue
		end
		set[instance] = true
	end
	return set
end

function HighlightOnHover(props: { Text: string, coords: { CubicCoordinate }, LayoutOrder: number? })
	local context = React.useContext(MainContext)
	return React.createElement(
		"TextButton",
		themes.theme_button {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.2,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 25),
			LayoutOrder = props.LayoutOrder,
			TextSize = 14,
			Text = props.Text,
			[React.Event.MouseEnter] = function()
				clear_show_cells(context)
				table.insert(context.selection_mode_stack, {
					type = "show_cells",
					cells = into_instance_set(context.world, props.coords),
				})
			end,
			[React.Event.MouseLeave] = function()
				clear_show_cells(context)
			end,
		},
		{
			Corner = React.createElement(Corner),
			SidePad = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
			}),
		}
	)
end

return {
	HighlightOnHover = HighlightOnHover,
}
