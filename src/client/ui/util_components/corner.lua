local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)

function Corner()
	return React.createElement("UICorner", {
		CornerRadius = UDim.new(0, 4),
	})
end

return {
	Corner = Corner,
}
