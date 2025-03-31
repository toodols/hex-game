local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local themes = require(ReplicatedStorage.Client.ui.themes)
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
function SettingsMenu()
	local context = React.useContext(MainContext)
	local world = context.world
	return React.createElement(
		"Frame",
		themes.theme_background {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, -20),
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
				Debug = React.createElement(
					"TextButton",
					themes.theme_button {
						Size = UDim2.new(1, 0, 0, 40),
						Text = "Debug",
						LayoutOrder = 1,
						[React.Event.MouseButton1Click] = function()
							print(world)
						end,
					},
					{
						Corner = React.createElement(Corner),
					}
				),
			}),
		}
	)
end

return {
	SettingsMenu = SettingsMenu,
}
