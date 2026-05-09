local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Corner = util_components.Corner

type CubicCoordinate = types.CubicCoordinate

function CoordinateLabel(props: { coordinate: CubicCoordinate })
	return React.createElement("TextButton", {
		LayoutOrder = 1,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 20),
		Text = ("%s, %s, %s"):format(unpack(props.coordinate)),
	}, {
		Corner = React.createElement(Corner),

		SidePad = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),
	})
end

return {
	CoordinateLabel = CoordinateLabel,
}
