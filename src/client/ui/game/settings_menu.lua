local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local themes = require(ReplicatedStorage.Client.ui.themes)
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner

function SettingsMenu()
	return React.createElement(
		"Frame",
		themes.theme_background {
			Size = UDim2.new(1, -20, 1, -20),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		},
		{
			Corner = React.createElement(Corner),
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(600, 600),
			}),
			VerticalLayout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
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
							Size = UDim2.new(0, 0, 1, 0),
							Text = "Settings",
						},
						{
							SidePad = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 10),
							}),
						}
					),
				}
			),
			Content = React.createElement("ScrollingFrame", {
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 1, -40),
				CanvasSize = UDim2.new(1, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, {
				VerticalLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Text = React.createElement(
					"TextLabel",
					themes.theme_label {
						Size = UDim2.new(1, 0, 0, 40),
						Text = "tba",
					},
					{}
				),
			}),
		}
	)
end

return {
	SettingsMenu = SettingsMenu,
}
