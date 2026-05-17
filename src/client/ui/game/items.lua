local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local items_mod = require(ReplicatedStorage.Shared.items)

type Item = types.Item

-- Displays items labeled with numbers
function Items(props: { LayoutOrder: number?, items: { [Item]: number | string } })
	return React.createElement(
		"ScrollingFrame",
		{
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = props.LayoutOrder,
			BackgroundTransparency = 1,
			[React.Tag] = "scroll-h list-h list-pad-5 list-cl",
		},
		util.table_map(props.items, function(v, k)
			return React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, 0, 20),
				[React.Tag] = "list-h list-pad-5 list-cl pad-h-5",
			}, {
				TextLabel = React.createElement("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
					Size = UDim2.new(0, 0, 1, 0),
					Text = v,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
				}),

				Icon = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 10, 0, 10),
				}, {
					Inner = React.createElement("Frame", {
						BackgroundColor3 = items_mod.item_colors[k],
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						[React.Tag] = "align-cc",
						Rotation = 45,
						Size = UDim2.new(0, 7, 0, 7),
					}),
				}),
			})
		end)
	)
end

return { Items = Items }
