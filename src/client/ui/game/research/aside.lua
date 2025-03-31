local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local formatting = require(ReplicatedStorage.Shared.formatting)

local themes = require(ReplicatedStorage.Client.ui.themes)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Items = require(ReplicatedStorage.Client.ui.game.items).Items
local ActionButton = require(ReplicatedStorage.Client.ui.game.action_button).ActionButton
local Corner = util_components.Corner

type ResearchState = types.ResearchState

function Aside(props: { state: ResearchState, on_add: () -> (), on_remove: () -> () })
	local world = React.useContext(MainContext).world
	return React.createElement(
		"Frame",
		themes.theme_solid {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, 200, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
			ClipsDescendants = true,
		},
		{
			Corner = React.createElement(Corner),
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Stroke = React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = 1,
				Transparency = 0.9,
			}),
			Container = React.createElement(
				"Frame",
				{
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				},
				{
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingBottom = UDim.new(0, 10),
					}),
					VerticalLayout = React.createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
					}),
					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Text = props.state.name,
							TextXAlignment = Enum.TextXAlignment.Center,
							Size = UDim2.new(1, 0, 0, 30),
							LayoutOrder = 1,
						}
					),
					Description = React.createElement(
						"TextLabel",
						themes.theme_description {
							Text = formatting.format_text(world, props.state.description),
							Size = UDim2.new(1, 0, 0, 40),
							LayoutOrder = 2,
						}
					),
				},
				if props.state.status ~= "complete"
					then {
						Items = React.createElement(Items, {
							items = props.state.cost,
							LayoutOrder = 3,
						}),
					}
					else {},
				if props.state.status == "complete" or props.state.status == "researching"
					then {
						CompletedLabel = React.createElement(
							"TextLabel",
							themes.theme_description {
								Text = if props.state.status == "complete" then "Complete" else "Researching",
								Size = UDim2.new(1, 0, 0, 40),
								LayoutOrder = 4,
							}
						),
					}
					else {}
			),
		},
		if props.state.status == "incomplete"
			then {
				AddButton = React.createElement(ActionButton, {
					Size = UDim2.new(1, 0, 0, 20),
					Text = "Add Research",
					LayoutOrder = 3,
					color = Color3.fromRGB(200, 200, 200),
					on_click = function()
						props.on_add()
					end,
				}),
			}
			else {}
	)
end

return {
	Aside = Aside,
}
