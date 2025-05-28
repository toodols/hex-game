local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local util = require(ReplicatedStorage.Shared.util)
local world_mod = require(ReplicatedStorage.Shared.world)
local formatting = require(ReplicatedStorage.Shared.formatting)
local items_mod = require(ReplicatedStorage.Shared.items)
local team_mod = require(ReplicatedStorage.Shared.team)
local coords = require(ReplicatedStorage.Shared.coords)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

local hooks = require(ReplicatedStorage.Client.ui.hooks)
local ui_types = require(ReplicatedStorage.Client.ui.types)
local client_entity_mod = require(ReplicatedStorage.Client.ui.Parent.entity)
local context_mod = require(ReplicatedStorage.Client.ui.context)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)

local Items = require(script.Parent.items).Items
local HighlightOnHover = require(script.Parent.highlight_on_hover).HighlightOnHover
local ResearchPreview = require(script.Parent.research).ResearchPreview
local RequiredResearch = require(script.required_research).RequiredResearch
local action_buttons = require(script.action_buttons)

local Hitpoints = require(script.hitpoints).Hitpoints

local MainContext = context_mod.MainContext
local Corner = util_components.Corner
local Separator = util_components.Separator

local DeconstructButton = action_buttons.DeconstructButton
local DisguiseButton = action_buttons.DisguiseButton
local FilterButton = action_buttons.FilterButton
local AttackButton = action_buttons.AttackButton
local OpenRecipeButton = action_buttons.OpenRecipeButton
local ToggleEnableButton = action_buttons.ToggleEnableButton
local ActivateButton = action_buttons.ActivateButton
local StoreEntityButton = action_buttons.StoreEntityButton

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type EntityId = types.EntityId
type WorldUpdate = types.WorldUpdate
type World = types.World
type Entity = types.Entity
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type SelectionMode = ui_types.SelectionMode
type HexCell = types.HexCell

function OutputClock(props: { entity: Entity, LayoutOrder: number? })
	local shared_behavior = shared_entity_mod.registry[props.entity.type]
	local cycles_to_output = shared_behavior.cycles_to_output
	local should_output = props.entity.should_output

	local should_output_ref = React.useRef(should_output)
	local boxes = React.useRef {}

	React.useState(function()
		if should_output_ref ~= should_output then
			local min = math.min(should_output_ref.current, should_output)
			local max = math.max(should_output_ref.current, should_output)
			-- 1 -> 0
			for idx = min + 1, max + 1 do
				if boxes.current[idx] then
					boxes.current[idx].BackgroundColor3 = if should_output_ref + 1 >= idx
						then Color3.fromRGB(128, 128, 128)
						else Color3.fromRGB(214, 214, 214)
				end
			end
			should_output_ref.current = should_output
		end
	end, { should_output })

	return React.createElement(
		"Frame",
		{
			Size = UDim2.new(0.5, 0, 0, 10),
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
		},
		{
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 5),
			}),
		},
		util.table_map(util.table_reverse(util.range(cycles_to_output)), function(idx)
			return React.createElement("Frame", {
				Size = UDim2.new(1 / cycles_to_output, -2.5, 1, 0),
				BackgroundColor3 = if should_output_ref.current + 1 >= idx
					then Color3.fromRGB(128, 128, 128)
					else Color3.fromRGB(214, 214, 214),
				ref = function(instance)
					boxes.current[idx] = instance
				end,
			}, {
				Corner = React.createElement(Corner),
			})
		end)
	)
end

