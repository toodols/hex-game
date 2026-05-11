local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local Corner = require(script.Parent.corner).Corner
local util = require(ReplicatedStorage.Shared.util)

type DropdownProps = {
	LayoutOrder: number?,
	AnchorPoint: Vector2?,
	Size: UDim2?,
	Position: UDim2?,
	current: string,
	options: { [string]: any },
	on_change: (string) -> (),
}
function Dropdown(props: DropdownProps)
	local open, set_open = React.useState(false)

	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		Position = props.Position,
		Size = props.Size or UDim2.new(0, 150, 0, 25),
	}, {

		Item = if #util.table_keys(props.options) > 1
			then React.createElement("TextButton", {
				[React.Tag] = "solid pad-l-5 stroke",
				Size = UDim2.new(1, 0, 0, 25),
				Text = "",
				[React.Event.MouseButton1Click] = function()
					set_open(not open)
				end,
			}, {
				Current = React.createElement("Frame", {
					[React.Tag] = "container",
				}, { props.options[props.current] }),
				DropdownIcon = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=6034818372",
					LayoutOrder = 3,
					[React.Tag] = "align-cr",
					Size = UDim2.new(0, 30, 0, 30),
				}),
			})
			else React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 25),
			}, {
				Current = props.options[props.current],
			}),
		List = if #util.table_keys(props.options) > 1
			then React.createElement(
				"Frame",
				{
					[React.Tag] = "solid container-v list-v list-pad-2 stroke",
					Visible = open,
					Position = UDim2.new(0, 0, 1, 5),
				},
				util.table_map(props.options, function(v, k)
					return React.createElement("TextButton", {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = "",
						BackgroundColor3 = Color3.fromRGB(50, 50, 50),

						[React.Event.MouseButton1Click] = function()
							set_open(false)
							if props.on_change then
								props.on_change(k)
							end
						end,
					}, {
						PaddingLeft = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 5),
						}),
					}, {
						v,
					})
				end)
			)
			else nil,
	})
end

return {
	Dropdown = Dropdown,
}
