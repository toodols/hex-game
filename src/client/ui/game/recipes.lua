local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local items_mod = require(ReplicatedStorage.Shared.items)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local Cost = require(script.Parent.cost).Cost
local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type Item = types.Item
type Entity = types.Entity
type Recipe = types.Recipe
type HexGrid = types.HexGrid
type EntityId = types.EntityId

function RecipeItem(props: {
	recipe: Recipe,
	on_click: () -> (),
	current_recipe: string,
	recipe_id: string,
})
	return React.createElement("TextButton", {
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		BackgroundTransparency = if props.current_recipe == props.recipe_id then 0.6 else 0.8,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		[React.Event.MouseButton1Click] = function()
			props.on_click()
		end,
	}, {
		HorizontalLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		UIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
		}),

		Input = React.createElement(Cost, {
			cost = props.recipe.input_items,
			LayoutOrder = 1,
		}),

		ImageLabel = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=6022668890",
			LayoutOrder = 2,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.new(0, 30, 1, 0),
		}),

		Output = React.createElement(Cost, {
			cost = items_mod.into_counted_items(props.recipe.output_items),
			LayoutOrder = 3,
		}),

		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	})
end

function Recipes(props: { entity_id: EntityId, on_close: () -> () })
	local entity = hooks.use_synced_entity(props.entity_id)
	local grid = React.useContext(MainContext).grid
	local config = grid.entity_configurations["factory"]
	return React.createElement("Frame", {
		Active = true,
		AnchorPoint = Vector2.new(0, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		LayoutOrder = 1,
		Position = UDim2.new(-250, 250, 20, -20),
		Size = UDim2.fromOffset(200, 0),
		Transparency = 1,
	}, {
		Header = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 40),
		}, {
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),

			Title = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Oswald.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.new(0, 0, 1, 0),
				Text = "Recipes",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				SidePad = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 15),
					PaddingRight = UDim.new(0, 15),
				}),
			}),
		}),

		Container = React.createElement(
			"Frame",
			{
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Position = UDim2.new(0, 0, 0.12, 0),
				Size = UDim2.new(1, 0, 0, 0),
			},
			{
				UIPadding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 2),
				}),

				VerticalLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
			util.table_map(config.recipes, function(v, k)
				return React.createElement(RecipeItem, {
					on_click = function()
						client_interaction_remote:FireServer {
							{
								type = "set_recipe",
								recipe_id = k,
								entity_id = props.entity_id,
							},
						}
						-- props.on_close()
					end,
					current_recipe = entity.current_recipe,
					recipe = v,
					recipe_id = k,
				})
			end)
		),

		VerticalLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

return {
	Recipes = Recipes,
}
