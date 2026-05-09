local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner

function Encyclopedia()
	local context = React.useContext(MainContext)
	local world = context.world
	return React.createElement("Frame", {
		Size = UDim2.new(1, -20, 1, -20),
		[React.Tag] = "align-cc background",
	}, {
		SizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(600, 600),
		}),
		VerticalLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = React.createElement("Frame", {
			LayoutOrder = 1,
			[React.Tag] = "header",
		}, {
			Title = React.createElement("TextLabel", {
				Text = "Encyclopedia",
				[React.Tag] = "title",
			}),
		}),
		Content = React.createElement("ScrollingFrame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 1, -40),
			CanvasSize = UDim2.new(1, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			[React.Tag] = "list-v list-pad-5",
		}, {
			Text = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				TextSize = 30,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				FontFace = Font.new(
					"rbxasset://fonts/families/Michroma.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.new(1, 0, 1, 0),
				Text = "I might add stuff later",
			}, {
				SidePad = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
				}),
			}),
		}),
	})
end

return {
	Encyclopedia = Encyclopedia,
}
