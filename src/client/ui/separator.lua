local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)

function Separator(props: { Position: UDim2?, LayoutOrder: number? })
	return React.createElement(
		"Frame",
		{
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder or 0,
		},
		React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.8, 0, 0, 1),
			BackgroundTransparency = 0.7,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
		})
	)
end

return {
	Separator = Separator,
}
