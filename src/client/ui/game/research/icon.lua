local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local types = require(ReplicatedStorage.Shared.types)
type Icon = types.Icon

function Icon(props: {
	ZIndex: number?,
	LayoutOrder: number?,
	Size: UDim2?,
	icon: Icon,
})
	local ref = React.useRef(nil :: any)
	local icon = props.icon
	local ZIndex = props.ZIndex
	local Size = props.Size or UDim2.new(1, 0, 1, 0)
	React.useEffect(function()
		if icon and icon.type == "model" then
			ref.current:ClearAllChildren()
			local template = asset_server.load(icon.model)
			local model = template:Clone()
			model.Parent = ref.current
			model:PivotTo(CFrame.new(0, -1, -4))
		end
	end, { icon })

	if not icon then
		return React.createElement(React.Fragment)
	end

	if icon.type == "model" then
		return React.createElement("ViewportFrame", {
			Size = Size,
			ref = ref,
			ZIndex = ZIndex,
			LayoutOrder = props.LayoutOrder,
			[React.Tag] = "align-cc",
		})
	elseif icon.type == "image" then
		return React.createElement("ImageLabel", {
			Size = Size,
			Image = icon.image,
			ZIndex = ZIndex,
			LayoutOrder = props.LayoutOrder,
			[React.Tag] = "align-cc",
		})
	else
		return React.createElement(React.Fragment)
	end
end

return {
	Icon = Icon,
}
