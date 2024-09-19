local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local util = require(ReplicatedStorage.Shared.util)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local formatting = require(ReplicatedStorage.Shared.formatting)
local items_mod = require(ReplicatedStorage.Shared.items)

local hooks = require(ReplicatedStorage.Client.ui.hooks)
local client_entity_mod = require(ReplicatedStorage.Client.ui.Parent.entity)
local context_mod = require(ReplicatedStorage.Client.ui.context)
local themes = require(ReplicatedStorage.Client.ui.themes)
local ActionButton = require(script.Parent.action_button).ActionButton
local Cost = require(script.Parent.cost).Cost
local MainContext = context_mod.MainContext
local decision_remote = ReplicatedStorage:FindFirstChild "DecisionRemote" :: RemoteEvent
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Corner = util_components.Corner
local Separator = util_components.Separator

type EntityId = types.EntityId
type GridUpdate = types.GridUpdate
type HexGrid = types.HexGrid
type Entity = types.Entity

function EntityInformation(props: {
	entity_id: EntityId,
	compressed: boolean,
	on_compress: () -> (),
	on_select: () -> (),
	toggle_submenu: (submenu: any) -> (),
})
	local context = React.useContext(MainContext)
	local grid: HexGrid = context.grid
	local selection_mode_stack = context.selection_mode_stack
	local update_highlights = context.update_highlights

	local viewport_ref = React.useRef(nil :: any)
	local header_ref = React.useRef(nil :: any)
	local ref = React.useRef(nil :: any)
	local layout_ref = React.useRef(nil :: any)

	local is_update = React.useRef(false)
	React.useEffect(function()
		if is_update.current then
			TweenService:Create(ref.current, TweenInfo.new(0.2), {
				Size = UDim2.new(
					1,
					0,
					0,
					if props.compressed
						then header_ref.current.AbsoluteSize.Y
						else layout_ref.current.AbsoluteContentSize.Y
				),
			}):Play()
		else
			is_update.current = true
		end
	end, { props.compressed })

	local entity = hooks.use_synced_entity(props.entity_id)
	local shared_behavior = grid.entity_configurations[entity.type]

	React.useEffect(function()
		TweenService:Create(ref.current, TweenInfo.new(0.2), {
			Size = UDim2.new(
				1,
				0,
				0,
				if props.compressed then header_ref.current.AbsoluteSize.Y else layout_ref.current.AbsoluteContentSize.Y
			),
		}):Play()
	end, { entity })

	React.useEffect(function()
		local model = client_entity_mod.registry[entity.type].model:Clone()
		model.Parent = viewport_ref.current
		model:PivotTo(CFrame.new(0, -2, -4))

		ref.current.Size = UDim2.new(
			1,
			0,
			0,
			if props.compressed then header_ref.current.AbsoluteSize.Y else layout_ref.current.AbsoluteContentSize.Y
		)
	end, { entity.type })

	local is_deconstructing = util.table_any(entity.queued_decisions, function(v)
		return v.type == "deconstruct"
	end)

	local text_color = if is_deconstructing
		then Color3.new(0.752941, 0.121568, 0.121568)
		else if entity.status == "blueprint"
			then Color3.new(0.458823, 0.756862, 1)
			else if entity.status == "scaffold" then Color3.new(0.6, 1, 0.654901) else Color3.new(1, 1, 1)

	local player_team = grid:get_player_team(Players.LocalPlayer)

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BackgroundTransparency = 0.2,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = -shared_behavior.layer,
		Position = UDim2.fromScale(1.64, -0.264),
		ZIndex = 2,
		ref = ref,
	}, {
		Corner = React.createElement(Corner),
		Container = React.createElement("Frame", themes.theme_container {}, {
			VerticalLayout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				ref = layout_ref,
			}),
			Header = React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ref = header_ref,
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
			}, {
				title = React.createElement(
					"TextLabel",
					themes.theme_title {
						TextColor3 = text_color,
						Size = UDim2.new(1, 0, 1, 0),
						Text = shared_behavior.name,
					},
					{
						SidePad = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 15),
							PaddingRight = UDim.new(0, 15),
						}),
					}
				),

				Hitbox = React.createElement("TextButton", {
					Active = props.compressed,
					[React.Event.MouseButton1Click] = function()
						props.on_select()
					end,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					ZIndex = 10,
				}),

				Hitpoints = React.createElement(
					"Frame",
					{
						AnchorPoint = Vector2.new(1, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(1, 0, 0, 0),
						Size = UDim2.new(0, 100, 1, 0),
					},
					{
						GridLayout = React.createElement("UIGridLayout", {
							CellPadding = UDim2.fromOffset(7, 7),
							CellSize = UDim2.fromOffset(6, 6),
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						}),

						AllPad = React.createElement("UIPadding", {
							PaddingBottom = UDim.new(0, 8),
							PaddingLeft = UDim.new(0, 4),
							PaddingRight = UDim.new(0, 4),
							PaddingTop = UDim.new(0, 8),
						}),
					},
					if entity.max_health > 20
						then React.createElement("TextLabel", {
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							Size = UDim2.new(0, 100, 0, 100),
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Right,
							Text = if entity.max_health ~= math.huge
								then entity.health .. "/" .. entity.max_health
								else "--",
						})
						elseif entity.max_health == 0 then React.createElement("Frame", {
							BorderSizePixel = 1,
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundColor3 = Color3.new(0, 0, 0),
							Size = UDim2.fromOffset(100, 100),
						})
						else util.table_map(util.range(entity.max_health), function(i)
							return React.createElement("Frame", {
								BackgroundColor3 = if i <= entity.max_health - entity.health
									then Color3.new(0.7, 0.7, 0.7)
									else Color3.new(1, 1, 1),
								BorderSizePixel = 0,
								Size = UDim2.fromOffset(100, 100),
							})
						end)
				),

				SizeConstraint = React.createElement("UISizeConstraint", {
					MinSize = Vector2.new(0, 30),
				}),

				RightPad = React.createElement("UIPadding", {
					PaddingRight = UDim.new(0, 5),
				}),
			}),

			Separator = React.createElement(Separator, { LayoutOrder = 2 }),
			Body = React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 0),
			}, {

				Top = React.createElement("ScrollingFrame", {
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 1,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 150),
				}, {
					SidePad = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),
					VerticalLayout = React.createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Description = React.createElement(
						"TextLabel",
						themes.theme_description {
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 2,
							Size = UDim2.new(1, 0, 0, 30),
							Text = formatting.format_text(grid, shared_behavior.description),
						}
					),
					-- Rotation = React.createElement(
					-- 	"TextLabel",
					-- 	themes.theme_description {
					-- 		LayoutOrder = 3,
					-- 		Size = UDim2.new(1, 0, 0, 30),
					-- 		Text = "Rotation: " .. entity.rotation,
					-- 	}
					-- ),
					StatusLabel = React.createElement(
						"TextLabel",
						themes.theme_description {
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 4,
							Size = UDim2.new(1, 0, 0, 30),
							Text = "Status: " .. entity.status,
						}
					),
					DecayLabel = entity.is_decaying and React.createElement(
						"TextLabel",
						themes.theme_description {
							LayoutOrder = 5,
							Size = UDim2.new(1, 0, 0, 30),
							Text = "Decay: " .. tostring(entity.decay),
						}
					),
					TurnsUntilBuilt = entity.status == "scaffold" and React.createElement(
						"TextLabel",
						themes.theme_description {
							LayoutOrder = 5,
							Size = UDim2.new(1, 0, 0, 30),
							Text = "Turns until built: " .. tostring(entity.build_time),
						}
					),
					Items = entity.inventory and React.createElement(
						"Frame",
						{
							BackgroundTransparency = 1,
							LayoutOrder = 6,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.new(1, 0, 0, 0),
						},
						{
							HorizontalLayout = React.createElement("UIListLayout", {
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								Padding = UDim.new(0, 8),
								VerticalAlignment = Enum.VerticalAlignment.Center,
							}),
							ItemsLabel = React.createElement(
								"TextLabel",
								themes.theme_description {
									LayoutOrder = 1,
									Size = UDim2.new(0, 0, 0, 30),
									Text = "Items",
								}
							),
						},
						(function()
							local items = items_mod.into_counted_items(entity.inventory.items)
							return React.createElement(Cost, {
								cost = items,
								LayoutOrder = 2,
							})
						end)()
					),
					Costs = entity.status == "blueprint" and React.createElement(
						"Frame",
						{
							BackgroundTransparency = 1,
							LayoutOrder = 6,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.new(1, 0, 0, 0),
						},
						{},

						-- IIFE IN LUA??? :vomit:
						(function()
							local cost = {}
							for item, amount in entity.cost do
								cost[item] = `{entity.cost_fulfilled[item] or 0}/{amount}`
							end
							return React.createElement(Cost, {
								cost = cost,
							})
						end)()
					),
				}),

				VerticalLayout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Bottom = React.createElement("Frame", {
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 30),
				}, {
					AttackButton = entity.owner == player_team.id
						and (entity.type == "scout" or entity.type == "turret")
						and entity.status == "complete"
						and React.createElement(ActionButton, {
							color = Color3.fromRGB(255, 120, 120),
							Text = "Attack",
							LayoutOrder = 0,
							on_click = function()
								if entity.type == "scout" or entity.type == "turret" then
									local candidates = {}
									for _, coord in hex_grid_mod.neighbors_leq(entity.primary_coordinate, 3) do
										local instance = grid.cell_instance_map[hex_grid_mod.encode_coord(coord)]
										if
											not instance
											or not hex_grid_mod.line_of_sight(
												grid,
												entity.primary_coordinate,
												coord,
												player_team.id
											)
										then
											continue
										end
										candidates[instance] = coord
									end
									table.insert(selection_mode_stack, {
										type = "select_some_cell",
										candidates = candidates,
										on_selected = function(instance)
											decision_remote:FireServer {
												{
													type = "ability",
													ability_type = if entity.type == "scout"
														then "scout_attack"
														else "turret_attack",
													entity_id = entity.id,
													coordinate = candidates[instance],
												},
											}
										end,
									})
									update_highlights()
								end
							end,
						}),
					UseButton = entity.owner == player_team.id
						and entity.type == "solution"
						and React.createElement(ActionButton, {
							color = Color3.fromRGB(255, 255, 120),
							Text = "Use",
							LayoutOrder = 1,
							on_click = function()
								decision_remote:FireServer {
									{
										type = "ability",
										ability_type = "solution_use",
										entity_id = entity.id,
									},
								}
							end,
						}),
					DeconstructButton = entity.owner == player_team.id and React.createElement(ActionButton, {
						color = Color3.fromRGB(255, 82, 82),
						Text = if is_deconstructing then "Cancel Deconstruct" else "Deconstruct",
						LayoutOrder = 1,
						on_click = function()
							if is_deconstructing then
								decision_remote:FireServer {
									{
										type = "cancel_decision",
										entity_id = entity.id,
										decision_type = "deconstruct",
									},
								}
							else
								decision_remote:FireServer {
									{
										type = "deconstruct",
										entity_id = entity.id,
									},
								}
							end
						end,
					}),
					ToggleEnableButton = entity.owner == player_team.id
						and shared_behavior.can_disable
						and React.createElement(ActionButton, {
							color = Color3.fromRGB(255, 255, 120),
							Text = if entity.enabled then "Disable" else "Enable",
							LayoutOrder = 2,
							on_click = function()
								decision_remote:FireServer {
									{
										type = "set_entity_enabled",
										entity_id = entity.id,
										enabled = not entity.enabled,
									},
								}
							end,
						}),
					-- RotateButton = entity.owner == player_team.id and React.createElement(ActionButton, {
					-- 	color = Color3.fromRGB(120, 255, 120),
					-- 	Text = "Rotate",
					-- 	LayoutOrder = 2,
					-- 	on_click = function() end,
					-- }),
					OpenRecipeButton = entity.owner == player_team.id
						and (entity.type == "factory")
						and entity.status == "complete"
						and React.createElement(ActionButton, {
							color = Color3.fromRGB(255, 255, 120),
							Text = "Open Recipes",
							LayoutOrder = 3,
							on_click = function()
								props.toggle_submenu {
									type = "recipes",
									entity_id = entity.id,
								}
							end,
						}),
					OpenResearchButton = entity.owner == player_team.id
						and (entity.type == "laboratory")
						and entity.status == "complete"
						and React.createElement(ActionButton, {
							color = Color3.fromRGB(255, 255, 120),
							Text = "Open Research",
							LayoutOrder = 4,
							on_click = function()
								props.toggle_submenu {
									type = "research",
									entity_id = entity.id,
								}
							end,
						}),
					-- HideButton = React.createElement(ActionButton, {
					-- 	color = Color3.fromRGB(255, 255, 255),
					-- 	Text = "Hide",
					-- 	LayoutOrder = 10,
					-- 	on_click = function()
					-- 		props.on_compress()
					-- 	end,
					-- }),

					VerticalLayout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),
			}),
		}),

		ViewportFrame = React.createElement("ViewportFrame", {
			Size = UDim2.new(0, 200, 0, 150),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 0.6,
			BackgroundTransparency = 1,
			ref = viewport_ref,
		}),

		Gradient = React.createElement("UIGradient", {
			Color = ColorSequence.new {
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(53, 53, 53)),
			},
			Rotation = 90,
		}),
	})
end

return {
	EntityInformation = EntityInformation,
}
