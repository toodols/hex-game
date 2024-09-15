local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)

function GradientStroke(props)
	return React.createElement("UIStroke", {}, {
		Gradient = React.createElement("UIGradient", {
			Transparency = props.Transparency or NumberSequence.new {},
		}),
	})
end

return {
	GradientStroke = GradientStroke,
}
