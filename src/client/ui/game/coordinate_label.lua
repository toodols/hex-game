local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local util_components = require(ReplicatedStorage.Client.ui.util_components)

type CubicCoordinate = types.CubicCoordinate

function CoordinateLabel(props: { coordinate: CubicCoordinate })
	return React.createElement("TextButton", {
		LayoutOrder = 1,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 20),
		Text = ("%s, %s, %s"):format(unpack(props.coordinate)),
		[React.Tag] = "background pad-h-5",
	})
end

return {
	CoordinateLabel = CoordinateLabel,
}
