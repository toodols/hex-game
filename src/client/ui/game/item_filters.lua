local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local themes = require(ReplicatedStorage.Client.ui.themes)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local Corner = util_components.Corner

type EntityId = types.EntityId
type HexGrid = types.HexGrid

function ItemFilters(props: { entity_id: EntityId })
	local grid = React.useContext(MainContext).grid
	local entity = hooks.use_synced_entity(props.entity_id)
	local inventory = entity.inventory
	assert(inventory, "inventory nil")

	return React.createElement("Frame", {
		Size = UDim2.new(500, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		VerticalLayout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Header = React.createElement(
			"Frame",
			themes.theme_solid {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 40),
			},
			{
				Title = React.createElement(
					"TextLabel",
					themes.theme_title {
						Size = UDim2.new(0, 0, 1, 0),
						Text = "Item Filters",
					},
					{
						SidePad = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 10),
						}),
					}
				),
			}
		),
		Content = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, {
			GridLayout = React.createElement("UIGridLayout", {
				CellPadding = UDim2.new(0, 10, 0, 10),
				CellSize = UDim2.new(0, 100, 0, 40),
			}),
		}),
	})
end

function ItemFiltersPreview(props: { LayoutOrder: number?, entity_id: EntityId, open: () -> () })
	local grid = React.useContext(MainContext).grid
	local entity = hooks.use_synced_entity(props.entity_id)
	local inventory = entity.inventory
	assert(inventory, "inventory nil")
	local is_owner = entity.owner == grid:get_player_team(Players.LocalPlayer).id

	return React.createElement("TextButton", {
		BackgroundTransparency = 0.9,
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		Size = UDim2.new(0, 0, 0, 25),
		LayoutOrder = props.LayoutOrder,
	}, {
		Corner = React.createElement(Corner),
		SidePad = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),
		Stroke = if is_owner
			then React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = 1,
				Transparency = 0.7,
			})
			else nil,
		HorizontalLayout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		}),
		Text = React.createElement(
			"TextLabel",
			themes.theme_description {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, 1, 0),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = "Edit Filter",
			}
		),
	})
end

return {
	ItemFilters = ItemFilters,
	ItemFiltersPreview = ItemFiltersPreview,
}
