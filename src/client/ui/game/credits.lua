local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner

function Credits()
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, -20),
		[React.Tag] = "align-cc",
	}, {
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
			[React.Tag] = "pad-l-10",
			Text = table.concat({
				"My beloved modeler",
				"♥♥♥ Leo",
				"My beloved playtesters",
				"♥ no1",
				"♥ Blue",
				"♥ Bacon",
				"♥ Roid",
				"♥ quin",
			}, "\n"),
		}),
	})
end

return {
	Credits = Credits,
}
