local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)

-- test component; bored
function Border(props: {
	thickness: number,
	margin: number,
	color: Color3,
})
	return React.createElement(React.Fragment, {}, {
		Left = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, props.margin, 0.5, 0),
			Size = UDim2.new(0, props.thickness, 1, -props.margin * 2),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
		}),
		Right = React.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -props.margin, 0.5, 0),
			Size = UDim2.new(0, props.thickness, 1, -props.margin * 2),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
		}),
		Top = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, props.margin),
			Size = UDim2.new(1, -props.margin * 2, 0, props.thickness),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
		}),
		Bottom = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -props.margin),
			Size = UDim2.new(1, -props.margin * 2, 0, props.thickness),
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,
		}),
	})
end

return {
	Border = Border,
}
