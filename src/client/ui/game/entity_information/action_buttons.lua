local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)
local util = require(ReplicatedStorage.Shared.util)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local ability_mod = require(ReplicatedStorage.Shared.ability)

local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local ui_types = require(ReplicatedStorage.Client.ui.types)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local SquareActionButton = require(ReplicatedStorage.Client.ui.game.action_button).SquareActionButton

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type SelectionMode = ui_types.SelectionMode
type EntityId = types.EntityId
type EncodedCoordinate = types.EncodedCoordinate
type World = types.World
type HexCell = types.HexCell
type Entity = types.Entity

function AttackButton(props: { ability_id: string, entity_id: EntityId, LayoutOrder: number? })
	local context = React.useContext(MainContext)
	local world: World = context.world
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local entity = hooks.use_synced_entity(props.entity_id)
	local config = world.entity_configurations[entity.type]
	local player_team = team_mod.team_of(world, Players.LocalPlayer)

	local is_attacking = util.table_any(entity.queued_decisions, function(v)
		return v.type == "ability" and v.ability_id == props.ability_id
	end)

	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://10734975486",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 120, 120),
		ImageColor3 = if is_attacking then Color3.fromRGB(255, 120, 120) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			if is_attacking then
				client_interaction_remote:FireServer {
					{
						type = "cancel_decision",
						decision_type = "ability",
						entity_id = entity.id,
						ability_id = props.ability_id,
					},
				}
				return
			end
			local ability = config.abilities[props.ability_id]
			local candidates =
				ability_mod.entity_attack_candidates(world, entity, ability.range, player_team.id, ability.ignore_los)

			table.insert(selection_mode_stack, {
				type = "select_some_cell",
				candidates = candidates,
				on_selected = function(coord)
					client_interaction_remote:FireServer {
						{
							type = "ability",
							ability_id = props.ability_id,
							entity_id = entity.id,
							coordinate = coord,
						},
					}
				end,
			})
		end,
	})
end

function DeconstructButton(props: { entity_id: EntityId, LayoutOrder: number?, active: boolean? })
	local entity = hooks.use_synced_entity(props.entity_id)

	local is_deconstructing = util.table_any(entity.queued_decisions, function(v)
		return v.type == "deconstruct"
	end)

	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://11768918600",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 0, 0),
		ImageColor3 = if is_deconstructing then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(200, 200, 200),
		action_id = "deconstruct",
		active = props.active,
		on_click = function()
			if is_deconstructing then
				client_interaction_remote:FireServer {
					{
						type = "cancel_decision",
						entity_id = entity.id,
						decision_type = "deconstruct",
					},
				}
			else
				client_interaction_remote:FireServer {
					{
						type = "deconstruct",
						entity_id = entity.id,
					},
				}
			end
		end,
	})
end

function DisguiseButton(props: { ability_id: string, entity_id: EntityId, LayoutOrder: number?, active: boolean? })
	local context = React.useContext(MainContext)
	local world: World = context.world
	local entity = hooks.use_synced_entity(props.entity_id)
	local shared_behavior = world.entity_configurations[entity.type]
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local is_disguising = util.table_any(entity.queued_decisions, function(v)
		return v.type == "ability" and v.ability_id == "disguise"
	end)
	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://6034467796",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 0, 0),
		ImageColor3 = if is_disguising then Color3.fromRGB(113, 172, 196) else Color3.fromRGB(200, 200, 200),
		action_id = "primary_ability",
		active = props.active,
		on_click = function()
			local ability = shared_behavior.abilities.disguise
			local candidates: { [EncodedCoordinate]: true } = {}
			for _, coord in coords_mod.neighbors_leq(entity.primary_coordinate, ability.range) do
				local cell = world:get_cell(coord)
				if cell == nil or next(cell.entities) == nil then
					continue
				end
				local encoded_coord = coords_mod.encode_coord(coord)
				candidates[encoded_coord] = true
			end
			table.insert(selection_mode_stack, {
				type = "select_some_cell",
				candidates = candidates,
				on_selected = function(coord)
					client_interaction_remote:FireServer {
						{
							type = "ability",
							ability_id = "disguise",
							entity_id = entity.id,
							coordinate = coord,
						},
					}
				end,
			})
		end,
	})
end

function FilterButton(props: { entity_id: EntityId, LayoutOrder: number?, active: boolean? })
	local entity = hooks.use_synced_entity(props.entity_id)
	local context = React.useContext(MainContext)

	local toggle_submenu = function(menu)
		context.set_submenu(function(current)
			return if util.deep_equal(current, menu) then {} else menu
		end)
	end

	local opened = context.submenu.type == "item_filters" and context.submenu.entity_id == props.entity_id

	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://6023426984",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(163, 255, 150),
		ImageColor3 = if opened then Color3.fromRGB(163, 255, 150) else Color3.fromRGB(200, 200, 200),
		action_id = "filter",
		active = props.active,
		on_click = function()
			toggle_submenu {
				type = "item_filters",
				entity_id = entity.id,
			}
		end,
	})
