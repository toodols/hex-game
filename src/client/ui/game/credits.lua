local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local themes = require(ReplicatedStorage.Client.ui.themes)
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner

function Credits()
	local context = React.useContext(MainContext)
	local world = context.world
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, -20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}, {
		Corner = React.createElement(Corner),
		SizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(400, 200),
		}),
		VerticalLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Text = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			TextSize = 30,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			FontFace = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Size = UDim2.new(1, 0, 1, 0),
			Text = table.concat({
				"♥♥♥ Leo",
				"♥ Blue",
				"♥ Bacon",
				"♥ Roid",
			}, "\n"),
		}, {
			SidePad = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
			}),
		}),
	})
end

return {
	Credits = Credits,
}
