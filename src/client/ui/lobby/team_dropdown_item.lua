local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local themes = require(ReplicatedStorage.Client.ui.themes)

function TeamDropdownItem(props: {
	icon_color: Color3,
	text: string,
})
	return React.createElement(React.Fragment, {}, {
		Icon = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=6022852108",
			ImageColor3 = props.icon_color,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 30, 0, 30),
		}),
		Label = React.createElement(
			"TextLabel",
			themes.theme_label {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				LayoutOrder = 2,
				Size = UDim2.new(0, 0, 1, 0),
				Text = props.text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
			} {
				LeftPadding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
				}),
			}
		),
		HorizontalLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
end

return {
	TeamDropdownItem = TeamDropdownItem,
}