end

function RotateButton(props: { entity_id: EntityId, LayoutOrder: number? })
	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://6031763429",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(232, 255, 26),
		on_click = function()
			client_interaction_remote:FireServer {
				{
					type = "rotate",
					entity_id = props.entity_id,
				},
			}
		end,
	})
end

-- ActivateButton: Activates the "solution" entity's ability.
function ActivateButton(props: { ability_id: string, entity_id: EntityId, LayoutOrder: number? })
	local entity = hooks.use_synced_entity(props.entity_id)

	local is_using = util.table_any(entity.queued_decisions, function(v)
		return v.type == "ability" and v.ability_id == props.ability_id
	end)

	return React.createElement(SquareActionButton, {
		Image = "http://www.roblox.com/asset/?id=6026663699",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 255, 120),
		ImageColor3 = if is_using then Color3.fromRGB(255, 255, 120) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			if is_using then
				client_interaction_remote:FireServer {
					{
						type = "cancel_decision",
						entity_id = entity.id,
						decision_type = "ability",
						ability_id = props.ability_id,
					},
				}
				return
			else
				client_interaction_remote:FireServer {
					{
						type = "ability",
						ability_id = props.ability_id,
						entity_id = entity.id,
					},
				}
			end
		end,
	})
end

-- ToggleEnableButton: Toggles the enabled state of an entity, lights up when enabled.
function ToggleEnableButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local entity = hooks.use_synced_entity(props.entity_id)

	local enabled = entity.enabled
	return React.createElement(SquareActionButton, {
		Image = "http://www.roblox.com/asset/?id=6031084743",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 255, 120),
		ImageColor3 = if not enabled then Color3.fromRGB(255, 255, 120) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			client_interaction_remote:FireServer {
				{
					type = "set_entity_enabled",
					entity_id = entity.id,
					enabled = not enabled,
				},
			}
		end,
	})
end

-- OpenRecipeButton: Opens the recipes submenu for a factory entity.
function OpenRecipeButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local entity = hooks.use_synced_entity(props.entity_id)
	local context = React.useContext(MainContext)
	local toggle_submenu = function(menu)
		context.set_submenu(function(current)
			return if util.deep_equal(current, menu) then {} else menu
		end)
	end

	local opened = context.submenu.type == "recipes" and context.submenu.entity_id == props.entity_id

	return React.createElement(SquareActionButton, {
		Image = "http://www.roblox.com/asset/?id=6035190838",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 255, 120),
		ImageColor3 = if opened then Color3.fromRGB(255, 255, 120) else Color3.fromRGB(200, 200, 200),
		action_id = "open_recipes",
		on_click = function()
			toggle_submenu {
				type = "recipes",
				entity_id = entity.id,
			}
		end,
	})
end

function StoreEntityButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local context = React.useContext(MainContext)
	local world = context.world
	local entity = hooks.use_synced_entity(props.entity_id)
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	return React.createElement(SquareActionButton, {
		Image = "http://www.roblox.com/asset/?id=6035067842",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 255, 120),
		ImageColor3 = Color3.fromRGB(200, 200, 200),
		on_click = function()
			local candidates = coords_mod.neighbors_eq(entity.primary_coordinate, 1)
			table.insert(selection_mode_stack, {
				type = "select_some_cell",
				candidates = candidates,
				on_selected = function(coord)
					client_interaction_remote:FireServer {
						{
							type = "store_entity",
							entity_id = entity.id,
							coord = coord,
						},
					}
				end,
			})
		end,
	})
end

function DeployEntityButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local context = React.useContext(MainContext)
	local world = context.world
	local entity = hooks.use_synced_entity(props.entity_id)
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local stored_entity = entity.stored_entity
	return React.createElement(SquareActionButton, {
		Image = "http://www.roblox.com/asset/?id=6023426930",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(119, 14, 151),
		ImageColor3 = Color3.fromRGB(200, 200, 200),
		on_click = function()
			local candidates = coords_mod.neighbors_eq(entity.primary_coordinate, 1)
			table.insert(selection_mode_stack, {
				type = "select_some_cell",
				candidates = candidates,
				on_selected = function(coord)
					client_interaction_remote:FireServer {
						{
							type = "deploy_entity",
							entity_id = stored_entity,
							coord = coord,
						},
					}
				end,
			})
		end,
	})
end

return {
	AttackButton = AttackButton,
	DisguiseButton = DisguiseButton,
	FilterButton = FilterButton,
	RotateButton = RotateButton,
	DeconstructButton = DeconstructButton,
	ActivateButton = ActivateButton,
	ToggleEnableButton = ToggleEnableButton,
	OpenRecipeButton = OpenRecipeButton,
	StoreEntityButton = StoreEntityButton,
}