function EntityInformation(props: {
	entity_id: EntityId,
	compressed: boolean,
	LayoutOrder: number?,
	on_compress: () -> (),
	on_select: () -> (),
})
	local context = React.useContext(MainContext)
	local world: World = context.world
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local toggle_submenu = function(menu)
		context.set_submenu(function(current)
			return if util.deep_equal(current, menu) then {} else menu
		end)
	end

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
	local shared_behavior = world.entity_configurations[entity.type]

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
		local model = client_entity_mod.create_model_from_type(world, entity.type)
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

	local player_team = team_mod.team_of(world, Players.LocalPlayer)

	return React.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BackgroundTransparency = 0.2,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = props.LayoutOrder,
		Position = UDim2.new(0, 0, 0, 0),
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

				Hitpoints = React.createElement(Hitpoints, {
					entity = entity,
				}),

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
						Padding = UDim.new(0, 5),
					}),

					Description = React.createElement(
						"TextLabel",
						themes.theme_description {
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 2,
							Size = UDim2.new(1, 0, 0, 20),
							Text = formatting.format_text(world, shared_behavior.description),
						}
					),
					StatusLabel = if entity.status ~= "complete"
						then React.createElement(
							"TextLabel",
							themes.theme_description {
								AutomaticSize = Enum.AutomaticSize.Y,
								LayoutOrder = 4,
								Size = UDim2.new(1, 0, 0, 20),
								Text = "Status: " .. entity.status,
							}
						)
						else nil,
					RequiredResearchInfo = React.createElement(RequiredResearch, {
						entity_id = entity.id,
						LayoutOrder = 5,
					}),
					DecayLabel = if entity.is_decaying
						then React.createElement(
							"TextLabel",
							themes.theme_description {
								LayoutOrder = 5,
								TextColor3 = Color3.fromRGB(255, 82, 82),
								Size = UDim2.new(1, 0, 0, 20),
								Text = "Decay: " .. tostring(entity.decay) .. "/ 3",
							}
						)
						else nil,

					DisabledLabel = if entity.enabled == false
						then React.createElement(
							"TextLabel",
							themes.theme_description {
								LayoutOrder = 5,
								TextColor3 = Color3.fromRGB(255, 255, 120),
								Size = UDim2.new(1, 0, 0, 20),
								Text = "This building is disabled.",
							}
						)
						else nil,
					TurnsUntilBuilt = if entity.status == "scaffold"
						then React.createElement(
							"TextLabel",
							themes.theme_description {
								LayoutOrder = 5,
								Size = UDim2.new(1, 0, 0, 20),
								Text = "Turns Left: " .. tostring(entity.build_time),
							}
						)
						else nil,
					OutputClock = if entity.type == "extractor"
						then React.createElement(OutputClock, {
							entity = entity,
							LayoutOrder = 5,
						})
						else nil,
					Disguised = if entity.disguise
						then React.createElement(
							"TextButton",
							themes.theme_button {
								LayoutOrder = 5,
								Text = "View Disguise",
								TextColor3 = Color3.fromRGB(255, 255, 255),
								AutoButtonColor = false,
								Size = UDim2.new(0, 0, 0, 20),
								[React.Event.MouseButton1Click] = function()
									table.insert(selection_mode_stack, {
										type = "show_one_entity",
										entity_id = entity.disguise,
									})
									context.force_update()
								end,
								[React.Event.MouseEnter] = function(current)
									TweenService:Create(current, TweenInfo.new(0.5), {
										BackgroundColor3 = Color3.fromRGB(113, 172, 196),
									}):Play()
								end,
								[React.Event.MouseLeave] = function(current)
									TweenService:Create(current, TweenInfo.new(0.5), {
										BackgroundColor3 = Color3.fromRGB(163, 162, 165),
									}):Play()
								end,
							},
							{
								Padding = React.createElement("UIPadding", {
									PaddingLeft = UDim.new(0, 10),
									PaddingRight = UDim.new(0, 10),
									PaddingTop = UDim.new(0, 5),
									PaddingBottom = UDim.new(0, 5),
								}),
							}
						)
						else nil,

					Items = if entity.inventory
						then React.createElement("Frame", {
							BackgroundTransparency = 1,
							LayoutOrder = 6,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.new(1, 0, 0, 0),
						}, {
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
									Size = UDim2.new(0, 0, 0, 20),
									Text = "Items",
								}
							),
							Items = React.createElement(Items, {
								items = items_mod.into_counted_items(entity.inventory.items),
								LayoutOrder = 2,
							}),
						})
						else nil,
					Costs = if entity.status == "blueprint"
						then React.createElement("Frame", {
							BackgroundTransparency = 1,
							LayoutOrder = 6,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.new(1, 0, 0, 0),
						}, {
							Items = React.createElement(Items, {
								items = util.table_map(entity.cost, function(v, k)
									return `{entity.cost_fulfilled[k] or 0}/{v}`
								end),
							}),
						})
						else nil,

					Gap = React.createElement("Frame", {
						BackgroundTransparency = 1,
						LayoutOrder = 7,
						Size = UDim2.new(1, 0, 0, 5),
					}),

					ResearchPreview = if entity.owner == player_team.id
							and (entity.researches ~= nil)
							and entity.status == "complete"
						then React.createElement(ResearchPreview, {
							LayoutOrder = 9,
							entity_id = entity.id,
							click = function()
								toggle_submenu {
									type = "research",
									entity_id = entity.id,
								}
							end,
						})
						else nil,
					
					-- Store

					Range = if entity.type == "laboratory"
						then React.createElement(HighlightOnHover, {
							Text = `Range: {world.entity_configurations.laboratory.range}`,
							coords = util.table_values(util.table_filter_map(world.cells, function(cell)
								if cell.influences[entity.id] ~= nil then
									return cell.coordinate
								else
									return nil
								end
							end)),
						})
						else nil,

					StatusEffects = React.createElement(
						"TextLabel",
						themes.theme_description {
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 10,
							Size = UDim2.new(1, 0, 0, 20),
							Visible = #entity.effects > 0,
							Text = "Status effects: " .. table.concat(
								util.table_map(entity.effects, function(v)
									if v.duration then
										return v.type .. " (" .. v.duration .. " turns)"
									else
										return v.type
									end
								end),
								", "
							),
						}
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
					ActionButtons = React.createElement("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 70),
					}, {
						SidePad = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 15),
							PaddingRight = UDim.new(0, 15),
						}),
						HorizontalLayout = React.createElement("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, 10),
						}),
						DeconstructButton = if entity.active ~= false
								and entity.owner == player_team.id
								and not entity.is_decaying
							then React.createElement(DeconstructButton, {
								entity_id = entity.id,
								LayoutOrder = 1,
							})
							else nil,
						AttackButton = if entity.active ~= false
								and entity.owner == player_team.id
								and (entity.type == "scout" or entity.type == "turret")
								and entity.status == "complete"
							then React.createElement(AttackButton, {
								entity_id = entity.id,
								LayoutOrder = 2,
							})
							else nil,

						DisguiseButton = if entity.active ~= false
								and entity.owner == player_team.id
								and entity.type == "phony"
							then React.createElement(DisguiseButton, {
								entity_id = entity.id,
								LayoutOrder = 2,
							})
							else nil,

						FilterButton = if entity.active ~= false
								and entity.owner == player_team.id
								and entity.inventory ~= nil
							then React.createElement(FilterButton, {
								entity_id = entity.id,
								LayoutOrder = 3,
							})
							else nil,

						ActivateButton = if entity.active ~= false
								and entity.owner == player_team.id
								and (entity.type == "solution" or entity.type == "impression")
							then React.createElement(ActivateButton, {
								entity_id = entity.id,
								LayoutOrder = 4,
							})
							else nil,

						ToggleEnableButton = if entity.active ~= false
								and entity.owner == player_team.id
								and shared_behavior.can_disable
								and entity.status == "complete"
							then React.createElement(ToggleEnableButton, {
								entity_id = entity.id,
								LayoutOrder = 2,
							})
							else nil,

						OpenRecipeButton = if entity.active ~= false
								and entity.owner == player_team.id
								and (entity.type == "factory")
								and entity.status == "complete"
							then React.createElement(OpenRecipeButton, {
								entity_id = entity.id,
								LayoutOrder = 5,
							})
							else nil,

						StoreEntityButton = if entity.active ~= false
								and entity.owner == player_team.id
								and (entity.type == "terminal")
								and entity.status == "complete"
							then React.createElement(StoreEntityButton, {
								entity_id = entity.id,
								LayoutOrder = 6,
							})
							else nil,
					}),

					-- Rotate = if entity.active ~= false
					-- 		and entity.type == "torch"
					-- 		and entity.owner == player_team.id
					-- 	then React.createElement(TextActionButton, {
					-- 		color = Color3.fromRGB(255, 255, 120),
					-- 		Text = "Rotate",
					-- 		LayoutOrder = 0,
					-- 		on_click = function()

					-- 		end,
					-- 	})
					-- 	else nil,

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
