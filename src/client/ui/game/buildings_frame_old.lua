local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Corner = util_components.Corner
local ActionButton = require(script.Parent.action_button).ActionButton

type CubicCoordinate = types.CubicCoordinate

local decision_remote = ReplicatedStorage:FindFirstChild "DecisionRemote" :: RemoteEvent

function BuildingItem(props: { type: string, selected_cells: { CubicCoordinate } })
	local shared_behavior = shared_entity_mod.registry[props.type]
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(100, 100),
	}, {
		Body = React.createElement(
			"Frame",
			themes.theme_solid {
				ClipsDescendants = true,
				Size = UDim2.new(1, 0, 1, 0),
			},
			{
				Padding = React.createElement("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0, 5),
				}),
				Corner = React.createElement(Corner),

				ItemTitle = React.createElement(
					"TextLabel",
					themes.theme_title {
						Size = UDim2.new(1, 0, 0, 20),
						Text = shared_behavior.name,
						LayoutOrder = 1,
					},
					{
						-- SidePad = React.createElement("UIPadding", {
						-- 	PaddingLeft = UDim.new(0, 15),
						-- 	PaddingRight = UDim.new(0, 15),
						-- }),
					}
				),

				VerticalLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Description = React.createElement(
					"TextLabel",
					themes.theme_description {
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 2,
						Text = shared_behavior.description,
					}
				),

				ConstructButton = React.createElement(ActionButton, {
					color = Color3.fromRGB(255, 255, 255),
					Text = "Construct",
					LayoutOrder = 3,
					on_click = function()
						decision_remote:FireServer {
							{
								type = "construct",
								entity_type = props.type,
								coordinate = props.selected_cells[1],
							},
						}
					end,
				}),
			}
		),
	})
end

function BuildingsFrame(props: { Visible: boolean, selected_cells: CubicCoordinate })
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Position = UDim2.new(-250, 250, 20, -20),
		Visible = props.Visible,
		Active = true,
	}, {
		Container = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Position = UDim2.new(0, 0, 0.12, 0),
		}, {
			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			ItemsScrollingFrame = React.createElement(
				"ScrollingFrame",
				themes.theme_background {
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
					ScrollBarThickness = 4,
					Size = UDim2.fromOffset(700, 350),
				},
				{
					Corner = React.createElement(Corner),

					GridLayout = React.createElement("UIGridLayout", {
						CellPadding = UDim2.fromOffset(7, 7),
						CellSize = UDim2.fromOffset(150, 200),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Padding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0, 2),
						PaddingLeft = UDim.new(0, 2),
						PaddingRight = UDim.new(0, 2),
						PaddingTop = UDim.new(0, 5),
					}),
				},
				util.table_map(
					{ "wires", "stockpile", "extractor", "scout", "factory", "generator", "laboratory", "turret" },
					function(entity_type)
						return React.createElement(BuildingItem, {
							type = entity_type,
							selected_cells = props.selected_cells,
						})
					end
				)
			),
		}),

		Header = React.createElement(
			"Frame",
			themes.theme_solid {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 40),
			},
			{

				Corner = React.createElement(Corner),

				Title = React.createElement(
					"TextLabel",
					themes.theme_title {
						Text = "Build",
						Size = UDim2.new(0, 0, 1, 0),
					},
					{
						SidePad = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 15),
							PaddingRight = UDim.new(0, 15),
						}),
					}
				),

				VerticalLayout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}
		),

		VerticalLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

return {
	BuildingsFrame = BuildingsFrame,
}
