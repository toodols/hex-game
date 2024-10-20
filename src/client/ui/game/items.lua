local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local items_mod = require(ReplicatedStorage.Shared.items)

type Item = types.Item

-- Displays items labeled with numbers
function Items(props: { LayoutOrder: number?, items: { [Item]: number | string } })
	return React.createElement(
		"Frame",
		{
			AutomaticSize = Enum.AutomaticSize.XY,
			LayoutOrder = props.LayoutOrder,
			BackgroundTransparency = 1,
		},
		{
			VerticalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
		util.table_map(props.items, function(v, k)
			return React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, 0, 20),
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
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = items_mod.item_colors[k],
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Rotation = 45,
						Size = UDim2.new(0, 7, 0, 7),
					}),
				}),

				HorizontalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				SidePad = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
			})
		end)
	)
end

return { Items = Items }
