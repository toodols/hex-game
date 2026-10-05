local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local util = require(ReplicatedStorage.Shared.util)
local formatting = require(ReplicatedStorage.Shared.formatting)
local items_mod = require(ReplicatedStorage.Shared.items)

local ui_types = require(ReplicatedStorage.Client.ui.types)
local client_entity_mod = require(ReplicatedStorage.Client.ui.Parent.entity)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Items = require(ReplicatedStorage.Client.ui.game.items).Items
local HighlightOnHover = require(ReplicatedStorage.Client.ui.game.highlight_on_hover).HighlightOnHover
local ResearchPreview = require(ReplicatedStorage.Client.ui.game.research).ResearchPreview

local RequiredResearch = require(script.Parent.required_research).RequiredResearch
local action_buttons = require(script.Parent.action_buttons)
local Hitpoints = require(script.Parent.hitpoints).Hitpoints
local context_mod = require(ReplicatedStorage.Client.ui.context)
local team_mod = require(ReplicatedStorage.Shared.team)

local MainContext = context_mod.MainContext
local Separator = util_components.Separator

local DeconstructButton = action_buttons.DeconstructButton
local DisguiseButton = action_buttons.DisguiseButton
local FilterButton = action_buttons.FilterButton
local AttackButton = action_buttons.AttackButton
local OpenRecipeButton = action_buttons.OpenRecipeButton
local ToggleEnableButton = action_buttons.ToggleEnableButton
local ActivateButton = action_buttons.ActivateButton
local StoreEntityButton = action_buttons.StoreEntityButton

type EntityId = types.EntityId
type WorldUpdate = types.WorldUpdate
type World = types.World
type Entity = types.Entity
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type SelectionMode = ui_types.SelectionMode
type HexCell = types.HexCell

function OutputClock(props: { entity: Entity, LayoutOrder: number? })
	local world: World = React.useContext(MainContext).world
	local shared_behavior = world.entity_configurations[props.entity.type]
	local cycles_to_output = shared_behavior.cycles_to_output
	local should_output = props.entity.should_output

	return React.createElement(
		"Frame",
		{
			Size = UDim2.new(0.5, 0, 0, 10),
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			[React.Tag] = "list-h list-cc list-pad-5",
		},
		util.table_map(util.table_reverse(util.range(cycles_to_output)), function(idx)
			return React.createElement("Frame", {
				Size = UDim2.new(1 / cycles_to_output, -2.5, 1, 0),
				BackgroundColor3 = if should_output + 1 >= idx
					then Color3.fromRGB(128, 128, 128)
					else Color3.fromRGB(214, 214, 214),
			})
		end)
	)
end

function name_color(entity: Entity): Color3
	local is_deconstructing = util.table_any(entity.queued_decisions, function(v)
		return v.type == "deconstruct"
	end)

	if is_deconstructing then
		return Color3.new(0.752941, 0.121568, 0.121568)
	elseif entity.status == "blueprint" then
		return Color3.new(0.458823, 0.756862, 1)
	elseif entity.status == "scaffold" then
		return Color3.new(0.6, 1, 0.654901)
	else
		return Color3.new(1, 1, 1)
	end
end

