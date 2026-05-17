local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local items_mod = require(ReplicatedStorage.Shared.items)

local hooks = require(ReplicatedStorage.Client.ui.hooks)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local Items = require(script.Parent.items).Items

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type Item = types.Item
type Entity = types.Entity
type Recipe = types.Recipe
type World = types.World
type EntityId = types.EntityId

function RecipeItem(props: {
	recipe: Recipe,
	on_click: () -> (),
	current_recipe: string,
	recipe_id: string,
})
	return React.createElement("TextButton", {
		BackgroundTransparency = if props.current_recipe == props.recipe_id then 0.6 else 0.8,
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		[React.Event.MouseButton1Click] = function()
			props.on_click()
		end,
		[React.Tag] = "solid list-h list-pad-5 list-cc pad-l-5",
	}, {
		Input = React.createElement(Items, {
			items = props.recipe.input_items,
			LayoutOrder = 1,
		}),

		ImageLabel = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=6022668890",
			LayoutOrder = 2,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.new(0, 30, 1, 0),
		}),

		Output = React.createElement(Items, {
			items = items_mod.into_counted_items(props.recipe.output_items),
			LayoutOrder = 3,
		}),
	})
end

function Recipes(props: { entity_id: EntityId, on_close: () -> () })
	local entity = hooks.use_synced_entity(props.entity_id)
	local world = React.useContext(MainContext).world
	local config = world.entity_configurations["factory"]
	return React.createElement("Frame", {
		Active = true,
		[React.Tag] = "container-v align-br recipes list-v list-pad-2",
		LayoutOrder = 1,
		Position = UDim2.new(-250, 250, 20, -20),
		Size = UDim2.new(0, 250, 0, 0),
	}, {
		Header = React.createElement("Frame", {
			LayoutOrder = 1,
			[React.Tag] = "header list-v",
		}, {
			Title = React.createElement("TextLabel", {
				Text = "Recipes",
				[React.Tag] = "title",
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
				[React.Tag] = "pad-t-2 list-v list-pad-2",
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
	})
end

return {
	Recipes = Recipes,
}
