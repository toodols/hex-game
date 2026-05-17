local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)

function TeamDropdownItem(props: {
	icon_color: Color3,
	text: string,
})
	return React.createElement(React.Fragment, {}, {
		Icon = React.createElement("ImageLabel", {
			Image = "http://www.roblox.com/asset/?id=6022852108",
			ImageColor3 = props.icon_color,
			[React.Tag] = "align-cc list-h list-pad-10 list-cl",
			Size = UDim2.new(0, 30, 0, 30),
		}),
		Label = React.createElement("TextLabel", {
			[React.Tag] = "pad-l-5",
			LayoutOrder = 2,
			Text = props.text,
		}),
	})
end

return {
	TeamDropdownItem = TeamDropdownItem,
}