local Building = React.forwardRef(function(
	props: {
		entity: Entity,
		header_ref: { current: Frame? },
		active: boolean,
		on_select: () -> (),
	},
	ref
)
	local context = React.useContext(MainContext)
	local world: World = context.world
	local entity = props.entity

	local config = world.entity_configurations[entity.type]
	local player_team = team_mod.team_of(world, Players.LocalPlayer)

	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local toggle_submenu = function(menu)
		context.set_submenu(function(current)
			return if util.deep_equal(current, menu) then {} else menu
		end)
	end
	local header_ref = props.header_ref
	local viewport_ref = React.useRef(nil :: any)

	React.useEffect(function()
		local model = client_entity_mod.create_model_from_type(world, entity.type)
		model.Parent = viewport_ref.current
		model:PivotTo(CFrame.new(0, -2, -4))
	end, { entity.type })

	return React.createElement(React.Fragment, {}, {
		Container = React.createElement("Frame", {
			[React.Tag] = "container list-v list-pad-4",
			ref = ref,
		}, {
			Header = React.createElement("Frame", {
				ref = header_ref,
				LayoutOrder = 1,
				[React.Tag] = "container-v pad-r-5",
			}, {
				title = React.createElement("TextLabel", {
					TextColor3 = name_color(entity),
					Size = UDim2.new(1, 0, 1, 0),
					Text = config.name,
					[React.Tag] = "subtitle pad-h-10",
				}),

				Hitbox = React.createElement("TextButton", {
					Active = not props.active,
					[React.Event.MouseButton1Click] = function()
						props.on_select()
					end,
					[React.Tag] = "container",
					Text = "",
					ZIndex = 10,
				}),

				Hitpoints = React.createElement(Hitpoints, {
					entity_id = entity.id,
				}),

				SizeConstraint = React.createElement("UISizeConstraint", {
					MinSize = Vector2.new(0, 30),
				}),
			}),

			Separator = React.createElement(Separator, { LayoutOrder = 2 }),
			Body = React.createElement("Frame", {
				LayoutOrder = 3,
				[React.Tag] = "container-v list-v",
			}, {
				Top = React.createElement("ScrollingFrame", {
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 150),
					[React.Tag] = "pad-h-10 container-scroll-v list-v list-pad-5",
				}, {
					Description = React.createElement("TextLabel", {
						LayoutOrder = 2,
						Text = formatting.format_text(world, config.description),
						[React.Tag] = "description",
					}),
					StatusLabel = if entity.status ~= "complete"
						then React.createElement("TextLabel", {
							LayoutOrder = 4,
							Text = "Status: " .. entity.status,
							[React.Tag] = "description",
						})
						else nil,
					RequiredResearchInfo = React.createElement(RequiredResearch, {
						entity_id = entity.id,
						LayoutOrder = 5,
					}),
					DecayLabel = if entity.is_decaying
						then React.createElement("TextLabel", {
							LayoutOrder = 5,
							TextColor3 = Color3.fromRGB(255, 82, 82),
							[React.Tag] = "description",
							Text = "Decay: " .. tostring(entity.decay) .. "/ 3",
						})
						else nil,

					DisabledLabel = if entity.enabled == false
						then React.createElement("TextLabel", {
							LayoutOrder = 5,
							TextColor3 = Color3.fromRGB(255, 255, 120),
							[React.Tag] = "description",
							Text = "This building is disabled.",
						})
						else nil,
					TurnsUntilBuilt = if entity.status == "scaffold"
						then React.createElement("TextLabel", {
							LayoutOrder = 5,
							[React.Tag] = "description",
							Text = "Turns Left: " .. tostring(entity.build_time),
						})
						else nil,
					OutputClock = if entity.type == "extractor"
						then React.createElement(OutputClock, {
							entity = entity,
							LayoutOrder = 5,
						})
						else nil,
					Disguised = if entity.disguise
						then React.createElement("TextButton", {
							LayoutOrder = 5,
							Text = "View Disguise",
							[React.Tag] = "pad-h-10 pad-v-5",
							AutoButtonColor = false,
							BackgroundColor3 = Color3.fromRGB(163, 162, 165),
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
						})
						else nil,

					Items = if entity.inventory
						then React.createElement("Frame", {
							BackgroundTransparency = 1,
							LayoutOrder = 6,
							AutomaticSize = Enum.AutomaticSize.Y,
							[React.Tag] = "list-h list-pad-5 list-cl",
							Size = UDim2.new(1, 0, 0, 0),
						}, {
							ItemsLabel = React.createElement("TextLabel", {
								LayoutOrder = 1,
								AutomaticSize = Enum.AutomaticSize.X,
								Size = UDim2.new(0, 0, 0, 20),
								[React.Tag] = "description",
								Text = "Items",
							}),
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
							active = props.active,
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

					StatusEffects = React.createElement("TextLabel", {
						LayoutOrder = 10,
						Visible = #entity.effects > 0,
						[React.Tag] = "description",
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
					}),
				}),

				Bottom = React.createElement("Frame", {
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 30),
					[React.Tag] = "container-v list-v list-pad-2",
				}, {
					ActionButtons = React.createElement(
						"Frame",
						{
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 70),
							[React.Tag] = "list-h list-pad-5 list-cl pad-h-10",
						},
						{
							DeconstructButton = if entity.active ~= false
									and entity.owner == player_team.id
									and not entity.is_decaying
								then React.createElement(DeconstructButton, {
									active = props.active,
									entity_id = entity.id,
									LayoutOrder = 1,
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

							ToggleEnableButton = if entity.active ~= false
									and entity.owner == player_team.id
									and config.can_disable
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
						},
						if entity.active == true and entity.owner == player_team.id
							then util.table_map(config.abilities, function(ability, ability_id)
								if ability.type == "cannon" then
									return React.createElement(AttackButton, {
										entity_id = entity.id,
										ability_id = ability_id,
										action_id = "primary_ability",
										LayoutOrder = 10,
										active = props.active,
									})
								elseif ability.type == "disguise" then
									return React.createElement(DisguiseButton, {
										entity_id = entity.id,
										ability_id = ability_id,
										action_id = "primary_ability",
										LayoutOrder = 10,
									})
								elseif ability.type == "solution_activate" then
									return React.createElement(ActivateButton, {
										entity_id = entity.id,
										ability_id = ability_id,
										action_id = "primary_ability",
										LayoutOrder = 10,
									})
								elseif ability.type == "impression_activate" then
									return React.createElement(ActivateButton, {
										entity_id = entity.id,
										ability_id = ability_id,
										action_id = "primary_ability",
										LayoutOrder = 10,
									})
								elseif ability.type == "rash" then
									return React.createElement(AttackButton, {
										entity_id = entity.id,
										ability_id = ability_id,
										action_id = "primary_ability",
										LayoutOrder = 10,
									})
								else
									error("Unknown ability type: " .. ability.type)
								end
							end)
							else nil
					),
				}),
			}),
		}),

		ViewportFrame = React.createElement("ViewportFrame", {
			Size = UDim2.new(0, 200, 0, 150),
			[React.Tag] = "align-cc",
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
end)

return {
	Building = Building,
}
